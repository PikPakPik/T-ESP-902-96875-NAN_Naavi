# GitLab KPIs Exporter pour Prometheus

Exporter personnalisé qui collecte toutes les données brutes de GitLab (issues, merge requests, milestones, branches, tags, commits) et les expose au format Prometheus.

**Philosophie:** Exporter toutes les données brutes individuellement, faire les agrégations côté Grafana.

## Métriques exportées

Chaque entité est exportée individuellement avec toutes ses métadonnées sous forme de labels Prometheus. Cela permet une flexibilité maximale pour créer des agrégations personnalisées dans Grafana.

### Projets
**Métrique:** `gitlab_project_info`

Chaque projet expose:
- `project_id` - ID numérique du projet
- `project` - Nom du projet
- `namespace` - Chemin complet du namespace (groupe/sous-groupe)
- `visibility` - Visibilité (public, private, internal)
- `default_branch` - Branche par défaut
- `created_at` - Date de création

### Issues
**Métrique:** `gitlab_issue`

Chaque issue expose:
- `project_id`, `project`, `namespace` - Identification du projet
- `issue_iid`, `issue_id` - IID et ID de l'issue
- `title` - Titre de l'issue (tronqué à 150 chars)
- `state` - État (opened, closed)
- `author` - Username de l'auteur
- `assignees` - Liste des assignees (séparés par virgule)
- `labels` - Labels de l'issue
- `created_at`, `updated_at`, `closed_at` - Timestamps
- `milestone` - Milestone associée
- `web_url` - URL vers l'issue

### Merge Requests
**Métrique:** `gitlab_merge_request`

Chaque MR expose:
- `project_id`, `project`, `namespace` - Identification du projet
- `mr_iid`, `mr_id` - IID et ID de la MR
- `title` - Titre de la MR (tronqué à 150 chars)
- `state` - État (opened, merged, closed)
- `author` - Username de l'auteur
- `assignees` - Liste des assignees
- `reviewers` - Liste des reviewers
- `labels` - Labels de la MR
- `source_branch`, `target_branch` - Branches source et cible
- `created_at`, `updated_at`, `merged_at`, `closed_at` - Timestamps
- `draft`, `work_in_progress` - Indicateurs draft/WIP
- `milestone` - Milestone associée
- `web_url` - URL vers la MR

### Milestones
**Métrique:** `gitlab_milestone`

Chaque milestone expose:
- `project_id`, `project`, `namespace` - Identification du projet
- `milestone_id`, `milestone_iid` - ID et IID du milestone
- `title` - Titre du milestone
- `state` - État (active, closed)
- `created_at`, `updated_at`, `due_date`, `start_date` - Timestamps
- `web_url` - URL vers le milestone

### Branches
**Métrique:** `gitlab_branch`

Chaque branche expose:
- `project_id`, `project`, `namespace` - Identification du projet
- `branch_name` - Nom de la branche
- `protected` - Branche protégée (true/false)
- `merged` - Branche mergée (true/false)
- `default` - Branche par défaut (true/false)
- `commit_sha` - SHA du dernier commit
- `commit_author` - Auteur du dernier commit
- `commit_date` - Date du dernier commit

### Tags
**Métrique:** `gitlab_tag`

Chaque tag expose:
- `project_id`, `project`, `namespace` - Identification du projet
- `tag_name` - Nom du tag
- `message` - Message du tag
- `target` - Cible du tag
- `commit_sha` - SHA du commit associé
- `commit_author` - Auteur du commit
- `commit_date` - Date du commit
- `release` - A une release associée (true/false)

### Commits
**Métrique:** `gitlab_commit`

Chaque commit expose (limité aux 100 derniers de la branche par défaut):
- `project_id`, `project`, `namespace` - Identification du projet
- `commit_sha` - SHA complet du commit
- `short_id` - SHA court
- `author_name`, `author_email` - Informations de l'auteur
- `committer_name`, `committer_email` - Informations du committer
- `created_at` - Date du commit
- `title` - Titre du commit (première ligne)
- `message_first_line` - Première ligne du message
- `web_url` - URL vers le commit

## Prérequis

1. Token GitLab avec les permissions suivantes:
   - `api`
   - `read_api`
   - `read_repository`

2. Pour créer un token:
   - Aller sur GitLab → Settings → Access Tokens
   - Créer un token avec les scopes mentionnés ci-dessus

