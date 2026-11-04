#!/usr/bin/env bash
# kubeconform-gate.sh — strict schema validation of every raw manifest and
# every rendered release. CRDs are validated against the datreeio CRDs
# catalog; a resource without any schema is an error, never silently skipped.
set -euo pipefail

readonly RENDER_DIR="${RENDER_DIR:-${RUNNER_TEMP:-$PWD}/.ci-rendered}"
readonly KUBERNETES_VERSION="${KUBERNETES_VERSION:-1.33.0}"
readonly CRD_SCHEMA_LOCATION='https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'
readonly MANIFEST_ROOTS=(
  argocd
  kubernetes/manifests
  kubernetes/namespaces
  kubernetes/policies
  kubernetes/secrets
  "$RENDER_DIR"
)

kubeconform \
  -strict \
  -summary \
  -output text \
  -kubernetes-version "$KUBERNETES_VERSION" \
  -schema-location default \
  -schema-location "$CRD_SCHEMA_LOCATION" \
  "${MANIFEST_ROOTS[@]}"
