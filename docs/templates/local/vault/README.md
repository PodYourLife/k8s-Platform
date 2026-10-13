> [!WARNING]
> **Obsolete — see [ADR-0001](../../../adr/0001-fondations.md).** This document describes the model replaced by ADR-0001 (environment branches, `__PLACEHOLDER__` hydration, `platform-bot env` commands, AWS as the only target). It will be rewritten in phase C1. Still-valid content is tracked in the [traceability table](../../../adr/0001-foundations/traceability.md).

# Vault Dev-Mode Templates (Kind Local Only)

These files are **templates** for running HashiCorp Vault in dev mode on a local Kind cluster.

## Usage

They are injected automatically by:

```bash
platform-bot env setup --env dev
```

**Do NOT copy these files manually to staging or production branches.**

## Security

- The root token `"root"` is acceptable **only** in a local Kind dev environment.
- staging and production use **AWS Secrets Manager via IRSA** — no Vault.
- If you see a Vault root token outside of a local dev cluster, treat it as a security incident.

## File mapping

| Template path | Injected to (dev branch) |
|---------------|--------------------------|
| `argocd/vault.yaml` | `argocd/platform/vault/vault.yaml` |
| `argocd/secret-store.yaml` | `argocd/platform/vault/secret-store.yaml` |
| `manifests/cluster-secret-store.yaml` | `kubernetes/manifests/vault/cluster-secret-store.yaml` |
| `namespace.yaml` | `kubernetes/namespaces/vault-namespace.yaml` |
| `seed-vault.sh` | `docs/seed-vault.sh` |
