> [!WARNING]
> **Obsolete — see [ADR-0001](../../../docs/adr/0001-fondations.md).** This document describes the model replaced by ADR-0001 (environment branches, `__PLACEHOLDER__` hydration, `platform-bot env` commands, AWS as the only target). It will be rewritten in phase C2. Still-valid content is tracked in the [traceability table](../../../docs/adr/0001-foundations/traceability.md).

# domains/platform

Platform team domain — node groups and IRSA roles for platform workloads (ArgoCD, Istio, Prometheus, ESO, Cluster Autoscaler).

## Environments

| Environment | State key |
|-------------|-----------|
| [`dev`](./dev/) | `domains/platform/dev/terraform.tfstate` |
| [`staging`](./staging/) | `domains/platform/staging/terraform.tfstate` |
| [`prod`](./prod/) | `domains/platform/prod/terraform.tfstate` |

## Depends on

`_core/shared/{env}` must be applied before this domain in each environment.
