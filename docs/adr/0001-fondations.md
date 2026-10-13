# ADR-0001 — Fondations de k8s-platform et platform-bot

- **Statut** : Proposé
- **Date** : 2026-10-13
- **Périmètre** : `PodYourLife/k8s-platform`, `PodYourLife/platform-bot` (nouveau dépôt)
- **Remplace** : le modèle « `main` à placeholders + branches par environnement hydratées par le bot »

---

## 1. Contexte

La Phase 3 v1 (premier déploiement EKS dev, mai 2026) a échoué sur des régressions du bot :

| # | Régression | Cause racine |
|---|---|---|
| R1 | Réécriture de `platform.yaml` destructive | Le bot manipule des fichiers Git |
| R2 | `__ESO_IRSA_ROLE_ARN__` non substitué, exit 0 | Réinjection des sorties Terraform dans Git |
| R3 | `env hydrate --env dev` modifie staging/prod | Hydratation par branche |
| R4 | `env push` SSH en échec (go-git) | Le bot pousse dans Git |
| B | Fichiers de travail committés | Le bot committe |

Les cinq défauts ont la même cause : le bot réimplémente en impératif ce que Helm et ArgoCD font en déclaratif. Le passage à Oracle Cloud (offre Always Free) aurait ajouté du code par fournisseur dans le bot. Chaque évolution d'un cloud aurait alors touché Go, Terraform et les valeurs Helm.

Références :
- OpenGitOps : https://opengitops.dev/
- Structure de dépôt par dossiers (Flux) : https://fluxcd.io/flux/guides/repository-structure/
- Générateur *cluster* d'ApplicationSet : https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Cluster/
- Plateformes CNCF : https://tag-app-delivery.cncf.io/whitepapers/platforms/

---

## 2. Décisions

### D1 — Un seul `main`, des dossiers par environnement

- Les branches `dev`, `staging` et `prod` sont abandonnées. ArgoCD lit `main`.
- La variance d'environnement passe uniquement par `values-{env}.yaml`. C'est le pattern établi, sans Kustomize.
- La promotion se fait par PR qui modifie le fichier de valeurs de l'environnement cible.

### D2 — Portable, pas multi-cloud actif

- Oracle (OKE) et Kind sont testés de bout en bout en continu.
- AWS (EKS) reste un module Terraform qui respecte le contrat (D3), sans E2E tant qu'il n'y a pas de budget.
- Le free tier Oracle n'est pas strict : la bascule en Pay-As-You-Go est un réglage, pas un changement d'architecture.

### D3 — Contrat de plateforme

Chaque module fournisseur Terraform (`_core/modules/{aws,oci,kind}/`) exporte **le même** jeu de sorties :

| Sortie | Porté par | Exemple |
|---|---|---|
| `cloud` | label | `oci`, `aws`, `kind` |
| `environment` | label | `dev` |
| `region` | label | `eu-paris-1` |
| `identity_mode` | label | `workload-identity`, `instance-principal`, `irsa`, `none` |
| `secret_store_provider` | label | `oracle`, `aws`, `kubernetes` |
| `cluster_name` | annotation | `dev-k8s` |
| `dataset_bucket` | annotation | `quanvnn-datasets-dev` |
| `identity_reference` | annotation | ARN de rôle, OCID de policy, ou vide |

- **Labels** : valeurs courtes servant de sélecteurs (63 caractères max).
- **Annotations** : valeurs libres (ARN, OCID).
- Préfixe obligatoire : `platform.podyourlife.io/`.

Le contrat est écrit dans le Secret de cluster ArgoCD (`argocd.argoproj.io/secret-type: cluster`). Les ApplicationSets le lisent au runtime :

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: external-secrets
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "-1"
spec:
  goTemplate: true
  goTemplateOptions: ["missingkey=error"]   # fail closed on missing contract keys
  generators:
    - clusters:
        selector:
          matchLabels:
            platform.podyourlife.io/managed: "true"
  template:
    metadata:
      name: 'external-secrets-{{index .metadata.labels "platform.podyourlife.io/environment"}}'
    spec:
      project: platform
      source:
        repoURL: https://github.com/PodYourLife/k8s-platform.git
        targetRevision: main
        path: argocd/platform/external-secrets
        helm:
          valueFiles:
            - 'values-{{index .metadata.labels "platform.podyourlife.io/cloud"}}.yaml'
            - 'values-{{index .metadata.labels "platform.podyourlife.io/environment"}}.yaml'
      destination:
        server: '{{.server}}'
        namespace: external-secrets
