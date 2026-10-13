> [!WARNING]
> **Obsolete — see [ADR-0001](../../docs/adr/0001-fondations.md).** This document describes the model replaced by ADR-0001 (environment branches, `__PLACEHOLDER__` hydration, `platform-bot env` commands, AWS as the only target). It will be rewritten in phase E1. Still-valid content is tracked in the [traceability table](../../docs/adr/0001-foundations/traceability.md).

# _ci

CI/CD tooling configuration — shared across all Terraform environments.

## Files

| File | Purpose |
|------|---------|
| `.terraform-version` | Pinned Terraform version for tfenv |
| `.tflint.hcl` | TFLint rules — naming conventions, documented variables/outputs, typed variables |
| `.pre-commit-config.yaml` | Pre-commit hooks — fmt, validate, tflint, trivy, secret detection |
| `github-actions/terraform-shared.yml` | CI pipeline for `_core/shared` — plan on PR, apply on merge |
| `github-actions/terraform-platform.yml` | CI pipeline for `domains/platform` — plan on PR, apply on merge |

## Local setup

```bash
# Install tfenv and use pinned version
tfenv install
tfenv use

# Install pre-commit hooks (run once per clone)
pip install pre-commit
pre-commit install

# Run all hooks manually
pre-commit run --all-files
```

## CI pipeline flow

```
PR opened
  → lint (terraform fmt --check, tflint)
  → plan dev + staging + prod (comment on PR)

Merge to main
  → apply dev
  → apply staging
  → apply prod
```

Each environment requires manual approval in GitHub Environments before apply in staging and prod.
