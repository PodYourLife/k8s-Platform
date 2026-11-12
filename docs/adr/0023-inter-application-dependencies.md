---
adr: 0023
title: "Dépendances entre Applications : convergence par réessai, sync-waves limitées à une Application"
status: Accepté
date: 2026-11-12
recorded: 2026-11-12
scope: [k8s-platform, platform-bot]
provenance: []
related: [ADR-0001, ADR-0002, ADR-0003]
supersedes: [ADR-0003]
---

# ADR-0023 — Dépendances entre Applications ArgoCD

- **Statut** : Accepté (2026-11-12)
- **Date** : 2026-11-12
- **Périmètre** : k8s-platform, platform-bot
- **Remplace** : ADR-0003

## Contexte

ADR-0003 ordonne le déploiement de la plateforme par l'annotation `argocd.argoproj.io/sync-wave`, posée sur les Applications. Ce mécanisme n'ordonne rien dans l'architecture actuelle :

1. **Une sync-wave ordonne des ressources au sein d'une seule synchronisation.** Elle n'a d'effet sur une Application que si une Application parente synchronise cette Application comme une ressource.
2. **Les Applications de la plateforme sont générées par des ApplicationSets** (ADR-0001 D3). Le contrôleur ApplicationSet crée et met à jour toutes les Applications d'un ApplicationSet en même temps (stratégie par défaut `AllAtOnce`). Aucune synchronisation parente n'évalue leurs vagues.
3. **Les Applications Istio posées directement** (`istio-base`, `istiod`…) ne sont synchronisées par aucune Application racine.
4. **Même avec une Application racine, ArgoCD n'évalue plus la santé des ressources `argoproj.io/Application` depuis la v1.8.** Ordonner des Applications par vagues exige de restaurer ce contrôle de santé par une personnalisation Lua dans `argocd-cm`.

Les vagues documentent donc un ordre que personne n'applique. La plateforme converge aujourd'hui par auto-guérison, sans que ce soit une décision.

Références :
- Sync waves : https://argo-cd.readthedocs.io/en/stable/user-guide/sync-waves/
- Santé de `argoproj.io/Application` : https://argo-cd.readthedocs.io/en/stable/operator-manual/health/
- Bootstrapping de cluster : https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/
- Progressive Syncs : https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Progressive-Syncs/
- Sync options : https://argo-cd.readthedocs.io/en/stable/user-guide/sync-options/
- Synchronisation automatique et réessais : https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/

## Options évaluées

| Option | Verdict | Raison |
|---|---|---|
| Garder les vagues sur les Applications générées | Écartée | Sans effet (contexte, points 1 et 2). |
| Application racine (app-of-apps) avec vagues + santé `Application` restaurée | Écartée | ArgoCD recommande les ApplicationSets avec générateur *cluster* pour le bootstrapping et présente l'app-of-apps comme une alternative réservée aux admins. Cela réintroduirait une couche que ADR-0001 a retirée, plus un script Lua à maintenir dans `argocd-cm`. |
| Progressive Syncs (`RollingSync`) | Écartée | Fonctionnalité en bêta. `RollingSync` force la désactivation de l'autosync sur toutes les Applications générées, incompatible avec `automated` + `selfHeal`. Elle n'ordonne que les Applications d'un même ApplicationSet. |
| **Convergence par réessai, vagues limitées à l'intérieur d'une Application** | **Retenue** | Modèle déclaratif d'ArgoCD : chaque Application converge seule, ses dépendances absentes provoquent un échec transitoire réessayé automatiquement. |

## Décision

### D1 — Aucun ordonnancement entre Applications par sync-waves

- L'annotation `argocd.argoproj.io/sync-wave` est **interdite** sur les ressources `Application` et `ApplicationSet`, et dans `template.metadata` des ApplicationSets.
- Elle reste autorisée sur les ressources Kubernetes **à l'intérieur** d'une Application (par exemple un `Job` de migration avant un `Deployment`), seul cas où ArgoCD l'applique.

