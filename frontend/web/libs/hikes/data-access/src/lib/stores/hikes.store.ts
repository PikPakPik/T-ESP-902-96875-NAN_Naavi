import { inject } from '@angular/core';
import { Hike, HikesQueryParams } from '@web/shared/models/settings';
import {
  addEntity,
  removeEntity,
  setEntities,
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
import { HikesService } from '../services/hikes.service';
import {
  setError,
  setFulfilled,
  setPending,
  withRequestStatus,
} from '@web/shared/util/signal-stores/request-status';

interface HikesPaginationState {
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

interface HikesConfigurationState {
  difficulties: string[];
  status: string[];
  sources: string[];
  seasons: string[];
}

interface UserLocationState {
  latitude: number | null;
  longitude: number | null;
}

export const HikesStore = signalStore(
  { providedIn: 'root' },
  withEntities<Hike>(),
  withState<HikesPaginationState>({
    total: 0,
    page: 1,
    limit: 20,
    totalPages: 0,
  }),
  withState<HikesConfigurationState>({
    difficulties: [],
    status: [],
    sources: [],
    seasons: [],
  }),
  withState<UserLocationState>({
    latitude: null,
    longitude: null,
  }),
  withLogger('Hikes'),
  withDevtools('Hikes'),
  withRequestStatus(),
  withMethods((store, hikesService = inject(HikesService)) => ({
    setPage(page: number): void {
      patchState(store, { page });
    },
    setLimit(limit: number): void {
      patchState(store, { limit });
    },
    async getHikes(queryParams?: HikesQueryParams): Promise<void> {
      patchState(store, setPending());
      try {
        // Construire les params en incluant la position si disponible
        const params: HikesQueryParams = { ...queryParams };

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
          params.radius = params.radius || 50; // 50km par défaut
        }

        const response = await lastValueFrom(hikesService.getHikes(params));

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
          setEntities(response.hikesInstances),
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
    async getHikeById(id: string): Promise<Hike | undefined> {
      patchState(store, setPending());
      try {
        const hike = await lastValueFrom(hikesService.getHikeById(id));
        // Ajouter la randonnée au store si elle n'existe pas déjà
        if (hike && !store.entities().find((h) => h.id === hike.id)) {
          patchState(store, addEntity(hike), setFulfilled());
        } else {
          patchState(store, setFulfilled());
        }
        return hike;
      } catch (error: unknown) {
        patchState(store, setError(error as string));
        return undefined;
      }
    },
    async create(hike: Hike): Promise<void> {
      patchState(store, setPending());
      try {
        const createdHike = await lastValueFrom(hikesService.addHike(hike));
        patchState(store, addEntity(createdHike), setFulfilled());
      } catch (error: unknown) {
        patchState(store, setError(error as string));
      }
    },
    async update(hike: Hike): Promise<void> {
      patchState(store, setPending());
      try {
        const updatedHike = await lastValueFrom(hikesService.updateHike(hike));
        // Remplacer complètement l'entité pour préserver l'instance de classe Hike
        // et ses méthodes (comme getFormattedDuration)
        patchState(
          store,
          removeEntity(updatedHike.id),
          addEntity(updatedHike),
          setFulfilled()
        );
      } catch (error: unknown) {
        patchState(store, setError(error as string));
      }
    },
    async delete(id: string): Promise<void> {
      patchState(store, setPending());
      try {
        await lastValueFrom(hikesService.deleteHike(id));
        patchState(store, removeEntity(id), setFulfilled());
      } catch (error: unknown) {
        patchState(store, setError(error as string));
      }
    },
    async loadConfigurations(): Promise<void> {
      try {
        const config = await lastValueFrom(hikesService.getConfigurations());
        patchState(store, {
          difficulties: config.difficulties,
          status: config.status,
          sources: config.sources,
          seasons: config.seasons,
        });
      } catch (error: unknown) {
        console.error('Failed to load configurations:', error);
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
  })),
  withHooks({
    async onInit(store) {
      try {
        await store.getUserLocation();
        // Ne charger les randonnées que si on a la position
        if (store.latitude() !== null && store.longitude() !== null) {
          await store.getHikes();
        }
        await store.loadConfigurations();
      } catch (error) {
        console.error('Error during HikesStore initialization:', error);
        // Continue initialization even if there are errors
        // This prevents the app from crashing in CI or when APIs are unavailable
      }
    },
  })
);
