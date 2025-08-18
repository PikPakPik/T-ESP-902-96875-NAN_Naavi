# auth-data-access

Cette bibliothèque contient la logique d'authentification pour l'application, incluant le store d'authentification et les guards de protection des routes.

## Guards disponibles

### TokenGuard

Vérifie la présence de l'access token et du refresh token dans le localStorage.

```typescript
import { TokenGuard } from '@web/auth/data-access';

// Dans votre configuration de routes
{
  path: 'dashboard',
  component: DashboardComponent,
  canActivate: [TokenGuard]
}
```

### AuthGuard

Vérifie si un utilisateur est connecté via le AuthStore.

```typescript
import { AuthGuard } from '@web/auth/data-access';

{
  path: 'profile',
  component: ProfileComponent,
  canActivate: [AuthGuard]
}
```

### CombinedAuthGuard

Vérifie à la fois la présence des tokens ET que l'utilisateur soit connecté. Recommandé pour une sécurité maximale.

```typescript
import { CombinedAuthGuard } from '@web/auth/data-access';

{
  path: 'admin',
  component: AdminComponent,
  canActivate: [CombinedAuthGuard]
}
```

## Méthodes utilitaires

Le `TokenGuard` expose des méthodes statiques utilitaires :

```typescript
import { TokenGuard } from '@web/auth/data-access';

// Vérifier si les tokens sont présents
const hasTokens = TokenGuard.hasValidTokens();

// Supprimer les tokens
TokenGuard.clearTokens();
```

## Stockage des tokens

Les guards s'attendent à trouver les tokens suivants dans le localStorage :

- `accessToken` : Token d'accès pour les API
- `refreshToken` : Token de rafraîchissement

## Tests

Exécutez `nx test auth-data-access` pour lancer les tests unitaires.
