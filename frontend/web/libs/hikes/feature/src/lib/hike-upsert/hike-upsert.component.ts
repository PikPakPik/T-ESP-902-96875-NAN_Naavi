import { Component, inject, signal, effect, computed } from '@angular/core';

import { form, Field, required } from '@angular/forms/signals';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { InputTextModule } from 'primeng/inputtext';
import { TextareaModule } from 'primeng/textarea';
import { CardModule } from 'primeng/card';
import { SelectModule } from 'primeng/select';
import { MultiSelectModule } from 'primeng/multiselect';
import { InputNumberModule } from 'primeng/inputnumber';
import { ToastModule } from 'primeng/toast';
import { MessageService } from 'primeng/api';
import {
  MapComponent,
  LayerComponent,
  GeoJSONSourceComponent,
  MarkerComponent,
} from 'ngx-mapbox-gl';
import {
  HikesStore,
  HikeDetailStore,
  getDifficultyTranslationKey,
  getStatusTranslationKey,
  getSourceTranslationKey,
  getSeasonTranslationKey,
} from '@web/hikes/data-access';
import { Coordinate, Hike } from '@web/shared/models/settings';
import { PanelModule } from 'primeng/panel';
import { lineString } from '@turf/helpers';
import length from '@turf/length';
import { MapboxService } from '@web/shared/util';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { DragDropModule, CdkDragDrop } from '@angular/cdk/drag-drop';
import { LngLat, type Marker } from 'mapbox-gl';
import { TooltipModule } from 'primeng/tooltip';

  // Form data model
  interface HikeFormData {
    name: string;
    location: string;
    difficulty: string;
    status: string;
    source: string;
    seasons: string[];
  }
@Component({
  selector: 'hike-upsert',
  standalone: true,
  imports: [
    Field,
    FormsModule,
    ButtonModule,
    InputTextModule,
    TextareaModule,
    CardModule,
    SelectModule,
    MultiSelectModule,
    InputNumberModule,
    ToastModule,
    MapComponent,
    LayerComponent,
    GeoJSONSourceComponent,
    MarkerComponent,
    PanelModule,
    TranslateModule,
    DragDropModule,
    TooltipModule
],
  providers: [MessageService, HikeDetailStore],
  templateUrl: './hike-upsert.component.html',
  styleUrl: './hike-upsert.component.scss',
})
export class HikeUpsertComponent {
  #router = inject(Router);
  #mapboxService = inject(MapboxService);
  #hikesStore = inject(HikesStore);
  #hikeDetailStore = inject(HikeDetailStore);
  #messageService = inject(MessageService);
  #translateService = inject(TranslateService);

  // Constants
  readonly MAX_WAYPOINTS = 25; // Limite de l'API Mapbox Directions

  // Form data - signals séparés pour compatibilité avec PrimeNG ngModel
  name = signal('');
  location = signal('');
  difficulty = signal('');
  status = signal('DRAFT');
  source = signal('');
  seasons = signal<string[]>([]);

  // Modèle Signal Forms pour la validation
  hikeFormModel = signal<HikeFormData>({
    name: '',
    location: '',
    difficulty: '',
    status: 'DRAFT',
    source: '',
    seasons: [],
  });

