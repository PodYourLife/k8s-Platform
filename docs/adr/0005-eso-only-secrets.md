---
adr: 0005
title: "External Secrets Operator, seul mécanisme de secrets"
status: Accepté
date: 2026-03-02
recorded: 2026-10-13
scope: [k8s-platform]
provenance: ["k8s-platform@e23b947"]
related: [ADR-0001]
---

# ADR-0005 — External Secrets Operator, seul mécanisme de secrets

- **Statut** : Accepté (rédigé rétroactivement le 2026-10-13)
- **Date d'origine** : 2026-03-02
- **Périmètre** : k8s-platform

## Contexte

Les premiers secrets étaient des SealedSecrets versionnés. Leur déchiffrement dépend d'une clé de contrôleur liée au cluster, et le format ne s'adapte pas à plusieurs backends.

## Décision

- ESO est le seul mécanisme de fourniture de secrets Kubernetes.
- Aucun Secret ni SealedSecret dans Git, aucune valeur secrète dans les fichiers `values-*.yaml`.
- Les ExternalSecrets référencent un ClusterSecretStore au nom stable, quel que soit le backend.

## Conséquences

- Le backend (gestionnaire de secrets du fournisseur, Vault, Kubernetes) peut changer sans modifier les ExternalSecrets.
- Des SealedSecrets chiffrés subsistent dans l'historique public (février-mars 2026) ; ils ne sont déchiffrables qu'avec la clé du contrôleur de l'époque.

## Statut au regard de l'ADR-0001

Préservé. Le backend est sélectionné par `secret_store_provider` (D3). Le nom neutre du store reste à arbitrer (conflit C03).

## Provenance

- `k8s-platform@e23b947` (2026-03-02)
- Sources documentaires : ARCHITECTURE.md, CLAUDE.md racine, CUSTOM_INSTRUCTIONS, SECURITY.md, DOCS_ESO_AND_K8S_SECURITY.md
- Table de traçabilité : [`0001-foundations/traceability.md`](0001-foundations/traceability.md)
