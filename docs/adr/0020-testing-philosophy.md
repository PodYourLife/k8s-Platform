---
adr: 0020
title: "Philosophie de test du bot"
status: Accepté
date: 2026-04-21
recorded: 2026-10-13
scope: [platform-bot]
provenance: ["platform-bot@c928b3d", "platform-bot@0303ed2"]
related: [ADR-0001]
---

# ADR-0020 — Philosophie de test du bot

- **Statut** : Accepté (rédigé rétroactivement le 2026-10-13)
- **Date d'origine** : 2026-04-21
- **Périmètre** : platform-bot

## Contexte

Des mocks enregistreurs pour chaque dépendance rendaient les tests fragiles sans détecter les régressions de bout en bout.

## Décision

- Mocks uniquement pour les effets externes, un par port, avec compteurs d'appels.
- Les helpers de test vivent dans `export_test.go` ; aucun code réservé aux tests dans le binaire.
- Injection par champ de struct plutôt que par variable de paquet.
- La suite E2E (tag `e2e`, sur Kind) est le filet de régression.

## Conséquences

- Le postmortem Phase 3 v1 montre que des tests unitaires verts ne suffisent pas : la suite E2E doit vérifier des invariants (aucun échec partiel en code 0, aucune écriture hors périmètre).

## Statut au regard de l'ADR-0001

Préservé pour le nouveau dépôt (B2), complété par les enseignements du postmortem.

## Provenance

- `platform-bot@c928b3d` (2026-04-21)
- `platform-bot@0303ed2` (2026-04-21)
- Sources documentaires : platform-bot CLAUDE.md, DOCS_TESTING_STRATEGY.md
- Table de traçabilité : [`0001-foundations/traceability.md`](0001-foundations/traceability.md)
