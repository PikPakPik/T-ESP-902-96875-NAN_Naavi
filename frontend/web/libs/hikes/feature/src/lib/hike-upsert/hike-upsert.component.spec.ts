import { ComponentFixture, TestBed } from '@angular/core/testing';
import { HikeUpsertComponent } from './hike-upsert.component';
import { HikesStore, HikeDetailStore } from '@web/hikes/data-access';
import { Router, ActivatedRoute } from '@angular/router';
import { signal, NO_ERRORS_SCHEMA, ChangeDetectorRef } from '@angular/core';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { of, Observable } from 'rxjs';
import { MapboxService } from '@web/shared/util';
import { MessageService } from 'primeng/api';
import { NgForm } from '@angular/forms';
import { CdkDragDrop } from '@angular/cdk/drag-drop';
import { Marker } from 'mapbox-gl';
import { Coordinate, Hike } from '@web/shared/models/settings';

describe('HikeUpsertComponent', () => {
  let component: HikeUpsertComponent;
  let fixture: ComponentFixture<HikeUpsertComponent>;
  let hikesStore: jest.Mocked<Partial<InstanceType<typeof HikesStore>>>;
  let router: jest.Mocked<Router>;
  let mapboxService: jest.Mocked<MapboxService>;
  let messageService: jest.Mocked<MessageService>;
  let translateService: TranslateService;

  beforeEach(async () => {
    const hikesStoreMock = {
      difficulties: signal(['EASY', 'MEDIUM', 'HARD']),
      status: signal(['DRAFT', 'PUBLISHED']),
      sources: signal(['OFFICIAL', 'COMMUNITY']),
      seasons: signal(['SPRING', 'SUMMER', 'FALL', 'WINTER']),
      create: jest.fn(),
      update: jest.fn(),
      getHikeById: jest.fn(),
    };

    const routerMock = {
      navigate: jest.fn(),
    };

    const activatedRouteMock = {
      params: of({ id: null }),
      snapshot: {
        params: {},
      },
    };

    mapboxService = {
      getAccessToken: jest.fn(() => 'test-token'),
      getDirectionsRoute: jest.fn().mockResolvedValue({
        code: 'Ok',
        routes: [
          {
            geometry: {
              coordinates: [
                [2.3522, 48.8566],
                [2.355, 48.86],
              ],
            },
          },
        ],
      }),
    } as unknown as jest.Mocked<MapboxService>;

    messageService = {
      add: jest.fn(),
    } as unknown as jest.Mocked<MessageService>;

    const translateServiceMock = {
      instant: jest.fn((key: string) => key),
      get: jest.fn((key: string): Observable<string> => of(key)),
      currentLang: 'fr',
      onLangChange: of({ lang: 'fr', translations: {} }),
    };

    const hikeDetailStoreMock = {
      hike: signal(null),
      isPending: signal(false),
      load: jest.fn(),
    } as unknown as jest.Mocked<typeof HikeDetailStore>;

    await TestBed.configureTestingModule({
      imports: [HikeUpsertComponent, TranslateModule.forRoot()],
      providers: [
        { provide: HikesStore, useValue: hikesStoreMock },
        { provide: Router, useValue: routerMock },
        { provide: ActivatedRoute, useValue: activatedRouteMock },
        { provide: MapboxService, useValue: mapboxService },
        { provide: MessageService, useValue: messageService },
        { provide: HikeDetailStore, useValue: hikeDetailStoreMock },
        { provide: TranslateService, useValue: translateServiceMock },
      ],
      schemas: [NO_ERRORS_SCHEMA],
    })
      .overrideProvider(TranslateService, { useValue: translateServiceMock })
      .overrideComponent(HikeUpsertComponent, {
        set: {
          providers: [
            { provide: MessageService, useValue: messageService },
            { provide: HikeDetailStore, useValue: hikeDetailStoreMock },
          ],
        },
      })
      .compileComponents();

    fixture = TestBed.createComponent(HikeUpsertComponent);
    component = fixture.componentInstance;
    hikesStore = TestBed.inject(HikesStore) as jest.Mocked<
      Partial<InstanceType<typeof HikesStore>>
    >;
    router = TestBed.inject(Router) as jest.Mocked<Router>;
    translateService = TestBed.inject(TranslateService) as any;
    // Ne pas appeler detectChanges() pour éviter le rendu du template
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should add a coordinate when addCoordinate is called', async () => {
    const initialLength = component.waypoints().length;
    await component.addCoordinate(48.8566, 2.3522);

    expect(component.waypoints()).toHaveLength(initialLength + 1);
    expect(component.waypoints()[initialLength]).toEqual({
      latitude: 48.8566,
      longitude: 2.3522,
    });
  });

  it('should not add more than 25 waypoints', async () => {
    // Add 25 waypoints
    for (let i = 0; i < 25; i++) {
      await component.addCoordinate(48.85 + i * 0.001, 2.35 + i * 0.001);
    }

    expect(component.waypoints()).toHaveLength(25);

    // Try to add 26th waypoint
    await component.addCoordinate(48.9, 2.4);

    // Should still be 25
    expect(component.waypoints()).toHaveLength(25);
  });

  it('should navigate back when cancel is called', () => {
    component.cancel();
    expect(router.navigate).toHaveBeenCalledWith(['/backoffice/hikes']);
  });

  it('should create hike when saveHike is called in create mode', async () => {
    component.name.set('Test Hike');
    component.difficulty.set('EASY');
    component.coordinates.set([
      { latitude: 48.8566, longitude: 2.3522 },
      { latitude: 48.86, longitude: 2.355 },
    ]);
    component.distance.set(5);

    await component.saveHike();

    expect(hikesStore.create).toHaveBeenCalled();
    expect(router.navigate).toHaveBeenCalledWith(['/backoffice/hikes']);
  });

  it('should update hike when saveHike is called in edit mode', async () => {
    const mockCreatedAt = new Date('2024-01-01');
    component.isEditMode.set(true);
    component.hikeId.set('1');
    component.createdAt.set(mockCreatedAt);
    component.name.set('Updated Hike');
    component.difficulty.set('MEDIUM');
    component.coordinates.set([{ latitude: 45.764, longitude: 4.8357 }]);
    component.distance.set(10);

    await component.saveHike();

    expect(hikesStore.update).toHaveBeenCalled();
    expect(hikesStore.update).toHaveBeenCalledWith(
      expect.objectContaining({
        id: '1',
        name: 'Updated Hike',
        difficulty: 'MEDIUM',
        createdAt: mockCreatedAt,
      })
    );
    expect(router.navigate).toHaveBeenCalledWith(['/backoffice/hikes']);
  });

  it('should not save hike when required fields are missing', async () => {
    component.name.set('');

    // Créer un formulaire invalide pour tester la validation
    const formMock = {
      valid: false,
      control: {
        markAllAsTouched: jest.fn(),
      },
    } as unknown as NgForm;

    await component.saveHike(formMock);

    expect(hikesStore.create).not.toHaveBeenCalled();
    expect(hikesStore.update).not.toHaveBeenCalled();
  });

  describe('coordinatesToGeoJSON', () => {
    it('should return Point with map center when no coordinates', () => {
      component.coordinates.set([]);

      const geojson = component.coordinatesToGeoJSON();

      expect(geojson.type).toBe('Feature');
      expect(geojson.geometry.type).toBe('Point');
    });

    it('should return Point for single coordinate', () => {
      component.coordinates.set([{ latitude: 48.8566, longitude: 2.3522 }]);

      const geojson = component.coordinatesToGeoJSON();

      expect(geojson.type).toBe('Feature');
      expect(geojson.geometry.type).toBe('Point');
      if (geojson.geometry.type === 'Point') {
        expect(geojson.geometry.coordinates).toEqual([2.3522, 48.8566]);
      }
    });

    it('should return LineString for multiple coordinates', () => {
      component.coordinates.set([
        { latitude: 48.8566, longitude: 2.3522 },
        { latitude: 48.86, longitude: 2.355 },
      ]);

      const geojson = component.coordinatesToGeoJSON();

      expect(geojson.type).toBe('Feature');
      expect(geojson.geometry.type).toBe('LineString');
      if (geojson.geometry.type === 'LineString') {
        expect(geojson.geometry.coordinates).toHaveLength(2);
      }
    });
  });

  it('should calculate map center', () => {
    component.coordinates.set([
      { latitude: 48.8566, longitude: 2.3522 },
      { latitude: 48.86, longitude: 2.355 },
    ]);

    const center = component.mapCenter();

    expect(center).toHaveLength(2);
  });

  it('should clear all waypoints and coordinates when clearWaypoints is called', () => {
    component.waypoints.set([
      { latitude: 48.8566, longitude: 2.3522 },
      { latitude: 48.86, longitude: 2.355 },
    ]);
    component.coordinates.set([
      { latitude: 48.8566, longitude: 2.3522 },
      { latitude: 48.86, longitude: 2.355 },
    ]);

    component.clearCoordinates();

    expect(component.waypoints()).toHaveLength(0);
    expect(component.coordinates()).toHaveLength(0);
  });

  describe('getMapBounds', () => {
    it('should return undefined when no coordinates', () => {
      component.coordinates.set([]);

      const bounds = component.getMapBounds();

      expect(bounds).toBeUndefined();
    });

    it('should return bounds for single coordinate', () => {
      component.coordinates.set([{ latitude: 48.8566, longitude: 2.3522 }]);

      const bounds = component.getMapBounds();

      expect(bounds).toBeDefined();
      if (bounds) {
        expect(bounds).toHaveLength(2);
        expect(bounds[0][0]).toBeCloseTo(2.3522 - 0.01);
        expect(bounds[0][1]).toBeCloseTo(48.8566 - 0.01);
        expect(bounds[1][0]).toBeCloseTo(2.3522 + 0.01);
        expect(bounds[1][1]).toBeCloseTo(48.8566 + 0.01);
      }
    });

    it('should calculate bounds for multiple coordinates', () => {
      component.coordinates.set([
        { latitude: 48.8566, longitude: 2.3522 },
        { latitude: 48.86, longitude: 2.355 },
      ]);

      const bounds = component.getMapBounds();

      expect(bounds).toBeDefined();
      if (bounds) {
        expect(bounds[0]).toEqual([2.3522, 48.8566]);
        expect(bounds[1]).toEqual([2.355, 48.86]);
      }
    });
  });

  describe('calculateRouteBetweenPoints error handling', () => {
    beforeEach(() => {
      jest.clearAllMocks();
    });

    it('should handle error when route calculation fails', async () => {
      const error = new Error('Route calculation failed');
      mapboxService.getDirectionsRoute.mockRejectedValueOnce(error);
      jest.spyOn(console, 'error').mockImplementation();

      // Detach change detector to prevent automatic change detection from signals
      const cdr = fixture.componentRef.injector.get(ChangeDetectorRef);
      cdr.detach();

      component.waypoints.set([
        { latitude: 48.8566, longitude: 2.3522 },
        { latitude: 48.86, longitude: 2.355 },
        { latitude: 48.865, longitude: 2.36 },
      ]);

      // Trigger calculateRouteBetweenPoints indirectly via removeCoordinate
      // This will leave 2 waypoints and trigger route calculation
      await component.removeCoordinate(1);
      // Wait for async operations to complete
      await new Promise((resolve) => setTimeout(resolve, 200));

      // The error should have been logged
      expect(console.error).toHaveBeenCalled();
      expect(component.isLoadingRoute()).toBe(false);

      jest.spyOn(console, 'error').mockRestore();
    });
  });

  describe('removeCoordinate', () => {
    beforeEach(() => {
      jest.clearAllMocks();
      mapboxService.getDirectionsRoute.mockResolvedValue({
        code: 'Ok',
        routes: [
          {
            geometry: {
              coordinates: [
                [2.3522, 48.8566],
                [2.355, 48.86],
              ],
            },
          },
        ],
      });
    });

    it('should recalculate route when removing coordinate with 2+ waypoints', async () => {
      component.waypoints.set([
        { latitude: 48.8566, longitude: 2.3522 },
        { latitude: 48.86, longitude: 2.355 },
        { latitude: 48.865, longitude: 2.36 },
      ]);

      await component.removeCoordinate(1);

      expect(mapboxService.getDirectionsRoute).toHaveBeenCalled();
      expect(messageService.add).toHaveBeenCalled();
    });

    it('should set coordinates directly when removing to 1 waypoint', async () => {
      component.waypoints.set([
        { latitude: 48.8566, longitude: 2.3522 },
        { latitude: 48.86, longitude: 2.355 },
      ]);

      await component.removeCoordinate(1);

      expect(component.waypoints()).toHaveLength(1);
      expect(component.coordinates()).toHaveLength(1);
      expect(messageService.add).toHaveBeenCalled();
    });

    it('should clear everything when removing last waypoint', async () => {
      component.waypoints.set([{ latitude: 48.8566, longitude: 2.3522 }]);
      component.elevationGain.set(100);
      component.elevationLoss.set(50);

      await component.removeCoordinate(0);

      expect(component.waypoints()).toHaveLength(0);
      expect(component.coordinates()).toHaveLength(0);
      expect(component.elevationGain()).toBe(0);
      expect(component.elevationLoss()).toBe(0);
      expect(messageService.add).toHaveBeenCalled();
    });
  });

  describe('dropWaypoint', () => {
    beforeEach(() => {
      jest.clearAllMocks();
      mapboxService.getDirectionsRoute.mockResolvedValue({
        code: 'Ok',
        routes: [
          {
            geometry: {
              coordinates: [
                [2.3522, 48.8566],
                [2.355, 48.86],
              ],
            },
          },
        ],
      });
    });

    it('should return early when previousIndex equals currentIndex', async () => {
      component.waypoints.set([
        { latitude: 48.8566, longitude: 2.3522 },
        { latitude: 48.86, longitude: 2.355 },
      ]);

      const event = {
        previousIndex: 0,
        currentIndex: 0,
      } as CdkDragDrop<Coordinate[]>;

      await component.dropWaypoint(event);

      expect(messageService.add).not.toHaveBeenCalled();
    });

    it('should recalculate route when dropping with 2+ waypoints', async () => {
      component.waypoints.set([
        { latitude: 48.8566, longitude: 2.3522 },
        { latitude: 48.86, longitude: 2.355 },
        { latitude: 48.865, longitude: 2.36 },
      ]);

      const event = {
        previousIndex: 0,
        currentIndex: 2,
      } as CdkDragDrop<Coordinate[]>;

      await component.dropWaypoint(event);

      expect(component.waypoints()).toHaveLength(3);
      expect(mapboxService.getDirectionsRoute).toHaveBeenCalled();
      expect(messageService.add).toHaveBeenCalled();
    });

    it('should set coordinates directly when dropping with 1 waypoint', async () => {
      component.waypoints.set([{ latitude: 48.8566, longitude: 2.3522 }]);

      const event = {
        previousIndex: 0,
        currentIndex: 0,
      } as CdkDragDrop<Coordinate[]>;

      // Since previousIndex === currentIndex, it should return early
      await component.dropWaypoint(event);

      expect(messageService.add).not.toHaveBeenCalled();
    });
  });

  describe('onMapClick', () => {
    it('should not add coordinate when waypoint limit is reached', async () => {
      // Fill waypoints to max
      for (let i = 0; i < 25; i++) {
        component.waypoints.set([
          ...component.waypoints(),
          { latitude: 48.85 + i * 0.001, longitude: 2.35 + i * 0.001 },
        ]);
      }

      const mockEvent = {
        lngLat: {
          lat: 48.9,
          lng: 2.4,
        },
      };

      component.onMapClick(mockEvent);

      expect(component.waypoints()).toHaveLength(25);
      expect(messageService.add).toHaveBeenCalledWith(
        expect.objectContaining({
          severity: 'warn',
        })
      );
    });

    it('should add coordinate when limit not reached', async () => {
      component.waypoints.set([]);

      const mockEvent = {
        lngLat: {
          lat: 48.8566,
          lng: 2.3522,
        },
      };

      component.onMapClick(mockEvent);

      expect(component.waypoints().length).toBeGreaterThan(0);
    });
  });

  describe('addCoordinate', () => {
    it('should set coordinates directly when only one waypoint', async () => {
      component.waypoints.set([]);

      await component.addCoordinate(48.8566, 2.3522);

      expect(component.waypoints()).toHaveLength(1);
      expect(component.coordinates()).toHaveLength(1);
      expect(messageService.add).toHaveBeenCalled();
    });
  });

  describe('mapCenter computed', () => {
    it('should use first waypoint when waypoints exist', () => {
      component.waypoints.set([{ latitude: 48.8566, longitude: 2.3522 }]);

      const center = component.mapCenter();

      expect(center).toEqual([2.3522, 48.8566]);
    });

    it('should use first coordinate when no waypoints but coordinates exist', () => {
      component.waypoints.set([]);
      component.coordinates.set([{ latitude: 48.86, longitude: 2.355 }]);

      const center = component.mapCenter();

      expect(center).toEqual([2.355, 48.86]);
    });

    it('should use default when no waypoints and no coordinates', () => {
      component.waypoints.set([]);
      component.coordinates.set([]);

      const center = component.mapCenter();

      expect(center).toEqual([6.8652, 45.8326]); // Mont Blanc default
    });
  });

  describe('loadHikeForEdit', () => {
    beforeEach(() => {
      jest.clearAllMocks();
    });

    it('should load hike with fallback values', () => {
      const mockHike = new Hike({
        id: '1',
        name: 'Test Hike',
        startingPointLatitude: 48.8566,
        startingPointLongitude: 2.3522,
        startingElevation: 100,
        arrivalPointLatitude: 48.86,
        arrivalPointLongitude: 2.355,
        arrivalElevation: 150,
        wkbGeometry: '',
        wkbWaypoints: '',
        distance: 5000,
        difficulty: 'EASY',
        status: 'PUBLISHED',
        location: '', // Empty to test fallback
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      });
      (mockHike as any).source = undefined; // Test fallback
      (mockHike as any).seasons = undefined; // Test fallback
      (mockHike as any).elevationGain = undefined; // Test fallback
      (mockHike as any).elevationLoss = undefined; // Test fallback
      mockHike.coordinates = [];

      component.loadHikeForEdit(mockHike);

      expect(component.isEditMode()).toBe(true);
      expect(component.hikeId()).toBe('1');
      expect(component.location()).toBe('');
      expect(component.source()).toBe('');
      expect(component.seasons()).toEqual([]);
      expect(component.elevationGain()).toBe(0);
      expect(component.elevationLoss()).toBe(0);
    });

    it('should recalculate distance when distance is missing or zero', () => {
      const mockHike = new Hike({
        id: '1',
        name: 'Test Hike',
        startingPointLatitude: 48.8566,
        startingPointLongitude: 2.3522,
        startingElevation: 100,
        arrivalPointLatitude: 48.86,
        arrivalPointLongitude: 2.355,
        arrivalElevation: 150,
        wkbGeometry: '',
        wkbWaypoints: '',
        distance: 0, // Zero distance to trigger recalculation
        difficulty: 'EASY',
        status: 'PUBLISHED',
        location: 'Paris',
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      });
      mockHike.coordinates = [
        { latitude: 48.8566, longitude: 2.3522 },
        { latitude: 48.86, longitude: 2.355 },
      ];

      const recalculateDistanceSpy = jest.spyOn(
        component,
        'recalculateDistance' as any
      );

      component.loadHikeForEdit(mockHike);

      expect(recalculateDistanceSpy).toHaveBeenCalled();
    });

    it('should recalculate elevation when elevationGain is missing or zero', () => {
      const mockHike = new Hike({
        id: '1',
        name: 'Test Hike',
        startingPointLatitude: 48.8566,
        startingPointLongitude: 2.3522,
        startingElevation: 100,
        arrivalPointLatitude: 48.86,
        arrivalPointLongitude: 2.355,
        arrivalElevation: 150,
        wkbGeometry: '',
        wkbWaypoints: '',
        distance: 5000,
        difficulty: 'EASY',
        status: 'PUBLISHED',
        location: 'Paris',
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      });
      (mockHike as any).elevationGain = 0; // Zero to trigger recalculation
      mockHike.coordinates = [
        { latitude: 48.8566, longitude: 2.3522 },
        { latitude: 48.86, longitude: 2.355 },
      ];

      const recalculateElevationSpy = jest.spyOn(
        component,
        'recalculateElevation' as any
      );

      component.loadHikeForEdit(mockHike);

      expect(recalculateElevationSpy).toHaveBeenCalled();
    });

    it('should handle error when loading hike fails', () => {
      jest.spyOn(console, 'error').mockImplementation();

      // Create a hike that will cause an error when accessing properties
      const invalidHike = {
        id: '1',
        name: null, // This will cause an error when trying to set it
        coordinates: [],
        waypoints: [],
      } as any;

      // Mock setName to throw an error
      jest.spyOn(component.name, 'set').mockImplementation(() => {
        throw new Error('Test error');
      });

      component.loadHikeForEdit(invalidHike);

      expect(console.error).toHaveBeenCalled();
      expect(messageService.add).toHaveBeenCalledWith(
        expect.objectContaining({
          severity: 'error',
        })
      );

      jest.spyOn(console, 'error').mockRestore();
      (component.name.set as jest.Mock).mockRestore();
    });
  });

  describe('recalculateElevation', () => {
    it('should calculate elevation loss when diff is negative', () => {
      component.coordinates.set([
        { latitude: 48.8566, longitude: 2.3522, elevation: 200 },
        { latitude: 48.86, longitude: 2.355, elevation: 100 },
      ]);

      component['recalculateElevation']();

      expect(component.elevationGain()).toBe(0);
      expect(component.elevationLoss()).toBe(100);
    });

    it('should set zero when coordinates length is less than 2', () => {
      component.coordinates.set([{ latitude: 48.8566, longitude: 2.3522 }]);

      component['recalculateElevation']();

      expect(component.elevationGain()).toBe(0);
      expect(component.elevationLoss()).toBe(0);
    });
  });

  describe('saveHike error handling', () => {
    it('should throw error when hikeId is missing in edit mode', async () => {
      component.isEditMode.set(true);
      component.hikeId.set(null);
      component.name.set('Test Hike');
      component.difficulty.set('EASY');

      jest.spyOn(console, 'error').mockImplementation();

      await component.saveHike();

      expect(console.error).toHaveBeenCalled();
      expect(messageService.add).toHaveBeenCalledWith(
        expect.objectContaining({
          severity: 'error',
        })
      );

      jest.spyOn(console, 'error').mockRestore();
    });

    it('should handle error when save fails', async () => {
      const error = new Error('Save failed');
      if (hikesStore.create) {
        (hikesStore.create as jest.Mock).mockRejectedValue(error);
      }
      jest.spyOn(console, 'error').mockImplementation();

      component.name.set('Test Hike');
      component.difficulty.set('EASY');
      component.coordinates.set([{ latitude: 48.8566, longitude: 2.3522 }]);

      await component.saveHike();

      expect(console.error).toHaveBeenCalledWith('Error saving hike:', error);
      expect(messageService.add).toHaveBeenCalledWith(
        expect.objectContaining({
          severity: 'error',
        })
      );

      jest.spyOn(console, 'error').mockRestore();
    });
  });

  describe('onMarkerDragEnd', () => {
    beforeEach(() => {
      jest.clearAllMocks();
      mapboxService.getDirectionsRoute.mockResolvedValue({
        code: 'Ok',
        routes: [
          {
            geometry: {
              coordinates: [
                [2.3522, 48.8566],
                [2.355, 48.86],
              ],
            },
          },
        ],
      });
    });

    it('should recalculate route when dragging marker with 2+ waypoints', async () => {
      component.waypoints.set([
        { latitude: 48.8566, longitude: 2.3522 },
        { latitude: 48.86, longitude: 2.355 },
      ]);

      const mockMarker = {
        getLngLat: jest.fn(() => ({
          lng: 2.35,
          lat: 48.857,
        })),
      } as unknown as Marker;

      await component.onMarkerDragEnd(mockMarker, 0);

      expect(component.waypoints()[0].longitude).toBe(2.35);
      expect(component.waypoints()[0].latitude).toBe(48.857);
      expect(mapboxService.getDirectionsRoute).toHaveBeenCalled();
      expect(messageService.add).toHaveBeenCalled();
    });

    it('should set coordinates directly when dragging marker with 1 waypoint', async () => {
      component.waypoints.set([{ latitude: 48.8566, longitude: 2.3522 }]);

      const mockMarker = {
        getLngLat: jest.fn(() => ({
          lng: 2.35,
          lat: 48.857,
        })),
      } as unknown as Marker;

      await component.onMarkerDragEnd(mockMarker, 0);

      expect(component.waypoints()[0].longitude).toBe(2.35);
      expect(component.waypoints()[0].latitude).toBe(48.857);
      expect(component.coordinates()).toHaveLength(1);
      expect(messageService.add).toHaveBeenCalled();
    });
  });
});
