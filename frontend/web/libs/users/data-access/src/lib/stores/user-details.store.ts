import { lastValueFrom } from 'rxjs';
import { inject } from '@angular/core';
import { signalStore, withHooks, withMethods, withState } from '@ngrx/signals';
import { patchState } from '@ngrx/signals';
import { MessageService } from 'primeng/api';
import { TranslateService } from '@ngx-translate/core';
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
      hikesService = inject(HikesService),
      messageService = inject(MessageService),
      translateService = inject(TranslateService)
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
      async deleteProfilePicture(userId: string): Promise<void> {
        try {
          await lastValueFrom(usersService.deleteProfilePicture(userId));
          const updatedUser = await lastValueFrom(usersService.getUserById(userId));
          patchState(store, { user: updatedUser }, setFulfilled());
          messageService.add({
            severity: 'success',
            summary: translateService.instant('COMMON.SUCCESS'),
            detail: translateService.instant('USER.SUCCESS.PROFILE_PICTURE_DELETED'),
          });
        } catch (error: unknown) {
          patchState(store, setError(error as string));
          messageService.add({
            severity: 'error',
            summary: translateService.instant('COMMON.ERROR'),
            detail: translateService.instant('USER.ERROR.DELETE_PROFILE_PICTURE_FAILED'),
          });
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
