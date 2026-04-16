/** Mock for mapbox-gl - used in Jest tests */
export class LngLat {
  constructor(public lng: number, public lat: number) {}
}

export class Marker {
  setLngLat = jest.fn();
  addTo = jest.fn();
  remove = jest.fn();
}

export class Map {
  on = jest.fn();
  off = jest.fn();
  remove = jest.fn();
  getCenter = jest.fn(() => new LngLat(0, 0));
  flyTo = jest.fn();
  fitBounds = jest.fn();
}

export type MapLayerMouseEvent = unknown;
