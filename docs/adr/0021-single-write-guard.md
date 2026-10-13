---
adr: 0021
title: "Façade d'écriture unique pour --dry-run"
status: Accepté
date: 2026-04-28
recorded: 2026-10-13
scope: [platform-bot]
provenance: ["platform-bot@e55f889"]
related: [ADR-0001]
---

# ADR-0021 — Façade d'écriture unique pour --dry-run

- **Statut** : Accepté (rédigé rétroactivement le 2026-10-13)
- **Date d'origine** : 2026-04-28
- **Périmètre** : platform-bot

## Contexte

Un `--dry-run` qui laisse passer une seule écriture n'est pas fiable.

## Décision

- Toute mutation passe par un garde unique, contrôlé par le mode dry-run, qui enregistre les chemins et ressources visés.
- Le résumé des écritures prévues est produit par ce garde.

## Conséquences

- Le garde doit refléter les écritures réelles : en Phase 3 v1, le compteur annonçait zéro fichier modifié alors que des fichiers étaient corrompus (postmortem, R3).

## Statut au regard de l'ADR-0001

Préservé comme motif pour `bootstrap` et `scaffold --dry-run` (D5).

## Provenance

- `platform-bot@e55f889` (2026-04-28)
- Sources documentaires : platform-bot CLAUDE.md
- Table de traçabilité : [`0001-foundations/traceability.md`](0001-foundations/traceability.md)
