---
adr: 0013
title: "PriorityClasses gérées par la plateforme"
status: Accepté
date: 2026-04-26
recorded: 2026-10-13
scope: [k8s-platform]
provenance: ["k8s-platform@0d02210"]
related: [ADR-0001]
---

# ADR-0013 — PriorityClasses gérées par la plateforme

- **Statut** : Accepté (rédigé rétroactivement le 2026-10-13)
- **Date d'origine** : 2026-04-26
- **Périmètre** : k8s-platform

## Contexte

Les PriorityClasses sont cluster-scoped. Le projet `ml` n'autorise aucune ressource cluster-scoped (ADR-0004).

## Décision

- `gpu-high-priority` (inférence) et `gpu-batch-priority` (entraînement, préemptible) sont déclarées par la plateforme, via un ApplicationSet dédié.
- Les charts applicatifs ne font que les référencer.

## Conséquences

- Le chart reste installable dans un projet sans droits cluster.
- Ajouter une classe de priorité passe par une PR plateforme.

## Statut au regard de l'ADR-0001

Préservé.

## Provenance

- `k8s-platform@0d02210` (2026-04-26)
- Sources documentaires : ROADMAP.md, DOCS_AI_WORKLOADS.md, DOCS_KUBERNETES.md, AUDIT_QUANVNN_MVP.md
- Table de traçabilité : [`0001-foundations/traceability.md`](0001-foundations/traceability.md)
