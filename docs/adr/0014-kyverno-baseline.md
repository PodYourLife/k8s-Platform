---
adr: 0014
title: "Socle de politiques Kyverno"
status: Accepté
date: 2026-04-18
recorded: 2026-10-13
scope: [k8s-platform]
provenance: ["k8s-platform@8a22dea", "k8s-platform@2f6a5c6"]
related: [ADR-0001]
---

# ADR-0014 — Socle de politiques Kyverno

- **Statut** : Accepté (rédigé rétroactivement le 2026-10-13)
- **Date d'origine** : 2026-04-18
- **Périmètre** : k8s-platform

## Contexte

Les règles de sécurité des pods (non-root, pas d'escalade, pas de `latest`, registres autorisés) doivent être appliquées à l'admission, pas seulement documentées.

## Décision

- Un socle de ClusterPolicies Kyverno : Enforce en staging et prod, Audit en dev.
- Les namespaces de plateforme dont les charts amont ne sont pas conformes sont exclus explicitement.

## Conséquences

- Chaque exclusion est documentée.
- Le mode Audit en dev peut masquer une politique mal écrite (voir lessons-learned : comparaison avec un astérisque littéral).

## Statut au regard de l'ADR-0001

Préservé. L'ADR-0001 ajoute `verifyImages` (signature cosign) en Enforce.

## Provenance

- `k8s-platform@8a22dea` (2026-04-18)
- `k8s-platform@2f6a5c6` (2026-04-18)
- Sources documentaires : SECURITY.md, kubernetes/policies/
- Table de traçabilité : [`0001-foundations/traceability.md`](0001-foundations/traceability.md)
