import { withDevtools } from '@angular-architects/ngrx-toolkit';
import { User } from '@web/shared/models/settings';
import { patchState, signalStore, withMethods, withState } from '@ngrx/signals';
import { withLogger } from '@web/shared/util/signal-stores/logger';
import {
  setError,
  setFulfilled,
  setPending,
  withRequestStatus,
} from '@web/shared/util/signal-stores/request-status';
import { AuthService } from './services/auth.service';
import { lastValueFrom } from 'rxjs';
import { inject } from '@angular/core';

export interface AuthSignalState {
  user: User | null;
}

export const initialState: AuthSignalState = {
  user: null,
};

export const AuthStore = signalStore(
  { providedIn: 'root' },
  withState(initialState),
  withRequestStatus(),
  withLogger('Auth'),
  withDevtools('Auth'),
  withMethods((store, authService = inject(AuthService)) => ({
    async getUser(): Promise<void> {
      patchState(store, setPending());
      try {
        const user = await lastValueFrom(authService.user());
        patchState(store, { user }, setFulfilled());
      } catch (error: unknown) {
        patchState(store, setError(error as string));
      }
    },

    async login(email: string, password: string): Promise<void> {
      patchState(store, setPending());
      try {
        const { user } = await lastValueFrom(
          authService.login(email, password)
        );
        patchState(store, { user }, setFulfilled());
      } catch (error: unknown) {
        patchState(store, setError(error as string));
      }
    },

    async forgotPassword(email: string): Promise<void> {
      patchState(store, setPending());
      try {
        await lastValueFrom(authService.forgotPassword(email));
        patchState(store, setFulfilled());
      } catch (error: unknown) {
        patchState(store, setError(error as string));
      }
    },

    async logout(): Promise<void> {
      patchState(store, setPending());
      try {
        await lastValueFrom(authService.logout());
        patchState(store, { user: null }, setFulfilled());
      } catch (error: unknown) {
        patchState(store, setError(error as string));
      }
    },
  }))
);
