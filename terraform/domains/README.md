> [!WARNING]
> **Obsolete — see [ADR-0001](../../docs/adr/0001-fondations.md).** This document describes the model replaced by ADR-0001 (environment branches, `__PLACEHOLDER__` hydration, `platform-bot env` commands, AWS as the only target). It will be rewritten in phase C2. Still-valid content is tracked in the [traceability table](../../docs/adr/0001-foundations/traceability.md).

# domains

Business domain infrastructure — each domain is owned by a dedicated team and deployed independently.

## Domain structure

Each domain follows the same layout:

```
domains/{domain}/
  dev/
    backend.tf       ← S3 remote state
    versions.tf      ← pinned provider versions
    providers.tf     ← AWS provider
    variables.tf     ← input variables
    shared.tf        ← terraform_remote_state from _core/shared/{env}
    nodegroups.tf    ← domain-specific node groups
    irsa.tf          ← domain-specific IRSA roles
    outputs.tf       ← domain outputs
    terraform.tfvars ← env values (gitignored)
  staging/
  prod/
```

## Active domains

| Domain | Team | Description |
|--------|------|-------------|
| [`platform`](./platform/) | Platform | Core infra — ArgoCD, Istio, Prometheus, ESO |

## Adding a domain

Domains are scaffolded by platform-bot:

```bash
platform-bot domain add --name data --team data-team
```

This generates `domains/data/{dev,staging,prod}/` with pre-filled templates consuming `_core/shared` outputs.
