import { withDevtools } from '@angular-architects/ngrx-toolkit';
import { User } from '@web/shared/models/settings';
import {
  patchState,
  signalStore,
  withMethods,
  withState,
} from '@ngrx/signals';
import { withLogger } from '@web/shared/util/signal-stores/logger';
import {
  setError,
  setFulfilled,
  setPending,
  withRequestStatus,
} from '@web/shared/util/signal-stores/request-status';
import { AuthService } from './services/auth.service';
import { lastValueFrom } from 'rxjs';
import {
  ACCESS_TOKEN_COOKIE,
  REFRESH_TOKEN_COOKIE,
  deleteCookie,
  setCookie,
} from '@web/shared/util';
import { inject } from '@angular/core';
import { HttpErrorResponse } from '@angular/common/http';
import { TranslateService } from '@ngx-translate/core';

const defaultUser: User = {
  id: '',
  fullName: '',
  email: '',
  firstname: '',
  lastname: '',
  profilePicture: null,
  roles: [],
  status: 'UNVERIFIED',
};
export interface AuthSignalState {
  user: User;
}

export const initialState: AuthSignalState = {
  user: defaultUser,
};

const ERROR_STATUS_MAP: Record<number, string> = {
  400: 'AUTH.LOGIN.ERROR.INVALID_CREDENTIALS',
  401: 'AUTH.LOGIN.ERROR.UNAUTHORIZED',
  403: 'AUTH.LOGIN.ERROR.FORBIDDEN',
};
function translate(
  key: string,
  fallback: string,
  translateService?: TranslateService
): string {
  return translateService?.instant(key) || fallback;
}

function extractHttpErrorMessage(error: HttpErrorResponse): string | null {
  if (!error.error) {
    return null;
  }

  if (typeof error.error === 'string') {
    return error.error;
  }

  return error.error.message || error.error.error || null;
}

function getErrorMessage(
  error: unknown,
  translateService?: TranslateService
): string {
  // Gestion des erreurs HTTP
  if (error instanceof HttpErrorResponse) {
    // Extraire le message depuis la réponse HTTP si disponible
    const extractedMessage = extractHttpErrorMessage(error);
    if (extractedMessage) {
      return extractedMessage;
    }

    // Utiliser le message traduit selon le code de statut
    const translationKey = ERROR_STATUS_MAP[error.status];
    if (translationKey) {
      const fallbackMessage =
        translateService?.instant('AUTH.LOGIN.ERROR.GENERIC') ??
        'An error occurred';
      return translate(translationKey, fallbackMessage, translateService);
    }

    // Message générique pour les autres codes d'erreur
    return translate(
      'AUTH.LOGIN.ERROR.GENERIC',
      error.message || 'Une erreur est survenue',
      translateService
    );
  }

  // Gestion des erreurs Error standard
  if (error instanceof Error) {
    return error.message;
  }

  // Fallback pour les autres types d'erreurs
  return translate(
    'AUTH.LOGIN.ERROR.GENERIC',
    String(error) || 'Une erreur est survenue',
    translateService
  );
}

export const AuthStore = signalStore(
  { providedIn: 'root' },
  withState(initialState),
  withRequestStatus(),
  withLogger('Auth'),
  withDevtools('Auth'),
  withMethods(
    (
      store,
      authService = inject(AuthService),
      translateService = inject(TranslateService)
    ) => ({
      async currentUser(): Promise<void> {
        patchState(store, setPending());
        try {
          const user = await lastValueFrom(authService.currentUser());
          patchState(store, { user }, setFulfilled());
        } catch (error: unknown) {
          // Clear user on error and set error state
          patchState(
            store,
            { user: defaultUser },
            setError(getErrorMessage(error, translateService))
          );
          throw error; // Re-throw to let the guard handle it
        }
      },
      async login(
        email: string,
        password: string,
        token: string
      ): Promise<void> {
        patchState(store, setPending());
        try {
          const tokens = await lastValueFrom(
            authService.login(email, password, token)
          );
          setCookie(ACCESS_TOKEN_COOKIE, tokens.accessToken, {
            path: '/',
            sameSite: 'Lax',
            secure: true,
          });
          setCookie(REFRESH_TOKEN_COOKIE, tokens.refreshToken, {
            path: '/',
            sameSite: 'Lax',
            secure: true,
          });
          const user = await lastValueFrom(authService.currentUser());
          patchState(store, { user }, setFulfilled());
        } catch (error: unknown) {
          patchState(store, setError(getErrorMessage(error, translateService)));
        }
      },

      async forgotPassword(email: string): Promise<void> {
        patchState(store, setPending());
        try {
          await lastValueFrom(authService.forgotPassword(email));
          patchState(store, setFulfilled());
        } catch (error: unknown) {
          patchState(store, setError(getErrorMessage(error, translateService)));
        }
      },

      async logout(): Promise<void> {
        patchState(store, setPending());
        try {
          await lastValueFrom(authService.logout());
        } catch (error: unknown) {
          patchState(store, setError(getErrorMessage(error, translateService)));
          // Continue: best-effort logout even if API fails (e.g. session already invalid)
        } finally {
          deleteCookie(ACCESS_TOKEN_COOKIE, { path: '/' });
          deleteCookie(REFRESH_TOKEN_COOKIE, { path: '/' });
          patchState(store, { user: defaultUser }, setFulfilled());
        }
      },

      clearError(): void {
        patchState(store, setFulfilled());
      },
    })
  ),
);
