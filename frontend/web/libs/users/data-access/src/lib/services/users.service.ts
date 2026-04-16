import { MessageService } from 'primeng/api';
import { API_URL } from '@web/shared/http-client';
import { inject, Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { catchError, map, Observable, throwError, tap } from 'rxjs';
import {
  User,
  IDB_User,
  UsersQueryParams,
  PaginatedUsersResponse,
} from '@web/shared/models/settings';

@Injectable({
  providedIn: 'root',
})
export class UsersService {
  #http = inject(HttpClient);
  #messageService = inject(MessageService);
  #apiUrl = inject(API_URL);

  getUsers(
    queryParams?: UsersQueryParams
  ): Observable<PaginatedUsersResponse & { usersInstances: User[] }> {
    let params = new HttpParams();

    // Valeurs par défaut obligatoires
    const page = queryParams?.page ?? 1;
    const limit = queryParams?.limit ?? 10;

    params = params.set('page', page.toString());
    params = params.set('limit', limit.toString());

    // Paramètres optionnels
    if (queryParams?.query) {
      params = params.set('query', queryParams.query);
    }
    if (queryParams?.orderField) {
      params = params.set('orderField', queryParams.orderField);
    }
    if (queryParams?.order) {
      params = params.set('order', queryParams.order);
    }

    return this.#http
      .get<PaginatedUsersResponse>(
        `${this.#apiUrl}identity/administration/users`,
        { params }
      )
      .pipe(
        map((response) => {
          return {
            ...response,
            usersInstances: response.items
              .filter((user) => user.status !== 'DELETED')
              .map((user) => new User(user)),
          };
        }),
        catchError((error) => {
          this.#messageService.add({
            severity: 'error',
            summary: 'Error',
            detail: 'Failed to get users',
          });
          return throwError(() => error);
        })
      );
  }

  getUserById(id: string): Observable<User> {
    return this.#http
      .get<IDB_User>(`${this.#apiUrl}identity/administration/users/${id}`)
      .pipe(
        map((user) => new User(user)),
        catchError((error) => {
          this.#messageService.add({
            severity: 'error',
            summary: 'Error',
            detail: 'Failed to get user',
          });
          return throwError(() => error);
        })
      );
  }
  addUser(user: User): Observable<User> {
    return this.#http.post<User>(
      `${this.#apiUrl}identity/administration/users`,
      user
    );
  }
  updateUser(user: User): Observable<User> {
    return this.#http.put<User>(
      `${this.#apiUrl}identity/administration/users/${user.id}`,
      user
    );
  }
  deleteUser(id: string): Observable<void> {
    return this.#http.delete<void>(
      `${this.#apiUrl}identity/administration/users/${id}`
    );
  }

  deleteProfilePicture(userId: string): Observable<void> {
    return this.#http.delete<void>(
      `${this.#apiUrl}identity/administration/users/${userId}/profile-picture`
    );
  }
  resetPassword(user: User): Observable<void> {
    return this.#http
      .post<void>(`${this.#apiUrl}identity/forgot-password`, {
        email: user.email,
      })
      .pipe(
        tap(() => {
          this.#messageService.add({
            severity: 'success',
            summary: 'Success',
            detail: `Password reset email sent to ${user.email}`,
          });
        }),
        catchError((error) => {
          this.#messageService.add({
            severity: 'error',
            summary: 'Error',
            detail: 'Failed to send password reset email',
          });
          return throwError(() => error);
        })
      );
  }
}
