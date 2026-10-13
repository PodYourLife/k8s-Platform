---
adr: 0008
title: "Apply de prod depuis la CI uniquement, identité fédérée restreinte"
status: Accepté
date: 2026-03-03
recorded: 2026-10-13
scope: [k8s-platform]
provenance: ["k8s-platform@9b8f310", "k8s-platform@98511f1"]
related: [ADR-0001]
---

# ADR-0008 — Apply de prod depuis la CI uniquement, identité fédérée restreinte

- **Statut** : Accepté (rédigé rétroactivement le 2026-10-13)
- **Date d'origine** : 2026-03-03
- **Périmètre** : k8s-platform

## Contexte

Un apply de prod depuis un poste humain n'est ni reproductible ni auditable, et suppose des droits d'écriture humains en prod.

## Décision

- L'apply de prod s'exécute uniquement depuis la CI.
- La CI obtient ses droits par une identité fédérée, sans credential statique, restreinte au dépôt et à l'environnement visé.
- Aucun wildcard de dépôt ni de branche n'est accepté.

## Conséquences

- Implémentation actuelle : OIDC GitHub vers AWS (module `github-oidc`, validations qui refusent `*`).
- Faiblesse connue : le rôle d'apply d'un environnement accepte aujourd'hui les `sub` des trois environnements (suivi dans « À traiter » de l'ADR-0001, phase C2).
- Implémentation Oracle Cloud prévue en E1.

## Statut au regard de l'ADR-0001

Préservé. Le principe est indépendant du fournisseur ; l'OIDC AWS n'en est qu'une implémentation.

## Provenance

- `k8s-platform@9b8f310` (2026-03-03)
- `k8s-platform@98511f1` (2026-03-30)
- Sources documentaires : ARCHITECTURE.md, CUSTOM_INSTRUCTIONS, SECURITY.md, terraform/_core/modules/aws/github-oidc/README.md
- Table de traçabilité : [`0001-foundations/traceability.md`](0001-foundations/traceability.md)
