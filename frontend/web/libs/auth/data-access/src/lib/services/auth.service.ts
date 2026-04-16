import { API_URL } from '@web/shared/http-client';
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { catchError, Observable } from 'rxjs';
import { User } from '@web/shared/models/settings';
import { MessageService } from 'primeng/api';

@Injectable({
  providedIn: 'root',
})
export class AuthService {
  private http = inject(HttpClient);
  private apiUrl = inject(API_URL);
  private messageService = inject(MessageService);

  currentUser(): Observable<User> {
    return this.http.get<User>(`${this.apiUrl}identity/user`);
  }

  login(
    email: string,
    password: string,
    token: string
  ): Observable<{
    accessToken: string;
    refreshToken: string;
  }> {
    return this.http
      .post<{
        accessToken: string;
        refreshToken: string;
      }>(`${this.apiUrl}identity/login`, { email, password, token })
      .pipe(
        catchError((error) => {
          this.messageService.add({
            severity: 'error',
            summary: 'Error',
            detail: 'Invalid credentials',
          });
          throw error;
        })
      );
  }

  // Méthode pour rafraîchir les tokens. Utilisée par l'intercepteur HTTP
  refreshToken(): Observable<void> {
    try {
      return this.http.post<void>(`${this.apiUrl}identity/refresh`, {});
    } catch (error) {
      this.messageService.add({
        severity: 'error',
        summary: 'Error',
        detail: 'Failed to refresh token',
      });
      throw error;
    }
  }

  logout(): Observable<void> {
    try {
      return this.http.delete<void>(`${this.apiUrl}identity/logout`);
    } catch (error) {
      this.messageService.add({
        severity: 'error',
        summary: 'Error',
        detail: 'Failed to logout',
      });
      throw error;
    }
  }

  forgotPassword(email: string): Observable<void> {
    try {
      return this.http.post<void>(`${this.apiUrl}identity/forgot-password`, {
        email,
      });
    } catch (error) {
      this.messageService.add({
        severity: 'error',
        summary: 'Error',
        detail: 'Failed to send password reset email',
      });
      throw error;
    }
  }

  /**
   * Process an authorization request (e.g. from email link with ?token=...).
   * POST identity/authorization with { authorizationToken, token }.
   */
  processAuthorization(
    authorizationToken: string,
    turnstileToken: string
  ): Observable<{ i18nKey: string; message: string; extra?: unknown }> {
    return this.http
      .post<{ i18nKey: string; message: string; extra?: unknown }>(
        `${this.apiUrl}identity/authorization`,
        { authorizationToken, token: turnstileToken }
      )
      .pipe(
        catchError((error) => {
          throw error;
        })
      );
  }
}
