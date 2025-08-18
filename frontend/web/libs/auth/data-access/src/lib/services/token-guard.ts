import { Injectable, inject } from '@angular/core';
import { CanActivate, Router, UrlTree } from '@angular/router';
import { Observable, of } from 'rxjs';
import { LocalStorageService } from '@web/shared/util';

@Injectable({ providedIn: 'root' })
export class TokenGuard implements CanActivate {
  private router = inject(Router);
  private localStorage = inject(LocalStorageService);
  canActivate(): Observable<boolean | UrlTree> {
    const accessToken = this.localStorage.getItem('accessToken');
    const refreshToken = this.localStorage.getItem('refreshToken');

    // Vérifier que les deux tokens sont présents
    if (accessToken && refreshToken) {
      return of(true);
    } else {
      // Rediriger vers la page de connexion si les tokens sont manquants
      return of(this.router.parseUrl('/login'));
    }
  }

  /**
   * Méthode utilitaire pour vérifier si les tokens sont présents
   * @returns true si les deux tokens sont présents, false sinon
   */
  hasValidTokens(): boolean {
    const accessToken = this.localStorage.getItem('accessToken');
    const refreshToken = this.localStorage.getItem('refreshToken');
    return !!(accessToken && refreshToken);
  }

  /**
   * Méthode utilitaire pour supprimer les tokens
   */
  clearTokens(): void {
    this.localStorage.removeItem('accessToken');
    this.localStorage.removeItem('refreshToken');
  }
}
