#!/usr/bin/env bash
# placeholder-ratchet.sh — the __TOKEN__ count on deployable surfaces may only
# go down (ADR-0001: main carries no env placeholders once C1 is done).
#
# - count above baseline  -> fail: a change reintroduced placeholders.
# - count below baseline  -> fail: lower the baseline in the same PR, so the
#                            progress is recorded and cannot be undone later.
# - count equal           -> pass.
# Markdown is excluded: docs describe tokens, they do not deploy them.
set -euo pipefail

readonly BASELINE_FILE="scripts/ci/placeholder-baseline.txt"
readonly TOKEN_PATTERN='__[A-Z][A-Z0-9_]*__'
readonly DEPLOYABLE_PATHS=(argocd kubernetes terraform istio platform.yaml ':!*.md')

baseline_count="$(grep -vE '^\s*(#|$)' "$BASELINE_FILE" | head -n1)"
current_count="$(git grep -ohE "$TOKEN_PATTERN" -- "${DEPLOYABLE_PATHS[@]}" | wc -l | tr -d ' ')"

echo "Placeholder tokens on deployable surfaces: current=$current_count baseline=$baseline_count"

if (( current_count > baseline_count )); then
  echo "New placeholder tokens introduced:" >&2
  git grep -nE "$TOKEN_PATTERN" -- "${DEPLOYABLE_PATHS[@]}" >&2
  exit 1
fi
if (( current_count < baseline_count )); then
  echo "Token count dropped — set $BASELINE_FILE to $current_count in this PR." >&2
  exit 1
fi
