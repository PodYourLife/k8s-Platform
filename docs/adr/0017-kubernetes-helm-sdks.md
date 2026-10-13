---
adr: 0017
title: "SDK Kubernetes et Helm, CLI externes en exécution contrôlée"
status: Accepté
date: 2026-04-18
recorded: 2026-10-13
scope: [platform-bot]
provenance: ["platform-bot@73e436b"]
related: [ADR-0001]
---

# ADR-0017 — SDK Kubernetes et Helm, CLI externes en exécution contrôlée

- **Statut** : Accepté (rédigé rétroactivement le 2026-10-13)
- **Date d'origine** : 2026-04-18
- **Périmètre** : platform-bot

## Contexte

Les appels `kubectl` et `helm` en sous-processus renvoyaient des erreurs non typées et n'étaient testables que par des mocks d'exécution.

## Décision

- `client-go` et `helm/v3` remplacent `kubectl` et `helm` en sous-processus.
- Les outils sans SDK stable (`terraform`, `kind`) restent appelés par `os/exec`, avec codes de sortie typés, sortie `-json` et délais par opération.

## Conséquences

- Tests possibles avec un faux clientset.
- Le durcissement des appels `os/exec` est inscrit à la roadmap.

## Statut au regard de l'ADR-0001

Repris par D5 de l'ADR-0001. go-git et le SDK AWS, prévus par le même plan, sont abandonnés.

## Provenance

- `platform-bot@73e436b` (2026-04-18)
- Sources documentaires : platform-bot docs/SDK_MIGRATION_PLAN.md, CLAUDE.md
- Table de traçabilité : [`0001-foundations/traceability.md`](0001-foundations/traceability.md)
