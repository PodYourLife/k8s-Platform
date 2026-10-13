---
adr: 0015
title: "NetworkPolicy en refus par défaut"
status: Accepté
date: 2026-04-18
recorded: 2026-10-13
scope: [k8s-platform]
provenance: ["k8s-platform@d65d1b9"]
related: [ADR-0001]
---

# ADR-0015 — NetworkPolicy en refus par défaut

- **Statut** : Accepté (rédigé rétroactivement le 2026-10-13)
- **Date d'origine** : 2026-04-18
- **Périmètre** : k8s-platform

## Contexte

Sans NetworkPolicy, tout pod peut joindre tout autre pod. Les namespaces exemptés de sidecar (ADR-0009) ne bénéficient pas du contrôle du mesh.

## Décision

- Chaque namespace de plateforme a une politique `deny-all`.
- Les flux nécessaires (DNS, collecte de métriques, API Kubernetes, sorties identifiées) sont ouverts par des exceptions ciblées.

## Conséquences

- Un nouveau flux exige une exception explicite.

## Statut au regard de l'ADR-0001

Préservé. L'extension aux namespaces applicatifs et à `ml` est inscrite à la roadmap.

## Provenance

- `k8s-platform@d65d1b9` (2026-04-18)
- Sources documentaires : SECURITY.md, DOCS_ESO_AND_K8S_SECURITY.md, DOCS_KUBERNETES.md
- Table de traçabilité : [`0001-foundations/traceability.md`](0001-foundations/traceability.md)
