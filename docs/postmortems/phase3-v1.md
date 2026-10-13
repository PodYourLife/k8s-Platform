# Postmortem — Phase 3 v1 (premier déploiement EKS dev)

- **Date de l'incident** : 2026-04-27 → 2026-05-04
- **Rédigé le** : 2026-10-13
- **Format** : sans recherche de coupable (blameless). On décrit le système et les décisions, pas les personnes.
- **Impact** : aucun environnement n'a été mis en service. Une branche `dev` corrompue a été poussée ; des identifiants cloud ont été versionnés dans un dépôt public. Le compte cloud a ensuite été entièrement vidé.
- **Décision** : [ADR-0001](../adr/0001-fondations.md).

Les hashes `k8s:` désignent ce dépôt, les hashes `bot:` l'ancien dépôt platform-bot. Les commits de la branche `dev` restent résolubles dans l'archive privée `PodYourLife/platform-archive`.

---

## Chronologie

| Date | Événement |
|---|---|
| 2026-04-27 | `k8s:8be6e10` : première hydratation de `dev` par le bot. Elle génère `backend.tf` dans les sept racines Terraform et hydrate aussi les tfvars de staging et de prod. |
| 2026-04-28 | PR #10 fusionnée dans le bot (`bot:522d52b`) : dry-run en lecture seule (`bot:e55f889`), commit limité aux fichiers produits (`bot:18ddc37`), push SSH (`bot:828e779`). |
| 2026-04-30 | `k8s:f7e19c7` : `env setup --env dev`, commit de 54 fichiers par le bot. |
| 2026-05-04 | `k8s:cfd0ca3` : réinjection des sorties Terraform dans `dev`. La session est interrompue après l'étape 3 sur 4. |
| 2026-05-04 | Vérification : le binaire installé correspond exactement à `bot:522d52b` (empreinte SHA-256 identique à une compilation de `main`). Les défauts sont des régressions réelles, pas un binaire périmé. |
| 2026-05-04 | Destruction de l'infrastructure et du compte cloud. |

## Défauts

### R1 — Réécriture destructive de `platform.yaml` (silencieux, majeur)
- **Symptôme** : après `env apply`, `platform.yaml` perd des champs vides (`eso_irsa_role_arn`, et `cluster_name` et `repo_url` pour staging et prod), les entrées de comptes de staging et prod, tous les commentaires ; l'indentation passe de 2 à 4 espaces et les guillemets des versions disparaissent. Visible dans `k8s:f7e19c7`.
- **Cause** : sérialisation par aller-retour Marshal/Unmarshal d'une struct avec `omitempty`, au lieu d'une manipulation qui préserve le document.
- **Détection manquée** : des tests de sauvegarde existaient mais ne couvraient pas ce chemin.

### R2 — Placeholder non substitué, code de sortie 0 (silencieux, bloquant)
- **Symptôme** : le bot annonce « re-injected into 1 file(s) » ; `__ESO_IRSA_ROLE_ARN__` reste littéral dans 16 ApplicationSets de `dev` (`k8s:cfd0ca3`). ESO aurait redémarré en boucle à l'étape suivante.
- **Cause** : la réinjection ne couvrait qu'une partie de la table de correspondance utilisée par l'hydratation, et aucun contrôle après l'étape ne cherchait les tokens restants. Même famille que plusieurs bugs antérieurs de correspondance des placeholders.

### R3 — `env hydrate --env dev` modifie staging et prod (silencieux, majeur)
- **Symptôme** : tfvars et `backend.tf` de staging et prod réécrits (nom de cluster de dev, bucket vide). Le bot annonce « 0 file(s) modified ».
- **Effet de bord grave** : dans `k8s:f7e19c7`, le motif de recherche du contrôle des placeholders de `.github/workflows/validate-pr.yml` a lui-même été substitué. Le contrôle était neutralisé et un identifiant de compte a été écrit dans le workflow.
- **Cause** : les écritures n'étaient pas limitées aux chemins de l'environnement visé, et le compteur de la façade d'écriture ne reflétait pas les écritures réelles.

