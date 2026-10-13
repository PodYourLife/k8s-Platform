> [!WARNING]
> **Obsolete — see [ADR-0001](../../docs/adr/0001-fondations.md).** This document describes the model replaced by ADR-0001 (environment branches, `__PLACEHOLDER__` hydration, `platform-bot env` commands, AWS as the only target). It will be rewritten in phase C2. Still-valid content is tracked in the [traceability table](../../docs/adr/0001-foundations/traceability.md).

# _core

Platform infrastructure foundation — owned by the platform team. Read-only for domain teams.

## Structure

```
_core/
  modules/    ← reusable single-responsibility modules
  shared/     ← cross-domain cluster foundation (VPC, EKS, IAM, compliance)
```

## Ownership

`_core` is maintained by the **platform-maintainers** group. PRs touching `_core` require review from at least one platform maintainer before merge.

Domain teams consume `_core` outputs via `terraform_remote_state` — they never modify `_core` directly.
