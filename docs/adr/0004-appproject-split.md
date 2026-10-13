---
adr: 0004
title: "Découpage des AppProjects"
status: Accepté
date: 2026-03-01
recorded: 2026-10-13
scope: [k8s-platform]
provenance: ["k8s-platform@d568d63", "k8s-platform@6ea216a"]
related: [ADR-0001]
---

# ADR-0004 — Découpage des AppProjects

- **Statut** : Accepté (rédigé rétroactivement le 2026-10-13)
- **Date d'origine** : 2026-03-01
- **Périmètre** : k8s-platform

## Contexte

La plateforme, les applications et les workloads ML n'ont pas le même profil de risque. Un AppProject unique donnerait à chaque Application les droits les plus larges.

## Décision

- Trois AppProjects : `platform`, `applications` et `ml`.
- `ml` n'autorise aucune ressource cluster-scoped (`clusterResourceWhitelist: []`) et porte les rôles `ml-operator` et `ml-readonly`.

## Conséquences

- Toute nouvelle source (dépôt de charts) ou ressource cluster-scoped doit être ajoutée explicitement au projet, sinon le sync est refusé alors que `helm lint` reste vert (voir lessons-learned).
- Les ressources cluster-scoped nécessaires au ML sont fournies par la plateforme (ADR-0013).

## Statut au regard de l'ADR-0001

Préservé.

## Provenance

- `k8s-platform@d568d63` (2026-03-01)
- `k8s-platform@6ea216a` (2026-03-19)
- Sources documentaires : ARCHITECTURE.md, ROADMAP.md, dev:CLAUDE.md
- Table de traçabilité : [`0001-foundations/traceability.md`](0001-foundations/traceability.md)
