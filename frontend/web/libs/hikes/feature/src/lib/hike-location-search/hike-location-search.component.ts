import {
  Component,
  output,
  signal,
  computed,
  type Signal,
  ViewChild,
  AfterViewInit,
  effect,
} from '@angular/core';

import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { DialogModule } from 'primeng/dialog';
import { SliderModule } from 'primeng/slider';
import { InputNumberModule } from 'primeng/inputnumber';
import {
  MapComponent,
  MarkerComponent,
  LayerComponent,
  GeoJSONSourceComponent,
} from 'ngx-mapbox-gl';
import { LngLat, type MapMouseEvent, type Marker, type Map } from 'mapbox-gl';

export interface LocationSearchParams {
  latitude: number;
  longitude: number;
  radius: number; // en kilomètres
}

@Component({
  selector: 'hike-location-search',
  standalone: true,
  imports: [
    FormsModule,
    ButtonModule,
    DialogModule,
    SliderModule,
    InputNumberModule,
    MapComponent,
    MarkerComponent,
    LayerComponent,
    GeoJSONSourceComponent
],
  templateUrl: './hike-location-search.component.html',
  styleUrl: './hike-location-search.component.scss',
})
export class HikeLocationSearchComponent implements AfterViewInit {
  // Outputs
  searchLocation = output<LocationSearchParams>();
  clearLocation = output<void>();

  // Dialog visibility
  visible = signal(false);

  // Map reference
  @ViewChild('map') mapComponent?: MapComponent;

  // Map configuration
  mapStyle = 'mapbox://styles/mapbox/outdoors-v12';
  mapCenter = signal<[number, number]>([2.3522, 48.8566]); // Paris par défaut
  mapZoom = signal(10);

  // Search parameters
  latitude = signal(48.8566);
  longitude = signal(2.3522);
  radius = signal(10); // km

  // Marker draggable
  markerLngLat = computed<[number, number]>(() => [
    this.longitude(),
    this.latitude(),
  ]);

  // Circle pour visualiser le rayon
  circleGeoJSON: Signal<GeoJSON.FeatureCollection<GeoJSON.Polygon>> = computed(
    () => {
      const centerLng = this.longitude();
      const centerLat = this.latitude();
      const radiusKm = this.radius();

      // Créer un cercle approximatif (simplifié)
      const steps = 64;
      const coordinates: [number, number][] = [];

      // Conversion approximative: 1 degré ≈ 111 km
      const radiusDeg = radiusKm / 111;

      for (let i = 0; i < steps; i++) {
        const angle = (i / steps) * 2 * Math.PI;
        const lng =
          centerLng +
          (radiusDeg * Math.cos(angle)) / Math.cos((centerLat * Math.PI) / 180);
        const lat = centerLat + radiusDeg * Math.sin(angle);
        coordinates.push([lng, lat]);
      }
      // Fermer le cercle
      coordinates.push(coordinates[0]);

      const circleFeature: GeoJSON.Feature<GeoJSON.Polygon> = {
        type: 'Feature',
        properties: {},
        geometry: {
          type: 'Polygon',
          coordinates: [coordinates],
        },
      };

      return {
        type: 'FeatureCollection',
        features: [circleFeature],
      };
    }
  );

  constructor() {
    // Redimensionner la carte quand le dialog devient visible
    effect(() => {
      if (this.visible()) {
        // Attendre que le dialog soit complètement rendu
        setTimeout(() => {
          this.resizeMap();
        }, 100);
      }
    });
  }

  ngAfterViewInit() {
    // Redimensionner la carte après l'initialisation
    if (this.visible()) {
      setTimeout(() => {
        this.resizeMap();
      }, 100);
    }
  }

  private resizeMap() {
    if (this.mapComponent?.mapInstance) {
      const map = this.mapComponent.mapInstance as Map;
      map.resize();
    }
  }

  open() {
    this.visible.set(true);
    // Essayer d'obtenir la position de l'utilisateur à l'ouverture
    this.resetToCurrentLocation();
    // Redimensionner la carte après l'ouverture du dialog
    setTimeout(() => {
      this.resizeMap();
    }, 200);
  }

  close() {
    this.visible.set(false);
  }

  onMarkerDragEnd(marker: Marker) {
    const lngLat = marker.getLngLat() as LngLat;
    this.longitude.set(lngLat.lng);
    this.latitude.set(lngLat.lat);
    this.updateMapCenter();
  }

  onMapClick(event: MapMouseEvent) {
    const lngLat = event.lngLat;
    this.longitude.set(lngLat.lng);
    this.latitude.set(lngLat.lat);
    this.updateMapCenter();
  }

  updateMapCenter() {
    this.mapCenter.set([this.longitude(), this.latitude()]);
  }

  applySearch() {
    this.searchLocation.emit({
      latitude: this.latitude(),
      longitude: this.longitude(),
      radius: this.radius(),
    });
    this.close();
  }

  clearSearch() {
    this.clearLocation.emit();
    this.close();
  }

  resetToCurrentLocation() {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          this.latitude.set(position.coords.latitude);
          this.longitude.set(position.coords.longitude);
          this.updateMapCenter();
          this.mapZoom.set(12);
        },
        (error) => {
          console.error('Erreur de géolocalisation:', error);
        }
      );
    }
  }
}