  hikeForm = form(this.hikeFormModel, (schemaPath) => {
    required(schemaPath.name, { message: this.#translateService.instant('HIKE.UPSERT.NAME_REQUIRED') });
    required(schemaPath.difficulty, { message: this.#translateService.instant('HIKE.DIFFICULTY_REQUIRED') });
    required(schemaPath.status, { message: this.#translateService.instant('HIKE.UPSERT.STATUS_REQUIRED') });
  });

  constructor() {
    // Synchroniser les signals avec le modèle Signal Forms
    effect(() => {
      this.hikeFormModel.update((model) => ({
        ...model,
        name: this.name(),
        location: this.location(),
        difficulty: this.difficulty(),
        status: this.status(),
        source: this.source(),
        seasons: this.seasons(),
      }));
    });

    // The store automatically loads the hike via onInit hook when id is in route params
    effect(() => {
      const hike = this.#hikeDetailStore.hike();
      if (hike && hike.id !== this.hikeId()) {
        this.loadHikeForEdit(hike);
      }
    });
  }


  // Données non-formulaires (calculées ou gérées séparément)
  distance = signal(0);
  elevationGain = signal(0); // dénivelé positif en mètres
  elevationLoss = signal(0); // dénivelé négatif en mètres
  coordinates = signal<Coordinate[]>([]);
  waypoints = signal<Coordinate[]>([]); // Points cliqués par l'utilisateur
  isEditMode = signal(false);
  hikeId = signal<string | null>(null);
  createdAt = signal<Date | null>(null); // Date de création pour préserver lors de l'update
  isLoadingRoute = signal(false);
  submitted = signal(false);

  // Computed pour savoir si on peut ajouter des waypoints
  canAddWaypoint = computed(() => this.waypoints().length < this.MAX_WAYPOINTS);

  // Configuration options from store
  difficulties = computed(() => {
    const difficulties = this.#hikesStore.difficulties();
    return difficulties.map((difficulty) => ({
      label: getDifficultyTranslationKey(difficulty),
      value: difficulty,
    }));
  });

  statusOptions = computed(() => {
    const statuses = this.#hikesStore.status();
    return statuses.map((status) => ({
      label: getStatusTranslationKey(status),
      value: status,
    }));
  });

  sourceOptions = computed(() => {
    const sources = this.#hikesStore.sources();
    return sources.map((source) => ({
      label: getSourceTranslationKey(source),
      value: source,
    }));
  });

  seasonOptions = computed(() => {
    const seasons = this.#hikesStore.seasons();
    return seasons.map((season) => ({
      label: getSeasonTranslationKey(season),
      value: season,
    }));
  });

  // Méthode helper pour traduire une saison (utilisée dans le template)
  getSeasonTranslationKey(season: string): string {
    return getSeasonTranslationKey(season);
  }

  // Map configuration
  mapStyle = 'mapbox://styles/mapbox/outdoors-v12';
  mapCenter = computed<[number, number]>(() => {
    // Utiliser le premier waypoint comme point de départ
    const waypoints = this.waypoints();
    if (waypoints.length > 0) {
      return [waypoints[0].longitude, waypoints[0].latitude];
    }

    // Sinon utiliser la première coordonnée de la route
    const coords = this.coordinates();
    if (coords.length > 0) {
      return [coords[0].longitude, coords[0].latitude];
    }

    return [6.8652, 45.8326]; // Default: Mont Blanc
  });
  mapZoom = 10;


  async loadHikeForEdit(hike: Hike) {
    try {
      if (hike) {
        this.isEditMode.set(true);
        this.hikeId.set(hike.id);
        this.name.set(hike.name);
        this.location.set(hike.location || '');
        this.difficulty.set(hike.difficulty);
        this.status.set(hike.status || 'DRAFT');
        this.source.set(hike.source || '');
        this.seasons.set(hike.seasons || []);
        this.distance.set(hike.distance);
        this.elevationGain.set(hike.elevationGain || 0);
        this.elevationLoss.set(hike.elevationLoss || 0);
        // Préserver la date de création
        this.createdAt.set(hike.createdAt || new Date());
        // En mode édition, considérer les coordonnées existantes comme la route calculée
        this.coordinates.set([...hike.coordinates]);
        // Restaurer les waypoints cliqués par l'utilisateur (max 25)
        this.waypoints.set([...hike.waypoints]);
        // Si distance absente ou nulle, recalculer depuis la trace
        if (!hike.distance || hike.distance <= 0) {
          this.recalculateDistance();
        }
        // Si dénivelé absent ou élévations manquantes, recalculer depuis l'API
        const needsElevationRecalculation =
          !hike.elevationGain ||
          hike.elevationGain <= 0 ||
          !hike.startingElevation ||
          hike.startingElevation <= 0 ||
          !hike.arrivalElevation ||
          hike.arrivalElevation <= 0 ||
          hike.coordinates.some((c) => !c.elevation || c.elevation === 0);

        if (needsElevationRecalculation && hike.coordinates.length > 0) {
          try {
            // Récupérer les élévations depuis l'API Mapbox Terrain-RGB
            const elevations =
              await this.#mapboxService.getElevationsForCoordinates(
                hike.coordinates
              );
            this.coordinates.set(elevations);
            this.recalculateElevation();
          } catch (elevationError) {
            console.warn(
              'Erreur lors de la récupération des élévations:',
              elevationError
            );
            // Continuer sans élévations si l'API échoue
            this.recalculateElevation();
          }
        } else {
          // Recalculer le dénivelé depuis les coordonnées existantes
          this.recalculateElevation();
        }
      }
    } catch (error) {
      console.error('Error loading hike:', error);
      this.#messageService.add({
        severity: 'error',
        summary: this.#translateService.instant('COMMON.ERROR'),
        detail: this.#translateService.instant('HIKE.ERROR.LOAD_FAILED'),
      });
    }
  }

  onMapClick(event: unknown) {
    // Vérifier la limite de waypoints
    if (this.waypoints().length >= this.MAX_WAYPOINTS) {
      this.#messageService.add({
        severity: 'warn',
        summary: this.#translateService.instant('COMMON.WARNING'),
        detail: this.#translateService.instant('HIKE.UPSERT.WAYPOINT_LIMIT', {
          maxPoints: this.MAX_WAYPOINTS,
        }),
        life: 5000,
      });
      return;
    }

