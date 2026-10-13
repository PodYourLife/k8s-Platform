---
adr: 0006
title: "Terraform en couches, sorties comme API publique"
status: Accepté
date: 2026-03-03
recorded: 2026-10-13
scope: [k8s-platform]
provenance: ["k8s-platform@324957b", "k8s-platform@9b8f310"]
related: [ADR-0001]
---

# ADR-0006 — Terraform en couches, sorties comme API publique

- **Statut** : Accepté (rédigé rétroactivement le 2026-10-13)
- **Date d'origine** : 2026-03-03
- **Périmètre** : k8s-platform

## Contexte

Un état Terraform unique pour le réseau, le cluster et les domaines rend chaque apply risqué et lent.

## Décision

- Modules réutilisables dans `_core/modules/`, rangés par fournisseur.
- Fondation par environnement dans `_core/shared/<env>/`, domaines dans `domains/<domaine>/<env>/`, reliés par `terraform_remote_state`.
- Les sorties d'une couche sont son API publique ; l'apply suit l'ordre des couches.

## Conséquences

- Le rayon d'impact d'un apply est limité à une couche.
- Renommer une sortie est un changement cassant.

## Statut au regard de l'ADR-0001

Préservé. D3 ajoute `_core/modules/{aws,oci,kind}` et impose le même contrat de sorties à chaque fournisseur.

## Provenance

- `k8s-platform@324957b` (2026-03-03)
- `k8s-platform@9b8f310` (2026-03-03)
- Sources documentaires : ARCHITECTURE.md, CLAUDE.md racine, CUSTOM_INSTRUCTIONS, DOCS_TERRAFORM_AWS.md, terraform/**/README.md
- Table de traçabilité : [`0001-foundations/traceability.md`](0001-foundations/traceability.md)
