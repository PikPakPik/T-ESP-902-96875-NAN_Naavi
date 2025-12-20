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
}

interface UserLocationState {
  latitude: number | null;
  longitude: number | null;
}

export const POIsStore = signalStore(
  { providedIn: 'root' },
  withEntities<POI>(),
  withState<POIsPaginationState>({
    total: 0,
    page: 1,
    limit: 20,
    totalPages: 0,
  }),
  withState<UserLocationState>({
    latitude: null,
    longitude: null,
  }),
  withState<POIConfiguration>({
    point_of_interest_categories: [],
    status: [],
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
    async getPOIs(queryParams?: POIsQueryParams): Promise<void> {
      patchState(store, setPending());
      try {
        // Construire les params en incluant la position si disponible
        const params: POIsQueryParams = { ...queryParams };

        // Utiliser la page et le limit du store si non spécifiés dans queryParams
        if (params.page === undefined) {
          params.page = store.page();
        }
        if (params.limit === undefined) {
          params.limit = store.limit();
        }

        // Si pas de coordonnées fournies explicitement, utiliser celles du store
        if (!params.latitude && !params.longitude) {
          params.latitude = store.latitude() ?? undefined;
          params.longitude = store.longitude() ?? undefined;
          params.radius = params.radius || 20; // 20km par défaut
        }

        const response = await lastValueFrom(poisService.searchPOIs(params));
        // Filter out any POIs without an id (should not happen, but safety check)
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
    async create(poi: POI | Partial<IDB_POI>): Promise<void> {
      patchState(store, setPending());
      try {
        const createdPOI = await lastValueFrom(poisService.addPOI(poi));
        patchState(store, addEntity(createdPOI), setFulfilled());
      } catch (error: unknown) {
        patchState(store, setError(error as string));
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
    async getUserLocation(): Promise<void> {
      return new Promise((resolve) => {
        // Check if running in a browser environment
        if (typeof navigator === 'undefined' || !navigator.geolocation) {
          console.warn('Geolocation is not supported by this environment.');
          patchState(store, { latitude: null, longitude: null });
          resolve();
          return;
        }

        navigator.geolocation.getCurrentPosition(
          (position) => {
            patchState(store, {
              latitude: position.coords.latitude,
              longitude: position.coords.longitude,
            });
            resolve();
          },
          (error) => {
            console.warn('Unable to retrieve user location:', error.message);
            patchState(store, {
              latitude: null,
              longitude: null,
            });
            resolve();
          },
          {
            timeout: 5000,
            maximumAge: 60000, // Cache la position pendant 1 minute
          }
        );
      });
    },
    setDefaultLocation(latitude: number, longitude: number): void {
      patchState(store, {
        latitude,
        longitude,
      });
    },
    async loadConfigurations(): Promise<void> {
      try {
        const config = await lastValueFrom(poisService.getConfigurations());
        patchState(store, {
          point_of_interest_categories:
            config.point_of_interest_categories || [],
          status: config.status || [],
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
        await store.getUserLocation();
        // Ne charger les POIs que si on a la position
        if (store.latitude() !== null && store.longitude() !== null) {
          await store.getPOIs();
        }
      } catch (error) {
        console.error('Error during POIsStore initialization:', error);
        // Continue initialization even if there are errors
        // This prevents the app from crashing in CI or when APIs are unavailable
      }
    },
  })
);
