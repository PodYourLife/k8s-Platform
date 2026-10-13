> [!WARNING]
> **Obsolete — see [ADR-0001](../../../docs/adr/0001-fondations.md).** This document describes the model replaced by ADR-0001 (environment branches, `__PLACEHOLDER__` hydration, `platform-bot env` commands, AWS as the only target). It will be rewritten in phase C2. Still-valid content is tracked in the [traceability table](../../../docs/adr/0001-foundations/traceability.md).

# _core/shared

Cross-domain cluster foundation — provisioned once per environment, consumed by all domains via `terraform_remote_state`.

## Environments

| Environment | Compliance | State key |
|-------------|-----------|-----------|
| [`dev`](./dev/) | `none` | `core/shared/dev/terraform.tfstate` |
| [`staging`](./staging/) | `soc2` | `core/shared/staging/terraform.tfstate` |
| [`prod`](./prod/) | `hipaa` | `core/shared/prod/terraform.tfstate` |

## Apply order

Always apply `_core/shared` before any domain — domains consume shared outputs via remote state.

```
_core/shared/dev  →  domains/*/dev
_core/shared/staging  →  domains/*/staging
_core/shared/prod  →  domains/*/prod
```

## Public API

`outputs.tf` in each environment is the contract with all domain teams. Never remove or rename an output without coordinating with domain teams first.
