import { Injectable, inject } from '@angular/core';
import { CanActivate, Router, UrlTree } from '@angular/router';
import { AuthStore } from '../auth.store';
import { TokenGuard } from './token-guard';
import { Observable, of, from } from 'rxjs';
import { map, catchError } from 'rxjs/operators';

@Injectable({ providedIn: 'root' })
export class CombinedAuthGuard implements CanActivate {
  private router = inject(Router);
  private authStore = inject(AuthStore);
  private tokenGuard = inject(TokenGuard);

  canActivate(): Observable<boolean | UrlTree> {
    // Vérifier d'abord si les tokens sont présents
    const hasValidTokens = this.tokenGuard.hasValidTokens();

    if (!hasValidTokens) {
      // Pas de tokens valides, nettoyer et rediriger
      this.tokenGuard.clearTokens();
      return of(this.router.parseUrl('/login'));
    }

    // Si les tokens sont valides, vérifier si l'utilisateur est déjà chargé
    const user = this.authStore.user();

    if (user) {
      // Utilisateur déjà présent, autoriser l'accès
      return of(true);
    }

    // Tokens présents mais pas d'utilisateur, essayer de le charger
    return from(this.authStore.getUser()).pipe(
      map(() => {
        // Après avoir chargé l'utilisateur, vérifier s'il est maintenant présent
        const loadedUser = this.authStore.user();
        return loadedUser ? true : this.router.parseUrl('/login');
      }),
      catchError(() => {
        // En cas d'erreur lors du chargement, nettoyer et rediriger
        this.tokenGuard.clearTokens();
        return of(this.router.parseUrl('/login'));
      })
    );
  }
}
