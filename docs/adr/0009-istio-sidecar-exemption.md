---
adr: 0009
title: "Exemption de sidecar pour les Jobs et les opérateurs hors mesh"
status: Accepté
date: 2026-03-01
recorded: 2026-10-13
scope: [k8s-platform]
provenance: ["k8s-platform@0d7967c", "k8s-platform@ff5c315", "k8s-platform@f838f58"]
related: [ADR-0001]
---

# ADR-0009 — Exemption de sidecar pour les Jobs et les opérateurs hors mesh

- **Statut** : Accepté (rédigé rétroactivement le 2026-10-13)
- **Date d'origine** : 2026-03-01
- **Périmètre** : k8s-platform

## Contexte

Un Job avec sidecar n'atteint jamais l'état `Completed`. Le conteneur `istio-init` exige `NET_ADMIN`, refusé par Pod Security Standards `restricted` ; après un remplacement de nœud, ArgoCD ne redémarrait plus.

## Décision

- Pas d'injection de sidecar pour les workloads batch (namespace `ml`).
- Pas d'injection pour les opérateurs de plateforme qui n'ont pas besoin du mesh.
- `istio-system` n'est jamais injecté.

## Conséquences

- Le trafic de ces namespaces n'est pas couvert par le mTLS du mesh : la NetworkPolicy (ADR-0015) prend le relais.
- La matrice d'injection par namespace diverge entre plusieurs documents (conflit C04) : elle est provisoire.

## Statut au regard de l'ADR-0001

Préservé, provisoire jusqu'à l'évaluation du mode ambient (A1).

## Provenance

- `k8s-platform@0d7967c` (2026-03-01)
- `k8s-platform@ff5c315` (2026-03-24)
- `k8s-platform@f838f58` (2026-04-17)
- Sources documentaires : ARCHITECTURE.md, CUSTOM_INSTRUCTIONS, SECURITY.md, DOCS_ISTIO.md, DOCS_KUBERNETES.md, DOCS_AI_WORKLOADS.md
- Table de traçabilité : [`0001-foundations/traceability.md`](0001-foundations/traceability.md)
