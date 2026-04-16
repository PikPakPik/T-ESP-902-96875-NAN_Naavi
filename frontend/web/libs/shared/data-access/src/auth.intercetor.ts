import {
  HttpEvent,
  HttpHandlerFn,
  HttpRequest,
  HttpErrorResponse,
  HttpClient,
} from '@angular/common/http';
import { inject } from '@angular/core';
import { Observable, throwError, catchError, switchMap, map } from 'rxjs';
import {
  ACCESS_TOKEN_COOKIE,
  REFRESH_TOKEN_COOKIE,
  getCookie,
  setCookie,
} from '@web/shared/util';
import { API_URL } from '@web/shared/http-client';

export function authInterceptor(
  req: HttpRequest<unknown>,
  next: HttpHandlerFn
): Observable<HttpEvent<unknown>> {
  const http = inject(HttpClient);
  const apiUrl = inject(API_URL);

  const accessToken = getCookie(ACCESS_TOKEN_COOKIE);
  const isAuthOrRefresh =
    req.url.includes('/identity/login') ||
    req.url.includes('/identity/refresh');

  const authorizedRequest =
    accessToken && !isAuthOrRefresh
      ? req.clone({
          setHeaders: {
            Authorization: `Bearer ${accessToken}`,
          },
        })
      : req;

  return next(authorizedRequest).pipe(
    catchError((error: HttpErrorResponse) => {
      if (error.status === 401) {
        if (isAuthOrRefresh) {
          return throwError(() => error);
        }
        // FormData/Blob body cannot be replayed on retry - skip refresh+retry
        const body = req.body;
        if (
          body instanceof FormData ||
          body instanceof Blob ||
          (typeof File !== 'undefined' && body instanceof File)
        ) {
          return throwError(() => error);
        }

        const refreshToken = getCookie(REFRESH_TOKEN_COOKIE);
        if (!refreshToken) {
          setCookie(ACCESS_TOKEN_COOKIE, '', { path: '/', maxAgeSeconds: 0 });
          setCookie(REFRESH_TOKEN_COOKIE, '', { path: '/', maxAgeSeconds: 0 });
          return throwError(() => error);
        }

        return http
          .post<{ accessToken: string; refreshToken: string }>(
            `${apiUrl}identity/refresh`,
            {},
            { headers: { Authorization: `Bearer ${refreshToken}` } }
          )
          .pipe(
            map((tokens) => {
              if (tokens?.accessToken) {
                setCookie(ACCESS_TOKEN_COOKIE, tokens.accessToken, {
                  path: '/',
                  sameSite: 'Lax',
                  secure: true,
                });
              }
              if (tokens?.refreshToken) {
                setCookie(REFRESH_TOKEN_COOKIE, tokens.refreshToken, {
                  path: '/',
                  sameSite: 'Lax',
                  secure: true,
                });
              }
              return true;
            }),
            switchMap(() => {
              const newAccessToken = getCookie(ACCESS_TOKEN_COOKIE);
              const retried = newAccessToken
                ? authorizedRequest.clone({
                    setHeaders: {
                      Authorization: `Bearer ${newAccessToken}`,
                    },
                  })
                : authorizedRequest;
              return next(retried);
            }),
            catchError((refreshError) => {
              setCookie(ACCESS_TOKEN_COOKIE, '', {
                path: '/',
                maxAgeSeconds: 0,
              });
              setCookie(REFRESH_TOKEN_COOKIE, '', {
                path: '/',
                maxAgeSeconds: 0,
              });
              return throwError(() => refreshError);
            })
          );
      }
      return throwError(() => error);
    })
  );
}
