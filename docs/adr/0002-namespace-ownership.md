---
adr: 0002
title: "Propriété des namespaces"
status: Accepté
date: 2026-03-18
recorded: 2026-10-13
scope: [k8s-platform]
provenance: ["k8s-platform@385911b"]
related: [ADR-0001]
---

# ADR-0002 — Propriété des namespaces

- **Statut** : Accepté (rédigé rétroactivement le 2026-10-13)
- **Date d'origine** : 2026-03-18
- **Périmètre** : k8s-platform

## Contexte

Les labels d'un namespace (injection Istio, niveau Pod Security Standards) conditionnent le comportement de tout ce qui y est déployé. Quand chaque Application crée son propre namespace (`CreateNamespace=true`), ces labels dépendent de l'ordre de synchronisation et n'ont pas de source unique.

## Décision

- Tous les namespaces non amont sont déclarés par l'ApplicationSet `namespaces`, en sync-wave `-3`.
- Toutes les autres Applications ArgoCD utilisent `CreateNamespace=false`.

## Conséquences

- Les labels de namespace ont une source unique et versionnée.
- Ajouter un namespace passe par une PR sur l'ApplicationSet `namespaces`.
- Une Application dont le namespace n'existe pas échoue au sync : c'est voulu.

## Statut au regard de l'ADR-0001

Préservé. Avec D3, l'ApplicationSet `namespaces` passera au générateur *cluster* (phase C1).

## Provenance

- `k8s-platform@385911b` (2026-03-18)
- Sources documentaires : ARCHITECTURE.md, CLAUDE.md racine, dev:CLAUDE.md
- Table de traçabilité : [`0001-foundations/traceability.md`](0001-foundations/traceability.md)
