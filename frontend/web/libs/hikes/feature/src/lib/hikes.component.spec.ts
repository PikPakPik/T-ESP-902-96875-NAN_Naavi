import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Hikes } from './hikes.component';
import { ConfirmationService } from 'primeng/api';
import { MapboxService } from '@web/shared/util';
import { TranslateModule } from '@ngx-translate/core';
import { Hike } from '@web/shared/models/settings';
import { Subject } from 'rxjs';
import { Table } from 'primeng/table';

describe('Hikes Component', () => {
  let component: Hikes;
  let fixture: ComponentFixture<Hikes>;
  let confirmationService: jest.Mocked<ConfirmationService>;

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

    await TestBed.configureTestingModule({
      imports: [Hikes, TranslateModule.forRoot()],
      providers: [{ provide: MapboxService, useValue: mapboxServiceMock }],
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
  });
});
