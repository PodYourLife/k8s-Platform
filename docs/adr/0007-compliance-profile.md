---
adr: 0007
title: "Profil de conformité gradué"
status: Accepté
date: 2026-03-03
recorded: 2026-10-13
scope: [k8s-platform]
provenance: ["k8s-platform@324957b"]
related: [ADR-0001]
---

# ADR-0007 — Profil de conformité gradué

- **Statut** : Accepté (rédigé rétroactivement le 2026-10-13)
- **Date d'origine** : 2026-03-03
- **Périmètre** : k8s-platform

## Contexte

Les contrôles de conformité (journalisation d'audit, détection, chiffrement) ont un coût qui ne se justifie pas en dev.

## Décision

- Une variable `compliance_profile` (`none`, `soc2`, `hipaa`) active des contrôles additifs.
- Aucun contrôle n'est activé hors de cette variable.

## Conséquences

- Un environnement change de profil par une seule valeur.
- Les contrôles sont aujourd'hui implémentés pour AWS uniquement.

## Statut au regard de l'ADR-0001

Préservé côté AWS. Le profil de prod (`hipaa` ou `soc2`) est à trancher en C2. Les équivalents OCI sont à définir.

## Provenance

- `k8s-platform@324957b` (2026-03-03)
- Sources documentaires : ARCHITECTURE.md, CUSTOM_INSTRUCTIONS, SECURITY.md, terraform/README.md
- Table de traçabilité : [`0001-foundations/traceability.md`](0001-foundations/traceability.md)
