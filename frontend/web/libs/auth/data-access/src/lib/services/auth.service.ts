import { marker } from '@colsen1991/ngx-translate-extract-marker';
import { catchError, Observable, tap } from 'rxjs';
import { HttpClient } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { User } from '@web/shared/models/settings';
import { API_URL } from '@web/shared/http-client';
import { NotificationService } from '@web/ui/notification';
import { LocalStorageService } from '@web/shared/util';

@Injectable({
  providedIn: 'root',
})
export class AuthService {
  readonly #http = inject(HttpClient);
  readonly #notification = inject(NotificationService);
  readonly #localStorage = inject(LocalStorageService);
  user(): Observable<User> {
    const message = marker('API.AUTH.FETCH_USER.FAILED.MESSAGE');
    const title = marker('API.AUTH.FETCH_USER.FAILED.TITLE');

    return this.#http.get<User>(`${API_URL}/users/user`).pipe(
      catchError((error) => {
        this.#notification.open(message, title, 'warn');
        throw error;
      })
    );
  }

  login(
    email: string,
    password: string
  ): Observable<{ token: string; user: User }> {
    const message = marker('API.AUTH.LOGIN.FAILED.MESSAGE');
    const title = marker('API.AUTH.LOGIN.FAILED.TITLE');

    return this.#http
      .post<{ token: string; user: User }>(`${API_URL}/users/login`, {
        email,
        password,
      })
      .pipe(
        tap((response) => {
          this.#localStorage.setItem('accessToken', response.token);
          this.#notification.open(message, title, 'success');
        }),
        catchError((error) => {
          this.#notification.open(message, title, 'warn');
          throw error;
        })
      );
  }

  logout(): Observable<void> {
    return this.#http.post<void>(`${API_URL}/users/logout`, {}).pipe(
      tap(() => {
        this.#localStorage.removeItem('accessToken');
      })
    );
  }
}
