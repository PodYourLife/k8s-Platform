---
adr: 0022
title: "Token d'abonnement Claude pour les agents CI, exception encadrée à la règle sans credential statique"
status: Accepté
date: 2026-11-12
recorded: 2026-11-12
scope: [k8s-platform]
provenance: ["k8s-platform#52", "k8s-platform#56"]
related: [ADR-0001, ADR-0008, ADR-0016]
---

# ADR-0022 — Token d'abonnement Claude pour les agents CI

- **Statut** : Accepté
- **Date** : 2026-11-12
- **Périmètre** : k8s-platform

## Contexte

Les workflows `agent-review` et `agent-implement` exécutent Claude via `anthropics/claude-code-action`. Trois modes d'authentification existent :

| Mode | Credential stocké | Coût |
|---|---|---|
| Fédération d'identité (OIDC GitHub vers un service account de la Claude Console) | aucun | facturation API à l'usage |
| Fournisseur cloud (Bedrock, Vertex, Foundry) via OIDC | aucun | facturation du fournisseur, dépendance à un cloud |
| `CLAUDE_CODE_OAUTH_TOKEN` généré par `claude setup-token` | token d'environ un an | inclus dans l'abonnement Claude |

La règle « aucun credential statique » (ADR-0008, ADR-0016) écarte le troisième mode. Mais le projet n'a pas de budget API, et ADR-0001 D2 écarte une dépendance à un fournisseur cloud tant qu'il n'y a pas de budget.

Référence : https://code.claude.com/docs/en/github-actions

## Décision

- Les agents CI s'authentifient avec `CLAUDE_CODE_OAUTH_TOKEN`, stocké en secret de dépôt, jamais committé.
- C'est la **seule** exception à la règle sans credential statique. Elle ne s'étend à aucun autre système.
- Encadrement obligatoire :
  - token limité à l'inférence : il ne donne accès ni au dépôt ni à un cloud ;
  - rotation annuelle, et révocation immédiate en cas de doute ;
  - utilisé seulement par les workflows qui le nomment explicitement, sur des événements déclenchés par le propriétaire ou un collaborateur ;
  - jamais exposé aux PR de forks (GitHub ne transmet pas les secrets à ces runs).

## Conséquences

- Coût marginal nul, mais le quota est partagé avec l'usage interactif du propriétaire.
- Le token est lié à l'abonnement d'une personne. Dès qu'un second humain déclenche les agents, on passe à la fédération d'identité, et cet ADR est remplacé.
- Le reviewer agent ne bloque plus une PR pour la seule présence de `CLAUDE_CODE_OAUTH_TOKEN` dans un workflow agent.

## Statut au regard de l'ADR-0001

Compatible. D6 (l'agent est un utilisateur, il écrit uniquement par PR) n'est pas affecté : le token authentifie l'inférence, pas les écritures sur le dépôt.