```

Règles associées :
- **Aucune valeur du contrat n'est codée en dur.** `region`, `cloud` et les identifiants de compte sont des variables d'entrée Terraform propres à chaque déploiement. Ils remontent en sorties, puis dans le Secret de cluster. Aucun module, chart ou fichier `values-*.yaml` ne référence une région.
- **`preflight` vérifie la région choisie** : disponibilité des services et des shapes requis. Les contraintes propres à un type de compte (par exemple Always Free Oracle limité à la région d'origine) sont signalées, jamais imposées par le code.
- **`ignoreMissingValueFiles` est interdit.** Un fichier fournisseur absent doit faire échouer la synchronisation, pas passer en silence.
- **Aucune donnée sensible dans le contrat.** Seulement des identifiants publics (noms, ARN, OCID). Les secrets restent dans ESO.
- `destination.server: '{{.server}}'` préserve le fix « destination environment-aware, 1 ArgoCD par cluster ».

### D4 — Qui écrit le contrat

`platform-bot bootstrap` exécute `terraform output -json`, valide la sortie contre le schéma du contrat, puis crée le Secret de cluster via client-go.

Terraform n'écrit **pas** le Secret avec le provider `kubernetes`. Configurer ce provider à partir des attributs d'un cluster créé dans le même apply est une source connue d'échecs. La couche 0 reste ainsi sans dépendance au cycle de vie du cluster.

Pour le cluster local (ArgoCD sur `https://kubernetes.default.svc`), un Secret de cluster explicite est nécessaire pour porter les labels. C'est le comportement documenté du générateur *cluster*.

### D5 — platform-bot : CLI DevX déterministe

| Commande | Rôle | Mutation |
|---|---|---|
| `bootstrap` | couche 0 → install ArgoCD → écriture du contrat → app racine | oui, confirmation explicite |
| `preflight` | quotas, versions, contrat complet, fichiers `values-<cloud>.yaml` présents | non |
| `status` | état live via client-go | non |
| `scaffold` | nouvelle app depuis `k8s-platform/docs/templates/` | fichiers locaux, pas de commit |

`scaffold` est une nouvelle fonctionnalité, développée en phase B2. Ce n'est pas une reprise : `internal/helm/scaffold.go` a été supprimé de l'ancien dépôt en mars 2026 (`f692beb`).

Propriétés obligatoires :
- `--output json` sur toute commande en lecture.
- Codes de sortie documentés. Tout échec partiel renvoie un code ≠ 0.
- Idempotence et `--dry-run` sur toute commande qui modifie l'état.
- Le bot n'écrit jamais dans Git et ne détient aucun droit d'écriture sur les dépôts.
- Aucun SDK cloud : `os/exec` pour `terraform`, `client-go` pour Kubernetes, `helm/v3` pour Helm.

### D6 — L'agent est un utilisateur, pas un composant

Un futur agent (Avraham, autofix) utilise le bot et n'en fait pas partie :
- Il lit via `platform-bot status --output json` et les alertes.
- Il écrit **uniquement** par PR. La CI, Kyverno et la revue humaine valident.
- Il n'a ni accès en écriture à l'API Kubernetes, ni `terraform apply`.
- Il n'a jamais plus de droits qu'un opérateur humain.
- Aucune dépendance LLM dans le chemin de `bootstrap`.

### D7 — Dépôts

**k8s-platform est conservé.** La migration se fait par PR sur `main`, une par phase.

Nettoyage, dans cet ordre :
1. Scanner tout l'historique avec gitleaks. `CreateBranchAndPush` faisait `git add -f terraform.tfvars`. Tout token trouvé est révoqué.
2. Taguer chaque branche d'environnement (`archive/phase3-v1-{env}`), puis la supprimer. Aucun force-push n'est nécessaire.
3. Trier les fichiers non suivis et les stashes.

**platform-bot repart d'un nouveau dépôt.** L'ancien est archivé sur GitHub en lecture seule.
- Le chemin du module ne contient pas de version dans son nom. `/vN` est réservé aux versions majeures : https://go.dev/doc/modules/major-version
- Reprise par copie revue, fichier par fichier : `internal/kubernetes/`, `internal/tui/`, `internal/ui/{output,prompt}.go`, `internal/helm/{actions,client,repo}.go`, `internal/bootstrap/{argocd,argocd_install}.go`.
- Abandonnés : `internal/git/`, `internal/generate/`, l'hydratation, les placeholders, go-git.

---

## 3. Conséquences

