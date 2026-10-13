---
adr: 0016
title: "GitHub App plutôt que PAT pour l'accès d'ArgoCD au dépôt"
status: Accepté
date: 2026-04-17
recorded: 2026-10-13
scope: [k8s-platform, platform-bot]
provenance: ["platform-bot@10831fa"]
related: [ADR-0001]
---

# ADR-0016 — GitHub App plutôt que PAT pour l'accès d'ArgoCD au dépôt

- **Statut** : Accepté (rédigé rétroactivement le 2026-10-13)
- **Date d'origine** : 2026-04-17
- **Périmètre** : k8s-platform, platform-bot

## Contexte

Un PAT est lié à une personne, a une portée large et une durée de vie longue.

## Décision

- ArgoCD accède au dépôt via une GitHub App : lecture seule sur le contenu, installation limitée au dépôt de plateforme.
- La clé privée est stockée dans le gestionnaire de secrets et tournée en faisant coexister deux clés.

## Conséquences

- L'accès survit au départ d'une personne et est traçable.
- Les tokens d'installation expirent après une heure : leur renouvellement est à superviser (roadmap).

## Statut au regard de l'ADR-0001

Préservé. La clé est livrée par ESO via le store neutre (D3), au lieu d'être lue par le bot. Procédure : runbook `github-app-argocd`.

## Provenance

- `platform-bot@10831fa` (2026-04-17)
- Sources documentaires : platform-bot docs/ARGOCD_GITHUB_APP_SETUP.md, ARCHITECTURE.md, CUSTOM_INSTRUCTIONS
- Table de traçabilité : [`0001-foundations/traceability.md`](0001-foundations/traceability.md)
