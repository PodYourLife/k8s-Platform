#!/usr/bin/env bash
# kyverno-gate.sh — evaluates the platform ClusterPolicies against the rendered
# releases, with PolicyExceptions applied, and fails on any violation.
#
# Why policies and exceptions are split: when a PolicyException sits in the
# directory passed to `kyverno apply`, the CLI (v1.14) loads zero rules and
# reports a green "pass: 0" — a gate that can never fail. The guard on the
# loaded rule count below makes that regression impossible to miss.
set -euo pipefail

readonly POLICY_DIR="kubernetes/policies"
readonly RENDER_DIR="${RENDER_DIR:-${RUNNER_TEMP:-$PWD}/.ci-rendered}"

policy_files=()
exception_files=()
for manifest_file in "$POLICY_DIR"/*.yaml; do
  if grep -qE '^kind:[[:space:]]*PolicyException' "$manifest_file"; then
    exception_files+=("$manifest_file")
  elif grep -qE '^kind:[[:space:]]*ClusterPolicy' "$manifest_file"; then
    policy_files+=("$manifest_file")
  else
    echo "Unexpected manifest kind in $manifest_file" >&2
    exit 1
  fi
done

exception_args=()
for exception_file in "${exception_files[@]}"; do
  exception_args+=(--exception "$exception_file")
done

apply_output="$(kyverno apply "${policy_files[@]}" \
  --resource "$RENDER_DIR" \
  "${exception_args[@]}" \
  --audit-warn \
  --detailed-results 2>&1)" || apply_status=$?
echo "$apply_output"

loaded_rule_count="$(echo "$apply_output" | sed -nE 's/^Applying ([0-9]+) policy rule.*/\1/p')"
if [[ -z "$loaded_rule_count" || "$loaded_rule_count" -eq 0 ]]; then
  echo "Kyverno loaded no rules — the gate would pass vacuously." >&2
  exit 1
fi
exit "${apply_status:-0}"
