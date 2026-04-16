/** Mock for ngx-mapbox-gl - used in Jest tests */
import { Component } from '@angular/core';

@Component({ selector: 'mgl-map', template: '' })
export class MapComponent {}

@Component({ selector: 'mgl-marker', template: '' })
export class MarkerComponent {}

@Component({ selector: 'mgl-layer', template: '' })
export class LayerComponent {}

@Component({ selector: 'mgl-geojson-source', template: '' })
export class GeoJSONSourceComponent {}
