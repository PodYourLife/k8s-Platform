#!/usr/bin/env bash
# render-charts.sh — lints every in-repo chart, then renders the releases that
# ArgoCD actually deploys into $RENDER_DIR for kubeconform and Kyverno.
#
# A release is "chart path|values file|release name|namespace". The list mirrors
# the Applications that point at in-repo charts; update it when one is added.
set -euo pipefail

readonly RENDER_DIR="${RENDER_DIR:-${RUNNER_TEMP:-$PWD}/.ci-rendered}"
readonly CHART_PATHS=(
  kubernetes/helm/ml-batch-job
  kubernetes/helm/sample-app
  istio/helm
)
readonly DEPLOYED_RELEASES=(
  "kubernetes/helm/ml-batch-job|kubernetes/helm/values/quanvnn-dev.yaml|quanvnn|ml"
  "istio/helm|istio/helm/values.yaml|istio-config|istio-system"
)

rm -rf "$RENDER_DIR" && mkdir -p "$RENDER_DIR"

for chart_path in "${CHART_PATHS[@]}"; do
  echo "::group::helm lint $chart_path"
  # Charts with inputs that deliberately have no default ship them in
  # ci/*-values.yaml (Helm convention); lint once per file when present.
  lint_values_files=("$chart_path"/ci/*-values.yaml)
  if [[ -e "${lint_values_files[0]}" ]]; then
    for lint_values_file in "${lint_values_files[@]}"; do
      helm lint --strict "$chart_path" --values "$lint_values_file"
    done
  else
    helm lint --strict "$chart_path"
  fi
  echo "::endgroup::"
done

for release_spec in "${DEPLOYED_RELEASES[@]}"; do
  IFS='|' read -r chart_path values_file release_name release_namespace <<< "$release_spec"
  rendered_file="$RENDER_DIR/${release_name}.yaml"
  helm template "$release_name" "$chart_path" \
    --namespace "$release_namespace" \
    --values "$values_file" > "$rendered_file"
  echo "Rendered $release_name ($chart_path) -> $rendered_file"
done
