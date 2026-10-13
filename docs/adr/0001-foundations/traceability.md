# Traçabilité ADR-0001 — table consolidée (validée le 2026-10-13)

> Les SHA cités pour la branche `dev` (dont `f7e19c7`, `cfd0ca3`, `8be6e10`) restent résolubles dans l'archive privée `PodYourLife/platform-archive`.

Sources : ARCH=ARCHITECTURE.md · RC=CLAUDE.md racine · CI=CUSTOM_INSTRUCTIONS_1_ · RM=ROADMAP.md · SEC=SECURITY.md ·
AI/ARGO/ESO/IST/K8S/OBS/TF/TEST=DOCS_* · GO=go-best-practices · AUD=AUDIT_QUANVNN_MVP · INT=INTEGRITY_REVIEW ·
KC=k8s-platform dev:CLAUDE.md · KR=k8s README/CONTRIBUTING/PR template/READMEs · PRxx=dev:PR_xx_REVIEW ·
BC=platform-bot CLAUDE.md · BR=bot README · GHA=ARGOCD_GITHUB_APP_SETUP · SDK=SDK_MIGRATION_PLAN · MEM=notes de session Phase 3 v1 (2026-05-04).
Hashes : k8s-platform (k8s:) ou platform-bot (bot:).

## A. ADR rétroactifs (statut Accepté, date d'origine = commit)

Les identifiants de travail A01 à A20 correspondent aux ADR-0002 à ADR-0021.

