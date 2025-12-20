import { TestBed } from '@angular/core/testing';
import { HikesStore } from './hikes.store';
import { HikesService } from '../services/hikes.service';
import { of, throwError } from 'rxjs';
import {
  Hike,
  PaginatedHikesResponse,
  HikeConfiguration,
} from '@web/shared/models/settings';

describe('HikesStore', () => {
  let store: InstanceType<typeof HikesStore>;
  let hikesService: jest.Mocked<HikesService>;

  const mockIDBHike = {
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

  const mockHike: Hike = new Hike(mockIDBHike);

  const mockPaginatedResponse: PaginatedHikesResponse & {
    hikesInstances: Hike[];
  } = {
    items: [mockIDBHike],
    hikesInstances: [mockHike],
    totalItems: 1,
    currentPage: 1,
    nextPage: null,
    previousPage: null,
    limit: 20,
    totalPages: 1,
  };

  const mockConfiguration: HikeConfiguration = {
    difficulties: ['EASY', 'MEDIUM', 'HARD'],
    status: ['PUBLISHED', 'DRAFT', 'UNPUBLISHED'],
    sources: ['OFFICIAL', 'COMMUNITY'],
    seasons: ['SPRING', 'SUMMER', 'FALL', 'WINTER'],
  };

  beforeEach(() => {
    const hikesServiceMock = {
      getHikes: jest.fn(),
      getHikeById: jest.fn(),
      addHike: jest.fn(),
      updateHike: jest.fn(),
      deleteHike: jest.fn(),
      getConfigurations: jest.fn(() => of(mockConfiguration)),
    } as unknown as jest.Mocked<HikesService>;

    TestBed.configureTestingModule({
      providers: [
        HikesStore,
        { provide: HikesService, useValue: hikesServiceMock },
      ],
    });

    hikesService = TestBed.inject(HikesService) as jest.Mocked<HikesService>;

    // S'assurer que navigator existe
    if (typeof global.navigator === 'undefined') {
      (global as any).navigator = {};
    }
    // Mock navigator.geolocation pour éviter les erreurs dans les tests
    Object.defineProperty(global.navigator, 'geolocation', {
      writable: true,
      configurable: true,
      value: {
        getCurrentPosition: jest.fn((success) =>
          success({
            coords: {
              latitude: 48.8566,
              longitude: 2.3522,
            },
          })
        ),
      },
    });

    store = TestBed.inject(HikesStore);
  });

  it('should be created', () => {
    expect(store).toBeTruthy();
  });

  describe('getHikes', () => {
    it('should fetch hikes successfully', async () => {
      hikesService.getHikes.mockReturnValue(of(mockPaginatedResponse));

      await store.getHikes();

      expect(hikesService.getHikes).toHaveBeenCalled();
      expect(store.entities()).toEqual([mockHike]);
      expect(store.total()).toBe(1);
      expect(store.page()).toBe(1);
      expect(store.limit()).toBe(20);
      expect(store.totalPages()).toBe(1);
      expect(store.isPending()).toBe(false);
    });

    it('should fetch hikes with query parameters', async () => {
      hikesService.getHikes.mockReturnValue(of(mockPaginatedResponse));

      await store.getHikes({
        page: 2,
        limit: 10,
        latitude: 48.8566,
        longitude: 2.3522,
        radius: 50,
      });

      expect(hikesService.getHikes).toHaveBeenCalledWith({
        page: 2,
        limit: 10,
        latitude: 48.8566,
        longitude: 2.3522,
        radius: 50,
      });
    });

    it('should use store location if not provided in query params', async () => {
      hikesService.getHikes.mockReturnValue(of(mockPaginatedResponse));

      // Set store location
      store.setDefaultLocation(48.8566, 2.3522);

      await store.getHikes();

      expect(hikesService.getHikes).toHaveBeenCalledWith(
        expect.objectContaining({
          latitude: 48.8566,
          longitude: 2.3522,
          radius: 50,
        })
      );
    });

    it('should handle errors when fetching hikes', async () => {
      const errorMessage = 'Error fetching hikes';
      hikesService.getHikes.mockReturnValue(throwError(() => errorMessage));

      await store.getHikes();

      expect(store.isPending()).toBe(false);
      expect(store.error()).toBeTruthy();
    });
  });

  describe('getHikeById', () => {
    it('should fetch a hike by id successfully', async () => {
      hikesService.getHikeById.mockReturnValue(of(mockHike));

      const result = await store.getHikeById('1');

      expect(hikesService.getHikeById).toHaveBeenCalledWith('1');
      expect(result).toEqual(mockHike);
      expect(store.isPending()).toBe(false);
    });

    it('should add hike to store if not already present', async () => {
      hikesService.getHikeById.mockReturnValue(of(mockHike));

      await store.getHikeById('1');

      expect(store.entities()).toContainEqual(mockHike);
    });

    it('should handle errors when fetching hike by id', async () => {
      const errorMessage = 'Error fetching hike';
      hikesService.getHikeById.mockReturnValue(throwError(() => errorMessage));

      const result = await store.getHikeById('1');

      expect(result).toBeUndefined();
      expect(store.isPending()).toBe(false);
      expect(store.error()).toBeTruthy();
    });
  });

  describe('create', () => {
    it('should create a new hike successfully', async () => {
      const newHikeData = { ...mockIDBHike, id: '2', name: 'New Hike' };
      const newHike = new Hike(newHikeData);
      hikesService.addHike.mockReturnValue(of(newHike));

      await store.create(newHike);

      expect(hikesService.addHike).toHaveBeenCalledWith(newHike);
      expect(store.entities()).toContainEqual(newHike);
      expect(store.isPending()).toBe(false);
    });

    it('should handle errors when creating hike', async () => {
      const errorMessage = 'Error creating hike';
      hikesService.addHike.mockReturnValue(throwError(() => errorMessage));

      await store.create(mockHike);

      expect(store.isPending()).toBe(false);
      expect(store.error()).toBeTruthy();
    });
  });

  describe('update', () => {
    it('should update a hike successfully', async () => {
      // First add a hike to the store
      hikesService.getHikes.mockReturnValue(of(mockPaginatedResponse));
      await store.getHikes();

      const updatedHikeData = { ...mockIDBHike, name: 'Updated Hike' };
      const updatedHike = new Hike(updatedHikeData);
      hikesService.updateHike.mockReturnValue(of(updatedHike));

      await store.update(updatedHike);

      expect(hikesService.updateHike).toHaveBeenCalledWith(updatedHike);
      const entity = store.entities().find((h) => h.id === '1');
      expect(entity?.name).toBe('Updated Hike');
      expect(store.isPending()).toBe(false);
    });

    it('should handle errors when updating hike', async () => {
      const errorMessage = 'Error updating hike';
      hikesService.updateHike.mockReturnValue(throwError(() => errorMessage));

      await store.update(mockHike);

      expect(store.isPending()).toBe(false);
      expect(store.error()).toBeTruthy();
    });
  });

  describe('delete', () => {
    it('should delete a hike successfully', async () => {
      // First add a hike to the store
      hikesService.getHikes.mockReturnValue(of(mockPaginatedResponse));
      await store.getHikes();

      hikesService.deleteHike.mockReturnValue(of(undefined));

      await store.delete('1');

      expect(hikesService.deleteHike).toHaveBeenCalledWith('1');
      expect(store.entities()).not.toContainEqual(mockHike);
      expect(store.isPending()).toBe(false);
    });

    it('should handle errors when deleting hike', async () => {
      const errorMessage = 'Error deleting hike';
      hikesService.deleteHike.mockReturnValue(throwError(() => errorMessage));

      await store.delete('1');

      expect(store.isPending()).toBe(false);
      expect(store.error()).toBeTruthy();
    });
  });

  describe('loadConfigurations', () => {
    it('should load configurations successfully', async () => {
      hikesService.getConfigurations.mockReturnValue(of(mockConfiguration));

      await store.loadConfigurations();

      expect(hikesService.getConfigurations).toHaveBeenCalled();
      expect(store.difficulties()).toEqual(['EASY', 'MEDIUM', 'HARD']);
      expect(store.status()).toEqual(['PUBLISHED', 'DRAFT', 'UNPUBLISHED']);
      expect(store.sources()).toEqual(['OFFICIAL', 'COMMUNITY']);
      expect(store.seasons()).toEqual(['SPRING', 'SUMMER', 'FALL', 'WINTER']);
    });

    it('should handle errors when loading configurations', async () => {
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation();
      const errorMessage = 'Error loading configurations';
      hikesService.getConfigurations.mockReturnValue(
        throwError(() => errorMessage)
      );

      await store.loadConfigurations();

      expect(consoleSpy).toHaveBeenCalledWith(
        'Failed to load configurations:',
        errorMessage
      );
      consoleSpy.mockRestore();
    });
  });

  describe('getUserLocation', () => {
    it('should get user location successfully', async () => {
      const mockGeolocation = {
        getCurrentPosition: jest.fn((success) => {
          // Appeler success de manière synchrone
          success({
            coords: {
              latitude: 50.1234,
              longitude: 3.5678,
            },
          });
        }),
      };
      Object.defineProperty(global.navigator, 'geolocation', {
        writable: true,
        configurable: true,
        value: mockGeolocation,
      });

      await store.getUserLocation();

      expect(store.latitude()).toBe(50.1234);
      expect(store.longitude()).toBe(3.5678);
    });

    it('should handle geolocation errors', async () => {
      const consoleWarnSpy = jest.spyOn(console, 'warn').mockImplementation();
      const mockGeolocation = {
        getCurrentPosition: jest.fn((success, error) =>
          error({ message: 'Location denied' })
        ),
      };
      Object.defineProperty(global.navigator, 'geolocation', {
        writable: true,
        configurable: true,
        value: mockGeolocation,
      });

      await store.getUserLocation();

      expect(store.latitude()).toBeNull();
      expect(store.longitude()).toBeNull();
      expect(consoleWarnSpy).toHaveBeenCalledWith(
        'Unable to retrieve user location:',
        'Location denied'
      );
      consoleWarnSpy.mockRestore();
    });

    it('should handle missing geolocation API', async () => {
      const consoleWarnSpy = jest.spyOn(console, 'warn').mockImplementation();
      Object.defineProperty(global.navigator, 'geolocation', {
        writable: true,
        value: undefined,
      });

      await store.getUserLocation();

      expect(store.latitude()).toBeNull();
      expect(store.longitude()).toBeNull();
      expect(consoleWarnSpy).toHaveBeenCalledWith(
        'Geolocation is not supported by this environment.'
      );
      consoleWarnSpy.mockRestore();
    });
  });

  describe('setDefaultLocation', () => {
    it('should set default location', () => {
      store.setDefaultLocation(48.8566, 2.3522);

      expect(store.latitude()).toBe(48.8566);
      expect(store.longitude()).toBe(2.3522);
    });
  });
});
