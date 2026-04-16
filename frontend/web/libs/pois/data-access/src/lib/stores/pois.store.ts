import { inject } from '@angular/core';
import {
  POI,
  POIConfiguration,
  POIsQueryParams,
  IDB_POI,
} from '@web/shared/models/settings';
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
import { POIsService } from '../services/pois.service';
import {
  setError,
  setFulfilled,
  setPending,
  withRequestStatus,
} from '@web/shared/util/signal-stores/request-status';

interface POIsPaginationState {
  total: number;
  page: number;
  limit: number;
  totalPages: number;
  pendingApprovalCount: number;
  selectedStatus: string | null;
}

export const POIsStore = signalStore(
  { providedIn: 'root' },
  withEntities<POI>(),
  withState<POIsPaginationState>({
    total: 0,
    page: 1,
    limit: 20,
    totalPages: 0,
    pendingApprovalCount: 0,
    selectedStatus: null,
  }),
  withState<POIConfiguration>({
    point_of_interest_categories: [],
    status: [],
    sources: [],
  }),
  withLogger('POIs'),
  withDevtools('POIs'),
  withRequestStatus(),
  withMethods((store, poisService = inject(POIsService)) => ({
    setPage(page: number): void {
      patchState(store, { page });
    },
    setLimit(limit: number): void {
      patchState(store, { limit });
    },
    setSelectedStatus(selectedStatus: string | null): void {
      patchState(store, { selectedStatus });
    },
    async getPOIs(queryParams?: POIsQueryParams): Promise<void> {
      patchState(store, setPending());
      try {
        const params: POIsQueryParams = { ...queryParams };
        if (params.page === undefined) {
          params.page = store.page();
        }
        if (params.limit === undefined) {
          params.limit = store.limit();
        }
        if (params.status === undefined) {
          params.status = store.selectedStatus() ?? undefined;
        }

        const response = await lastValueFrom(poisService.searchPOIs(params));
        const validPOIs = response.poisInstances.filter(
          (poi) => poi.id != null
        );

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
          setEntities(validPOIs),
          {
            total,
            page: currentPage,
            limit,
            totalPages,
            selectedStatus: params.status ?? null,
          },
          setFulfilled()
        );
      } catch (error: unknown) {
        patchState(store, setError(error as string));
      }
    },
    async getPOIById(id: string): Promise<POI | undefined> {
      patchState(store, setPending());
      try {
        const poi = await lastValueFrom(poisService.getPOIById(id));
        // Ajouter le POI au store s'il n'existe pas déjà
        if (poi && !store.entities().find((p) => p.id === poi.id)) {
          patchState(store, addEntity(poi), setFulfilled());
        } else {
          patchState(store, setFulfilled());
        }
        return poi;
      } catch (error: unknown) {
        patchState(store, setError(error as string));
        return undefined;
      }
    },
    async create(poi: POI | Partial<IDB_POI>): Promise<POI | undefined> {
      patchState(store, setPending());
      try {
        const createdPOI = await lastValueFrom(poisService.addPOI(poi));
        patchState(store, addEntity(createdPOI), setFulfilled());
        return createdPOI;
      } catch (error: unknown) {
        patchState(store, setError(error as string));
        return undefined;
      }
    },
    async update(poi: POI | Partial<IDB_POI>): Promise<void> {
      patchState(store, setPending());
      try {
        const updatedPOI = await lastValueFrom(poisService.updatePOI(poi));
        patchState(
          store,
          updateEntity({ id: updatedPOI.id, changes: { ...updatedPOI } }),
          setFulfilled()
        );
      } catch (error: unknown) {
        patchState(store, setError(error as string));
      }
    },
    async delete(id: string): Promise<void> {
      patchState(store, setPending());
      try {
        await lastValueFrom(poisService.deletePOI(id));
        patchState(store, removeEntity(id), setFulfilled());
      } catch (error: unknown) {
        patchState(store, setError(error as string));
      }
    },
    async loadPendingApprovalCount(): Promise<void> {
      try {
        const pendingApprovalCount = await lastValueFrom(
          poisService.getPendingApprovalCount()
        );
        patchState(store, { pendingApprovalCount });
      } catch (error: unknown) {
        console.error('Failed to load pending POI approval count:', error);
      }
    },
    async loadConfigurations(): Promise<void> {
      try {
        const config = await lastValueFrom(poisService.getConfigurations());
        patchState(store, {
          point_of_interest_categories:
            config.point_of_interest_categories || [],
          status: config.status || [],
          sources: config.sources || [],
        });
      } catch (error: unknown) {
        console.error('Failed to load POI configurations:', error);
      }
    },
  })),
  withHooks({
    async onInit(store) {
      try {
        await store.loadConfigurations();
        await store.loadPendingApprovalCount();
        await store.getPOIs();
      } catch (error) {
        console.error('Error during POIsStore initialization:', error);
      }
    },
  })
);