| ID | Titre | Date / commit | Décision | Sources | Note |
|---|---|---|---|---|---|
| [ADR-0002](../0002-namespace-ownership.md) | Propriété des namespaces | 2026-03-18 k8s:385911b | AppSet `namespaces` wave -3, `CreateNamespace=false` ailleurs | ARCH, RC, KC | |
| [ADR-0003](../0003-sync-wave-ordering.md) | Ordonnancement par sync-waves | 2026-03-01 k8s:fd3b16a | Ordre déterministe -3→16 | ARCH, CI, KC | table canonique à arbitrer (C02), révision GW |
| [ADR-0004](../0004-appproject-split.md) | Découpage des AppProjects | 2026-03-01 k8s:d568d63 (ml 2026-03-19 6ea216a) | platform / applications / ml, ml sans ressources cluster | ARCH, RM, KC | |
| [ADR-0005](../0005-eso-only-secrets.md) | ESO seul fournisseur de secrets | 2026-03-02 k8s:e23b947 | Ni Sealed Secrets ni Secret dans Git ; nom de store stable | ARCH, RC, CI, SEC, ESO | nom neutre à arbitrer (C03) |
| [ADR-0006](../0006-terraform-layering.md) | Terraform en couches, outputs = API publique | 2026-03-03 k8s:324957b | `_core` → `domains` via remote_state, apply en étapes | ARCH, RC, CI, TF | D3 ajoute `modules/{aws,oci,kind}` |
| [ADR-0007](../0007-compliance-profile.md) | Profil de conformité gradué | 2026-03-03 k8s:324957b | `compliance_profile` none/soc2/hipaa | ARCH, CI, SEC | profil prod à trancher (C2) |
| [ADR-0008](../0008-ci-only-prod-apply.md) | Apply prod depuis la CI uniquement, identité fédérée restreinte au dépôt et à l'environnement | 2026-03-03 k8s:9b8f310 / 2026-03-30 98511f1 | Aucun humain n'écrit en prod ; implémentation actuelle : OIDC GitHub → AWS (`sub`) ; OCI en E1 | ARCH, CI, SEC, KR | |
| [ADR-0009](../0009-istio-sidecar-exemption.md) | Exemption sidecar pour Jobs et opérateurs non-mesh | 2026-03-01 k8s:0d7967c (+ff5c315, f838f58) | Pas d'injection sur Jobs batch / opérateurs | ARCH, AI, K8S, IST, KC | sera révisé par ADR ambient (A1) |
| [ADR-0010](../0010-ml-batch-job-chart.md) | Chart ml-batch-job générique | 2026-03-19 k8s:1b145a8 | Jobs GPU→CPU, déclenchement `runId`, `restartPolicy: Never`, TTL 24 h, GPU scale-to-zero, agnostique du déclencheur | ARCH, AI, K8S | |
| [ADR-0011](../0011-whole-gpu-allocation.md) | Allocation GPU entière | 2026-04-08 — `DOCS_AI_WORKLOADS.md` (sha256 c1668f2f874b…), `DOCS_KUBERNETES.md` (sha256 669c0133e19e…), non versionnés, mtime 2026-04-08 | Ni MIG ni time-slicing | AI, K8S, ARCH | date incertaine |
| [ADR-0012](../0012-workload-identity.md) | Identité par workload | 2026-04-08 — `DOCS_KUBERNETES.md` (sha256 669c0133e19e…), non versionné, mtime 2026-04-08 | 1 SA par workload, pas d'automount, noms verrouillés (chaîne SA → identité) | K8S, ESO, INT, RM | dépend de `identity_mode` |
| [ADR-0013](../0013-platform-owned-priorityclasses.md) | PriorityClasses gérées par la plateforme | 2026-04-26 k8s:0d02210 | Ressources cluster-scoped hors des charts | RM, AI, K8S, AUD | |
| [ADR-0014](../0014-kyverno-baseline.md) | Baseline Kyverno | 2026-04-18 k8s:8a22dea | Policies obligatoires + exclusions plateforme | SEC, KR | + `verifyImages` (ADR-0001) |
| [ADR-0015](../0015-networkpolicy-default-deny.md) | NetworkPolicy deny-all par défaut | 2026-04-18 k8s:d65d1b9 | deny-all + DNS + scrape | SEC, ESO, K8S | |
| [ADR-0016](../0016-github-app-argocd.md) | GitHub App plutôt que PAT pour ArgoCD | 2026-04-17 bot:10831fa | Identité machine, portée 1 dépôt, rotation | GHA, ARCH, CI | stockage via ESO (D3) |
| [ADR-0017](../0017-kubernetes-helm-sdks.md) | SDK Kubernetes/Helm, CLI en exec durcies | 2026-04-18 bot:73e436b | client-go + helm/v3 ; terraform/kind en exec | SDK, BC | justification de D5 |
| [ADR-0018](../0018-ddd-and-size-limits.md) | Discipline DDD et plafonds de taille | 2026-03-17 bot:f692beb / 2026-03-30 1e3db2d | 1 paquet propriétaire, pas de pass-through, 200 l./fichier, 50/80 l./fonction | BC, INT, ARCH, CI | |
| [ADR-0019](../0019-interface-segregation.md) | ISP, pas de God interface | 2026-04-22 bot:0112ca1 | Interfaces étroites, composites locaux | BC, MEM | |
| [ADR-0020](../0020-testing-philosophy.md) | Philosophie de test | 2026-04-21 bot:c928b3d | 1 mock par port, E2E filet, pas de code test en prod | BC, TEST | |
| [ADR-0021](../0021-single-write-guard.md) | Façade d'écriture unique pour `--dry-run` | 2026-04-28 bot:e55f889 | Toute mutation passe par un garde | BC | base de `scaffold --dry-run` |
| — | KEDA ScaledJob pour Jobs ; sync dataset par initContainer | 2026-04-08 / 2026-04-26 | jamais implémentés | AI, RM | **proposé : roadmap, pas ADR** |
| — | Niveaux PSS | 2026-03-22 | — | ESO, K8S | **ADR après arbitrage A2** (C01) |

## B. lessons-learned.md (symptôme, cause, correctif, statut post-ADR, test)

