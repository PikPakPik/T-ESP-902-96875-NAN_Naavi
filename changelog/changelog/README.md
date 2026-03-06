# Naavi Changelog

Changelog statique exposé via GitLab Pages pour l'app mobile et le backoffice.

## Structure

```
public/
├── main/                    # Prod
│   ├── mobile/
│   │   └── changelog.json
│   └── backoffice/
│       └── changelog.json
└── develop/                 # Dev
    ├── mobile/
    │   └── changelog.json
    └── backoffice/
        └── changelog.json
```

## URLs

### GitLab Pages (direct)

| Env | Mobile | Backoffice |
|-----|--------|------------|
| **main** (prod) | `https://epitech-msc-2026.gitlab.io/changelog/main/mobile/changelog.json` | `.../main/backoffice/changelog.json` |
| **develop** (dev) | `https://epitech-msc-2026.gitlab.io/changelog/develop/mobile/changelog.json` | `.../develop/backoffice/changelog.json` |

### Redirections naavi-trails.fr (Nginx Ingress)

| Env | URL | Redirige vers |
|-----|-----|---------------|
| **prod** | `https://naavi-trails.fr/Changelog` | `.../changelog/main/` |
| **prod** | `https://naavi-trails.fr/Changelog/mobile` | `.../main/mobile/changelog.json` |
| **prod** | `https://naavi-trails.fr/Changelog/backoffice` | `.../main/backoffice/changelog.json` |
| **dev** | `https://dev.naavi-trails.fr/Changelog` | `.../changelog/develop/` |
| **dev** | `https://dev.naavi-trails.fr/Changelog/mobile` | `.../develop/mobile/changelog.json` |
| **dev** | `https://dev.naavi-trails.fr/Changelog/backoffice` | `.../develop/backoffice/changelog.json` |

**Usage dans les apps :** Flutter (mobile) et Angular (backoffice) peuvent fetcher `https://<env>.naavi-trails.fr/Changelog/<plateforme>` — la redirection 302 renvoie vers le JSON GitLab Pages.

## Format JSON

```json
[
  {
    "version": "1.2.0",
    "date": "2025-02-27",
    "entries": [
      { "type": "feature", "text": "Description de la feature" },
      { "type": "fix", "text": "Description du fix" }
    ]
  }
]
```

Types d'entrées : `feature`, `fix`, `improvement`, `breaking`, etc.

## Mise à jour

Éditer les fichiers JSON dans `public/<env>/<plateforme>/changelog.json` et pusher sur `main`.
