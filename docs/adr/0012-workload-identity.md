---
adr: 0012
title: "Une identité par workload"
status: Accepté
date: 2026-04-08
recorded: 2026-10-13
scope: [k8s-platform]
provenance: ["DOCS_KUBERNETES.md (sha256 669c0133e19e…)"]
related: [ADR-0001]
---

# ADR-0012 — Une identité par workload

- **Statut** : Accepté (rédigé rétroactivement le 2026-10-13)
- **Date d'origine** : 2026-04-08
- **Périmètre** : k8s-platform

## Contexte

Le lien entre un ServiceAccount et une identité cloud repose sur des noms exacts. Un renommage du chart, de la release ou du ServiceAccount casse l'accès sans erreur visible.

## Décision

- Un ServiceAccount dédié par workload, jamais `default`.
- `automountServiceAccountToken: false` sauf besoin explicite.
- Les noms de chart, release et ServiceAccount sont verrouillés (énumérations dans `values.schema.json`, `releaseName` explicite).

## Conséquences

- Les permissions sont attribuées au plus juste, workload par workload.
- Voir lessons-learned : renommage de ServiceAccount par le nom de release ArgoCD.

## Statut au regard de l'ADR-0001

Préservé. Le mécanisme d'identité suit `identity_mode` et `identity_reference` du contrat (D3).

## Provenance

- Document `DOCS_KUBERNETES.md` (sha256 669c0133e19e…), non versionné, archivé dans `PodYourLife/platform-archive`
- Sources documentaires : DOCS_KUBERNETES.md, DOCS_ESO_AND_K8S_SECURITY.md, INTEGRITY_REVIEW_PRE_2C.md, ROADMAP.md (documents non versionnés, archivés dans `platform-archive`)
- Table de traçabilité : [`0001-foundations/traceability.md`](0001-foundations/traceability.md)
