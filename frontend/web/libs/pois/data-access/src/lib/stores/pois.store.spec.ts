import { TestBed } from '@angular/core/testing';
import { POIsStore } from './pois.store';
import { POIsService } from '../services/pois.service';
import { of, throwError } from 'rxjs';
import { POI, IDB_POI } from '@web/shared/models/settings';

describe('POIsStore', () => {
  let store: InstanceType<typeof POIsStore>;
  let poisService: jest.Mocked<POIsService>;

  const mockIDBPOI: IDB_POI = {
    id: '1',
    name: 'Test POI',
    description: 'A test POI',
    categories: ['RESTAURANT'],
    photos: [],
    latitude: 48.8566,
    longitude: 2.3522,
    comment: 'Test comment',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    status: 'ACTIVE',
  };

  const mockPOI = new POI(mockIDBPOI);

  beforeEach(() => {
    const poisServiceMock = {
      getPOIs: jest.fn(),
      searchPOIs: jest.fn(),
      getPOIById: jest.fn(),
      addPOI: jest.fn(),
      updatePOI: jest.fn(),
      deletePOI: jest.fn(),
      getConfigurations: jest.fn(() =>
        of({
          point_of_interest_categories: ['RESTAURANT', 'HOTEL'],
          status: ['ACTIVE', 'INACTIVE'],
        })
      ),
    } as unknown as jest.Mocked<POIsService>;

    TestBed.configureTestingModule({
      providers: [
        POIsStore,
        { provide: POIsService, useValue: poisServiceMock },
      ],
    });

    poisService = TestBed.inject(POIsService) as jest.Mocked<POIsService>;
    store = TestBed.inject(POIsStore);
  });

  it('should be created', () => {
    expect(store).toBeTruthy();
  });

  describe('getPOIs', () => {
    it('should fetch POIs successfully', async () => {
      poisService.searchPOIs.mockReturnValue(
        of({
          items: [mockIDBPOI],
          poisInstances: [mockPOI],
          totalItems: 1,
          currentPage: 1,
          limit: 20,
          totalPages: 1,
          nextPage: null,
          previousPage: null,
        })
      );

      await store.getPOIs();

      expect(poisService.searchPOIs).toHaveBeenCalled();
      expect(store.entities()).toHaveLength(1);
      expect(store.entities()[0].id).toBe(mockPOI.id);
      expect(store.isPending()).toBe(false);
    });

    it('should handle errors when fetching POIs', async () => {
      const errorMessage = 'Error fetching POIs';
      poisService.searchPOIs.mockReturnValue(throwError(() => errorMessage));

      await store.getPOIs();

      expect(store.isPending()).toBe(false);
      expect(store.error()).toBeTruthy();
    });
  });

  describe('getPOIById', () => {
    it('should fetch a POI by id successfully', async () => {
      poisService.getPOIById.mockReturnValue(of(mockPOI));

      const result = await store.getPOIById('1');

      expect(poisService.getPOIById).toHaveBeenCalledWith('1');
      expect(result).toEqual(mockPOI);
    });

    it('should handle errors when fetching POI by id', async () => {
      const errorMessage = 'Error fetching POI';
      poisService.getPOIById.mockReturnValue(throwError(() => errorMessage));

      const result = await store.getPOIById('1');

      expect(result).toBeUndefined();
      expect(store.error()).toBeTruthy();
    });
  });

  describe('create', () => {
    it('should create a new POI successfully', async () => {
      poisService.addPOI.mockReturnValue(of(mockPOI));

      await store.create(mockPOI);

      expect(poisService.addPOI).toHaveBeenCalledWith(mockPOI);
      expect(store.entities()).toContainEqual(mockPOI);
      expect(store.isPending()).toBe(false);
    });

    it('should handle errors when creating POI', async () => {
      const errorMessage = 'Error creating POI';
      poisService.addPOI.mockReturnValue(throwError(() => errorMessage));

      await store.create(mockPOI);

      expect(store.isPending()).toBe(false);
      expect(store.error()).toBeTruthy();
    });
  });

  describe('update', () => {
    it('should update a POI successfully', async () => {
      // First add the POI to the store
      poisService.addPOI.mockReturnValue(of(mockPOI));
      await store.create(mockPOI);

      const updatedPOI = new POI({
        id: '1',
        name: 'Updated POI',
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
      poisService.updatePOI.mockReturnValue(of(updatedPOI));

      await store.update(updatedPOI);

      expect(poisService.updatePOI).toHaveBeenCalledWith(updatedPOI);
      const entity = store.entities().find((p) => p.id === '1');
      expect(entity?.name).toBe('Updated POI');
      expect(store.isPending()).toBe(false);
    });

    it('should handle errors when updating POI', async () => {
      const errorMessage = 'Error updating POI';
      poisService.updatePOI.mockReturnValue(throwError(() => errorMessage));

      await store.update(mockPOI);

      expect(store.isPending()).toBe(false);
      expect(store.error()).toBeTruthy();
    });
  });

  describe('delete', () => {
    it('should delete a POI successfully', async () => {
      // First add the POI to the store
      poisService.addPOI.mockReturnValue(of(mockPOI));
      await store.create(mockPOI);

      poisService.deletePOI.mockReturnValue(of(undefined));

      await store.delete('1');

      expect(poisService.deletePOI).toHaveBeenCalledWith('1');
      expect(store.entities().find((p) => p.id === '1')).toBeUndefined();
      expect(store.isPending()).toBe(false);
    });

    it('should handle errors when deleting POI', async () => {
      const errorMessage = 'Error deleting POI';
      poisService.deletePOI.mockReturnValue(throwError(() => errorMessage));

      await store.delete('1');

      expect(store.isPending()).toBe(false);
      expect(store.error()).toBeTruthy();
    });
  });

  describe('setPage', () => {
    it('should update page', () => {
      store.setPage(2);
      expect(store.page()).toBe(2);
    });
  });

  describe('setLimit', () => {
    it('should update limit', () => {
      store.setLimit(50);
      expect(store.limit()).toBe(50);
    });
  });

  describe('setDefaultLocation', () => {
    it('should set default location', () => {
      store.setDefaultLocation(48.8566, 2.3522);
      expect(store.latitude()).toBe(48.8566);
      expect(store.longitude()).toBe(2.3522);
    });
  });

  describe('getUserLocation', () => {
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

      const mockGeolocation = {
        getCurrentPosition: jest.fn((success) => {
          // Appeler success de manière synchrone
          success(mockPosition);
        }),
      };

      Object.defineProperty(global.navigator, 'geolocation', {
        value: mockGeolocation,
        writable: true,
        configurable: true,
      });

      store.getUserLocation().then(() => {
        expect(store.latitude()).toBe(50.0);
        expect(store.longitude()).toBe(3.0);
        done();
      });
    });

    it('should handle geolocation error', (done) => {
      const mockGeolocation = {
        getCurrentPosition: jest.fn((success, error) => {
          error(new Error('Geolocation error'));
        }),
      };
      Object.defineProperty(global.navigator, 'geolocation', {
        value: mockGeolocation,
        writable: true,
        configurable: true,
      });

      store.getUserLocation().then(() => {
        expect(store.latitude()).toBeNull();
        expect(store.longitude()).toBeNull();
        done();
      });
    });

    it('should handle missing geolocation', (done) => {
      // S'assurer que navigator existe
      if (typeof global.navigator === 'undefined') {
        (global as any).navigator = {};
      }
      Object.defineProperty(global.navigator, 'geolocation', {
        value: undefined,
        writable: true,
        configurable: true,
      });

      store.getUserLocation().then(() => {
        expect(store.latitude()).toBeNull();
        expect(store.longitude()).toBeNull();
        done();
      });
    });
  });

  describe('loadConfigurations', () => {
    it('should load configurations successfully', async () => {
      poisService.getConfigurations.mockReturnValue(
        of({
          point_of_interest_categories: ['RESTAURANT', 'HOTEL'],
          status: ['ACTIVE', 'INACTIVE'],
        })
      );

      await store.loadConfigurations();

      expect(store.point_of_interest_categories()).toEqual([
        'RESTAURANT',
        'HOTEL',
      ]);
      expect(store.status()).toEqual(['ACTIVE', 'INACTIVE']);
    });

    it('should handle errors when loading configurations', async () => {
      const consoleErrorSpy = jest
        .spyOn(console, 'error')
        .mockImplementation(() => {
          // Mock implementation to suppress console.error in tests
        });

      poisService.getConfigurations.mockReturnValue(
        throwError(() => 'Error loading configurations')
      );

      await store.loadConfigurations();

      expect(consoleErrorSpy).toHaveBeenCalled();
      consoleErrorSpy.mockRestore();
    });
  });
});
