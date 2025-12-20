import {
  Component,
  input,
  signal,
  OnDestroy,
  ViewChild,
  ChangeDetectionStrategy,
  effect,
} from '@angular/core';

import {
  MapComponent,
  LayerComponent,
  GeoJSONSourceComponent,
} from 'ngx-mapbox-gl';
import type { Map as MapboxMap } from 'mapbox-gl';

export interface HikeCoordinate {
  latitude: number;
  longitude: number;
  elevation?: number;
}

// Configuration de l'animation des pointillés
const ANIMATION_CONFIG = {
  DASH_LENGTH: 0.8, // Longueur des tirets (en unités de ligne)
  BASE_GAP: 6, // Espacement de base entre les tirets
  SPEED: 1.5, // Vitesse de déplacement (unités par seconde)
};

@Component({
  selector: 'hike-map',
  standalone: true,
  imports: [MapComponent, LayerComponent, GeoJSONSourceComponent],
  templateUrl: './hike-map.component.html',
  styleUrls: ['./hike-map.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class HikeMapComponent implements OnDestroy {
  coordinates = input.required<HikeCoordinate[]>();
  hikeId = input.required<string>();
  showAnimation = input<boolean>(true);

  private mapInstance: MapboxMap | null = null;
  private animationFrame: number | null = null;
  private animationTime = 0; // Temps continu en secondes
  dashOffset = signal<number>(0);

  @ViewChild('map') mapComponent?: MapComponent;

  constructor() {
    // Démarrer l'animation quand le composant est initialisé et showAnimation est true
    effect(() => {
      if (this.showAnimation()) {
        this.startAnimation();
      } else {
        this.stopAnimation();
      }
    });
  }

  ngOnDestroy() {
    this.stopAnimation();
  }

  /**
   * Calcule le multiplicateur de gap en fonction du zoom
   * Plus le zoom est élevé, plus le gap doit être grand pour avoir moins de tirets
   */
  private getGapMultiplier(zoom: number): number {
    // Zoom 8 → multiplier 0.5 (beaucoup de tirets)
    // Zoom 12 → multiplier 1 (normal)
    // Zoom 16 → multiplier 2 (moins de tirets)
    // Zoom 20 → multiplier 4 (très peu de tirets)
    return Math.pow(2, (zoom - 12) / 4);
  }

  private startAnimation() {
    this.stopAnimation();
    let lastTime = performance.now();

    const animate = (currentTime: number) => {
      // Calculer le delta time pour une animation indépendante du framerate
      const deltaTime = (currentTime - lastTime) / 1000; // en secondes
      lastTime = currentTime;

      // Incrémenter le temps de manière continue (jamais de reset brutal)
      this.animationTime += deltaTime * ANIMATION_CONFIG.SPEED;

      // Mettre à jour le dash-array du layer animé si la map est chargée
      if (this.mapInstance) {
        const layerId = `line-animated-${this.hikeId()}`;
        try {
          if (this.mapInstance.getLayer(layerId)) {
            // Obtenir le zoom actuel pour adapter le gap
            const zoom = this.mapInstance.getZoom();
            const gapMultiplier = this.getGapMultiplier(zoom);
            const currentGap = ANIMATION_CONFIG.BASE_GAP * gapMultiplier;

            // Calculer l'offset avec modulo pour une boucle parfaite
            // L'offset varie de 0 à currentGap de manière continue
            const offset = this.animationTime % currentGap;

            this.dashOffset.set(offset);

            // Animation fluide en boucle parfaite
            // Pattern: [invisible, offset, dash, gap_restant]
            this.mapInstance.setPaintProperty(layerId, 'line-dasharray', [
              0, // Ligne invisible au début
              offset, // Espace qui grandit (décale le dash vers l'avant)
              ANIMATION_CONFIG.DASH_LENGTH * gapMultiplier, // Le tiret visible (adapté au zoom)
              currentGap - offset, // Espace qui rétrécit (maintient la période constante)
            ]);
          }
        } catch {
          // Le layer n'existe peut-être pas encore
        }
      }

      this.animationFrame = requestAnimationFrame(animate);
    };

    this.animationFrame = requestAnimationFrame(animate);
  }

  private stopAnimation() {
    if (this.animationFrame !== null) {
      cancelAnimationFrame(this.animationFrame);
      this.animationFrame = null;
    }
    // Ne pas reset animationTime pour reprendre où on en était
  }

  onMapLoad(event: { target: MapboxMap }) {
    this.mapInstance = event.target;
  }

  coordinatesToGeoJSON(coordinates: HikeCoordinate[]): GeoJSON.Feature {
    if (coordinates.length === 0) {
      return {
        type: 'Feature',
        properties: {},
        geometry: {
          type: 'Point',
          coordinates: [0, 0],
        },
      };
    }

    if (coordinates.length === 1) {
      return {
        type: 'Feature',
        properties: {},
        geometry: {
          type: 'Point',
          coordinates: [coordinates[0].longitude, coordinates[0].latitude],
        },
      };
    }

    return {
      type: 'Feature',
      properties: {},
      geometry: {
        type: 'LineString',
        coordinates: coordinates.map((c) => [c.longitude, c.latitude]),
      },
    };
  }

  getMapCenter(coordinates: HikeCoordinate[]): [number, number] {
    if (coordinates.length === 0) {
      return [2.3522, 48.8566]; // Paris par défaut
    }

    if (coordinates.length === 1) {
      return [coordinates[0].longitude, coordinates[0].latitude];
    }

    // Calculer le centre de la bounding box
    const lats = coordinates.map((c) => c.latitude);
    const lngs = coordinates.map((c) => c.longitude);

    const centerLat = (Math.min(...lats) + Math.max(...lats)) / 2;
    const centerLng = (Math.min(...lngs) + Math.max(...lngs)) / 2;

    return [centerLng, centerLat];
  }

  getMapBounds(
    coordinates: HikeCoordinate[]
  ): [[number, number], [number, number]] | undefined {
    if (coordinates.length === 0) {
      return undefined;
    }

    const lats = coordinates.map((c) => c.latitude);
    const lngs = coordinates.map((c) => c.longitude);

    return [
      [Math.min(...lngs), Math.min(...lats)],
      [Math.max(...lngs), Math.max(...lats)],
    ];
  }
}
