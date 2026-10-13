# Lessons learned

Ce document liste les pièges que le système actuel peut encore reproduire. Chaque entrée donne le symptôme, la cause racine, le correctif, son statut au regard de l'[ADR-0001](adr/0001-fondations.md) et, quand il existe, le test de non-régression.

Les bugs dont le code a disparu avec l'ADR-0001 (attente de la CI par le bot, go-git, substitution de placeholders, `git add -f` sur les tfvars) sont archivés. Leur leçon générale est reprise dans le [postmortem Phase 3 v1](postmortems/phase3-v1.md).

Provenance de chaque entrée : [table de traçabilité](adr/0001-foundations/traceability.md), section B. Les hashes `k8s:` désignent ce dépôt, les hashes `bot:` l'ancien dépôt platform-bot.

---

## ArgoCD

### L01 — Tous les environnements déployés sur le même cluster
- **Symptôme** : les ApplicationSets de chaque environnement synchronisaient vers le même cluster.
- **Cause** : la `destination` ne dépendait pas de l'environnement.
- **Correctif** : destination dérivée du cluster, un ArgoCD par cluster (`k8s:0468ae0`).
- **Statut** : préservé, via `destination.server: '{{.server}}'` (ADR-0001, D3).
- **Test** : critère 2 du POC A0.

### L02 — AppProject qui refuse le sync alors que `helm lint` est vert
- **Symptôme** : Applications refusées au sync (kyverno, puis dépôt de charts NVIDIA, puis `PriorityClass`).
- **Cause** : la source, la destination ou le type cluster-scoped manquait dans `sourceRepos`, `destinations` ou `clusterResourceWhitelist`. Ni `helm lint` ni `helm template` ne vérifient l'AppProject.
- **Correctif** : `k8s:8390149`, `k8s:e402435`.
- **Statut** : préservé.
- **Test** : aucun. Un contrôle CI qui confronte les `repoURL` et les types de ressources à l'AppProject est inscrit à la roadmap.

### L03 — Mismatch de version entre gateway et istiod
- **Symptôme** : injection en échec, puis `ErrImagePull` sur la gateway en `image: auto`.
- **Cause** : versions de chart différentes, et gateway synchronisée avant qu'istiod soit sain.
- **Correctif** : alignement des versions (`k8s:c54f30b`), istiod en wave `-1`, gateway dans `istio-ingress` (`k8s:066643d`, `k8s:cc3191b`).
- **Statut** : partie version préservée ; partie gateway en attente de l'ADR Gateway API (A1).

### L04 — Dérive du `caBundle` d'istiod
- **Symptôme** : l'Application istiod reste OutOfSync en permanence.
- **Cause** : istiod réécrit le `caBundle` de son `ValidatingWebhookConfiguration`.
- **Correctif** : `ignoreDifferences` sur ce champ.
- **Statut** : préservé.

### L07 — OutOfSync permanent sur les Jobs ML
- **Symptôme** : l'Application QuanvNN oscille entre Synced et OutOfSync.
- **Cause** : Kubernetes écrit `/status` et le label `controller-uid`, sous deux formes (avec et sans préfixe `batch.kubernetes.io/`). L'Application pointait aussi vers le projet `platform` au lieu de `ml`.
- **Correctif** : `ignoreDifferences` sur `/status` et sur les deux formes du label (`k8s:04697ad`), projet `ml` (`k8s:f3f69ff`).
- **Statut** : préservé. Le label `batch.kubernetes.io/job-name` n'est pas encore couvert (roadmap).

### L08 — ServiceAccount renommé par le nom de release
- **Symptôme** : l'identité cloud d'ESO ne fonctionne plus.
- **Cause** : ArgoCD utilise le nom de l'Application comme nom de release ; le chart en dérive le nom du ServiceAccount, qui ne correspond plus à l'identité attendue.
- **Correctif** : `releaseName` explicite (`k8s:b0f96c3`).
- **Statut** : préservé, voir ADR-0012.

## Sécurité et admission

### L05 — Politique Kyverno qui refuse tout en silence
- **Symptôme** : en Enforce, tous les pods auraient été refusés ; le mode Audit le masquait.
- **Cause** : `NotEquals` avec `value: "registry/*"` compare à un astérisque littéral.
- **Correctif** : migration vers `foreach` avec `pattern.image` (`k8s:0a7fbcd`). `anyPattern` a été écarté car il bloque les pods qui mélangent plusieurs registres.
- **Statut** : préservé. Toute politique doit être testée en Enforce avant d'être activée.

### L09 — `istio-init` refusé par Pod Security Standards
- **Symptôme** : ArgoCD ne redémarre plus après un remplacement de nœud ; les Jobs avec sidecar n'atteignent jamais `Completed`.
- **Cause** : `istio-init` exige `NET_ADMIN` et l'UID 0, refusés par le niveau `restricted`.
- **Correctif** : injection désactivée sur les namespaces concernés (`k8s:f838f58`, `k8s:ff5c315`).
- **Statut** : préservé, voir ADR-0009. À revoir si le mode ambient est retenu (A1).

### L16 — Charts amont non conformes aux politiques Enforce
- **Symptôme** : composants de plateforme refusés à l'admission.
- **Cause** : sidecars de charts amont non conformes.
- **Correctif** : exclusion explicite des namespaces de plateforme (`k8s:2f6a5c6`).
- **Statut** : préservé, voir ADR-0014.

### L18 — Secret d'administration initial d'ArgoCD
- **Leçon** : après le bootstrap, lire le mot de passe initial, demander sa rotation, supprimer `argocd-initial-admin-secret`, ne jamais l'afficher dans un résumé (`bot:61b7708`).
- **Statut** : préservé dans `bootstrap`.

