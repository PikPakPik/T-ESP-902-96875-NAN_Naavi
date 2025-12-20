import { ComponentFixture, TestBed } from '@angular/core/testing';
import { HikeLocationSearchComponent } from './hike-location-search.component';
import { TranslateModule } from '@ngx-translate/core';
import { NO_ERRORS_SCHEMA } from '@angular/core';

describe('HikeLocationSearchComponent', () => {
  let component: HikeLocationSearchComponent;
  let fixture: ComponentFixture<HikeLocationSearchComponent>;
  let mockGetCurrentPosition: jest.Mock;
  let mockError: jest.Mock;

  beforeEach(async () => {
    mockGetCurrentPosition = jest.fn((success) =>
      success({
        coords: {
          latitude: 48.8566,
          longitude: 2.3522,
        },
      })
    );
    mockError = jest.fn();

    // Mock geolocation
    Object.defineProperty(global.navigator, 'geolocation', {
      writable: true,
      value: {
        getCurrentPosition: mockGetCurrentPosition,
      },
    });

    await TestBed.configureTestingModule({
      imports: [HikeLocationSearchComponent, TranslateModule.forRoot()],
      schemas: [NO_ERRORS_SCHEMA],
    })
      .overrideComponent(HikeLocationSearchComponent, {
        set: {
          template: '', // Template vide pour éviter le rendu
        },
      })
      .compileComponents();

    fixture = TestBed.createComponent(HikeLocationSearchComponent);
    component = fixture.componentInstance;
    // Ne pas appeler detectChanges() pour éviter le rendu du template
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should open and close dialog', () => {
    expect(component.visible()).toBe(false);

    component.open();
    expect(component.visible()).toBe(true);

    component.close();
    expect(component.visible()).toBe(false);
  });

  it('should update location', () => {
    component.latitude.set(50.123);
    component.longitude.set(3.456);

    expect(component.latitude()).toBe(50.123);
    expect(component.longitude()).toBe(3.456);
  });

  describe('applySearch', () => {
    it('should emit searchLocation and close dialog', () => {
      const emitSpy = jest.spyOn(component.searchLocation, 'emit');
      component.latitude.set(48.8566);
      component.longitude.set(2.3522);
      component.radius.set(15);

      component.applySearch();

      expect(emitSpy).toHaveBeenCalledWith({
        latitude: 48.8566,
        longitude: 2.3522,
        radius: 15,
      });
      expect(component.visible()).toBe(false);
    });
  });

  describe('clearSearch', () => {
    it('should emit clearLocation and close dialog', () => {
      const emitSpy = jest.spyOn(component.clearLocation, 'emit');
      component.visible.set(true);

      component.clearSearch();

      expect(emitSpy).toHaveBeenCalled();
      expect(component.visible()).toBe(false);
    });
  });

  describe('updateMapCenter', () => {
    it('should update map center coordinates', () => {
      component.latitude.set(48.8566);
      component.longitude.set(2.3522);

      component.updateMapCenter();

      expect(component.mapCenter()).toEqual([2.3522, 48.8566]);
    });
  });

  describe('onMapClick', () => {
    it('should update location when map is clicked', () => {
      const mockEvent = {
        lngLat: {
          lng: 2.5,
          lat: 48.9,
        },
      } as any;

      component.onMapClick(mockEvent);

      expect(component.longitude()).toBe(2.5);
      expect(component.latitude()).toBe(48.9);
      expect(component.mapCenter()).toEqual([2.5, 48.9]);
    });
  });

  describe('onMarkerDragEnd', () => {
    it('should update location when marker is dragged', () => {
      const mockMarker = {
        getLngLat: jest.fn(() => ({
          lng: 2.5,
          lat: 48.9,
        })),
      } as any;

      component.onMarkerDragEnd(mockMarker);

      expect(component.longitude()).toBe(2.5);
      expect(component.latitude()).toBe(48.9);
      expect(component.mapCenter()).toEqual([2.5, 48.9]);
    });
  });

  describe('resetToCurrentLocation', () => {
    it('should update location from geolocation', () => {
      component.resetToCurrentLocation();

      expect(mockGetCurrentPosition).toHaveBeenCalled();
      expect(component.latitude()).toBe(48.8566);
      expect(component.longitude()).toBe(2.3522);
      expect(component.mapZoom()).toBe(12);
    });

    it('should handle geolocation error', () => {
      const error = new Error('Geolocation error');
      mockGetCurrentPosition.mockImplementation((success, errorCallback) => {
        if (errorCallback) errorCallback(error);
      });
      jest.spyOn(console, 'error').mockImplementation();

      component.resetToCurrentLocation();

      expect(console.error).toHaveBeenCalledWith(
        'Erreur de géolocalisation:',
        error
      );

      jest.spyOn(console, 'error').mockRestore();
    });

    it('should not do anything if geolocation is not available', () => {
      Object.defineProperty(global.navigator, 'geolocation', {
        writable: true,
        value: undefined,
      });

      component.resetToCurrentLocation();

      expect(component.latitude()).toBe(48.8566); // Default value
    });
  });

  describe('resizeMap', () => {
    it('should resize map when mapComponent is available', () => {
      const mockMap = {
        resize: jest.fn(),
      };
      component.mapComponent = {
        mapInstance: mockMap,
      } as any;

      component['resizeMap']();

      expect(mockMap.resize).toHaveBeenCalled();
    });

    it('should not resize map when mapComponent is not available', () => {
      component.mapComponent = undefined;

      expect(() => component['resizeMap']()).not.toThrow();
    });
  });

  describe('open', () => {
    beforeEach(() => {
      jest.useFakeTimers();
    });

    afterEach(() => {
      jest.useRealTimers();
    });

    it('should open dialog and reset to current location', () => {
      component.open();

      expect(component.visible()).toBe(true);
      expect(mockGetCurrentPosition).toHaveBeenCalled();
    });

    it('should resize map after opening', () => {
      const mockMap = {
        resize: jest.fn(),
      };
      component.mapComponent = {
        mapInstance: mockMap,
      } as any;

      component.open();

      jest.advanceTimersByTime(200);

      expect(mockMap.resize).toHaveBeenCalled();
    });
  });
});
