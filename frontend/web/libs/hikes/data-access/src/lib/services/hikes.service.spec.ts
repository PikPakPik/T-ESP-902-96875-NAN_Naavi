import { TestBed } from '@angular/core/testing';
import {
  provideHttpClient,
  withInterceptorsFromDi,
} from '@angular/common/http';
import {
  HttpTestingController,
  provideHttpClientTesting,
} from '@angular/common/http/testing';
import { HikesService } from './hikes.service';
import { MessageService } from 'primeng/api';
import { API_URL } from '@web/shared/http-client';
import {
  Hike,
  IDB_Hike,
  HikesQueryParams,
  PaginatedHikesResponse,
  HikeConfiguration,
} from '@web/shared/models/settings';

describe('HikesService', () => {
  let service: HikesService;
  let httpMock: HttpTestingController;
  let messageService: jest.Mocked<MessageService>;
  const apiUrl = 'http://localhost:3000/api/';

  const mockIDBHike: IDB_Hike = {
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
    estimatedDuration: 3600,
    difficulty: 'EASY',
    status: 'PUBLISHED',
    source: 'OFFICIAL',
    seasons: ['SPRING'],
    location: 'Paris',
    createdAt: '2024-01-01T00:00:00.000Z',
    updatedAt: '2024-01-01T00:00:00.000Z',
  };

  beforeEach(() => {
    const messageServiceMock = {
      add: jest.fn(),
    } as unknown as jest.Mocked<MessageService>;

    TestBed.configureTestingModule({
      providers: [
        HikesService,
        provideHttpClient(withInterceptorsFromDi()),
        provideHttpClientTesting(),
        { provide: MessageService, useValue: messageServiceMock },
        { provide: API_URL, useValue: apiUrl },
      ],
    });

    service = TestBed.inject(HikesService);
    httpMock = TestBed.inject(HttpTestingController);
    messageService = TestBed.inject(
      MessageService
    ) as jest.Mocked<MessageService>;
  });

  afterEach(() => {
    httpMock.verify();
  });

  describe('getHikes', () => {
    it('should fetch hikes with default parameters', (done) => {
      const mockResponse: PaginatedHikesResponse = {
        items: [mockIDBHike],
        totalItems: 1,
        currentPage: 1,
        nextPage: null,
        previousPage: null,
        limit: 20,
        totalPages: 1,
      };

      service.getHikes().subscribe((response) => {
        expect(response.totalItems).toBe(1);
        expect(response.hikesInstances).toHaveLength(1);
        expect(response.hikesInstances[0]).toBeInstanceOf(Hike);
        expect(response.hikesInstances[0].name).toBe('Test Hike');
        done();
      });

      const req = httpMock.expectOne(`${apiUrl}hike/administration/hikes?page=1&limit=20`);
      expect(req.request.method).toBe('GET');
      req.flush(mockResponse);
    });

    it('should fetch hikes with custom query parameters', (done) => {
      const queryParams: HikesQueryParams = {
        page: 2,
        limit: 10,
        query: 'mountain',
        orderField: 'name',
        order: 'asc',
        latitude: 48.8566,
        longitude: 2.3522,
        radius: 50,
        distance: 10,
        difficulty: 'HARD',
      };

      const mockResponse: PaginatedHikesResponse = {
        items: [],
        totalItems: 0,
        currentPage: 2,
        nextPage: null,
        previousPage: 1,
        limit: 10,
        totalPages: 0,
      };

      service.getHikes(queryParams).subscribe((response) => {
        expect(response.currentPage).toBe(2);
        expect(response.limit).toBe(10);
        done();
      });

      const req = httpMock.expectOne((request) => {
        return (
          request.url === `${apiUrl}hike/administration/hikes` &&
          request.params.get('page') === '2' &&
          request.params.get('limit') === '10' &&
          request.params.get('query') === 'mountain' &&
          request.params.get('orderField') === 'name' &&
          request.params.get('order') === 'asc' &&
          request.params.get('latitude') === '48.8566' &&
          request.params.get('longitude') === '2.3522' &&
          request.params.get('radius') === '50' &&
          request.params.get('distance') === '10' &&
          request.params.get('difficulty') === 'HARD'
        );
      });
      expect(req.request.method).toBe('GET');
      req.flush(mockResponse);
    });

    it('should handle error when fetching hikes fails', (done) => {
      service.getHikes().subscribe({
        next: () => fail('should have failed'),
        error: (error) => {
          expect(error).toBeTruthy();
          expect(messageService.add).toHaveBeenCalledWith({
            severity: 'error',
            summary: 'Error',
            detail: 'Failed to get hikes',
          });
          done();
        },
      });

      const req = httpMock.expectOne(`${apiUrl}hike/administration/hikes?page=1&limit=20`);
      req.flush('Error', { status: 500, statusText: 'Server Error' });
    });
  });

  describe('getHikeById', () => {
    it('should fetch a hike by id', (done) => {
      service.getHikeById('1').subscribe((hike) => {
        expect(hike).toBeInstanceOf(Hike);
        expect(hike.id).toBe('1');
        expect(hike.name).toBe('Test Hike');
        done();
      });

      const req = httpMock.expectOne(`${apiUrl}hike/hikes/1`);
      expect(req.request.method).toBe('GET');
      req.flush(mockIDBHike);
    });

    it('should handle error when fetching hike by id fails', (done) => {
      service.getHikeById('1').subscribe({
        next: () => fail('should have failed'),
        error: (error) => {
          expect(error).toBeTruthy();
          expect(messageService.add).toHaveBeenCalledWith({
            severity: 'error',
            summary: 'Error',
            detail: 'Failed to get hike',
          });
          done();
        },
      });

      const req = httpMock.expectOne(`${apiUrl}hike/hikes/1`);
      req.flush('Not Found', { status: 404, statusText: 'Not Found' });
    });
  });

  describe('addHike', () => {
    it('should create a new hike', (done) => {
      const newHike = new Hike({
        id: '',
        name: 'New Hike',
        difficulty: 'MEDIUM',
        distance: 10000,
        estimatedDuration: 7200,
        status: 'DRAFT',
        source: 'COMMUNITY',
        seasons: ['SUMMER'],
        startingPointLatitude: 48.8566,
        startingPointLongitude: 2.3522,
        startingElevation: 100,
        arrivalPointLatitude: 48.8566,
        arrivalPointLongitude: 2.3522,
        arrivalElevation: 150,
        wkbGeometry: '',
        wkbWaypoints: '',
        location: 'Paris',
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      });

      service.addHike(newHike).subscribe((hike) => {
        expect(hike).toBeInstanceOf(Hike);
        expect(hike.name).toBe('New Hike');
        done();
      });

      const req = httpMock.expectOne(`${apiUrl}hike/hikes`);
      expect(req.request.method).toBe('POST');
      expect(req.request.body).toBeDefined();
      req.flush({ ...mockIDBHike, name: 'New Hike' });
    });

    it('should handle error when creating hike fails', (done) => {
      const newHike = new Hike(mockIDBHike);

      service.addHike(newHike).subscribe({
        next: () => fail('should have failed'),
        error: (error) => {
          expect(error).toBeTruthy();
          expect(messageService.add).toHaveBeenCalledWith({
            severity: 'error',
            summary: 'Error',
            detail: 'Failed to add hike',
          });
          done();
        },
      });

      const req = httpMock.expectOne(`${apiUrl}hike/hikes`);
      req.flush('Bad Request', { status: 400, statusText: 'Bad Request' });
    });
  });

  describe('updateHike', () => {
    it('should update an existing hike', (done) => {
      const updatedHike = new Hike({
        ...mockIDBHike,
        name: 'Updated Hike',
      });

      service.updateHike(updatedHike).subscribe((hike) => {
        expect(hike).toBeInstanceOf(Hike);
        expect(hike.name).toBe('Updated Hike');
        done();
      });

      const req = httpMock.expectOne(`${apiUrl}hike/administration/hikes/1`);
      expect(req.request.method).toBe('PUT');
      req.flush({ ...mockIDBHike, name: 'Updated Hike' });
    });

    it('should handle error when updating hike fails', (done) => {
      const updatedHike = new Hike(mockIDBHike);

      service.updateHike(updatedHike).subscribe({
        next: () => fail('should have failed'),
        error: (error) => {
          expect(error).toBeTruthy();
          expect(messageService.add).toHaveBeenCalledWith({
            severity: 'error',
            summary: 'Error',
            detail: 'Failed to update hike',
          });
          done();
        },
      });

      const req = httpMock.expectOne(`${apiUrl}hike/administration/hikes/1`);
      req.flush('Server Error', { status: 500, statusText: 'Server Error' });
    });
  });

  describe('deleteHike', () => {
    it('should delete a hike', (done) => {
      service.deleteHike('1').subscribe(() => {
        done();
      });

      const req = httpMock.expectOne(`${apiUrl}hike/administration/hikes/1`);
      expect(req.request.method).toBe('DELETE');
      req.flush(null);
    });

    it('should handle error when deleting hike fails', (done) => {
      service.deleteHike('1').subscribe({
        next: () => fail('should have failed'),
        error: (error) => {
          expect(error).toBeTruthy();
          expect(messageService.add).toHaveBeenCalledWith({
            severity: 'error',
            summary: 'Error',
            detail: 'Failed to delete hike',
          });
          done();
        },
      });

      const req = httpMock.expectOne(`${apiUrl}hike/administration/hikes/1`);
      req.flush('Not Found', { status: 404, statusText: 'Not Found' });
    });
  });

  describe('getConfigurations', () => {
    it('should fetch hike configurations', (done) => {
      const mockConfig: HikeConfiguration = {
        difficulties: ['EASY', 'MEDIUM', 'HARD'],
        status: ['PUBLISHED', 'DRAFT', 'UNPUBLISHED'],
        sources: ['OFFICIAL', 'COMMUNITY'],
        seasons: ['SPRING', 'SUMMER', 'FALL', 'WINTER'],
      };

      service.getConfigurations().subscribe((config) => {
        expect(config).toEqual(mockConfig);
        expect(config.difficulties).toHaveLength(3);
        expect(config.seasons).toHaveLength(4);
        done();
      });

      const req = httpMock.expectOne(`${apiUrl}hike/configurations`);
      expect(req.request.method).toBe('GET');
      req.flush(mockConfig);
    });

    it('should handle error when fetching configurations fails', (done) => {
      service.getConfigurations().subscribe({
        next: () => fail('should have failed'),
        error: (error) => {
          expect(error).toBeTruthy();
          expect(messageService.add).toHaveBeenCalledWith({
            severity: 'error',
            summary: 'Error',
            detail: 'Failed to get configurations',
          });
          done();
        },
      });

      const req = httpMock.expectOne(`${apiUrl}hike/configurations`);
      req.flush('Server Error', { status: 500, statusText: 'Server Error' });
    });
  });

  describe('getUserHikeHistory', () => {
    it('should fetch user hike history with default parameters', (done) => {
      const mockHistory = {
        items: [
          {
            id: 1,
            hike: 'Test Hike',
            duration: 3600,
            createdAt: '2024-01-01T00:00:00.000Z',
          },
        ],
        totalItems: 1,
        totalPages: 1,
        currentPage: 1,
        nextPage: null,
        previousPage: null,
      };

      service.getUserHikeHistory('user123').subscribe((response) => {
        expect(response.items).toHaveLength(1);
        expect(response.totalItems).toBe(1);
        done();
      });

      const req = httpMock.expectOne(
        `${apiUrl}hike/administration/hikes/history/user/user123?page=1&limit=20`
      );
      expect(req.request.method).toBe('GET');
      req.flush(mockHistory);
    });

    it('should fetch user hike history with custom query parameters', (done) => {
      const queryParams = {
        page: 2,
        limit: 10,
        query: 'mountain',
        orderField: 'createdAt',
        order: 'desc' as const,
      };

      const mockHistory = {
        items: [],
        totalItems: 0,
        totalPages: 0,
        currentPage: 2,
        nextPage: null,
        previousPage: 1,
      };

      service
        .getUserHikeHistory('user123', queryParams)
        .subscribe((response) => {
          expect(response.currentPage).toBe(2);
          done();
        });

      const req = httpMock.expectOne((request) => {
        return (
          request.url ===
            `${apiUrl}hike/administration/hikes/history/user/user123` &&
          request.params.get('page') === '2' &&
          request.params.get('limit') === '10' &&
          request.params.get('query') === 'mountain' &&
          request.params.get('orderField') === 'createdAt' &&
          request.params.get('order') === 'desc'
        );
      });
      expect(req.request.method).toBe('GET');
      req.flush(mockHistory);
    });

    it('should handle error when fetching user hike history fails', (done) => {
      service.getUserHikeHistory('user123').subscribe({
        next: () => fail('should have failed'),
        error: (error) => {
          expect(error).toBeTruthy();
          expect(messageService.add).toHaveBeenCalledWith({
            severity: 'error',
            summary: 'Error',
            detail: 'Failed to get user hike history',
          });
          done();
        },
      });

      const req = httpMock.expectOne(
        `${apiUrl}hike/administration/hikes/history/user/user123?page=1&limit=20`
      );
      req.flush('Server Error', { status: 500, statusText: 'Server Error' });
    });
  });
});
