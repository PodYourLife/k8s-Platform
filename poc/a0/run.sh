#!/usr/bin/env bash
# shellcheck disable=SC2329 # predicates are invoked indirectly through wait_until
# ADR-0001 POC A0 on Kind, plus the ADR-0023 convergence test.
# Usage: POC_REVISION=<commit sha> ARGOCD_VERSION=v3.6.1 poc/a0/run.sh
# Requires a running Kind cluster (kubectl context) and yq.
set -euo pipefail

POC_DIR="$(cd "$(dirname "$0")" && pwd)"
SUMMARY_FILE="${GITHUB_STEP_SUMMARY:-/dev/stdout}"
: "${POC_REVISION:?POC_REVISION must be the commit under test}"
: "${ARGOCD_VERSION:?ARGOCD_VERSION must be set}"
FAILED_CRITERIA=0

report() { # report <criterion> <PASS|FAIL> <detail>
  echo "| $1 | $2 | $3 |" >> "$SUMMARY_FILE"
  echo "[$2] $1 — $3"
  if [ "$2" = "FAIL" ]; then FAILED_CRITERIA=$((FAILED_CRITERIA + 1)); fi
}

wait_until() { # wait_until <timeout seconds> <command...>; true once the command succeeds
  local timeout_seconds="$1"; shift
  local deadline=$((SECONDS + timeout_seconds))
  until "$@" > /dev/null 2>&1; do
    if [ "$SECONDS" -ge "$deadline" ]; then return 1; fi
    sleep 5
  done
}

app_field() { # app_field <application> <jsonpath>
  kubectl -n argocd get application "$1" -o "jsonpath=$2"
}

app_synced_healthy() {
  [ "$(app_field "$1" '{.status.sync.status}')" = "Synced" ] \
    && [ "$(app_field "$1" '{.status.health.status}')" = "Healthy" ]
}

appset_has_error() { # appset_has_error <applicationset> <message fragment>
  kubectl -n argocd get applicationset "$1" -o json \
    | jq -e --arg fragment "$2" '.status.conditions[]? | select(.type == "ErrorOccurred" and .status == "True" and (.message | contains($fragment)))'
}

app_has_error() { # app_has_error <application> <message fragment>
  kubectl -n argocd get application "$1" -o json \
    | jq -e --arg fragment "$2" '[.status.conditions[]?.message, .status.operationState.message] | map(select(. != null)) | any(contains($fragment))'
}

app_sync_failed() {
  local phase
  phase="$(app_field "$1" '{.status.operationState.phase}')"
  [ "$phase" = "Failed" ] || [ "$phase" = "Error" ] || [ "$(app_field "$1" '{.status.operationState.retryCount}')" -ge 1 ] 2>/dev/null
}

apply_at_revision() { # apply_at_revision <file>: pin every ApplicationSet to the commit under test
  yq '(select(.kind == "ApplicationSet") | .spec.template.spec.source.targetRevision) = strenv(POC_REVISION)' "$1" \
    | kubectl apply -f -
}

{
  echo "## POC A0 — revision \`${POC_REVISION}\`, Argo CD ${ARGOCD_VERSION}"
  echo "| Criterion | Result | Detail |"
  echo "|---|---|---|"
} >> "$SUMMARY_FILE"

echo "::group::Install Argo CD ${ARGOCD_VERSION}"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd --server-side --force-conflicts \
  -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"
for deployment_name in argocd-repo-server argocd-applicationset-controller argocd-redis argocd-server; do
  kubectl -n argocd rollout status "deployment/${deployment_name}" --timeout=300s
done
kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=300s
kubectl create namespace poc-a0 --dry-run=client -o yaml | kubectl apply -f -
echo "::endgroup::"

# Criterion 1 — the cluster Secret carries the contract (ADR-0001 D3). Built here,
# never committed (ADR-0005); in real clusters platform-bot writes it (ADR-0001 D4).
kubectl -n argocd create secret generic in-cluster \
    --from-literal=name=in-cluster \
    --from-literal=server=https://kubernetes.default.svc \
    --from-literal=config='{"tlsClientConfig":{"insecure":false}}' \
    --dry-run=client -o yaml \
  | kubectl label --local -f - -o yaml \
    argocd.argoproj.io/secret-type=cluster \
    platform.podyourlife.io/managed=true \
    platform.podyourlife.io/cloud=kind \
    platform.podyourlife.io/environment=dev \
    platform.podyourlife.io/region=local \
    platform.podyourlife.io/identity_mode=none \
    platform.podyourlife.io/secret_store_provider=kubernetes \
  | kubectl annotate --local -f - -o yaml \
    platform.podyourlife.io/cluster_name=poc-a0 \
    platform.podyourlife.io/dataset_bucket= \
    platform.podyourlife.io/identity_reference= \
  | kubectl apply -f -
contract_label_count="$(kubectl -n argocd get secret in-cluster -o json \
  | jq '[.metadata.labels, .metadata.annotations] | map(keys[]) | map(select(startswith("platform.podyourlife.io/"))) | length')"
