import { inject } from '@angular/core';
import { User, UsersQueryParams } from '@web/shared/models/settings';
import {
  addEntity,
  removeEntity,
  setEntities,
  updateEntity,
  withEntities,
} from '@ngrx/signals/entities';
import {
  patchState,
  signalStore,
  withHooks,
  withMethods,
  withState,
} from '@ngrx/signals';
import { withLogger } from '@web/shared/util/signal-stores/logger';
import { withDevtools } from '@angular-architects/ngrx-toolkit';
import { lastValueFrom } from 'rxjs';
import { UsersService } from '../services/users.service';
import {
  setError,
  setFulfilled,
  setPending,
  withRequestStatus,
} from '@web/shared/util/signal-stores/request-status';

interface UsersPaginationState {
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export const UsersStore = signalStore(
  { providedIn: 'root' },
  withEntities<User>(),
  withState<UsersPaginationState>({
    total: 0,
    page: 1,
    limit: 10,
    totalPages: 0,
  }),
  withLogger('Users'),
  withDevtools('Users'),
  withRequestStatus(),
  withMethods((store, usersService = inject(UsersService)) => ({
    setPage(page: number): void {
      patchState(store, { page });
    },
    setLimit(limit: number): void {
      patchState(store, { limit });
    },
    async getUsers(queryParams?: UsersQueryParams): Promise<void> {
      patchState(store, setPending());
      try {
        // Construire les params en utilisant la page et le limit du store si non spécifiés
        const params: UsersQueryParams = { ...queryParams };

        // Utiliser la page et le limit du store si non spécifiés dans queryParams
        if (params.page === undefined) {
          params.page = store.page();
        }
        if (params.limit === undefined) {
          params.limit = store.limit();
        }

        const response = await lastValueFrom(usersService.getUsers(params));

        const total = response.totalItems ?? 0;
        const limit = response.limit ?? params.limit ?? store.limit();
        const currentPage = response.currentPage ?? params.page ?? store.page();
        // Calculer totalPages si non fourni par l'API
        const totalPages =
          response.totalPages ?? (total > 0 ? Math.ceil(total / limit) : 0);

        // Vider d'abord toutes les entités existantes pour éviter l'accumulation
        const currentIds = store.ids();
        const removeOps = currentIds.map((id) => removeEntity(id));

        patchState(
          store,
          ...removeOps,
          setEntities(response.usersInstances),
          {
            total,
            page: currentPage,
            limit,
            totalPages,
          },
          setFulfilled()
        );
      } catch (error: unknown) {
        patchState(store, setError(error as string));
      }
    },
    async getUserById(id: string): Promise<User | undefined> {
      patchState(store, setPending());
      try {
        const user = await lastValueFrom(usersService.getUserById(id));
        patchState(store, addEntity(user), setFulfilled());
        return user;
      } catch (error: unknown) {
        patchState(store, setError(error as string));
        return undefined;
      }
    },
    async create(user: User): Promise<void> {
      patchState(store, setPending());
      try {
        const users = await lastValueFrom(usersService.addUser(user));
        patchState(store, addEntity(users), setFulfilled());
      } catch (error: unknown) {
        patchState(store, setError(error as string));
      }
    },
    async update(user: User): Promise<void> {
      patchState(store, setPending());
      try {
        const users = await lastValueFrom(usersService.updateUser(user));
        patchState(
          store,
          updateEntity({ id: users.id, changes: { ...users } }),
          setFulfilled()
        );
      } catch (error: unknown) {
        patchState(store, setError(error as string));
      }
    },
    async delete(id: string): Promise<void> {
      patchState(store, setPending());
      try {
        await lastValueFrom(usersService.deleteUser(id));
        patchState(store, removeEntity(id), setFulfilled());
      } catch (error: unknown) {
        patchState(store, setError(error as string));
      }
    },
    async resetPassword(user: User): Promise<void> {
      patchState(store, setPending());
      try {
        await lastValueFrom(usersService.resetPassword(user));
        patchState(store, setFulfilled());
      } catch (error: unknown) {
        patchState(store, setError(error as string));
      }
    },
  })),
  withHooks({
    onInit() {
      // Ne pas charger automatiquement, laisser le container le faire explicitement
    },
  })
);
