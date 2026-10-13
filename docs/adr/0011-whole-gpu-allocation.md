---
adr: 0011
title: "Allocation d'un GPU entier par Job"
status: Accepté
date: 2026-04-08
recorded: 2026-10-13
scope: [k8s-platform]
provenance: ["DOCS_AI_WORKLOADS.md (sha256 c1668f2f874b…)", "DOCS_KUBERNETES.md (sha256 669c0133e19e…)"]
related: [ADR-0001]
---

# ADR-0011 — Allocation d'un GPU entier par Job

- **Statut** : Accepté (rédigé rétroactivement le 2026-10-13)
- **Date d'origine** : 2026-04-08
- **Périmètre** : k8s-platform

## Contexte

Le GPU ciblé (T4) ne supporte pas MIG. Le time-slicing n'offre aucune isolation mémoire : un Job peut provoquer l'OOM d'un autre.

## Décision

- Chaque Job GPU reçoit un GPU entier.
- Ni MIG ni time-slicing.

## Conséquences

- Le coût GPU est proportionnel au nombre de Jobs simultanés.
- L'item de backlog « device plugin + MIG time-slicing » est contredit et sera réécrit en A2 (conflit C21).

## Statut au regard de l'ADR-0001

Préservé. Sans objet sur l'offre gratuite Oracle (pas de GPU) ; s'applique dès qu'un GPU est disponible.

## Provenance

- Document `DOCS_AI_WORKLOADS.md` (sha256 c1668f2f874b…), non versionné, archivé dans `PodYourLife/platform-archive`
- Document `DOCS_KUBERNETES.md` (sha256 669c0133e19e…), non versionné, archivé dans `PodYourLife/platform-archive`
- Sources documentaires : DOCS_AI_WORKLOADS.md, DOCS_KUBERNETES.md, ARCHITECTURE.md (documents non versionnés, mtime 2026-04-08, archivés dans `platform-archive`)
- Table de traçabilité : [`0001-foundations/traceability.md`](0001-foundations/traceability.md)