## Installation

### 1. Créer le Secret avec votre token GitLab

Éditez `secret.yaml` et remplacez `YOUR_GITLAB_TOKEN_HERE` par votre token, puis appliquez:

```bash
kubectl apply -f secret.yaml
```

Ou créez le secret directement en ligne de commande:

```bash
kubectl create secret generic gitlab-kpis-exporter-secret \
  --from-literal=gitlab-token=YOUR_GITLAB_TOKEN_HERE \
  -n monitoring
```

### 2. Builder et pusher l'image Docker

```bash
# Builder l'image
docker build -t YOUR_REGISTRY/gitlab-kpis-exporter:latest .

# Pusher vers votre registry
docker push YOUR_REGISTRY/gitlab-kpis-exporter:latest
```

Mettez à jour `deployment.yaml` avec le bon nom d'image.

### 3. Déployer dans Kubernetes

```bash
kubectl apply -f configmap.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

### 4. Vérifier le déploiement

```bash
# Vérifier que le pod tourne
kubectl get pods -n monitoring -l app=gitlab-kpis-exporter

# Voir les logs
kubectl logs -n monitoring -l app=gitlab-kpis-exporter -f

# Tester les métriques (port-forward)
kubectl port-forward -n monitoring svc/gitlab-kpis-exporter 8080:8080
curl http://localhost:8080/metrics
```

## Configuration

Modifiez `configmap.yaml` pour ajuster:

- `GITLAB_URL`: URL de votre instance GitLab (défaut: https://gitlab.com)
- `GITLAB_GROUP`: Nom du groupe GitLab à surveiller
- `INCLUDE_SUBGROUPS`: Inclure les sous-groupes (true/false)
- `PORT`: Port du serveur de métriques (défaut: 8080)
- `REFRESH_INTERVAL`: Intervalle de refresh en secondes (défaut: 3600)
- `COMMIT_SINCE_DAYS`: Nombre de jours pour les commits récents (défaut: 30). Seuls les commits sur la branche par défaut depuis cette date sont exportés.

## Configuration Prometheus

L'exporter est automatiquement découvert par Prometheus grâce aux annotations du Service.

La configuration Prometheus a déjà été mise à jour dans `monitoring/prometheus/configmap.yaml`:

```yaml
- job_name: 'gitlab-kpis-exporter'
  static_configs:
    - targets: ['gitlab-kpis-exporter.monitoring.svc.cluster.local:8080']
  metrics_path: /metrics
  scrape_interval: 60s
  scrape_timeout: 30s
```

## Exemples de requêtes PromQL pour Grafana

### Compteurs simples

```promql
# Nombre total d'issues ouvertes
count(gitlab_issue{state="opened"})

# Nombre total d'issues par projet
count(gitlab_issue) by (project)

# Nombre d'issues par état
count(gitlab_issue) by (state)

# Nombre d'issues par auteur
count(gitlab_issue) by (author)

# Nombre de MRs ouvertes
count(gitlab_merge_request{state="opened"})

# Nombre de MRs mergées
count(gitlab_merge_request{state="merged"})

# Nombre de commits par projet
count(gitlab_commit) by (project)

# Nombre de branches par projet
count(gitlab_branch) by (project)

# Nombre de tags par projet
count(gitlab_tag) by (project)
```

### Métriques par utilisateur

```promql
# Top 10 des auteurs d'issues
topk(10, count(gitlab_issue) by (author))

# Top 10 des auteurs de MRs
topk(10, count(gitlab_merge_request) by (author))

# Top 10 des contributeurs (commits)
topk(10, count(gitlab_commit) by (author_name))

# Issues assignées par personne
count(gitlab_issue{assignees!=""}) by (assignees)

# MRs assignées par personne
count(gitlab_merge_request{assignees!=""}) by (assignees)
```

### Métriques temporelles

```promql
# Issues ouvertes il y a plus de 30 jours
# Note: Les dates sont en ISO format, vous pouvez utiliser des transformations Grafana
count(gitlab_issue{state="opened"})

# MRs ouvertes depuis plus de 7 jours
count(gitlab_merge_request{state="opened"})

# Durée entre création et merge (en utilisant les timestamps)
# Utilisez les transformations Grafana pour calculer merged_at - created_at
```

### Métriques par milestone

```promql
# Issues par milestone
count(gitlab_issue{milestone!=""}) by (milestone)

