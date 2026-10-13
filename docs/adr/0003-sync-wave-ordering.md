---
adr: 0003
title: "Ordonnancement du déploiement par sync-waves"
status: Accepté
date: 2026-03-01
recorded: 2026-10-13
scope: [k8s-platform]
provenance: ["k8s-platform@fd3b16a"]
related: [ADR-0001]
---

# ADR-0003 — Ordonnancement du déploiement par sync-waves

- **Statut** : Accepté (rédigé rétroactivement le 2026-10-13)
- **Date d'origine** : 2026-03-01
- **Périmètre** : k8s-platform

## Contexte

Les composants de la plateforme dépendent les uns des autres : CRD avant ressources personnalisées, istiod avant les workloads injectés, ESO avant les ExternalSecrets. Sans ordre explicite, le premier sync échoue ou converge par auto-guérison.

## Décision

- Le déploiement de la plateforme est ordonné par l'annotation `argocd.argoproj.io/sync-wave`, de `-3` (namespaces) aux applications (`9` et au-delà).
- Les ressources cluster-scoped et les CRD précèdent leurs consommateurs.

## Conséquences

- Les dépendances sont lisibles dans les manifests.
- La table de référence diverge entre plusieurs documents (conflit C02 de la table de traçabilité) : elle sera établie à partir des manifests de `main`, comparés à `dev`, puis validée par le POC A0.

## Statut au regard de l'ADR-0001

Préservé. Révision des waves de la gateway attendue avec l'ADR Gateway API (A1).

## Provenance

- `k8s-platform@fd3b16a` (2026-03-01)
- Sources documentaires : ARCHITECTURE.md, CUSTOM_INSTRUCTIONS, dev:CLAUDE.md, argocd/README.md
- Table de traçabilité : [`0001-foundations/traceability.md`](0001-foundations/traceability.md)
