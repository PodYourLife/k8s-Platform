---
adr: 0018
title: "Discipline de paquets et plafonds de taille"
status: Accepté
date: 2026-03-17
recorded: 2026-10-13
scope: [platform-bot]
provenance: ["platform-bot@f692beb", "platform-bot@1e3db2d"]
related: [ADR-0001]
---

# ADR-0018 — Discipline de paquets et plafonds de taille

- **Statut** : Accepté (rédigé rétroactivement le 2026-10-13)
- **Date d'origine** : 2026-03-17
- **Périmètre** : platform-bot

## Contexte

Les premières versions du bot mélangeaient câblage CLI, logique métier et accès externes ; un audit a relevé de nombreuses violations de responsabilité.

## Décision

- `cmd/` ne fait que le câblage Cobra. Chaque responsabilité a un seul paquet propriétaire. Pas de fonction pass-through.
- Plafonds : 200 lignes par fichier, tests compris ; 50 lignes par fonction dans `cmd/`, 80 dans `internal/`.

## Conséquences

- Les gros fichiers de test doivent être découpés.
- Les plafonds sont vérifiables automatiquement.

## Statut au regard de l'ADR-0001

Préservé pour le nouveau dépôt (B2), référencé depuis son CLAUDE.md.

## Provenance

- `platform-bot@f692beb` (2026-03-17)
- `platform-bot@1e3db2d` (2026-03-30)
- Sources documentaires : platform-bot CLAUDE.md, INTEGRITY_REVIEW_PRE_2C.md, ARCHITECTURE.md
- Table de traçabilité : [`0001-foundations/traceability.md`](0001-foundations/traceability.md)