# MRs par milestone
count(gitlab_merge_request{milestone!=""}) by (milestone)
```

### Métriques par labels

```promql
# Issues par label (si un seul label)
count(gitlab_issue{labels!=""}) by (labels)

# MRs avec le label "bug"
count(gitlab_merge_request{labels=~".*bug.*"})
```

### Métriques avancées

```promql
# Ratio MRs draft vs non-draft
count(gitlab_merge_request{draft="true"}) / count(gitlab_merge_request)

# Branches protégées
count(gitlab_branch{protected="true"})

# Tags avec release
count(gitlab_tag{release="true"})

# Commits par email domain
count(gitlab_commit) by (author_email)

# Projets par visibilité
count(gitlab_project_info) by (visibility)
```

### Tables et listes détaillées

Pour afficher des tables dans Grafana, utilisez directement les métriques:

```promql
# Liste de toutes les issues ouvertes avec détails
gitlab_issue{state="opened"}

# Liste de toutes les MRs ouvertes
gitlab_merge_request{state="opened"}

# Toutes les branches
gitlab_branch
```

Dans Grafana, configurez le panel en mode "Table" et sélectionnez les colonnes à afficher.

## Performance et considérations

### Volumétrie

- L'exporter collecte TOUTES les entités (issues, MRs, branches, tags) de tous les projets
- Les commits sont limités aux 100 derniers de chaque branche par défaut
- Pour un gros groupe avec beaucoup de projets et d'historique, cela peut générer beaucoup de métriques

### Limites Prometheus

Prometheus a des limites sur le nombre de séries temporelles. Si vous avez trop de projets:

1. **Option 1:** Ajustez `INCLUDE_SUBGROUPS=false` pour limiter aux projets du groupe principal
2. **Option 2:** Limitez le nombre de commits: modifiez `per_page=100` dans la fonction `_collect_commits`
3. **Option 3:** Filtrez certains projets en modifiant le code
4. **Option 4:** Augmentez les limites de Prometheus

### Optimisations

- Par défaut, la collecte est faite à chaque scrape Prometheus (toutes les 60s selon la config)
- Le collector met les données en cache entre les scrapes
- Ajustez `scrape_interval` dans la config Prometheus selon vos besoins

### Limites de ressources

Les limites définies dans `deployment.yaml`:
- Requests: 256Mi RAM, 200m CPU
- Limits: 512Mi RAM, 1000m CPU

Ajustez selon le nombre de projets et la volumétrie.

## Développement local

Pour tester en local:

```bash
# Installer les dépendances
pip install -r requirements.txt

# Configurer les variables d'environnement
export GITLAB_TOKEN="your_token_here"
export GITLAB_URL="https://gitlab.com"
export GITLAB_GROUP="epitech-msc-2026"
export INCLUDE_SUBGROUPS="true"
export PORT="8080"

# Lancer l'exporter
python exporter.py

# Les métriques sont disponibles sur http://localhost:8080/metrics
curl http://localhost:8080/metrics | grep gitlab_issue
```

## Troubleshooting

### Les métriques ne s'affichent pas
- Vérifiez que le token GitLab a les bonnes permissions
- Vérifiez les logs du pod: `kubectl logs -n monitoring -l app=gitlab-kpis-exporter`

### Timeout lors de la collecte
- Augmentez `scrape_timeout` dans la config Prometheus
- Augmentez les limites de ressources dans `deployment.yaml`
- Réduisez le nombre de projets en désactivant `INCLUDE_SUBGROUPS`
- Limitez le nombre de commits collectés

### Erreur 403 de GitLab
- Vérifiez que le token est valide et a les bonnes permissions
- Vérifiez que le groupe existe et est accessible avec ce token

### Trop de métriques / Prometheus surchargé
- Limitez les commits: réduisez `per_page` dans `_collect_commits`
- Désactivez `INCLUDE_SUBGROUPS` pour limiter aux projets du groupe principal
- Filtrez les projets archivés ou inactifs (modifiez le code)
- Augmentez les ressources Prometheus

### Labels tronqués
- Les labels Prometheus ont une limite de ~200 caractères
- Le code tronque automatiquement les valeurs trop longues
- Ajustez `max_length` dans les fonctions `_safe_str()` si nécessaire