| ID | Bug | Correctif | Statut post-ADR | Test |
|---|---|---|---|---|
| L01 | AppSets de tous les env vers le même cluster | k8s:0468ae0 destination env-aware | Préservé (`{{.server}}`) | critère POC A0 n°2 |
| L02 | AppProject refuse au sync (kyverno, repo nvidia, PriorityClass) ; helm lint vert | k8s:8390149, e402435 | Préservé | gate CI AppProject (ouvert) |
| L03 | Mismatch version gateway/istiod ; `ErrImagePull` sur `image: auto` | k8s:c54f30b, 066643d, cc3191b | Version préservée ; partie gateway en attente de l'ADR Gateway API (A1) | — |
| L04 | Dérive `caBundle` istiod | `ignoreDifferences` VWC | Préservé | — |
| L05 | Kyverno `NotEquals` + `*` littéral → tout refusé (masqué par Audit) | k8s:0a7fbcd foreach | Préservé | — |
| L06 | ExternalSecret v1beta1 → v1 | k8s:f17cf3e | Préservé, **résidus v1beta1 dans docs/templates** | — |
| L07 | OutOfSync ml : Job `/status`, `controller-uid` préfixé ; app hors projet `ml` | k8s:04697ad, f3f69ff | Préservé (`job-name` non couvert) | — |
| L08 | ReleaseName = nom d'app → SA renommé → identité cassée | k8s:b0f96c3 `releaseName` explicite | Préservé | — |
| L09 | `istio-init` refusé par PSS restricted ; Jobs jamais Completed avec sidecar | k8s:f838f58, ff5c315 | Préservé (revoir si ambient) | — |
| L10 | `bitnami/kubectl` retiré de docker.io | k8s:d23336e override kyverno-cli | Préservé | — |
| L11 | Grafana crash sur double provisioning datasource | k8s:61d7877 1 ConfigMap/uid fixe | Préservé | — |
| L12 | Dashboard ArgoCD vide (sélecteurs) ; PodMonitor ml ignoré (RBAC) | k8s:f56662e | Préservé | — |
| L13 | Rôle plan sans perms de verrou ; `sub` différent sous GitHub Environment | k8s:96a26fe, 23cce41 | Préservé (AWS, transposable OCI) | — |
| L14 | t3.medium = 17 pods/nœud → 4 nœuds | k8s:5f288aa | Préservé (AWS) | — |
| L15 | Pièges Terraform AWS : `filter {}`, CoreDNS après nœuds, `[0]` sur count, `sed -i ''`, tiret cadratin SSO | divers | Préservé | — |
| L16 | Namespaces plateforme exclus des policies Enforce | k8s:2f6a5c6 | Préservé | — |
| L17 | BLOCKER-1 args ≠ montages ; plugin NVIDIA absent ; casse GHCR ; `readOnly` par volume | k8s:43fddde, 94697b7 … | Préservé | `helm template` vs CMD Dockerfile |
| L18 | `argocd-initial-admin-secret` jamais affiché, rotation, suppression | bot:61b7708 | Préservé (bootstrap) | — |
| L19 | Injection de commande `bash -c base64 -d` | bot:b1a551e | Préservé (règle) | `TestGetInitialAdminPassword_SecretExists_ReturnsDecoded` |
| L20 | ClusterSecretStore appliqué avant la CRD ESO | bot:157175b attente CRD | Préservé (bootstrap) | `TestIsCRDNotFoundError_*` |
| L21 | `append` sur slice de paquet ; erreurs avalées ; PersistentFlags Cobra | bot:b437657, 1b3020b, 66ea987 | Préservé (règles Go) | — |
| L26 | Le backend du store de secrets doit correspondre au cluster cible (cas d'origine : store Vault appliqué sur EKS) | bot:cb15a6f | Préservé, reformulé ; lié à C03 et C14 (risque Kind/OCI) | — |
| L27 | `gh` v2.88 ITERATION / `Repo` | — | Hors périmètre | — |

## C. Postmortem docs/postmortems/phase3-v1.md (blameless)

| ID | Contenu |
|---|---|
| P01 | Chronologie : 8be6e10 (27/04, 1re hydratation) → PR #10 bot 522d52b (28/04, fix A/B/C) → f7e19c7 (30/04, `env setup`, 54 fichiers) → cfd0ca3 (04/05, réinjection) → session interrompue après l'étape 3 ; binaire = 522d52b (SHA-256 vérifié) |
| P02 | R1 : platform.yaml réécrit (Marshal/Unmarshal + omitempty), constaté dans f7e19c7 ; tests existants hors chemin |
| P03 | R2 : `__ESO_IRSA_ROLE_ARN__` littéral dans 16 AppSets, exit 0 ; mapping partiel, pas de contrôle post-étape ; même famille que les bugs de mapping de placeholders (archivés) |
| P04 | R3 : tfvars et backend.tf staging/prod mutés dans f7e19c7 ; **validate-pr.yml : motif de contrôle des placeholders lui-même substitué** (contrôle neutralisé) |
| P05 | R4 : SSH agent go-git ≠ git système ; le correctif 828e779 régresse |
| P06 | B : f7e19c7 committe `.claude/settings.local.json`, CLAUDE.md, PR_*_REVIEW ; cfd0ca3 committe `terraform-outputs.json` (16 sorties) ; ARN substitué jusque dans un commentaire |
| P07 | Cause commune : réimplémentation impérative avec écriture Git (3/5 go-git, 2/5 mapping) |
| P08 | Détection manquée : tests unitaires verts sans invariants E2E, succès en exit 0 sur état partiel, E2E opt-in non lancé, SSH sans vrai agent, pas de diff d'arbre |
| P09 | Fragilités connues avant (AUD/INT) : timeout 25 min, output best-effort, table codée en dur, œuf-poule `--local --push`, découverte AppProjects par glob |
| P10 | Décision : ADR-0001 (D1, D4, D5, D7) |

## D. CLAUDE.md k8s-platform (rédigé en A2 — consigné ici)

D01 pas de `kubectl apply` hors break-glass · D02 pas de `latest` (digest/semver) · D03 aucun Secret dans Git, ESO seul · D04 `CreateNamespace=false` · D05 SSA sans `--force`, pas de `kubectl delete ns` · D06 securityContext restricted + exception rootfs documentée · D07 requests/limits, GPU en limits · D08 probes, Jobs exemptés, nodeSelector+toleration GPU ensemble · D09 RBAC Role/RoleBinding, jamais `*` · D10 mTLS STRICT racine · D11 un ArgoCD par cluster, Istio par Helm via ArgoCD · D12 versions épinglées (9 composants) · D13 200 l./fichier, SRP, ne jamais supprimer un commentaire, dépôt purement déclaratif · D14 `{{.camelCase}}` goTemplate · D15 split prometheus-values/grafana-values, sidecar `grafana_datasource=1` · D16 table des waves canonique (après C02) · D17 bugs résolus → lien lessons-learned.

## E. CLAUDE.md platform-bot (nouveau dépôt, B2)

E01 « Before every change » §1–6 + rapport « Checked: » · E02 pas de pass-through ni wrapper sans appelant · E03 contexte de bout en bout, `signal.NotifyContext` · E04 golangci-lint v2 + lefthook · E05 E2E opt-in tag `e2e` · E06 nommage `Subject_Condition_Result` · E07 `command_registry.go` source unique · E08 enchaînement bootstrap (nodes Ready → namespaces → ArgoCD → CRD ESO → store) · E09 timeouts par opération · E10 Go 1.25 · E11 `panic` (conflit C15).
Docs du nouveau dépôt : `docs/testing-strategy.md` (TEST, exemples réécrits), `docs/go-guidelines.md` (GO ch.1-12, sans exemples placeholders, sans automaxprocs).

## F. Runbooks (k8s-platform/docs/runbooks/)

R01 kind-local (topologie, accès, dépannage) · R02 github-app-argocd (création, rotation, shred) · R03 quanvnn-run (PR `runId` → suivi → Grafana) · R04 credential-leak (rotation, périmètre, révocation ; purge alignée sur D7) · R05 aws-bootstrap (state, 3 étapes, destroy — AWS sans E2E) · R06 istio-upgrade (canary `istio.io/rev`, adapter GW) · R07 state-backend (bucket supprimé avant destroy).

## G. Docs existantes à réécrire plus tard (contenu valide consigné)

argocd/README.md (waves, ignoreDifferences ml, repos amont, ajout d'app) · kubernetes/helm/ml-batch-job/README.md (contrat image, chemins, schéma, GHCR minuscules, verrou identité) · monitoring README (rétention, dashboards, uid fixes, Loki, KPIs QuanvNN) · terraform/**/README.md et modules/aws (I/O, contrôles conformité) · SECURITY.md (principes, Kyverno, securityContext, OIDC, registre d'exceptions, cible NetPol/AuthorizationPolicy).

## H. Roadmap

H01 initContainer dataSync + Dubai256 (F1) · H02 DoD run QuanvNN CPU (F2) · H03 KEDA ScaledJob, S3→file→Job neutre cloud · H04 DCGM, métriques GPU, Pushgateway · H05 NetworkPolicy/AuthorizationPolicy applicatives + `ml` · H06 ResourceQuota `ml` · H07 gate CI AppProject · H08 `job-name` ignoreDifferences · H09 `priorityClassName`/`preemptionPolicy` dans le chart · H10 pin `gpuFeatureDiscovery` nvidia · H11 résidus ESO v1beta1 dans docs/templates · H12 **templates scaffold en `:latest` → tag/digest avant B2** · H13 templates VirtualService → HTTPRoute (GW) · H14 durcissement exec terraform/kind (codes typés, `-json`, timeouts) · H15 `check` → base de `preflight` · H16 supervision expiration token GitHub App · H17 alerting Slack · H18 groupe `ml-team` · H19 SSE-KMS, `public_access_cidrs` · H20 multi-cluster/vCluster, QPU · H21 remplacer le grep de `validate-pr.yml` par gitleaks avec `.gitleaks.toml` versionné (règles ARN et account ID), binaire épinglé + checksum en CI.

## I. Conflits à arbitrer

C01 PSS par namespace (ESO ≠ K8S ≠ manifests) → A2 · C02 table des waves (ARGO, IST, argocd/README, KC) → la vérité = manifests de main · C03 nom du ClusterSecretStore (`aws-secrets-manager` vs `-cluster` vs neutre) · C04 matrice d'injection (README, KC, IST, K8S ≠ manifests) → vérité = manifests · C05 K8s 1.32/1.33 · C06 Go 1.24/1.25/1.26 · C07 namespace `ml` vs `ai-workloads` · C08 labels Kyverno `app/env/team` vs `app.kubernetes.io/*` · C09 mode Kyverno probes (Audit staging ?) · C10 métriques ServiceMonitor vs PodMonitor · C11 bucket = annotation non secrète (D3 tranche) · C12 conformité dev ✗/✓, prod hipaa/soc2 · C13 rôle apply : main seul vs branches/environments · C14 backend secrets Kind : mock / Vault / `kubernetes` · C15 `panic` autorisé (GO) vs interdit (global) · C16 rootfs RO vs `pip install` runtime GPU · C17 alias GHCR `-latest` · C18 langue des réponses FR (CI) vs EN (global) · C19 exceptions mTLS (`monitoring` vs `kube-system`) · C20 chemins de secrets (`{cluster}/{ns}/{app}` vs `<app>/<key>` vs `platform/…`) · C21 A10 (GPU entier) contre l'item backlog « device plugin + MIG time-slicing » → A10 l'emporte, backlog réécrit en A2 · C22 instructions du projet claude.ai encore sur l'ancien modèle (branches, `env add`, placeholders, `istio-ingress` + `image: auto`) → consigné dans « À traiter » de l'ADR, A2.

Procédure C02/C04 : partir de `main`, `git diff main..dev` restreint aux annotations `argocd.argoproj.io/sync-wave` et labels `istio-injection`, valider la table finale par le POC A0. C04 provisoire jusqu'à l'évaluation ambient (A1).

## J. Archive (remplacé / obsolète) → dépôt privé `PodYourLife/platform-archive`

L22–L25 (attente CI, go-git, placeholders, `git add -f`) : archive stricte ; la leçon générale de L24 est portée par P08.
Modèle de branches et placeholders (D1/D3) · générateur list (D3) · commandes et packages du bot (D5/D7) · réinjection des sorties (D4) · AWS en dur, 3 EKS, coûts $597 (D2/D3) · `istio-ingress`/`image: auto`/VirtualService/NLB (GW) · ArgoCD Image Updater (D1/D6) · aws-sdk, go-git, client REST GitHub (D5) · internal/domain et ports Git/Hydration/SecretStore (obsolète) · Sprints 1–2 et journal de décisions de RM · istio/README (1.20), monitoring README pré-ArgoCD, terraform-new-env.md, stubs azure/gcp · automaxprocs, loki-stack · AUD, INT, PR_38/39/41 (rapports datés).
