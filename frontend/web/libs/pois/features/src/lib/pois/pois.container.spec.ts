import { ComponentFixture, TestBed } from '@angular/core/testing';
import { PoisContainer } from './pois.container';
import { POIsStore } from '@web/pois/data-access';
import { Router } from '@angular/router';
import { signal } from '@angular/core';
import { POI } from '@web/shared/models/settings';
import { TranslateModule } from '@ngx-translate/core';
import { NO_ERRORS_SCHEMA } from '@angular/core';

describe('PoisContainer', () => {
  let component: PoisContainer;
  let fixture: ComponentFixture<PoisContainer>;
  let poisStore: jest.Mocked<Partial<InstanceType<typeof POIsStore>>>;
  let router: jest.Mocked<Router>;

  const mockPOI = new POI({
    id: '1',
    name: 'Test POI',
    description: 'A test POI',
    types: ['RESTAURANT'],
    photos: [],
    latitude: 48.8566,
    longitude: 2.3522,
    comment: 'Test comment',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    status: 'ACTIVE',
  });

  beforeEach(async () => {
    const poisStoreMock = {
      entities: signal([mockPOI]),
      isPending: signal(false),
      total: signal(1),
      page: signal(1),
      limit: signal(20),
      totalPages: signal(1),
      latitude: signal(null),
      longitude: signal(null),
      delete: jest.fn(),
      getPOIs: jest.fn().mockResolvedValue(undefined),
      setPage: jest.fn(),
      setLimit: jest.fn(),
      setDefaultLocation: jest.fn(),
    };

    const routerMock = {
      navigate: jest.fn(),
    };

    await TestBed.configureTestingModule({
      imports: [PoisContainer, TranslateModule.forRoot()],
      providers: [
        { provide: POIsStore, useValue: poisStoreMock },
        { provide: Router, useValue: routerMock },
      ],
      schemas: [NO_ERRORS_SCHEMA],
    }).compileComponents();

    fixture = TestBed.createComponent(PoisContainer);
    component = fixture.componentInstance;
    poisStore = TestBed.inject(POIsStore) as jest.Mocked<
      Partial<InstanceType<typeof POIsStore>>
    >;
    router = TestBed.inject(Router) as jest.Mocked<Router>;
    // Don't call detectChanges() here to avoid rendering mapbox-gl components
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should navigate to new POI page when onNewPOI is called', () => {
    component.onNewPOI();
    expect(router.navigate).toHaveBeenCalledWith(['/backoffice/pois/new']);
  });

  it('should navigate to edit page when onEditPOI is called', () => {
    component.onEditPOI(mockPOI);
    expect(router.navigate).toHaveBeenCalledWith([
      '/backoffice/pois/edit',
      mockPOI.id,
    ]);
  });

  it('should call store delete when onDeletePOI is called', () => {
    component.onDeletePOI(mockPOI);
    expect(poisStore.delete).toHaveBeenCalledWith(mockPOI.id);
  });

  it('should delete multiple POIs when onDeleteSelectedPOIs is called', async () => {
    const mockPOI2 = new POI({
      id: '2',
      name: 'Test POI 2',
      description: 'A test POI 2',
      types: ['CAFE'],
      photos: [],
      latitude: 48.8566,
      longitude: 2.3522,
      comment: 'Test comment 2',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      status: 'ACTIVE',
    });
    const pois = [mockPOI, mockPOI2];
    await component.onDeleteSelectedPOIs(pois);

    expect(poisStore.delete).toHaveBeenCalledTimes(2);
    expect(poisStore.delete).toHaveBeenCalledWith(mockPOI.id);
    expect(poisStore.delete).toHaveBeenCalledWith(mockPOI2.id);
  });

  it('should open location search when onLocationSearch is called', () => {
    // Mock the locationSearchComponent
    component.locationSearchComponent = {
      open: jest.fn(),
    } as any;
    component.onLocationSearch();
    expect(component.locationSearchComponent.open).toHaveBeenCalled();
  });

  it('should search by location', async () => {
    const params = { latitude: 50.123, longitude: 3.456, radius: 25 };
    await component.onSearchByLocation(params);

    expect(poisStore.setDefaultLocation).toHaveBeenCalledWith(50.123, 3.456);
    expect(poisStore.getPOIs).toHaveBeenCalledWith({
      latitude: 50.123,
      longitude: 3.456,
      radius: 25,
    });
  });

  it('should clear location search', async () => {
    await component.onClearLocationSearch();
    expect(poisStore.getPOIs).toHaveBeenCalled();
  });

  it('should set Paris default location and reload POIs', async () => {
    await component.onSetParisDefault();
    expect(poisStore.setDefaultLocation).toHaveBeenCalledWith(48.8566, 2.3522);
    expect(poisStore.getPOIs).toHaveBeenCalled();
  });

  it('should handle page change with location', async () => {
    poisStore.latitude = signal(48.8566);
    poisStore.longitude = signal(2.3522);
    const event = { page: 2, rows: 20 };

    await component.onPageChange(event);

    expect(poisStore.setPage).toHaveBeenCalledWith(2);
    expect(poisStore.setLimit).toHaveBeenCalledWith(20);
    expect(poisStore.getPOIs).toHaveBeenCalledWith({
      page: 2,
      limit: 20,
      latitude: 48.8566,
      longitude: 2.3522,
      radius: 20,
    });
  });

  it('should handle page change without location', async () => {
    poisStore.latitude = signal(null);
    poisStore.longitude = signal(null);
    const event = { page: 2, rows: 20 };

    await component.onPageChange(event);

    expect(poisStore.setPage).toHaveBeenCalledWith(2);
    expect(poisStore.setLimit).toHaveBeenCalledWith(20);
    expect(poisStore.getPOIs).toHaveBeenCalledWith({
      page: 2,
      limit: 20,
    });
  });

  it('should handle search change with location', async () => {
    poisStore.latitude = signal(48.8566);
    poisStore.longitude = signal(2.3522);
    poisStore.limit = signal(20);

    await component.onSearchChange('test query');

    expect(poisStore.setPage).toHaveBeenCalledWith(1);
    expect(poisStore.getPOIs).toHaveBeenCalledWith({
      page: 1,
      limit: 20,
      query: 'test query',
      latitude: 48.8566,
      longitude: 2.3522,
      radius: 20,
    });
  });

  it('should handle search change without location', async () => {
    poisStore.latitude = signal(null);
    poisStore.longitude = signal(null);
    poisStore.limit = signal(20);

    await component.onSearchChange('test query');

    expect(poisStore.setPage).toHaveBeenCalledWith(1);
    expect(poisStore.getPOIs).toHaveBeenCalledWith({
      page: 1,
      limit: 20,
      query: 'test query',
    });
  });

  it('should handle empty search query', async () => {
    poisStore.latitude = signal(null);
    poisStore.longitude = signal(null);
    poisStore.limit = signal(20);

    await component.onSearchChange('   ');

    expect(poisStore.getPOIs).toHaveBeenCalledWith({
      page: 1,
      limit: 20,
      query: undefined,
    });
  });
});