### R4 — `env push` en SSH : « invalid auth method » (bruyant, majeur)
- **Symptôme** : le push échoue ; contournement par `git push` système.
- **Cause** : l'authentification par agent SSH de go-git ne trouve pas l'agent comme le fait le client git système, et l'enchaînement de solutions de repli ne se déclenche pas sur cette erreur. Le correctif `bot:828e779` est celui qui régresse.

### B — Fichiers de travail committés (réintroduit)
- **Symptôme** :
  - `k8s:f7e19c7` committe `.claude/settings.local.json`, `CLAUDE.md`, `PR_38_REVIEW.md`, `PR_39_REVIEW.md` et `PR_41_REVIEW.md`, qui n'ont jamais existé sur `main`.
  - `k8s:cfd0ca3` committe deux `terraform-outputs.json` (16 sorties : identifiants de rôles, de réseau, endpoint du cluster) et substitue un identifiant de rôle jusque dans un commentaire.
- **Cause** : un chemin de commit échappait encore à la liste des fichiers produits. Le test de `bot:18ddc37` couvrait la fonction, pas l'orchestrateur `env setup`.

## Cause commune

Le bot réimplémentait en impératif, avec écriture dans Git, ce que Helm et ArgoCD font en déclaratif. Trois défauts sur cinq relèvent de la couche Git (go-git, staging, push), deux de la correspondance entre sorties Terraform et placeholders.

## Ce que la détection a manqué

- Des tests unitaires verts fonction par fonction, mais aucun invariant de bout en bout : « aucun token `__*__` ne reste », « aucune écriture hors du périmètre de l'environnement », « l'arbre Git ne contient que les fichiers attendus ».
- Des messages de succès avec un code de sortie 0 sur un état partiel.
- Une suite E2E en opt-in, non lancée avant la fusion de la PR #10.
- Un chemin SSH testé uniquement avec des simulations, jamais avec un vrai agent.
- Aucun contrôle de secrets fondé sur des règles d'identifiants cloud : le contrôle existant reposait sur des valeurs littérales, que l'outil fautif a lui-même réécrites.

## Fragilités connues avant l'incident

Les revues du 2026-04-26 avaient relevé :
- un délai d'apply Terraform de 25 minutes codé en dur ;
- une capture des sorties Terraform « au mieux », qui sortait en 0 en cas d'échec (le mécanisme de R2) ;
- une table de correspondance codée en dur ;
- le cycle « apply local, push, hydratation » du premier déploiement ;
- la découverte des AppProjects par motif de fichiers.

## Exposition et suites

- Un identifiant de compte cloud est présent dans l'historique public de `main` depuis mars 2026, et dans `dev`. Décision : accepté et documenté (identifiant non secret, compte vidé), sans réécriture d'historique. Suivi dans « À traiter » de l'ADR-0001.
- Des identifiants de rôles et de ressources sont présents uniquement dans `dev`. Ils disparaissent de `origin` avec l'archivage de la branche (ADR-0001, D7), après copie dans l'archive privée.
- Le contrôle par motif littéral de `validate-pr.yml` sera remplacé par gitleaks avec une configuration versionnée.

## Décision

[ADR-0001](../adr/0001-fondations.md) :
- **D1** : un seul `main`, plus de branches par environnement.
- **D4** : le contrat de plateforme est écrit dans le Secret de cluster, pas dans Git.
- **D5** : le bot n'écrit jamais dans Git ; tout échec partiel renvoie un code non nul.
- **D7** : nouveau dépôt pour le bot ; go-git, l'hydratation et les placeholders sont abandonnés.

R2, R3, R4 et B disparaissent avec le code qui les porte. R1 n'a plus de raison d'être.