### Ce qui disparaît
- Les placeholders `__*__` sur `main`, `InjectPlaceholders`, `env add/hydrate/apply/push`.
- R2, R3, R4 et le bug B, supprimés avec le code qui les porte. R1 n'a plus de raison d'être : le bot ne réécrit plus `platform.yaml`.

### Ce qui est ajouté à la trajectoire
- **Supply chain** : signature cosign en CI (OIDC keyless), Kyverno `verifyImages` en Enforce. https://kyverno.io/docs/
- **Gateway API à la place de l'ingress Istio classique** : https://istio.io/latest/docs/tasks/traffic-management/ingress/gateway-api/
  - ⚠️ **Breaking** : migration `networking.istio.io` `Gateway`/`VirtualService` → `gateway.networking.k8s.io` `Gateway`/`HTTPRoute`.
  - Istio déploie lui-même le gateway. Le namespace `istio-ingress` avec `istio-injection=enabled` et le placeholder `image: auto` deviennent inutiles. Le backlog #1 est redéfini par un ADR dédié.
- **Mode ambient Istio** : à évaluer pour la contrainte mémoire de 24 Go en ARM64 (ADR dédié). https://istio.io/latest/docs/ambient/

### Bugs résolus : statut après cet ADR

| Bug | Statut |
|---|---|
| ApplicationSets vers le même cluster | Préservé : `destination.server: '{{.server}}'` |
| `__REPO_URL__` non substitué | Obsolète : plus de placeholders |
| AppProject sans kyverno | Préservé : inchangé |
| Mismatch de version gateway/istiod | Préservé. Avec Gateway API, la version suit istiod par construction |
| Drift `caBundle` istiod | Préservé : `ignoreDifferences` inchangé |
| `gh` v2.88 ITERATION / `Repo` | Hors périmètre, inchangé |
| `git add -f` sur `terraform.tfvars` | Obsolète. Le scan gitleaks de D7 traite l'héritage |

### À traiter

| Sujet | Phase |
|---|---|
| Normaliser la casse de l'URL du dépôt (`k8s-Platform.git` → `k8s-platform.git`) dans les manifests ArgoCD | C1 |
| Remplacer Promtail, déprécié en amont, par Grafana Alloy | C1 |
| Conformité de prod : `hipaa` dans `terraform/_core/shared/README.md`, `soc2` dans les instructions globales. Trancher | C2 |
| Niveaux Pod Security Standards divergents entre les guides Kubernetes et ESO/sécurité. Trancher | A2 |
| Réécrire les instructions du projet claude.ai et `~/.claude/CLAUDE.md` selon cet ADR. En cas de conflit d'ici là, cet ADR prévaut | A2 |
| Corriger `skill-quality.md` : arbre de packages fictif (`internal/cluster/status.go`, `internal/helm/scaffold.go`), à l'origine de l'erreur initiale de D7 | B1 |

### Risques
- **Le contrat devient l'API centrale.** Toute modification est un changement versionné, avec un label `platform.podyourlife.io/contract-version`.
- **Le Secret de cluster est créé hors Git** par `bootstrap`. Sa dérive est détectée par `preflight`, qui compare les sorties Terraform et le Secret.

---

## 4. Validation : POC A0 sur Kind

Critères de sortie, tous obligatoires :
1. Un Secret de cluster local porte le contrat (labels et annotations préfixés).
2. Un ApplicationSet avec générateur *cluster* génère une Application qui utilise `values-kind.yaml` et `values-dev.yaml`.
3. La suppression d'une clé du contrat fait échouer la génération (`missingkey=error`).
4. La suppression de `values-kind.yaml` fait échouer la synchronisation.
5. Aucun fichier de `main` ne contient de token `__*__`.

---

## 5. Phases révisées

| Phase | Contenu |
|---|---|
| A0 | Cet ADR + POC Kind |
| A1 | ADR Gateway API + évaluation ambient |
| A2 | Mise à jour CLAUDE.md / ARCHITECTURE.md selon les ADR |
| B1 | Nettoyage k8s-platform (D7) |
| B2 | Nouveau dépôt platform-bot : squelette DDD, `status`, `preflight` |
| B3 | `bootstrap` + écriture du contrat |
| C1 | k8s-platform : passage aux dossiers et `values-<cloud>.yaml` |
| C2 | Modules Terraform `kind` puis `oci` respectant le contrat |
| D1 | E2E Kind |
| E1 | Bootstrap OKE + fédération CI GitHub → Oracle |
| F1–F2 | Sprints 3–4 QuanvNN (CPU, arm64) |
| G1–G3 | Sécurité P0–P2 revues + supply chain |