    const mapEvent = event as { lngLat: { lat: number; lng: number } };
    const lngLat = mapEvent.lngLat;
    this.addCoordinate(lngLat.lat, lngLat.lng);
  }

  async addCoordinate(lat: number, lng: number) {
    // Vérifier la limite avant d'ajouter
    if (this.waypoints().length >= this.MAX_WAYPOINTS) {
      this.#messageService.add({
        severity: 'warn',
        summary: this.#translateService.instant('COMMON.WARNING'),
        detail: this.#translateService.instant('HIKE.UPSERT.WAYPOINT_LIMIT', {
          maxPoints: this.MAX_WAYPOINTS,
        }),
        life: 5000,
      });
      return;
    }

    const newCoords: Coordinate = { latitude: lat, longitude: lng };

    // Ajouter le waypoint
    this.waypoints.update((waypoints) => [...waypoints, newCoords]);

    // Si on a plus d'un waypoint, calculer la route entre tous
    const waypoints = this.waypoints();
    if (waypoints.length >= 2) {
      await this.calculateRouteBetweenPoints();
    } else {
      // Si un seul point, l'afficher directement
      this.coordinates.set([newCoords]);
      this.recalculateDistance();
      this.recalculateElevation();
    }

    this.#messageService.add({
      severity: 'success',
      summary: 'Point ajouté',
      detail: `Point ajouté: ${lat.toFixed(5)}, ${lng.toFixed(5)}`,
    });
  }

  async calculateRouteBetweenPoints() {
    const waypoints = this.waypoints();
    if (waypoints.length < 2) return;

    this.isLoadingRoute.set(true);

    try {
      const data = await this.#mapboxService.getDirectionsRoute(
        waypoints,
        'walking'
      );

      if (data.code === 'Ok' && data.routes && data.routes.length > 0) {
        // Mettre à jour les coordonnées avec la route calculée
        const routeCoordinates = data.routes[0].geometry.coordinates;
        let updatedCoords: Coordinate[] = routeCoordinates.map(
          (coord: [number, number, number?]) => ({
            latitude: coord[1],
            longitude: coord[0],
            elevation: coord[2] !== undefined ? coord[2] : undefined,
          })
        );

        // Récupérer les élévations depuis l'API Mapbox Terrain-RGB
        // car annotations=elevation nécessite un token premium
        try {
          const elevations =
            await this.#mapboxService.getElevationsForCoordinates(
              updatedCoords
            );
          // Mettre à jour les coordonnées avec les élévations réelles
          updatedCoords = elevations;
        } catch (elevationError) {
          console.warn(
            'Erreur lors de la récupération des élévations:',
            elevationError
          );
          // Continuer sans élévations si l'API échoue
        }

        this.coordinates.set(updatedCoords);
        this.recalculateDistance();
        // Recalculer le dénivelé depuis les coordonnées avec élévation
        this.recalculateElevation();
      }
    } catch (error) {
      console.error('Erreur lors du calcul de la route:', error);
      // En cas d'erreur, garder les points originaux
      this.coordinates.set(waypoints);
      this.recalculateDistance();
      this.recalculateElevation();
    } finally {
      this.isLoadingRoute.set(false);
    }
  }

  async removeCoordinate(index: number) {
    this.waypoints.update((waypoints) =>
      waypoints.filter((_, i) => i !== index)
    );

    const waypoints = this.waypoints();
    if (waypoints.length >= 2) {
      await this.calculateRouteBetweenPoints();
    } else if (waypoints.length === 1) {
      this.coordinates.set(waypoints);
      this.recalculateDistance();
      this.recalculateElevation();
    } else {
      this.coordinates.set([]);
      this.recalculateDistance();
      this.elevationGain.set(0);
      this.elevationLoss.set(0);
    }

    this.#messageService.add({
      severity: 'info',
      summary: this.#translateService.instant('COMMON.SUCCESS'),
      detail: this.#translateService.instant('HIKE.WAYPOINT.REMOVED'),
    });
  }

  async dropWaypoint(event: CdkDragDrop<Coordinate[]>) {
    if (event.previousIndex === event.currentIndex) {
      return; // Pas de changement
    }

    this.waypoints.update((waypoints) => {
      const newWaypoints = [...waypoints];
      const movedItem = newWaypoints[event.previousIndex];
      newWaypoints.splice(event.previousIndex, 1);
      newWaypoints.splice(event.currentIndex, 0, movedItem);
      return newWaypoints;
    });

    const waypoints = this.waypoints();
    if (waypoints.length >= 2) {
      await this.calculateRouteBetweenPoints();
    } else {
      this.coordinates.set(waypoints);
      this.recalculateDistance();
      this.recalculateElevation();
    }

    this.#messageService.add({
      severity: 'success',
      summary: this.#translateService.instant('COMMON.SUCCESS'),
      detail: this.#translateService.instant('HIKE.WAYPOINT.ORDER_CHANGED'),
      life: 2000,
    });
  }

  async onMarkerDragEnd(marker: Marker, index: number) {
    const lngLat = marker.getLngLat() as LngLat;
    const newCoordinate: Coordinate = {
      latitude: lngLat.lat,
      longitude: lngLat.lng,
    };

    // Mettre à jour le waypoint à l'index spécifié
    this.waypoints.update((waypoints) => {
      const newWaypoints = [...waypoints];
      newWaypoints[index] = newCoordinate;
      return newWaypoints;
    });

    // Recalculer la route si on a au moins 2 waypoints
    const waypoints = this.waypoints();
    if (waypoints.length >= 2) {
      await this.calculateRouteBetweenPoints();
    } else {
      this.coordinates.set(waypoints);
      this.recalculateDistance();
      this.recalculateElevation();
    }

    this.#messageService.add({
      severity: 'success',
      summary: this.#translateService.instant('COMMON.SUCCESS'),
      detail: this.#translateService.instant('HIKE.WAYPOINT.MOVED', {
        index: index + 1,
      }),
      life: 2000,
    });
  }

  clearCoordinates() {
    this.waypoints.set([]);
    this.coordinates.set([]);
    this.recalculateDistance();
    this.elevationGain.set(0);
    this.elevationLoss.set(0);
    this.#messageService.add({
      severity: 'info',
      summary: this.#translateService.instant('COMMON.SUCCESS'),
      detail: this.#translateService.instant('HIKE.TRACK.CLEARED'),
    });
  }

  // updateMapCenter() n'est plus nécessaire car mapCenter est maintenant un computed
  // qui se met à jour automatiquement quand les coordonnées ou waypoints changent

  coordinatesToGeoJSON(): GeoJSON.Feature {
    const coords = this.coordinates();
    if (coords.length === 0) {
      const center: [number, number] = this.mapCenter();
      return {
        type: 'Feature',
        properties: {},
        geometry: {
          type: 'Point',
          coordinates: center,
        },
      };
    }
    if (coords.length === 1) {
      return {
        type: 'Feature',
        properties: {},
        geometry: {
          type: 'Point',
          coordinates: [coords[0].longitude, coords[0].latitude],
        },
      };
    }
    return {
      type: 'Feature',
      properties: {},
      geometry: {
        type: 'LineString',
        coordinates: coords.map((c) => [c.longitude, c.latitude]),
      },
    };
  }

  getMapBounds() {
    const coords = this.coordinates();
    if (coords.length === 0) return undefined;
    if (coords.length === 1) {
      const c = coords[0];
      return [
        [c.longitude - 0.01, c.latitude - 0.01],
        [c.longitude + 0.01, c.latitude + 0.01],
      ] as [number, number][];
    }
    const lngs = coords.map((c) => c.longitude);
    const lats = coords.map((c) => c.latitude);
    return [
      [Math.min(...lngs), Math.min(...lats)],
      [Math.max(...lngs), Math.max(...lats)],
    ] as [number, number][];
  }

  private recalculateDistance() {
    const coords = this.coordinates();
    if (coords.length < 2) {
      this.distance.set(0);
      return;
    }
    const line = lineString(coords.map((c) => [c.longitude, c.latitude]));
    const km = length(line, { units: 'kilometers' });
    this.distance.set(Number(km.toFixed(2)));
  }

  private recalculateElevation() {
    const coords = this.coordinates();
    if (coords.length < 2) {
      this.elevationGain.set(0);
      this.elevationLoss.set(0);
      return;
    }

    let gain = 0;
    let loss = 0;

    for (let i = 1; i < coords.length; i++) {
      const prevElevation = coords[i - 1].elevation || 0;
      const currentElevation = coords[i].elevation || 0;

      const diff = currentElevation - prevElevation;

      if (diff > 0) {
        gain += diff;
      } else {
        loss += Math.abs(diff);
      }
    }

    this.elevationGain.set(Math.round(gain));
    this.elevationLoss.set(Math.round(loss));
  }


  async saveHike() {
    this.submitted.set(true);

    // Mettre à jour le modèle Signal Forms avec les valeurs actuelles
    this.hikeFormModel.set({
      name: this.name(),
      location: this.location(),
      difficulty: this.difficulty(),
      status: this.status(),
      source: this.source(),
      seasons: this.seasons(),
    });

    const nameField = this.hikeForm.name();
    const difficultyField = this.hikeForm.difficulty();
    const statusField = this.hikeForm.status();

    if (!nameField.valid() || !difficultyField.valid() || !statusField.valid()) {
      return;
    }

    const hikeData = {
      id: this.hikeId() || Date.now().toString(),
      name: this.name(),
      difficulty: this.difficulty(),
      status: this.status(),
      source: this.source() || undefined,
      seasons: this.seasons().length > 0 ? this.seasons() : undefined,
      distance: this.distance(),
      coordinates: this.coordinates(),
      waypoints: this.waypoints(),
      elevationGain: this.elevationGain(),
      elevationLoss: this.elevationLoss(),
      estimatedDuration: 0,
      createdAt: this.isEditMode() ? new Date() : new Date(),
      updatedAt: new Date(),
    } as Partial<Hike>;

    try {
      if (this.isEditMode()) {
        const hikeId = this.hikeId();
        if (!hikeId) {
          throw new Error('Hike ID is required for update');
        }
        const updatedHike = {
          ...hikeData,
          id: hikeId,
          createdAt: this.createdAt() || new Date(),
        } as Hike;
        await this.#hikesStore.update(updatedHike);
        this.#messageService.add({
          severity: 'success',
          summary: this.#translateService.instant('COMMON.SUCCESS'),
          detail: this.#translateService.instant('HIKE.SUCCESS.UPDATED'),
        });
      } else {
        // Create new hike
        await this.#hikesStore.create(hikeData as Hike);
        this.#messageService.add({
          severity: 'success',
          summary: this.#translateService.instant('COMMON.SUCCESS'),
          detail: this.#translateService.instant('HIKE.SUCCESS.CREATED'),
        });
      }

      this.#router.navigate(['/backoffice/hikes']);
    } catch (error) {
      console.error('Error saving hike:', error);
      this.#messageService.add({
        severity: 'error',
        summary: this.#translateService.instant('COMMON.ERROR'),
        detail: this.#translateService.instant('HIKE.ERROR.SAVE_FAILED'),
      });
    }
  }

  cancel() {
    this.#router.navigate(['/backoffice/hikes']);
  }
}