### D2 — Convergence par réessai, configurée explicitement

Toute Application générée porte la même politique de synchronisation, définie dans le template de l'ApplicationSet :

```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
  retry:
    limit: -1          # retry until the dependency appears; failures are surfaced by D4
    backoff:
      duration: 10s
      factor: 2
      maxDuration: 3m
    refresh: true      # a retry picks up a newer commit instead of replaying a broken one
  syncOptions:
    - ServerSideApply=true
```

Le réessai est explicite, et non laissé au comportement par défaut : par défaut, une synchronisation automatique ne réessaie que 5 fois (de 5 s à 80 s), puis n'est plus retentée sur le même commit. Une dépendance plus lente à arriver laisserait l'Application bloquée jusqu'au commit suivant.

### D3 — Dépendances sur des CRD fournies par une autre Application

Une Application qui crée des ressources personnalisées dont la CRD est installée par une autre Application (ExternalSecret, ServiceMonitor, ClusterPolicy, Certificate…) porte :

```yaml
syncPolicy:
  syncOptions:
    - SkipDryRunOnMissingResource=true
```

Sans cette option, le dry-run échoue tant que la CRD n'existe pas. Avec elle, la synchronisation échoue proprement à l'application, puis D2 la réessaie jusqu'à l'arrivée de la CRD.

### D4 — Une non-convergence est un incident, pas un état normal

- Une Application `OutOfSync` ou `Degraded` depuis plus de **15 minutes** déclenche une alerte Prometheus, à partir de la métrique `argocd_app_info` (labels `sync_status`, `health_status`).
- `platform-bot status` et `preflight` (ADR-0001 D5) rapportent les Applications non convergées avec un code de sortie non nul.

### D5 — Cas qui ne convergent pas par réessai

Un réessai ne corrige que ce qui échoue à l'application. Un objet appliqué avec succès mais dans un état faux reste faux. Cas connu :

- **Gateway Istio classique** (`image: auto`) : si ses pods sont créés avant l'enregistrement du webhook d'injection, ils restent en `ImagePullBackOff`. La migration vers Gateway API (ADR-0001, phase A1), où istiod déploie lui-même le gateway, supprime ce cas. D'ici là, D4 le détecte et la correction est un `rollout restart` du gateway.

Tout nouveau cas de ce type est documenté ici, avec sa correction structurelle.

## Conséquences

- L'ordre de déploiement n'est plus documenté par des numéros de vague, mais par les dépendances réelles (CRD, namespaces, webhooks). Le premier déploiement d'un cluster prend quelques cycles de réessai de plus, borné par `maxDuration`.
- ADR-0002 est préservé : le namespace manquant fait échouer la synchronisation, qui est réessayée jusqu'à sa création par l'ApplicationSet `namespaces`.
- **À l'acceptation de cet ADR** :
  - ADR-0003 passe au statut « Remplacé par ADR-0023 » ;
  - retrait des annotations `sync-wave` des Applications et ApplicationSets, ajout de D2 et D3 aux templates (phase C1, avec la migration vers le générateur *cluster*) ;
  - suppression de la règle 6 de `validate-pr.yml` (présence de `sync-wave`), remplacée par la règle inverse ;
  - mise à jour des skills `pr-reviewer` et `implementer`, qui imposent aujourd'hui l'annotation (ADR-0003) ;
  - règle d'alerte de D4 dans la stack monitoring, livrée **dans la même PR** que D2 : un réessai illimité sans alerte masquerait une Application bloquée ;
  - sortie non convergée dans `platform-bot status`.

## Statut au regard de l'ADR-0001

Compatible et complémentaire. D3 (générateur *cluster*) est le modèle recommandé par ArgoCD pour le bootstrapping ; cet ADR en fixe la sémantique de convergence. D6 n'est pas affecté.
