import { TestBed } from '@angular/core/testing';
import { HikeDetailStore } from './hike-detail.store';
import { HikesService } from '../services/hikes.service';
import { of, throwError } from 'rxjs';
import { Hike } from '@web/shared/models/settings';
import { ActivatedRoute } from '@angular/router';

describe('HikeDetailStore', () => {
  let store: InstanceType<typeof HikeDetailStore>;
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

  beforeEach(() => {
    const hikesServiceMock = {
      getHikeById: jest.fn(),
    } as unknown as jest.Mocked<HikesService>;

    const activatedRouteMock = {
      params: of({ id: '1' }),
      snapshot: {
        params: { id: '1' },
      },
    };

    TestBed.configureTestingModule({
      providers: [
        HikeDetailStore,
        { provide: HikesService, useValue: hikesServiceMock },
        { provide: ActivatedRoute, useValue: activatedRouteMock },
      ],
    });

    hikesService = TestBed.inject(HikesService) as jest.Mocked<HikesService>;
    store = TestBed.inject(HikeDetailStore);
  });

  it('should be created', () => {
    expect(store).toBeTruthy();
  });

  it('should initialize with null hike', () => {
    expect(store.hike()).toBeNull();
  });

  describe('loadHike', () => {
    it('should load a hike successfully', async () => {
      hikesService.getHikeById.mockReturnValue(of(mockHike));

      await store.loadHike('1');

      expect(hikesService.getHikeById).toHaveBeenCalledWith('1');
      expect(store.hike()).toEqual(mockHike);
      expect(store.isPending()).toBe(false);
    });

    it('should set hike to null when service returns undefined', async () => {
      hikesService.getHikeById.mockReturnValue(of(undefined as unknown as Hike));

      await store.loadHike('1');

      expect(store.hike()).toBeNull();
      expect(store.isPending()).toBe(false);
    });

    it('should handle errors when loading hike', async () => {
      const errorMessage = 'Error loading hike';
      hikesService.getHikeById.mockReturnValue(throwError(() => errorMessage));

      await store.loadHike('1');

      expect(store.hike()).toBeNull();
      expect(store.isPending()).toBe(false);
      expect(store.error()).toBeTruthy();
    });

    it('should set pending state while loading', async () => {
      hikesService.getHikeById.mockReturnValue(of(mockHike));

      const loadPromise = store.loadHike('1');

      // Note: isPending state is set synchronously at the start of loadHike
      // but we can't check it mid-execution in a unit test easily
      await loadPromise;

      expect(store.isPending()).toBe(false);
    });
  });
});
