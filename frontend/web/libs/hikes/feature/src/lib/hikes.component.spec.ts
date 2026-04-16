import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Hikes } from './hikes.component';
import { ConfirmationService } from 'primeng/api';
import { MapboxService } from '@web/shared/util';
import { TranslateModule } from '@ngx-translate/core';
import { Hike, User } from '@web/shared/models/settings';
import { of, Subject, throwError } from 'rxjs';
import { Table } from 'primeng/table';
import { UsersService } from '@web/users/data-access';

describe('Hikes Component', () => {
  let component: Hikes;
  let fixture: ComponentFixture<Hikes>;
  let confirmationService: jest.Mocked<ConfirmationService>;
  let usersService: jest.Mocked<UsersService>;

  const mockHike = new Hike({
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
    seasons: ['SPRING'],
    location: 'Paris',
    createdAt: '2024-01-01T00:00:00.000Z',
    updatedAt: '2024-01-01T00:00:00.000Z',
  });

  beforeEach(async () => {
    // Create a Subject for the confirmation observable that ConfirmDialog needs
    const confirmationSubject = new Subject();
    const confirmationServiceMock = {
      confirm: jest.fn(),
      confirmation$: confirmationSubject.asObservable(),
      requireConfirmation$: confirmationSubject.asObservable(),
    } as unknown as jest.Mocked<ConfirmationService>;

    const mapboxServiceMock = {
      getStaticMapUrl: jest.fn(() => 'https://api.mapbox.com/static-map-url'),
    } as unknown as jest.Mocked<MapboxService>;

    const usersServiceMock = {
      getUserById: jest.fn(),
    } as unknown as jest.Mocked<UsersService>;

    await TestBed.configureTestingModule({
      imports: [Hikes, TranslateModule.forRoot()],
      providers: [
        { provide: MapboxService, useValue: mapboxServiceMock },
        { provide: UsersService, useValue: usersServiceMock },
      ],
    })
      .overrideComponent(Hikes, {
        set: {
          template: '', // Template vide pour éviter le rendu
          providers: [
            { provide: ConfirmationService, useValue: confirmationServiceMock },
          ],
        },
      })
      .compileComponents();

    fixture = TestBed.createComponent(Hikes);
    component = fixture.componentInstance;
    // Get ConfirmationService from component's injector (it's provided at component level)
    confirmationService = fixture.debugElement.injector.get(
      ConfirmationService
    ) as jest.Mocked<ConfirmationService>;
    usersService = TestBed.inject(UsersService) as jest.Mocked<UsersService>;
    // Ne pas appeler detectChanges() pour éviter le rendu du template
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should emit newHike event when openNewDialog is called', () => {
    const emitSpy = jest.spyOn(component.newHike, 'emit');
    component.openNewDialog();
    expect(emitSpy).toHaveBeenCalled();
  });

  it('should emit setParisDefault event when setParisLocation is called', () => {
    const emitSpy = jest.spyOn(component.setParisDefault, 'emit');
    component.setParisLocation();
    expect(emitSpy).toHaveBeenCalled();
  });

  it('should emit deleteHike event when confirming delete', () => {
    const emitSpy = jest.spyOn(component.deleteHike, 'emit');

    component.deleteHikeConfirm(mockHike);

    expect(confirmationService.confirm).toHaveBeenCalled();
    const confirmConfig = (confirmationService.confirm as jest.Mock).mock
      .calls[0][0];
    // Le message est traduit, donc il contiendra soit la clé soit le texte traduit avec le nom
    expect(confirmConfig.message).toBeDefined();

    // Simulate accept
    confirmConfig.accept();
    expect(emitSpy).toHaveBeenCalledWith(mockHike);
  });

  it('should emit deleteSelectedHikes event when confirming delete selected', () => {
    const emitSpy = jest.spyOn(component.deleteSelectedHikes, 'emit');
    component.selectedHikes = [mockHike];

    component.deleteSelectedHikesConfirm();

    expect(confirmationService.confirm).toHaveBeenCalled();
    const confirmConfig = (confirmationService.confirm as jest.Mock).mock
      .calls[0][0];

    // Simulate accept
    confirmConfig.accept();
    expect(emitSpy).toHaveBeenCalledWith([mockHike]);
  });

  it('should emit viewDetails event when viewDetailsClick is called', () => {
    const emitSpy = jest.spyOn(component.viewDetails, 'emit');
    component.viewDetailsClick(mockHike);
    expect(emitSpy).toHaveBeenCalledWith(mockHike);
  });

  describe('getOwnerLabel', () => {
    it('should return Officielle when hike has no userId', () => {
      expect(component.getOwnerLabel(mockHike)).toBe('Officielle');
    });

    it('should resolve and cache the owner full name', async () => {
      const communityHike = new Hike({
        ...mockHike,
        id: '2',
        userId: '16',
        source: 'COMMUNITY',
      });
      const owner = new User({
        id: '16',
        fullName: 'Jean Dupont',
        firstname: 'Jean',
        lastname: 'Dupont',
        email: 'jean.dupont@example.com',
        roles: ['USER'],
        status: 'ACTIVE',
      });

      usersService.getUserById.mockReturnValue(of(owner));

      fixture.componentRef.setInput('rows', [communityHike]);
      fixture.detectChanges();
      await fixture.whenStable();

      expect(usersService.getUserById).toHaveBeenCalledWith('16');
      expect(component.getOwnerLabel(communityHike)).toBe('Jean Dupont');

      fixture.componentRef.setInput('rows', [communityHike]);
      fixture.detectChanges();
      await fixture.whenStable();

      expect(usersService.getUserById).toHaveBeenCalledTimes(1);
    });

    it('should fallback to a readable label when owner lookup fails', async () => {
      const communityHike = new Hike({
        ...mockHike,
        id: '3',
        userId: '42',
        source: 'COMMUNITY',
      });

      usersService.getUserById.mockReturnValue(
        throwError(() => new Error('not found'))
      );

      fixture.componentRef.setInput('rows', [communityHike]);
      fixture.detectChanges();
      await fixture.whenStable();

      expect(component.getOwnerLabel(communityHike)).toBe('Utilisateur #42');
    });
  });

  // Tests removed: coordinatesToGeoJSON, getMapCenter, getMapBounds, getMapboxUrl methods don't exist on Hikes component
  // These methods exist on HikeMapComponent instead

  describe('clear', () => {
    it('should clear the table', () => {
      const tableMock = {
        clear: jest.fn(),
      } as unknown as Table;

      component.clear(tableMock);

      expect(tableMock.clear).toHaveBeenCalled();
    });
  });

  describe('openNew', () => {
    it('should initialize new hike and open dialog', () => {
      component.openNew();

      expect(component.hike()).toEqual({
        id: '',
        name: '',
        difficulty: 'Facile',
        distance: 0,
        location: '',
        status: 'ACTIVE',
      });
      expect(component.hikeDialog()).toBe(true);
      expect(component.submitted()).toBe(false);
    });
  });

  describe('editHikeDialog', () => {
    it('should set hike and open dialog', () => {
      component.editHikeDialog(mockHike);

      expect(component.hike()).toEqual(mockHike);
      expect(component.hikeDialog()).toBe(true);
    });
  });

  describe('hideDialog', () => {
    it('should hide dialog and reset submitted', () => {
      component.hikeDialog.set(true);
      component.submitted.set(true);

      component.hideDialog();

      expect(component.hikeDialog()).toBe(false);
      expect(component.submitted()).toBe(false);
    });
  });

  describe('saveHikeDialog', () => {
    beforeEach(() => {
      jest.clearAllMocks();
    });

    it('should emit saveHike and close dialog when form is valid', () => {
      const saveHikeSpy = jest.spyOn(component.saveHike, 'emit');
      component.hike.set({
        ...mockHike,
        name: 'Test Hike',
        difficulty: 'EASY',
      });
      component.hikeDialog.set(true);
      component.submitted.set(false);

      component.saveHikeDialog();

      expect(saveHikeSpy).toHaveBeenCalled();
      expect(component.hikeDialog()).toBe(false);
      expect(component.hike()).toEqual({});
      expect(component.submitted()).toBe(true);
    });

    it('should not save when name is empty', () => {
      const saveHikeSpy = jest.spyOn(component.saveHike, 'emit');
      component.hike.set({
        ...mockHike,
        name: '',
        difficulty: 'EASY',
      });

      component.saveHikeDialog();

      expect(saveHikeSpy).not.toHaveBeenCalled();
      expect(component.submitted()).toBe(true);
    });

    it('should not save when name is only whitespace', () => {
      const saveHikeSpy = jest.spyOn(component.saveHike, 'emit');
      component.hike.set({
        ...mockHike,
        name: '   ',
        difficulty: 'EASY',
      });

      component.saveHikeDialog();

      expect(saveHikeSpy).not.toHaveBeenCalled();
    });

    it('should not save when difficulty is empty', () => {
      const saveHikeSpy = jest.spyOn(component.saveHike, 'emit');
      component.hike.set({
        ...mockHike,
        name: 'Test Hike',
        difficulty: '',
      });

      component.saveHikeDialog();

      expect(saveHikeSpy).not.toHaveBeenCalled();
    });
  });

  describe('displayHikeMap', () => {
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

    it('should toggle map when clicking on same hike', () => {
      const mockEvent = {} as MouseEvent;
      component.currentHikeForMap.set(mockHike);

      component.displayHikeMap(mockEvent, mockHike);

      expect(component.currentHikeForMap()).toBeNull();
      expect(component.mapKey()).toBe('');
      expect(component.mapPopover.hide).toHaveBeenCalled();
    });

    it('should show map for different hike when no map is currently shown', () => {
      const mockEvent = {} as MouseEvent;
      component.currentHikeForMap.set(null);

      component.displayHikeMap(mockEvent, mockHike);

      expect(component.currentHikeForMap()).toEqual(mockHike);
      expect(component.mapKey()).toContain(`map-${mockHike.id}`);
      expect(component.mapPopover.show).toHaveBeenCalledWith(mockEvent);
    });

    it('should close current map and open new one when switching hikes', () => {
      const mockEvent = {} as MouseEvent;
      const otherHike = new Hike({
        id: '2',
        name: 'Other Hike',
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
        seasons: ['SPRING'],
        location: 'Paris',
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      });
      component.currentHikeForMap.set(otherHike);

      component.displayHikeMap(mockEvent, mockHike);

      expect(component.mapPopover.hide).toHaveBeenCalled();

      jest.advanceTimersByTime(150);

      expect(component.currentHikeForMap()).toEqual(mockHike);
      expect(component.mapKey()).toContain(`map-${mockHike.id}`);
      expect(component.mapPopover.show).toHaveBeenCalledWith(mockEvent);
    });
  });

  describe('onSearchChange', () => {
    beforeEach(() => {
      jest.useFakeTimers();
    });

    afterEach(() => {
      jest.useRealTimers();
    });

    it('should debounce and emit the latest search value', () => {
      const emitSpy = jest.spyOn(component.searchChange, 'emit');
      const firstEvent = { target: { value: 'alp' } } as unknown as Event;
      const secondEvent = { target: { value: 'alps' } } as unknown as Event;

      component.onSearchChange(firstEvent);
      component.onSearchChange(secondEvent);

      jest.advanceTimersByTime(499);
      expect(emitSpy).not.toHaveBeenCalled();

      jest.advanceTimersByTime(1);
      expect(emitSpy).toHaveBeenCalledTimes(1);
      expect(emitSpy).toHaveBeenCalledWith('alps');
    });
  });

  describe('onPageChange', () => {
    it('should emit the explicit page when PrimeNG provides it', () => {
      const emitSpy = jest.spyOn(component.pageChange, 'emit');

      component.onPageChange({ first: 20, rows: 10, page: 2 });

      expect(emitSpy).toHaveBeenCalledWith({ page: 3, rows: 10 });
    });

    it('should compute the page from first and rows when page is absent', () => {
      const emitSpy = jest.spyOn(component.pageChange, 'emit');

      component.onPageChange({ first: 40, rows: 20 });

      expect(emitSpy).toHaveBeenCalledWith({ page: 3, rows: 20 });
    });
  });

  describe('getVisibilityLabel', () => {
    it('should return Public by default', () => {
      expect(component.getVisibilityLabel(undefined)).toBe('Public');
    });

    it('should return the translated labels for known visibilities', () => {
      expect(component.getVisibilityLabel('PRIVATE')).toBe('Privé');
      expect(component.getVisibilityLabel('UNLISTED')).toBe('Non listée');
    });

    it('should return the raw value for unknown visibilities', () => {
      expect(component.getVisibilityLabel('TEAM_ONLY')).toBe('TEAM_ONLY');
    });
  });

  // Tests removed: getMapCenter method doesn't exist on Hikes component

  describe('calculateElevation', () => {
    it('should return zero gain and loss when coordinates are less than 2', () => {
      const result = component.calculateElevation([]);
      expect(result).toEqual({ gain: 0, loss: 0 });

      const result2 = component.calculateElevation([
        { latitude: 48.8566, longitude: 2.3522 },
      ]);
      expect(result2).toEqual({ gain: 0, loss: 0 });
    });

    it('should calculate elevation gain correctly', () => {
      const coords = [
        { latitude: 48.8566, longitude: 2.3522, elevation: 100 },
        { latitude: 48.86, longitude: 2.355, elevation: 200 },
        { latitude: 48.865, longitude: 2.36, elevation: 150 },
      ];

      const result = component.calculateElevation(coords);

      expect(result.gain).toBe(100); // 200 - 100 = 100
      expect(result.loss).toBe(50); // 200 - 150 = 50
    });

    it('should handle missing elevation values', () => {
      const coords = [
        { latitude: 48.8566, longitude: 2.3522, elevation: 100 },
        { latitude: 48.86, longitude: 2.355 }, // pas d'élévation (0 par défaut)
        { latitude: 48.865, longitude: 2.36, elevation: 150 },
      ];

      const result = component.calculateElevation(coords);

      // 0 - 100 = -100 (loss), puis 150 - 0 = 150 (gain)
      expect(result.gain).toBe(150);
      expect(result.loss).toBe(100);
    });
  });

  describe('getElevationGain', () => {
    it('should prioritize positive cumulative elevation from coordinates', () => {
      const hike = new Hike({
        id: '4',
        name: 'Elevation Hike',
        startingPointLatitude: 48.8566,
        startingPointLongitude: 2.3522,
        startingElevation: 100,
        arrivalPointLatitude: 48.8566,
        arrivalPointLongitude: 2.3522,
        arrivalElevation: 120,
        wkbGeometry: '',
        wkbWaypoints: '',
        distance: 5000,
        difficulty: 'EASY',
        status: 'PUBLISHED',
        source: 'OFFICIAL',
        seasons: ['SPRING'],
        location: 'Paris',
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      });
      hike.coordinates = [
        { latitude: 48.8566, longitude: 2.3522, elevation: 100 },
        { latitude: 48.86, longitude: 2.355, elevation: 180 },
        { latitude: 48.865, longitude: 2.36, elevation: 140 },
      ];
      hike.elevationGain = 50;

      expect(component.getElevationGain(hike)).toBe(80);
    });

    it('should use elevationGain from hike when available', () => {
      // Set elevationGain directly on the hike instance
      (mockHike as any).elevationGain = 500;

      const result = component.getElevationGain(mockHike);

      expect(result).toBe(500);
    });

    it('should calculate from starting and arrival elevation', () => {
      const hike = new Hike({
        id: '1',
        name: 'Test Hike',
        startingPointLatitude: 48.8566,
        startingPointLongitude: 2.3522,
        startingElevation: 100,
        arrivalPointLatitude: 48.8566,
        arrivalPointLongitude: 2.3522,
        arrivalElevation: 350,
        wkbGeometry: '',
        wkbWaypoints: '',
        distance: 5000,
        difficulty: 'EASY',
        status: 'PUBLISHED',
        source: 'OFFICIAL',
        seasons: ['SPRING'],
        location: 'Paris',
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      });
      (hike as any).elevationGain = undefined;

      const result = component.getElevationGain(hike);

      expect(result).toBe(250); // 350 - 100
    });

    it('should return 0 when no elevation data is available', () => {
      const hike = new Hike({
        id: '1',
        name: 'Test Hike',
        startingPointLatitude: 48.8566,
        startingPointLongitude: 2.3522,
        startingElevation: 0,
        arrivalPointLatitude: 48.8566,
        arrivalPointLongitude: 2.3522,
        arrivalElevation: 0,
        wkbGeometry: '',
        wkbWaypoints: '',
        distance: 5000,
        difficulty: 'EASY',
        status: 'PUBLISHED',
        location: 'Paris',
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      });
      (hike as any).elevationGain = undefined;
      hike.coordinates = [];

      const result = component.getElevationGain(hike);

      expect(result).toBe(0);
    });

    it('should return 0 when coordinates exist but have no positive gain and net elevation is negative', () => {
      const hike = new Hike({
        id: '5',
        name: 'Flat Hike',
        startingPointLatitude: 48.8566,
        startingPointLongitude: 2.3522,
        startingElevation: 300,
        arrivalPointLatitude: 48.8566,
        arrivalPointLongitude: 2.3522,
        arrivalElevation: 100,
        wkbGeometry: '',
        wkbWaypoints: '',
        distance: 5000,
        difficulty: 'EASY',
        status: 'PUBLISHED',
        source: 'OFFICIAL',
        seasons: ['SPRING'],
        location: 'Paris',
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      });
      hike.coordinates = [
        { latitude: 48.8566, longitude: 2.3522, elevation: 0 },
        { latitude: 48.86, longitude: 2.355, elevation: 0 },
      ];
      hike.elevationGain = 0;

      expect(component.getElevationGain(hike)).toBe(0);
    });
  });
});
