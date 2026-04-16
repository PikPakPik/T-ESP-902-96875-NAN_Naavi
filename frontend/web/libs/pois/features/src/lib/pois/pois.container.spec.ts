import { ComponentFixture, TestBed } from '@angular/core/testing';
import { PoisContainer } from './pois.container';
import { POIsStore } from '@web/pois/data-access';
import { Router } from '@angular/router';
import { signal } from '@angular/core';
import { POI } from '@web/shared/models/settings';
import { TranslateModule } from '@ngx-translate/core';
import { NO_ERRORS_SCHEMA } from '@angular/core';
import { UsersService } from '@web/users/data-access';

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
    images: [],
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
      pendingApprovalCount: signal(1),
      selectedStatus: signal(null),
      delete: jest.fn(),
      update: jest.fn().mockResolvedValue(undefined),
      getPOIs: jest.fn().mockResolvedValue(undefined),
      loadPendingApprovalCount: jest.fn().mockResolvedValue(undefined),
      setPage: jest.fn(),
      setLimit: jest.fn(),
      setSelectedStatus: jest.fn(),
    };

    const routerMock = {
      navigate: jest.fn(),
    };

    await TestBed.configureTestingModule({
      imports: [PoisContainer, TranslateModule.forRoot()],
      providers: [
        { provide: POIsStore, useValue: poisStoreMock },
        { provide: Router, useValue: routerMock },
        {
          provide: UsersService,
          useValue: { getUserById: jest.fn() },
        },
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
      images: [],
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

  it('should approve a POI', async () => {
    await component.onApprovePOI(mockPOI);
    expect(poisStore.update).toHaveBeenCalledWith({
      id: mockPOI.id,
      name: mockPOI.name,
      description: mockPOI.description,
      categories: mockPOI.types,
      latitude: mockPOI.latitude,
      longitude: mockPOI.longitude,
      comment: mockPOI.comment,
      source: mockPOI.source,
      userId: undefined,
      createdAt: mockPOI.createdAt.toISOString(),
      updatedAt: mockPOI.updatedAt.toISOString(),
      status: 'PUBLISHED',
    });
    expect(poisStore.loadPendingApprovalCount).toHaveBeenCalled();
  });

  it('should reject a POI', async () => {
    await component.onRejectPOI(mockPOI);
    expect(poisStore.update).toHaveBeenCalledWith({
      id: mockPOI.id,
      name: mockPOI.name,
      description: mockPOI.description,
      categories: mockPOI.types,
      latitude: mockPOI.latitude,
      longitude: mockPOI.longitude,
      comment: mockPOI.comment,
      source: mockPOI.source,
      userId: undefined,
      createdAt: mockPOI.createdAt.toISOString(),
      updatedAt: mockPOI.updatedAt.toISOString(),
      status: 'UNPUBLISHED',
    });
    expect(poisStore.loadPendingApprovalCount).toHaveBeenCalled();
    expect(poisStore.getPOIs).toHaveBeenCalled();
  });

  it('should keep community owner data in moderation payload', async () => {
    const communityPoi = new POI({
      id: '9',
      name: 'Community POI',
      description: 'A test community POI',
      source: 'COMMUNITY',
      userId: '17',
      types: ['CAFE'],
      photos: [],
      images: [],
      latitude: 48.8566,
      longitude: 2.3522,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      status: 'DRAFT',
    });

    await component.onApprovePOI(communityPoi);

    expect(poisStore.update).toHaveBeenCalledWith({
      id: communityPoi.id,
      name: communityPoi.name,
      description: communityPoi.description,
      categories: communityPoi.types,
      latitude: communityPoi.latitude,
      longitude: communityPoi.longitude,
      comment: communityPoi.comment,
      source: 'COMMUNITY',
      userId: '17',
      createdAt: communityPoi.createdAt.toISOString(),
      updatedAt: communityPoi.updatedAt.toISOString(),
      status: 'PUBLISHED',
    });
  });

  it('should handle page change with location', async () => {
    const event = { page: 2, rows: 20 };

    await component.onPageChange(event);

    expect(poisStore.setPage).toHaveBeenCalledWith(2);
    expect(poisStore.setLimit).toHaveBeenCalledWith(20);
    expect(poisStore.getPOIs).toHaveBeenCalledWith({
      page: 2,
      limit: 20,
      status: undefined,
    });
  });

  it('should keep selected status on page change when a filter is active', async () => {
    poisStore.selectedStatus = signal('DRAFT');

    await component.onPageChange({ page: 3, rows: 10 });

    expect(poisStore.getPOIs).toHaveBeenCalledWith({
      page: 3,
      limit: 10,
      status: 'DRAFT',
    });
  });

  it('should handle search change', async () => {
    poisStore.limit = signal(20);

    await component.onSearchChange('test query');

    expect(poisStore.setPage).toHaveBeenCalledWith(1);
    expect(poisStore.getPOIs).toHaveBeenCalledWith({
      page: 1,
      limit: 20,
      query: 'test query',
      status: undefined,
    });
  });

  it('should keep selected status on search change when a filter is active', async () => {
    poisStore.limit = signal(20);
    poisStore.selectedStatus = signal('DRAFT');

    await component.onSearchChange('test query');

    expect(poisStore.getPOIs).toHaveBeenCalledWith({
      page: 1,
      limit: 20,
      query: 'test query',
      status: 'DRAFT',
    });
  });

  it('should handle empty search query', async () => {
    poisStore.limit = signal(20);

    await component.onSearchChange('   ');

    expect(poisStore.getPOIs).toHaveBeenCalledWith({
      page: 1,
      limit: 20,
      query: undefined,
      status: undefined,
    });
  });

  it('should change status filter', async () => {
    poisStore.limit = signal(20);

    await component.onStatusFilterChange('DRAFT');

    expect(poisStore.setSelectedStatus).toHaveBeenCalledWith('DRAFT');
    expect(poisStore.setPage).toHaveBeenCalledWith(1);
    expect(poisStore.getPOIs).toHaveBeenCalledWith({
      page: 1,
      limit: 20,
      status: 'DRAFT',
    });
  });

  it('should reset status filter to all', async () => {
    poisStore.limit = signal(20);

    await component.onStatusFilterChange(null);

    expect(poisStore.setSelectedStatus).toHaveBeenCalledWith(null);
    expect(poisStore.setPage).toHaveBeenCalledWith(1);
    expect(poisStore.getPOIs).toHaveBeenCalledWith({
      page: 1,
      limit: 20,
      status: undefined,
    });
  });
});
