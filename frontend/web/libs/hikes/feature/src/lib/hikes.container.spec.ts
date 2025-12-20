import { ComponentFixture, TestBed } from '@angular/core/testing';
import { HikesContainer } from './hikes.container';
import { HikesStore } from '@web/hikes/data-access';
import { Router } from '@angular/router';
import { signal } from '@angular/core';
import { Hike } from '@web/shared/models/settings';
import { MapboxService, MAPBOX_TOKEN } from '@web/shared/util';
import { TranslateModule } from '@ngx-translate/core';
import { NO_ERRORS_SCHEMA } from '@angular/core';

describe('HikesContainer', () => {
  let component: HikesContainer;
  let fixture: ComponentFixture<HikesContainer>;
  let hikesStore: jest.Mocked<Partial<InstanceType<typeof HikesStore>>>;
  let router: jest.Mocked<Router>;

  const mockHikeData = {
    id: '1',
    name: 'Test Hike',
    startingPointLatitude: 48.8566,
    startingPointLongitude: 2.3522,
    startingElevation: 100,
    arrivalPointLatitude: 48.8566,
    arrivalPointLongitude: 2.3522,
    arrivalElevation: 100,
    wkbGeometry: '',
    wkbWaypoints: '',
    distance: 5000,
    difficulty: 'EASY',
    status: 'PUBLISHED',
    source: 'OFFICIAL',
    season: 'SPRING',
    location: 'Paris',
    createdAt: '2024-01-01T00:00:00.000Z',
    updatedAt: '2024-01-01T00:00:00.000Z',
  };
  const mockHike = new Hike(mockHikeData);

  beforeEach(async () => {
    const hikesStoreMock = {
      entities: signal([mockHike]),
      isPending: signal(false),
      latitude: signal(48.8566),
      longitude: signal(2.3522),
      total: signal(1),
      page: signal(1),
      limit: signal(20),
      totalPages: signal(1),
      delete: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      getHikes: jest.fn().mockResolvedValue(undefined),
      setDefaultLocation: jest.fn(),
      setPage: jest.fn(),
      setLimit: jest.fn(),
    };

    const routerMock = {
      navigate: jest.fn(),
    };

    const mapboxServiceMock = {
      getAccessToken: jest.fn(() => 'test-token'),
      getStaticMapUrl: jest.fn(() => 'https://api.mapbox.com/static-map-url'),
      getDirectionsRoute: jest.fn().mockResolvedValue({
        code: 'Ok',
        routes: [
          {
            geometry: {
              coordinates: [
                [1, 1],
                [2, 2],
              ],
            },
          },
        ],
      }),
    } as unknown as jest.Mocked<MapboxService>;

    await TestBed.configureTestingModule({
      imports: [HikesContainer, TranslateModule.forRoot()],
      providers: [
        { provide: HikesStore, useValue: hikesStoreMock },
        { provide: Router, useValue: routerMock },
        { provide: MapboxService, useValue: mapboxServiceMock },
        { provide: MAPBOX_TOKEN, useValue: 'test-token' },
      ],
      schemas: [NO_ERRORS_SCHEMA],
    }).compileComponents();

    fixture = TestBed.createComponent(HikesContainer);
    component = fixture.componentInstance;
    hikesStore = TestBed.inject(HikesStore) as jest.Mocked<
      Partial<InstanceType<typeof HikesStore>>
    >;
    router = TestBed.inject(Router) as jest.Mocked<Router>;
    // Don't call detectChanges() here to avoid rendering mapbox-gl components
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should navigate to edit page when onEditHike is called', () => {
    component.onEditHike(mockHike);
    expect(router.navigate).toHaveBeenCalledWith([
      '/backoffice/hikes/edit',
      '1',
    ]);
  });

  it('should call store delete when onDeleteHike is called', () => {
    component.onDeleteHike(mockHike);
    expect(hikesStore.delete).toHaveBeenCalledWith('1');
  });

  it('should call store update when onSaveHike is called for existing hike', () => {
    component.onSaveHike(mockHike);
    expect(hikesStore.update).toHaveBeenCalledWith(mockHike);
  });

  it('should call store create when onSaveHike is called for new hike', () => {
    hikesStore.entities = signal([]);
    const newHikeData = { ...mockHikeData, id: '2' };
    const newHike = new Hike(newHikeData);
    component.onSaveHike(newHike);
    expect(hikesStore.create).toHaveBeenCalledWith(newHike);
  });

  it('should delete multiple hikes when onDeleteSelectedHikes is called', async () => {
    const mockHike2Data = { ...mockHikeData, id: '2' };
    const mockHike2 = new Hike(mockHike2Data);
    const hikes = [mockHike, mockHike2];
    await component.onDeleteSelectedHikes(hikes);

    expect(hikesStore.delete).toHaveBeenCalledTimes(2);
    expect(hikesStore.delete).toHaveBeenCalledWith('1');
    expect(hikesStore.delete).toHaveBeenCalledWith('2');
  });

  it('should navigate to details page when onViewDetails is called', () => {
    component.onViewDetails(mockHike);
    expect(router.navigate).toHaveBeenCalledWith(['/backoffice/hikes', '1']);
  });

  it('should navigate to new hike page when onNewHike is called', () => {
    component.onNewHike();
    expect(router.navigate).toHaveBeenCalledWith(['/backoffice/hikes/new']);
  });

  it('should set Paris default location and reload hikes', async () => {
    await component.onSetParisDefault();
    expect(hikesStore.setDefaultLocation).toHaveBeenCalledWith(48.8566, 2.3522);
    expect(hikesStore.getHikes).toHaveBeenCalled();
  });

  it('should search by location', async () => {
    const params = { latitude: 50.123, longitude: 3.456, radius: 25 };
    await component.onSearchByLocation(params);

    expect(hikesStore.setDefaultLocation).toHaveBeenCalledWith(50.123, 3.456);
    expect(hikesStore.getHikes).toHaveBeenCalledWith({
      latitude: 50.123,
      longitude: 3.456,
      radius: 25,
    });
  });

  it('should clear location search', async () => {
    await component.onClearLocationSearch();
    expect(hikesStore.getHikes).toHaveBeenCalled();
  });

  it('should open location search when onLocationSearch is called', () => {
    // Mock the locationSearchComponent
    component.locationSearchComponent = {
      open: jest.fn(),
    } as any;
    component.onLocationSearch();
    expect(component.locationSearchComponent.open).toHaveBeenCalled();
  });

  it('should handle page change with location', async () => {
    hikesStore.latitude = signal(48.8566);
    hikesStore.longitude = signal(2.3522);
    const event = { page: 2, rows: 20 };

    await component.onPageChange(event);

    expect(hikesStore.setPage).toHaveBeenCalledWith(2);
    expect(hikesStore.setLimit).toHaveBeenCalledWith(20);
    expect(hikesStore.getHikes).toHaveBeenCalledWith({
      page: 2,
      limit: 20,
      latitude: 48.8566,
      longitude: 2.3522,
      radius: 50,
    });
  });

  it('should handle page change without location', async () => {
    hikesStore.latitude = signal(null);
    hikesStore.longitude = signal(null);
    const event = { page: 2, rows: 20 };

    await component.onPageChange(event);

    expect(hikesStore.setPage).toHaveBeenCalledWith(2);
    expect(hikesStore.setLimit).toHaveBeenCalledWith(20);
    expect(hikesStore.getHikes).toHaveBeenCalledWith({
      page: 2,
      limit: 20,
    });
  });

  it('should handle search change with location', async () => {
    hikesStore.latitude = signal(48.8566);
    hikesStore.longitude = signal(2.3522);
    hikesStore.limit = signal(20);

    await component.onSearchChange('test query');

    expect(hikesStore.setPage).toHaveBeenCalledWith(1);
    expect(hikesStore.getHikes).toHaveBeenCalledWith({
      page: 1,
      limit: 20,
      query: 'test query',
      latitude: 48.8566,
      longitude: 2.3522,
      radius: 50,
    });
  });

  it('should handle search change without location', async () => {
    hikesStore.latitude = signal(null);
    hikesStore.longitude = signal(null);
    hikesStore.limit = signal(20);

    await component.onSearchChange('test query');

    expect(hikesStore.setPage).toHaveBeenCalledWith(1);
    expect(hikesStore.getHikes).toHaveBeenCalledWith({
      page: 1,
      limit: 20,
      query: 'test query',
    });
  });

  it('should handle empty search query', async () => {
    hikesStore.latitude = signal(null);
    hikesStore.longitude = signal(null);
    hikesStore.limit = signal(20);

    await component.onSearchChange('   ');

    expect(hikesStore.getHikes).toHaveBeenCalledWith({
      page: 1,
      limit: 20,
      query: undefined,
    });
  });
});
