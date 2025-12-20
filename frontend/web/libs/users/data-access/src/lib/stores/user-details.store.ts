import { lastValueFrom } from 'rxjs';
import { inject } from '@angular/core';
import { signalStore, withHooks, withMethods, withState } from '@ngrx/signals';
import { patchState } from '@ngrx/signals';
import { User } from '@web/shared/models/settings';
import { UsersService } from '../services/users.service';
import { HikesService } from '@web/hikes/data-access';
import {
  HikeHistoryItem,
  HikeHistoryQueryParams,
} from '@web/shared/models/settings';
import {
  setError,
  setFulfilled,
  setPending,
  withRequestStatus,
} from '@web/shared/util/signal-stores/request-status';
import { withLogger } from '@web/shared/util/signal-stores/logger';
import { withDevtools } from '@angular-architects/ngrx-toolkit';
import { withRouteParams } from '@web/shared/util/signal-stores/route-params';
import { ParamsConfigClass } from '@web/shared/util/signal-stores';

interface UserDetailsState {
  user: User | null;
  history: HikeHistoryItem[];
  totalItems: number;
  totalPages: number;
  currentPage: number;
  nextPage: number | null;
  previousPage: number | null;
  limit: number;
}

export const UserDetailsStore = signalStore(
  withRouteParams({
    id: (param) => ParamsConfigClass.asString(param),
  }),
  withLogger('UserDetails'),
  withDevtools('UserDetails'),
  withRequestStatus(),
  withState<UserDetailsState>({
    user: null,
    history: [],
    totalItems: 0,
    totalPages: 0,
    currentPage: 1,
    nextPage: null,
    previousPage: null,
    limit: 20,
  }),
  withMethods(
    (
      store,
      usersService = inject(UsersService),
      hikesService = inject(HikesService)
    ) => ({
      setPage(page: number): void {
        patchState(store, { currentPage: page });
      },
      setLimit(limit: number): void {
        patchState(store, { limit });
      },
      async loadUser(id: string): Promise<void> {
        patchState(store, setPending());
        try {
          const loadedUser = await lastValueFrom(usersService.getUserById(id));
          patchState(store, { user: loadedUser }, setFulfilled());
        } catch (error: unknown) {
          patchState(store, setError(error as string));
        }
      },
      async loadHistory(
        userId: string,
        params?: HikeHistoryQueryParams
      ): Promise<void> {
        patchState(store, setPending());
        try {
          const historyHikesResponse = await lastValueFrom(
            hikesService.getUserHikeHistory(userId, {
              ...(params ?? {}),
              page: store.currentPage(),
              limit: store.limit(),
            })
          );
          patchState(
            store,
            {
              history: historyHikesResponse.items,
              totalItems: historyHikesResponse.totalItems,
              totalPages: historyHikesResponse.totalPages,
              nextPage: historyHikesResponse.nextPage,
              previousPage: historyHikesResponse.previousPage,
            },
            setFulfilled()
          );
        } catch (error: unknown) {
          patchState(store, setError(error as string));
        }
      },
    })
  ),
  withHooks({
    async onInit(store) {
      const userId = store.id();
      if (!userId) {
        return;
      }
      await store.loadUser(userId);
      await store.loadHistory(userId);
    },
  })
);