### L19 — Injection de commande
- **Symptôme** : décodage d'un secret via `bash -c "… | base64 -d"`.
- **Cause** : construction d'une commande shell avec une donnée externe.
- **Correctif** : `encoding/base64` (`bot:b1a551e`).
- **Statut** : préservé comme règle : aucune commande shell construite avec une donnée externe.
- **Test** : `TestGetInitialAdminPassword_SecretExists_ReturnsDecoded`.

## Secrets

### L06 — ExternalSecret en `v1beta1`
- **Symptôme** : manifests sur une version d'API dépréciée.
- **Correctif** : migration vers `external-secrets.io/v1` (`k8s:f17cf3e`).
- **Statut** : préservé. Des `v1beta1` subsistent dans `docs/templates/` et `docs/examples/` (roadmap).

### L20 — ClusterSecretStore appliqué avant la CRD d'ESO
- **Symptôme** : échec du bootstrap au premier passage.
- **Cause** : la ressource est appliquée avant que la CRD soit enregistrée.
- **Correctif** : attente de la CRD (`bot:157175b`).
- **Statut** : préservé dans `bootstrap`.
- **Test** : `TestIsCRDNotFoundError_*`.

### L26 — Backend du store différent du cluster cible
- **Symptôme** : ESO en échec sur EKS, qui avait reçu le store Vault prévu pour Kind.
- **Cause** : le choix du backend ne dépendait pas du cluster cible (`bot:cb15a6f`).
- **Leçon** : le backend du store de secrets doit toujours correspondre au cluster cible.
- **Statut** : préservé. Avec D3, le backend vient de `secret_store_provider` dans le Secret de cluster ; `preflight` doit vérifier la cohérence. Risque direct sur Kind et Oracle Cloud (conflits C03 et C14).

## Observabilité

### L11 — Crash de Grafana au démarrage
- **Symptôme** : erreur `NOT NULL` au provisioning.
- **Cause** : datasources provisionnées deux fois (valeurs du chart et ConfigMaps).
- **Correctif** : `defaultDatasourceEnabled: false`, une ConfigMap par datasource avec un uid fixe (`k8s:61d7877`).
- **Statut** : préservé.

### L12 — Métriques absentes
- **Symptôme** : dashboard ArgoCD vide ; PodMonitor du namespace `ml` ignoré.
- **Cause** : sélecteurs de ServiceMonitor erronés ; Prometheus sans Role/RoleBinding dans `ml`.
- **Correctif** : `k8s:f56662e`.
- **Statut** : préservé.

### L10 — Image retirée d'un registre public
- **Symptôme** : job de nettoyage Kyverno en `ImagePullBackOff`.
- **Cause** : `bitnami/kubectl` retiré de docker.io.
- **Correctif** : surcharge vers `kyverno-cli` (`k8s:d23336e`).
- **Statut** : préservé. Toute image amont doit être épinglée et sa disponibilité surveillée.

## Terraform et CI

### L13 — Identité fédérée de la CI
- **Symptôme** : plan en échec sur le verrou d'état ; apply refusé sous un GitHub Environment.
- **Cause** : rôle de plan sans droits d'écriture sur la table de verrou ; sous `environment: <env>`, GitHub remplace le `sub` par `repo:<org>/<repo>:environment:<env>`.
- **Correctif** : `k8s:96a26fe`, `k8s:23cce41`.
- **Statut** : préservé côté AWS, à transposer à Oracle Cloud (E1). Voir ADR-0008.

### L14 — Densité de pods par nœud
- **Symptôme** : capacité de pods insuffisante pour la stack.
- **Cause** : sur EKS, le nombre de pods par nœud dépend du type d'instance (17 pour t3.medium) ; la stack compte environ 65 pods.
- **Correctif** : 4 nœuds, minimum 2 (`k8s:5f288aa`).
- **Statut** : préservé pour AWS. Vérifier la limite équivalente sur OKE.

### L15 — Pièges Terraform AWS
- Les règles de cycle de vie S3 exigent un `filter {}`, même vide, sinon elles sont ignorées en silence.
- L'addon CoreDNS ne doit être créé qu'une fois les nœuds actifs.
- Un module en `count` s'adresse avec un index (`module.x[0]`).
- `sed -i ''` sur macOS, `sed -i` sur Linux.
- L'API d'Identity Center refuse le tiret cadratin dans les descriptions.
- **Statut** : préservé (module AWS).

## Workloads ML

### L17 — Bloqueurs de l'audit QuanvNN
- Les arguments de la commande ne correspondaient pas aux points de montage du chart (`k8s:43fddde`). Test : comparer `helm template` au `CMD` du Dockerfile.
- Sans device plugin NVIDIA, un Job GPU reste Pending indéfiniment (`k8s:94697b7`).
- GHCR impose des noms en minuscules ; l'allowlist Kyverno doit utiliser la même casse.
- `readOnly` se définit par volume, pas par conteneur : un initContainer qui écrit et un conteneur qui lit doivent monter le même PVC deux fois.
- **Statut** : préservé.

## Go (bot)

### L21 — Pièges Go
- `append` sur une slice de paquet peut écraser le tableau sous-jacent (`bot:b437657`).
- Une erreur de `Close()` ignorée masque un échec d'écriture (`bot:1b3020b`).
- Les flags partagés par des sous-commandes Cobra doivent être des `PersistentFlags` (`bot:66ea987`).
- **Statut** : préservé comme règles du nouveau dépôt (B2).

## Hors périmètre

### L27 — `gh` v2.88
- Le type de champ `ITERATION` devient `SINGLE_SELECT`, et le champ `Repo` devient `Source Repo`.
