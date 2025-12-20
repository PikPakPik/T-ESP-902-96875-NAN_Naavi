import { ComponentFixture, TestBed } from '@angular/core/testing';
import { LocationSearchComponent } from './location-search.component';
import { NO_ERRORS_SCHEMA } from '@angular/core';
import { MapComponent } from 'ngx-mapbox-gl';
import { Map } from 'mapbox-gl';

describe('LocationSearchComponent', () => {
  let component: LocationSearchComponent;
  let fixture: ComponentFixture<LocationSearchComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [LocationSearchComponent],
      schemas: [NO_ERRORS_SCHEMA],
    })
      .overrideComponent(LocationSearchComponent, {
        set: {
          template: '', // Template vide pour éviter le rendu
        },
      })
      .compileComponents();

    fixture = TestBed.createComponent(LocationSearchComponent);
    component = fixture.componentInstance;
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  describe('open', () => {
    it('should set visible to true', () => {
      component.open();
      expect(component.visible()).toBe(true);
    });
  });

  describe('close', () => {
    it('should set visible to false', () => {
      component.visible.set(true);
      component.close();
      expect(component.visible()).toBe(false);
    });
  });

  describe('updateMapCenter', () => {
    it('should update map center with current latitude and longitude', () => {
      component.latitude.set(45.0);
      component.longitude.set(2.0);
      component.updateMapCenter();
      expect(component.mapCenter()).toEqual([2.0, 45.0]);
    });
  });

  describe('applySearch', () => {
    it('should emit searchLocation with current parameters', () => {
      component.latitude.set(48.8566);
      component.longitude.set(2.3522);
      component.radius.set(10);
      const emitSpy = jest.spyOn(component.searchLocation, 'emit');
      const closeSpy = jest.spyOn(component, 'close');

      component.applySearch();

      expect(emitSpy).toHaveBeenCalledWith({
        latitude: 48.8566,
        longitude: 2.3522,
        radius: 10,
      });
      expect(closeSpy).toHaveBeenCalled();
    });
  });

  describe('clearSearch', () => {
    it('should emit clearLocation and close', () => {
      const emitSpy = jest.spyOn(component.clearLocation, 'emit');
      const closeSpy = jest.spyOn(component, 'close');

      component.clearSearch();

      expect(emitSpy).toHaveBeenCalled();
      expect(closeSpy).toHaveBeenCalled();
    });
  });

  describe('resetToCurrentLocation', () => {
    beforeEach(() => {
      // S'assurer que navigator existe
      if (typeof global.navigator === 'undefined') {
        (global as any).navigator = {};
      }
    });

    it('should handle geolocation success', (done) => {
      const mockPosition = {
        coords: {
          latitude: 50.0,
          longitude: 3.0,
        },
      };

      // Mock navigator.geolocation
      Object.defineProperty(global.navigator, 'geolocation', {
        value: {
          getCurrentPosition: jest.fn((success) => {
            // Appeler success de manière synchrone
            success(mockPosition);
          }),
        },
        writable: true,
        configurable: true,
      });

      component.resetToCurrentLocation();

      // Utiliser flush pour traiter les changements de Zone.js
      setTimeout(() => {
        expect(component.latitude()).toBe(50.0);
        expect(component.longitude()).toBe(3.0);
        expect(component.mapZoom()).toBe(12);
        done();
      }, 200);
    });

    it('should handle geolocation error', () => {
      const consoleErrorSpy = jest
        .spyOn(console, 'error')
        .mockImplementation(() => {
          // Mock implementation to suppress console.error in tests
        });

      // S'assurer que navigator existe
      if (typeof global.navigator === 'undefined') {
        (global as any).navigator = {};
      }
      Object.defineProperty(global.navigator, 'geolocation', {
        value: {
          getCurrentPosition: jest.fn((success, error) => {
            error(new Error('Geolocation error'));
          }),
        },
        writable: true,
        configurable: true,
      });

      component.resetToCurrentLocation();

      expect(consoleErrorSpy).toHaveBeenCalled();
      consoleErrorSpy.mockRestore();
    });

    it('should handle missing geolocation', () => {
      Object.defineProperty(navigator, 'geolocation', {
        value: undefined,
        configurable: true,
      });

      // Should not throw
      expect(() => component.resetToCurrentLocation()).not.toThrow();
    });
  });

  describe('markerLngLat', () => {
    it('should return computed coordinates', () => {
      component.latitude.set(48.8566);
      component.longitude.set(2.3522);
      expect(component.markerLngLat()).toEqual([2.3522, 48.8566]);
    });
  });

  describe('circleGeoJSON', () => {
    it('should generate circle GeoJSON with correct structure', () => {
      component.latitude.set(48.8566);
      component.longitude.set(2.3522);
      component.radius.set(10);

      const geoJSON = component.circleGeoJSON();

      expect(geoJSON.type).toBe('FeatureCollection');
      expect(geoJSON.features).toHaveLength(1);
      expect(geoJSON.features[0].type).toBe('Feature');
      expect(geoJSON.features[0].geometry.type).toBe('Polygon');
      expect(geoJSON.features[0].geometry.coordinates[0]).toHaveLength(65); // 64 steps + closing point
    });

    it('should update circle when radius changes', () => {
      component.latitude.set(48.8566);
      component.longitude.set(2.3522);
      component.radius.set(5);

      const geoJSON1 = component.circleGeoJSON();

      component.radius.set(20);
      const geoJSON2 = component.circleGeoJSON();

      // The coordinates should be different
      expect(geoJSON1).not.toEqual(geoJSON2);
    });

    it('should update circle when coordinates change', () => {
      component.latitude.set(48.8566);
      component.longitude.set(2.3522);
      component.radius.set(10);

      const geoJSON1 = component.circleGeoJSON();

      component.latitude.set(50.0);
      component.longitude.set(3.0);
      const geoJSON2 = component.circleGeoJSON();

      // The coordinates should be different
      expect(geoJSON1).not.toEqual(geoJSON2);
    });
  });

  describe('onMarkerDragEnd', () => {
    it('should update coordinates when marker is dragged', () => {
      const mockMarker = {
        getLngLat: jest.fn(() => ({
          lng: 3.0,
          lat: 50.0,
        })),
      } as unknown as mapboxgl.Marker;

      component.onMarkerDragEnd(mockMarker);

      expect(component.longitude()).toBe(3.0);
      expect(component.latitude()).toBe(50.0);
    });
  });

  describe('onMapClick', () => {
    it('should update coordinates when map is clicked', () => {
      const mockEvent = {
        lngLat: {
          lng: 4.0,
          lat: 51.0,
        },
      } as unknown as mapboxgl.MapLayerMouseEvent;

      component.onMapClick(mockEvent);

      expect(component.longitude()).toBe(4.0);
      expect(component.latitude()).toBe(51.0);
    });
  });

  describe('resizeMap', () => {
    it('should resize map when mapComponent is available', () => {
      const mockMap = {
        resize: jest.fn(),
      } as unknown as Map;

      const mockMapComponent = {
        mapInstance: mockMap,
      } as unknown as MapComponent;

      component['mapComponent'] = mockMapComponent;
      component['resizeMap']();

      expect(mockMap.resize).toHaveBeenCalled();
    });

    it('should not throw when mapComponent is not available', () => {
      component['mapComponent'] = undefined;
      expect(() => component['resizeMap']()).not.toThrow();
    });

    it('should not throw when mapInstance is not available', () => {
      const mockMapComponent = {
        mapInstance: undefined,
      } as unknown as MapComponent;

      component['mapComponent'] = mockMapComponent;
      expect(() => component['resizeMap']()).not.toThrow();
    });
  });

  describe('ngAfterViewInit', () => {
    beforeEach(() => {
      jest.useFakeTimers();
    });

    afterEach(() => {
      jest.useRealTimers();
    });

    it('should resize map if visible', () => {
      const mockMap = {
        resize: jest.fn(),
      } as unknown as Map;

      const mockMapComponent = {
        mapInstance: mockMap,
      } as unknown as MapComponent;

      component['mapComponent'] = mockMapComponent;
      component.visible.set(true);

      component.ngAfterViewInit();

      jest.advanceTimersByTime(100);
        expect(mockMap.resize).toHaveBeenCalled();
    });

    it('should not resize map if not visible', () => {
      const mockMap = {
        resize: jest.fn(),
      } as unknown as Map;

      const mockMapComponent = {
        mapInstance: mockMap,
      } as unknown as MapComponent;

      component['mapComponent'] = mockMapComponent;
      component.visible.set(false);

      component.ngAfterViewInit();

      jest.advanceTimersByTime(100);
        expect(mockMap.resize).not.toHaveBeenCalled();
    });
  });

  describe('open', () => {
    it('should call resetToCurrentLocation', () => {
      const resetSpy = jest.spyOn(component, 'resetToCurrentLocation');
      const mockMap = {
        resize: jest.fn(),
      } as unknown as Map;

      const mockMapComponent = {
        mapInstance: mockMap,
      } as unknown as MapComponent;

      component['mapComponent'] = mockMapComponent;

      Object.defineProperty(navigator, 'geolocation', {
        value: {
          getCurrentPosition: jest.fn(),
        },
        configurable: true,
      });

      component.open();

      expect(resetSpy).toHaveBeenCalled();
      expect(component.visible()).toBe(true);
    });
  });
});