if [ "$contract_label_count" -ge 9 ]; then
  report "1. Contract in the cluster Secret" PASS "${contract_label_count} prefixed labels and annotations"
else
  report "1. Contract in the cluster Secret" FAIL "only ${contract_label_count} prefixed keys"
fi

# Criterion 2 — the cluster generator renders values-kind.yaml and values-dev.yaml.
apply_at_revision "${POC_DIR}/argocd/contract.yaml"
contract_app="poc-a0-contract-dev"
if wait_until 300 app_synced_healthy "$contract_app"; then
  rendered="$(kubectl -n poc-a0 get configmap poc-a0-contract -o jsonpath='{.data.cloudSource}/{.data.environmentSource}')"
  if [ "$rendered" = "values-kind.yaml/values-dev.yaml" ]; then
    report "2. Cluster generator uses values-kind + values-dev" PASS "ConfigMap rendered ${rendered}"
  else
    report "2. Cluster generator uses values-kind + values-dev" FAIL "ConfigMap rendered '${rendered}'"
  fi
else
  report "2. Cluster generator uses values-kind + values-dev" FAIL "${contract_app} not Synced/Healthy after 300s"
fi

# Criterion 3 — removing a contract key fails generation (missingkey=error).
kubectl -n argocd label secret in-cluster platform.podyourlife.io/environment-
if wait_until 120 appset_has_error poc-a0-contract "contract key platform.podyourlife.io/environment missing"; then
  # Fail closed must not mean "delete": the existing Application has to survive.
  sleep 30
  if kubectl -n argocd get application "$contract_app" > /dev/null 2>&1; then
    report "3. Missing contract key fails generation" PASS "ErrorOccurred: contract key missing; ${contract_app} kept, not pruned"
  else
    report "3. Missing contract key fails generation" FAIL "generation failed but ${contract_app} was deleted"
  fi
else
  report "3. Missing contract key fails generation" FAIL "no ErrorOccurred condition after 120s"
  echo "::group::Diagnostics for criterion 3"
  kubectl -n argocd get applicationset poc-a0-contract -o json | jq '.status.conditions'
  kubectl -n argocd get applications -o wide
  echo "::endgroup::"
fi
kubectl -n argocd label secret in-cluster platform.podyourlife.io/environment=dev --overwrite

# Criterion 4 — a missing provider values file fails the sync (no ignoreMissingValueFiles).
kubectl -n argocd label secret in-cluster platform.podyourlife.io/cloud=absent --overwrite
if wait_until 180 app_has_error "$contract_app" "values-absent.yaml"; then
  report "4. Missing values-<cloud>.yaml fails the sync" PASS "error references values-absent.yaml"
else
  report "4. Missing values-<cloud>.yaml fails the sync" FAIL "no error referencing values-absent.yaml after 180s"
fi
kubectl -n argocd label secret in-cluster platform.podyourlife.io/cloud=kind --overwrite

# Criterion 5 — no __*__ token on main. Reported only: removal is phase C1.
placeholder_files="$(git -C "${POC_DIR}/../.." grep -lE '__[A-Z][A-Z0-9_]*__' -- '*.yaml' '*.tf' '*.tfvars' ':!docs/' ':!poc/' | wc -l)"
if [ "$placeholder_files" -eq 0 ]; then
  report "5. No __*__ token on main" PASS "0 files"
else
  echo "| 5. No __*__ token on main | EXPECTED FAIL | ${placeholder_files} files, removal planned in phase C1 |" >> "$SUMMARY_FILE"
  echo "[EXPECTED FAIL] 5. ${placeholder_files} files still contain __*__ tokens (phase C1)"
fi

# ADR-0023 — a consumer applied before its CRD fails, then converges by retry.
apply_at_revision <(yq 'select(.metadata.name == "poc-a0-consumer")' "${POC_DIR}/argocd/convergence.yaml")
if wait_until 180 app_sync_failed poc-a0-consumer; then
  consumer_failed_detail="sync failed without its CRD, as expected"
  apply_at_revision <(yq 'select(.metadata.name == "poc-a0-crd")' "${POC_DIR}/argocd/convergence.yaml")
  crd_applied_at=$SECONDS
  if wait_until 420 kubectl -n poc-a0 get widget poc-a0-widget \
     && wait_until 120 app_synced_healthy poc-a0-consumer; then
    report "ADR-0023. Consumer converges by retry" PASS "${consumer_failed_detail}; converged $((SECONDS - crd_applied_at))s after the CRD Application"
  else
    report "ADR-0023. Consumer converges by retry" FAIL "consumer not converged 540s after the CRD Application"
  fi
else
  report "ADR-0023. Consumer converges by retry" FAIL "consumer sync never failed without its CRD (test invalid)"
fi

echo "::group::Final Application state"
kubectl -n argocd get applications -o wide || true
kubectl -n argocd get applicationsets -o wide || true
echo "::endgroup::"

exit "$FAILED_CRITERIA"
