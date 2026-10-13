---
adr: 0019
title: "Ségrégation des interfaces"
status: Accepté
date: 2026-04-22
recorded: 2026-10-13
scope: [platform-bot]
provenance: ["platform-bot@0112ca1"]
related: [ADR-0001]
---

# ADR-0019 — Ségrégation des interfaces

- **Statut** : Accepté (rédigé rétroactivement le 2026-10-13)
- **Date d'origine** : 2026-04-22
- **Périmètre** : platform-bot

## Contexte

Une interface `GitPort` de douze méthodes, regroupant opérations Git, hydratation et injection de secrets, a été proposée puis refusée : elle figeait un mauvais découpage du domaine.

## Décision

- Chaque consommateur dépend de l'interface la plus étroite possible.
- Les interfaces sont groupées par raison de changer, pas par paquet d'implémentation.
- Les composites restent locaux à l'orchestrateur qui les utilise.

## Conséquences

- Un mock par interface, petit et lisible.

## Statut au regard de l'ADR-0001

Préservé. Les ports `GitPort`, `HydrationPort` et `SecretStorePort` envisagés sont abandonnés avec l'hydratation (ADR-0001, D7).

## Provenance

- `platform-bot@0112ca1` (2026-04-22)
- Sources documentaires : platform-bot CLAUDE.md, notes de revue d'architecture (2026-04-20)
- Table de traçabilité : [`0001-foundations/traceability.md`](0001-foundations/traceability.md)
