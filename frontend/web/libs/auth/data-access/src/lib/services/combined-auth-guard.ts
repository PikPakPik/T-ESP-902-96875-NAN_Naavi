import { Injectable, inject } from '@angular/core';
import { CanActivate, Router, UrlTree } from '@angular/router';
import { AuthStore } from '../auth.store';
import { TokenGuard } from './token-guard';
import { Observable, of } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class CombinedAuthGuard implements CanActivate {
  private router = inject(Router);
  private authStore = inject(AuthStore);
  private tokenGuard = inject(TokenGuard);

  canActivate(): Observable<boolean | UrlTree> {
    // Vérifier d'abord si les tokens sont présents
    const hasValidTokens = this.tokenGuard.hasValidTokens();

    // Vérifier ensuite si l'utilisateur est connecté
    const user = this.authStore.user();

    if (hasValidTokens && user) {
      return of(true);
    } else {
      // Si les tokens ou l'utilisateur manquent, nettoyer et rediriger
      if (!hasValidTokens) {
        this.tokenGuard.clearTokens();
      }
      return of(this.router.parseUrl('/login'));
    }
  }
}
