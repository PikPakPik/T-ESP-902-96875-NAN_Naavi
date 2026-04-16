import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Pois } from './pois.component';
import { ConfirmationService, MessageService } from 'primeng/api';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { POI } from '@web/shared/models/settings';
import { UsersService } from '@web/users/data-access';
import { Table } from 'primeng/table';
import { NO_ERRORS_SCHEMA } from '@angular/core';
import { of, throwError } from 'rxjs';

describe('Pois', () => {
  let component: Pois;
  let fixture: ComponentFixture<Pois>;
  let confirmationService: ConfirmationService;
  let confirmSpy: jest.SpyInstance;
  let translateService: TranslateService;
  let usersServiceMock: { getUserById: jest.Mock };

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

  let translateServiceMock: { instant: jest.Mock };

  beforeEach(async () => {
    translateServiceMock = {
      instant: jest.fn((key: string) => key),
    };
    usersServiceMock = {
      getUserById: jest.fn(),
    };

    const fullTranslateServiceMock = {
      ...translateServiceMock,
      get: jest.fn(() => ({ subscribe: jest.fn() })),
      currentLang: 'fr',
      onLangChange: { subscribe: jest.fn() },
    };

    await TestBed.configureTestingModule({
      imports: [Pois, TranslateModule.forRoot()],
      providers: [
        { provide: TranslateService, useValue: fullTranslateServiceMock },
        { provide: UsersService, useValue: usersServiceMock },
      ],
      schemas: [NO_ERRORS_SCHEMA],
    })
      .overrideComponent(Pois, {
        set: {
          template: '', // Template vide pour éviter le rendu
          providers: [
            { provide: ConfirmationService, useValue: { confirm: jest.fn() } },
            { provide: MessageService, useValue: { add: jest.fn() } },
          ],
        },
      })
      .compileComponents();

    fixture = TestBed.createComponent(Pois);
    component = fixture.componentInstance;

    // Get the ConfirmationService instance from the component's injector
    confirmationService =
      fixture.debugElement.injector.get(ConfirmationService);
    confirmSpy = jest.spyOn(confirmationService, 'confirm');
    translateService = TestBed.inject(TranslateService);
    // Ne pas appeler detectChanges() pour éviter le rendu du template
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should emit newPOI event when openNew is called', () => {
    const emitSpy = jest.spyOn(component.newPOI, 'emit');
    component.openNew();
    expect(emitSpy).toHaveBeenCalled();
  });

  it('should emit editPOI event when editPOIAction is called', () => {
    const emitSpy = jest.spyOn(component.editPOI, 'emit');
    component.editPOIAction(mockPOI);
    expect(emitSpy).toHaveBeenCalledWith(mockPOI);
  });

  it('should emit deletePOI event when confirming delete', () => {
    const emitSpy = jest.spyOn(component.deletePOI, 'emit');

    component.deletePOIConfirm(mockPOI);

    expect(confirmSpy).toHaveBeenCalled();
    const confirmConfig = confirmSpy.mock.calls[0][0];

    // Simulate accept
    confirmConfig.accept();
    expect(emitSpy).toHaveBeenCalledWith(mockPOI);
  });

  it('should emit deleteSelectedPOIs event when confirming delete selected', () => {
    const emitSpy = jest.spyOn(component.deleteSelectedPOIs, 'emit');
    component.selectedPOIs = [mockPOI];

    component.deleteSelectedPOIsConfirm();

    expect(confirmSpy).toHaveBeenCalled();
    const confirmConfig = confirmSpy.mock.calls[0][0];

    // Simulate accept
    confirmConfig.accept();
    expect(emitSpy).toHaveBeenCalledWith([mockPOI]);
  });

  it('should format types correctly', () => {
    const types = ['RESTAURANT', 'CAFE'];
    const formatted = component.getTypesLabel(types);
    expect(formatted).toBe('RESTAURANT, CAFE');
  });

  describe('clear', () => {
    it('should clear the table', () => {
      const tableMock = {
        clear: jest.fn(),
      } as unknown as Table;

      component.clear(tableMock);

      expect(tableMock.clear).toHaveBeenCalled();
    });
  });

  describe('getSeverity', () => {
    it('should return success for published status', () => {
      expect(component.getSeverity('published')).toBe('success');
      expect(component.getSeverity('PUBLISHED')).toBe('success');
    });

    it('should return warn for draft status', () => {
      expect(component.getSeverity('draft')).toBe('warn');
      expect(component.getSeverity('DRAFT')).toBe('warn');
    });

    it('should return secondary for unpublished status', () => {
      expect(component.getSeverity('unpublished')).toBe('secondary');
      expect(component.getSeverity('UNPUBLISHED')).toBe('secondary');
    });

    it('should return danger for deleted status', () => {
      expect(component.getSeverity('deleted')).toBe('danger');
      expect(component.getSeverity('DELETED')).toBe('danger');
    });

    it('should return secondary for unknown status', () => {
      expect(component.getSeverity('unknown')).toBe('secondary');
      expect(component.getSeverity('')).toBe('secondary');
      expect(component.getSeverity(null)).toBe('secondary');
      expect(component.getSeverity(undefined)).toBe('secondary');
    });
  });

  describe('deletePOIConfirm fallback', () => {
    it('should use fallback header when translation returns undefined', () => {
      jest
        .spyOn(translateService, 'instant')
        .mockImplementation((key: string | string[]) => {
          if (key === 'COMMON.CONFIRM') return undefined as any;
          return key as string;
        });

      component.deletePOIConfirm(mockPOI);

      expect(confirmSpy).toHaveBeenCalled();
      const confirmConfig = confirmSpy.mock.calls[0][0];
      expect(confirmConfig.header).toBe('Confirm');
    });
  });

  describe('deleteSelectedPOIsConfirm fallback', () => {
    it('should use fallback header when translation returns undefined', () => {
      jest
        .spyOn(translateService, 'instant')
        .mockImplementation((key: string | string[]) => {
          if (key === 'COMMON.CONFIRM') return undefined as any;
          return key as string;
        });
      component.selectedPOIs = [mockPOI];

      component.deleteSelectedPOIsConfirm();

      expect(confirmSpy).toHaveBeenCalled();
      const confirmConfig = confirmSpy.mock.calls[0][0];
      expect(confirmConfig.header).toBe('Confirm');
    });
  });

  describe('onSearchChange', () => {
    beforeEach(() => {
      jest.useFakeTimers();
    });

    afterEach(() => {
      jest.useRealTimers();
    });

    it('should emit searchChange after debounce', () => {
      const searchChangeSpy = jest.spyOn(component.searchChange, 'emit');
      const event = {
        target: { value: 'test query' },
      } as unknown as Event;

      component.onSearchChange(event);

      expect(searchChangeSpy).not.toHaveBeenCalled();

      jest.advanceTimersByTime(500);

      expect(searchChangeSpy).toHaveBeenCalledWith('test query');
    });

    it('should cancel previous timeout when called multiple times', () => {
      const searchChangeSpy = jest.spyOn(component.searchChange, 'emit');
      const event1 = {
        target: { value: 'first' },
      } as unknown as Event;
      const event2 = {
        target: { value: 'second' },
      } as unknown as Event;

      component.onSearchChange(event1);
      jest.advanceTimersByTime(300);
      component.onSearchChange(event2);
      jest.advanceTimersByTime(500);

      expect(searchChangeSpy).toHaveBeenCalledTimes(1);
      expect(searchChangeSpy).toHaveBeenCalledWith('second');
    });
  });

  describe('onPageChange', () => {
    it('should emit pageChange with correct page when page is provided', () => {
      const pageChangeSpy = jest.spyOn(component.pageChange, 'emit');
      const event = { first: 0, rows: 10, page: 0 };

      component.onPageChange(event);

      expect(pageChangeSpy).toHaveBeenCalledWith({ page: 1, rows: 10 });
    });

    it('should calculate page from first and rows when page is not provided', () => {
      const pageChangeSpy = jest.spyOn(component.pageChange, 'emit');
      const event = { first: 20, rows: 10 };

      component.onPageChange(event);

      expect(pageChangeSpy).toHaveBeenCalledWith({ page: 3, rows: 10 });
    });

    it('should handle page 0 correctly', () => {
      const pageChangeSpy = jest.spyOn(component.pageChange, 'emit');
      const event = { first: 0, rows: 10 };

      component.onPageChange(event);

      expect(pageChangeSpy).toHaveBeenCalledWith({ page: 1, rows: 10 });
    });
  });

  it('should emit approvePOI for selected detail POI', () => {
    const emitSpy = jest.spyOn(component.approvePOI, 'emit');
    component.selectedPOIForDetail.set(mockPOI);

    component.approveSelectedPOI();

    expect(emitSpy).toHaveBeenCalledWith(mockPOI);
  });

  it('should emit rejectPOI for selected detail POI', () => {
    const emitSpy = jest.spyOn(component.rejectPOI, 'emit');
    component.selectedPOIForDetail.set(mockPOI);

    component.rejectSelectedPOI();

    expect(emitSpy).toHaveBeenCalledWith(mockPOI);
  });

  it('should not emit approvePOI when no detail POI is selected', () => {
    const emitSpy = jest.spyOn(component.approvePOI, 'emit');

    component.approveSelectedPOI();

    expect(emitSpy).not.toHaveBeenCalled();
  });

  it('should not emit rejectPOI when no detail POI is selected', () => {
    const emitSpy = jest.spyOn(component.rejectPOI, 'emit');

    component.rejectSelectedPOI();

    expect(emitSpy).not.toHaveBeenCalled();
  });

  it('should open and close detail dialog', async () => {
    usersServiceMock.getUserById.mockReturnValue(
      throwError(() => new Error('not found'))
    );

    await component.openDetail(mockPOI);
    expect(component.selectedPOIForDetail()).toEqual(mockPOI);

    component.closeDetail();
    expect(component.selectedPOIForDetail()).toBeNull();
    expect(component.ownerDisplay()).toBe('');
  });

  it('should resolve owner display from user service', async () => {
    const communityPoi = new POI({
      id: '2',
      name: 'Community POI',
      description: 'A community POI',
      source: 'COMMUNITY',
      userId: '16',
      types: ['RESTAURANT'],
      photos: [],
      images: [],
      latitude: 48.8566,
      longitude: 2.3522,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      status: 'DRAFT',
    });
    usersServiceMock.getUserById.mockReturnValue(
      of({
        id: '16',
        firstname: 'Jean',
        lastname: 'Dupont',
      })
    );

    await component.openDetail(communityPoi);

    expect(component.ownerDisplay()).toBe('(#16) DUPONT Jean');
  });

  it('should fall back to source label when there is no owner id', async () => {
    const officialPoi = new POI({
      id: '3',
      name: 'Official POI',
      description: 'An official POI',
      source: 'OFFICIAL',
      userId: null,
      types: ['RESTAURANT'],
      photos: [],
      images: [],
      latitude: 48.8566,
      longitude: 2.3522,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      status: 'PUBLISHED',
    });

    await component.openDetail(officialPoi);

    expect(component.ownerDisplay()).toBe('HIKE.SOURCE.OFFICIAL');
  });

  it('should return official source translation key by default', () => {
    expect(component.getSourceTranslationKey(undefined)).toBe(
      'HIKE.SOURCE.OFFICIAL'
    );
  });

  it('should show unknown user fallback when owner lookup fails', async () => {
    const communityPoi = new POI({
      id: '4',
      name: 'Fallback POI',
      description: 'Fallback owner',
      source: 'COMMUNITY',
      userId: '42',
      types: ['RESTAURANT'],
      photos: [],
      images: [],
      latitude: 48.8566,
      longitude: 2.3522,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      status: 'DRAFT',
    });
    usersServiceMock.getUserById.mockReturnValue(
      throwError(() => new Error('not found'))
    );

    await component.openDetail(communityPoi);

    expect(component.ownerDisplay()).toBe('(#42) Utilisateur introuvable');
  });

  it('should emit status filter changes', () => {
    const emitSpy = jest.spyOn(component.statusFilterChange, 'emit');

    component.applyStatusFilter('DRAFT');
    component.applyStatusFilter(null);

    expect(emitSpy).toHaveBeenNthCalledWith(1, 'DRAFT');
    expect(emitSpy).toHaveBeenNthCalledWith(2, null);
  });

  it('should return the POI category translation key', () => {
    expect(component.getCategoryTranslationKey('RESTAURANT')).toBe(
      'POI.CATEGORY.RESTAURANT'
    );
  });

  describe('displayPOIMap', () => {
    beforeEach(() => {
      jest.useFakeTimers();
      const mapPopoverMock = {
        show: jest.fn(),
        hide: jest.fn(),
      };
      component.mapPopover = mapPopoverMock as any;
    });

    afterEach(() => {
      jest.useRealTimers();
    });

    it('should toggle map when clicking on same POI', () => {
      const mockEvent = {} as MouseEvent;
      component.currentPOIForMap.set(mockPOI);

      component.displayPOIMap(mockEvent, mockPOI);

      expect(component.currentPOIForMap()).toBeNull();
      expect(component.mapKey()).toBe('');
      expect(component.mapPopover.hide).toHaveBeenCalled();
    });

    it('should show map for different POI when no map is currently shown', () => {
      const mockEvent = {} as MouseEvent;
      component.currentPOIForMap.set(null);

      component.displayPOIMap(mockEvent, mockPOI);

      expect(component.currentPOIForMap()).toEqual(mockPOI);
      expect(component.mapKey()).toContain(`map-${mockPOI.id}`);
      expect(component.mapPopover.show).toHaveBeenCalledWith(mockEvent);
    });

    it('should close current map and open new one when switching POIs', () => {
      const mockEvent = {} as MouseEvent;
      const otherPOI = new POI({
        id: '2',
        name: 'Other POI',
        description: 'Another test POI',
        types: ['CAFE'],
        photos: [],
        latitude: 48.8606,
        longitude: 2.3376,
        comment: 'Test comment',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        status: 'ACTIVE',
      });
      component.currentPOIForMap.set(otherPOI);

      component.displayPOIMap(mockEvent, mockPOI);

      expect(component.mapPopover.hide).toHaveBeenCalled();

      jest.advanceTimersByTime(150);

      expect(component.currentPOIForMap()).toEqual(mockPOI);
      expect(component.mapKey()).toContain(`map-${mockPOI.id}`);
      expect(component.mapPopover.show).toHaveBeenCalledWith(mockEvent);
    });
  });
});
