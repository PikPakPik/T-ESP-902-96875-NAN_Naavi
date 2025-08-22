import { marker } from '@colsen1991/ngx-translate-extract-marker';
import { catchError, Observable, of, tap } from 'rxjs';
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
  readonly #notification: NotificationService = inject(NotificationService);
  readonly #localStorage = inject(LocalStorageService);
  readonly #apiUrl = inject(API_URL);

  user(): Observable<User> {
    const message = marker('API.AUTH.FETCH_USER.FAILED.MESSAGE');
    const title = marker('API.AUTH.FETCH_USER.FAILED.TITLE');

    return this.#http.get<User>(`${this.#apiUrl}/users/user`).pipe(
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

    this.#localStorage.setItem('accessToken', '123');
    this.#localStorage.setItem('refreshToken', '123');
    this.#notification.open(message, title, 'success');

    return of({
      token: '123',
      user: {
        id: '1',
        email,
        password,
        firstName: 'John',
        lastName: 'Doe',
      },
    });

    // return this.#http
    //   .post<{ token: string; user: User }>(`${API_URL}/users/login`, {
    //     email,
    //     password,
    //   })
    //   .pipe(
    //     tap((response) => {
    //       this.#localStorage.setItem('accessToken', response.token);
    //       this.#notification.open(message, title, 'success');
    //     }),
    //     catchError((error) => {
    //       this.#notification.open(message, title, 'error');
    //       throw error;
    //     })
    //   );
  }

  forgotPassword(email: string): Observable<void> {
    const message = marker('API.AUTH.FORGOT_PASSWORD.FAILED.MESSAGE');
    const title = marker('API.AUTH.FORGOT_PASSWORD.FAILED.TITLE');

    return this.#http
      .post<void>(`${this.#apiUrl}/users/forgot-password`, {
        email,
      })
      .pipe(
        tap(() => {
          this.#notification.open(message, title, 'success');
        }),
        catchError((error) => {
          this.#notification.open(message, title, 'error');
          throw error;
        })
      );
  }

  logout(): Observable<void> {
    return this.#http.post<void>(`${this.#apiUrl}/users/logout`, {}).pipe(
      tap(() => {
        this.#localStorage.removeItem('accessToken');
      })
    );
  }
}
