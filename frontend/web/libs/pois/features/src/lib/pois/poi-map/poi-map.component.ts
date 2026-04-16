import { Component, input, ChangeDetectionStrategy } from '@angular/core';
import { getPOICategoryIconPath } from '@web/pois/data-access';

import {
  MapComponent,
  MarkerComponent,
} from 'ngx-mapbox-gl';

@Component({
  selector: 'poi-map',
  standalone: true,
  imports: [MapComponent, MarkerComponent],
  templateUrl: './poi-map.component.html',
  styleUrls: ['./poi-map.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PoiMapComponent {
  latitude = input.required<number>();
  longitude = input.required<number>();
  poiId = input.required<string>();
  category = input<string | null>(null);
  useCategoryIcon = input(true);

  coordinatesToGeoJSON(): GeoJSON.Feature {
    return {
      type: 'Feature',
      properties: {},
      geometry: {
        type: 'Point',
        coordinates: [this.longitude(), this.latitude()],
      },
    };
  }

  getMapCenter(): [number, number] {
    return [this.longitude(), this.latitude()];
  }

  getMarkerIconPath(): string {
    return getPOICategoryIconPath(this.category());
  }
}
