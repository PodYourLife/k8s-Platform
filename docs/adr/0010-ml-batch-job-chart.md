---
adr: 0010
title: "Chart générique ml-batch-job"
status: Accepté
date: 2026-03-19
recorded: 2026-10-13
scope: [k8s-platform]
provenance: ["k8s-platform@1b145a8"]
related: [ADR-0001]
---

# ADR-0010 — Chart générique ml-batch-job

- **Statut** : Accepté (rédigé rétroactivement le 2026-10-13)
- **Date d'origine** : 2026-03-19
- **Périmètre** : k8s-platform

## Contexte

Les entraînements QuanvNN sont des traitements finis, en plusieurs étapes, et coûteux en GPU. Un Deployment ne convient pas, et un chart par projet ML multiplierait le code.

## Décision

- Un chart Helm `ml-batch-job` générique, fondé sur des Jobs, agnostique du déclencheur.
- Pipeline GPU puis CPU ; un run est déclenché en changeant `job.runId` par PR.
- `restartPolicy: Never` (un `OnFailure` peut réutiliser un état CUDA corrompu après un OOM), `backoffLimit` borné, `ttlSecondsAfterFinished: 86400`.
- Le nœud GPU revient à zéro hors run ; `values.schema.json` valide les valeurs.

## Conséquences

- L'évolution du déclencheur (KEDA, événements) relève de la plateforme, pas du chart.
- Les Jobs terminés sont ignorés par ArgoCD via `ignoreDifferences` (voir lessons-learned).

## Statut au regard de l'ADR-0001

Préservé. Les sprints F1–F2 l'exercent en CPU sur arm64.

## Provenance

- `k8s-platform@1b145a8` (2026-03-19)
- Sources documentaires : ARCHITECTURE.md, DOCS_AI_WORKLOADS.md, DOCS_KUBERNETES.md, docs/ml-batch-job-README.md
- Table de traçabilité : [`0001-foundations/traceability.md`](0001-foundations/traceability.md)
