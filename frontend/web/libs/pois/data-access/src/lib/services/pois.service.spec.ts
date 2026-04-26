import { TestBed } from '@angular/core/testing';
import {
  provideHttpClient,
  withInterceptorsFromDi,
} from '@angular/common/http';
import {
  HttpTestingController,
  provideHttpClientTesting,
} from '@angular/common/http/testing';
import { POIsService } from './pois.service';
import { MessageService } from 'primeng/api';
import { API_URL } from '@web/shared/http-client';
import { POI } from '@web/shared/models/settings';

describe('POIsService', () => {
  let service: POIsService;
  let httpMock: HttpTestingController;
  let messageService: jest.Mocked<MessageService>;
  const apiUrl = 'http://localhost:3000/api/';

  const mockIDBPOI = {
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
  };

  const mockPOI = new POI(mockIDBPOI);

  beforeEach(() => {
    const messageServiceMock = {
      add: jest.fn(),
    } as unknown as jest.Mocked<MessageService>;

    TestBed.configureTestingModule({
      providers: [
        POIsService,
        provideHttpClient(withInterceptorsFromDi()),
        provideHttpClientTesting(),
        { provide: MessageService, useValue: messageServiceMock },
        { provide: API_URL, useValue: apiUrl },
      ],
    });

    service = TestBed.inject(POIsService);
    httpMock = TestBed.inject(HttpTestingController);
    messageService = TestBed.inject(
      MessageService
    ) as jest.Mocked<MessageService>;
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  describe('getPOIs', () => {
    it('should fetch all POIs', (done) => {
      const mockPOIs = [mockPOI];

      service.getPOIs().subscribe((pois) => {
        expect(pois).toEqual(mockPOIs);
        done();
      });

      const req = httpMock.expectOne(
        (request) =>
          request.url === `${apiUrl}hike/mapElements` &&
          request.params.get('type') === 'POINT_OF_INTEREST'
      );
      expect(req.request.method).toBe('GET');
      req.flush({ items: [mockIDBPOI] });
    });

    it('should handle errors when fetching POIs', (done) => {
      service.getPOIs().subscribe({
        next: () => fail('should have failed'),
        error: (error) => {
          expect(error).toBeTruthy();
          expect(messageService.add).toHaveBeenCalledWith({
            severity: 'error',
            summary: 'Erreur',
            detail: 'Impossible de charger les POIs',
          });
          done();
        },
      });

      const req = httpMock.expectOne(
        (request) =>
          request.url === `${apiUrl}hike/mapElements` &&
          request.params.get('type') === 'POINT_OF_INTEREST'
      );
      req.flush('Error', { status: 500, statusText: 'Server Error' });
    });
  });

  describe('getPOIById', () => {
    it('should fetch a POI by id', (done) => {
      service.getPOIById('1').subscribe((poi) => {
        expect(poi).toEqual(mockPOI);
        done();
      });

      const req = httpMock.expectOne(
        (request) =>
          request.url === `${apiUrl}hike/mapElement/1` &&
          request.params.get('type') === 'POINT_OF_INTEREST'
      );
      expect(req.request.method).toBe('GET');
      req.flush(mockIDBPOI);
    });

    it('should handle errors when fetching POI by id', (done) => {
      service.getPOIById('1').subscribe({
        next: () => fail('should have failed'),
        error: (error) => {
          expect(error).toBeTruthy();
          expect(messageService.add).toHaveBeenCalledWith({
            severity: 'error',
            summary: 'Erreur',
            detail: 'Impossible de charger le POI',
          });
          done();
        },
      });

      const req = httpMock.expectOne(
        (request) =>
          request.url === `${apiUrl}hike/mapElement/1` &&
          request.params.get('type') === 'POINT_OF_INTEREST'
      );
      req.flush('Error', { status: 500, statusText: 'Server Error' });
    });
  });

  describe('addPOI', () => {
    it('should create a new POI', (done) => {
      service.addPOI(mockPOI).subscribe((poi) => {
        expect(poi).toEqual(mockPOI);
        done();
      });

      const req = httpMock.expectOne(`${apiUrl}hike/mapElement`);
      expect(req.request.method).toBe('POST');
      expect(req.request.body.type).toBe('POINT_OF_INTEREST');
      req.flush(mockIDBPOI);
    });

    it('should handle errors when creating POI', (done) => {
      service.addPOI(mockPOI).subscribe({
        next: () => fail('should have failed'),
        error: (error) => {
          expect(error).toBeTruthy();
          expect(messageService.add).toHaveBeenCalledWith({
            severity: 'error',
            summary: 'Erreur',
            detail: 'Impossible de créer le POI',
          });
          done();
        },
      });

      const req = httpMock.expectOne(`${apiUrl}hike/mapElement`);
      req.flush('Error', { status: 500, statusText: 'Server Error' });
    });

    it('should serialize date objects and categories fallback when creating POI', (done) => {
      const poiPayload = {
        id: '2',
        name: 'Created POI',
        description: 'Description',
        categories: ['RESTAURANT'],
        latitude: 48.5,
        longitude: 2.1,
        createdAt: new Date('2026-01-01T10:00:00.000Z'),
        updatedAt: new Date('2026-01-02T10:00:00.000Z'),
      };

      service.addPOI(poiPayload).subscribe(() => done());

      const req = httpMock.expectOne(`${apiUrl}hike/mapElement`);
      expect(req.request.body.categories).toEqual(['RESTAURANT']);
      expect(req.request.body.type).toBe('POINT_OF_INTEREST');
      expect(req.request.body.createdAt).toBe('2026-01-01T10:00:00.000Z');
      expect(req.request.body.updatedAt).toBe('2026-01-02T10:00:00.000Z');
      req.flush({ ...mockIDBPOI, id: '2', categories: ['RESTAURANT'] });
    });
  });

  describe('updatePOI', () => {
    it('should update a POI', (done) => {
      const updatedIDBPOI = {
        id: '1',
        name: 'Updated POI',
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
      };

      const updatedPOI = new POI(updatedIDBPOI);

      service.updatePOI(updatedPOI).subscribe((poi) => {
        expect(poi.name).toBe('Updated POI');
        done();
      });

      const req = httpMock.expectOne(
        `${apiUrl}hike/administration/mapElement/1`
      );
      expect(req.request.method).toBe('PUT');
      expect(req.request.body.type).toBe('POINT_OF_INTEREST');
      req.flush(updatedIDBPOI);
    });

    it('should handle errors when updating POI', (done) => {
      service.updatePOI(mockPOI).subscribe({
        next: () => fail('should have failed'),
        error: (error) => {
          expect(error).toBeTruthy();
          expect(messageService.add).toHaveBeenCalledWith({
            severity: 'error',
            summary: 'Erreur',
            detail: 'Impossible de mettre à jour le POI',
          });
          done();
        },
      });

      const req = httpMock.expectOne(
        `${apiUrl}hike/administration/mapElement/1`
      );
      req.flush('Error', { status: 500, statusText: 'Server Error' });
    });

    it('should keep undefined dates when updating POI partial payload', (done) => {
      service
        .updatePOI({
          id: '1',
          name: 'Partial POI',
          description: 'Partial description',
          categories: ['CAFE'],
          latitude: 10,
          longitude: 20,
          status: 'DRAFT',
        })
        .subscribe(() => done());

      const req = httpMock.expectOne(
        `${apiUrl}hike/administration/mapElement/1`
      );
      expect(req.request.body.createdAt).toBeUndefined();
      expect(req.request.body.updatedAt).toBeUndefined();
      expect(req.request.body.categories).toEqual(['CAFE']);
      expect(req.request.body.type).toBe('POINT_OF_INTEREST');
      req.flush({ ...mockIDBPOI, categories: ['CAFE'] });
    });
  });

  describe('deletePOI', () => {
    it('should delete a POI', (done) => {
      service.deletePOI('1').subscribe(() => {
        done();
      });

      const req = httpMock.expectOne(
        (request) =>
          request.url === `${apiUrl}hike/administration/mapElement/1` &&
          request.params.get('type') === 'POINT_OF_INTEREST'
      );
      expect(req.request.method).toBe('DELETE');
      req.flush(null);
    });

    it('should handle errors when deleting POI', (done) => {
      service.deletePOI('1').subscribe({
        next: () => fail('should have failed'),
        error: (error) => {
          expect(error).toBeTruthy();
          expect(messageService.add).toHaveBeenCalledWith({
            severity: 'error',
            summary: 'Erreur',
            detail: 'Impossible de supprimer le POI',
          });
          done();
        },
      });

      const req = httpMock.expectOne(
        (request) =>
          request.url === `${apiUrl}hike/administration/mapElement/1` &&
          request.params.get('type') === 'POINT_OF_INTEREST'
      );
      req.flush('Error', { status: 500, statusText: 'Server Error' });
    });
  });

  describe('searchPOIs', () => {
    it('should search POIs with default parameters', (done) => {
      const mockResponse = {
        items: [mockIDBPOI],
        poisInstances: [mockPOI],
        totalItems: 1,
        currentPage: 1,
        limit: 20,
        totalPages: 1,
        nextPage: null,
        previousPage: null,
      };

      service.searchPOIs().subscribe((response) => {
        expect(response.poisInstances).toHaveLength(1);
        expect(response.totalItems).toBe(1);
        done();
      });

      const req = httpMock.expectOne((request) => {
        return (
          request.url === `${apiUrl}hike/administration/pois` &&
          request.params.get('page') === '1' &&
          request.params.get('limit') === '20'
        );
      });
      expect(req.request.method).toBe('GET');
      req.flush(mockResponse);
    });

    it('should search POIs with custom query parameters', (done) => {
      const queryParams = {
        page: 2,
        limit: 10,
        query: 'restaurant',
        orderField: 'name',
        order: 'asc' as const,
        status: 'DRAFT',
      };

      const mockResponse = {
        items: [mockIDBPOI],
        poisInstances: [mockPOI],
        totalItems: 1,
        currentPage: 2,
        limit: 10,
        totalPages: 1,
        nextPage: null,
        previousPage: 1,
      };

      service.searchPOIs(queryParams).subscribe((response) => {
        expect(response.currentPage).toBe(2);
        expect(response.limit).toBe(10);
        done();
      });

      const req = httpMock.expectOne((request) => {
        return (
          request.url === `${apiUrl}hike/administration/pois` &&
          request.params.get('page') === '2' &&
          request.params.get('limit') === '10' &&
          request.params.get('query') === 'restaurant' &&
          request.params.get('orderField') === 'name' &&
          request.params.get('order') === 'asc' &&
          request.params.get('status') === 'DRAFT'
        );
      });
      expect(req.request.method).toBe('GET');
      req.flush(mockResponse);
    });

    it('should filter out POIs without id', (done) => {
      const mockResponse = {
        items: [
          mockIDBPOI,
          { ...mockIDBPOI, id: null },
          { ...mockIDBPOI, id: '2' },
        ],
        totalItems: 3,
        currentPage: 1,
        limit: 20,
        totalPages: 1,
        nextPage: null,
        previousPage: null,
      };

      service.searchPOIs().subscribe((response) => {
        // Should only have 2 POIs (the one with null id should be filtered out)
        expect(response.poisInstances).toHaveLength(2);
        done();
      });

      const req = httpMock.expectOne(
        `${apiUrl}hike/administration/pois?page=1&limit=20`
      );
      req.flush(mockResponse);
    });

    it('should handle errors when searching POIs', (done) => {
      service.searchPOIs().subscribe({
        next: () => fail('should have failed'),
        error: (error) => {
          expect(error).toBeTruthy();
          expect(messageService.add).toHaveBeenCalledWith({
            severity: 'error',
            summary: 'Erreur',
            detail: 'Impossible de rechercher les POIs',
          });
          done();
        },
      });

      const req = httpMock.expectOne((request) => {
        return (
          request.url === `${apiUrl}hike/administration/pois` &&
          request.params.get('page') === '1' &&
          request.params.get('limit') === '20'
        );
      });
      req.flush('Error', { status: 500, statusText: 'Server Error' });
    });
  });

  describe('getConfigurations', () => {
    it('should fetch POI configurations', (done) => {
      const mockConfig = {
        difficulties: ['EASY', 'MEDIUM', 'HARD'],
        status: ['ACTIVE', 'INACTIVE'],
        seasons: ['SPRING', 'SUMMER'],
        sources: ['OFFICIAL', 'COMMUNITY'],
        point_of_interest_categories: ['RESTAURANT', 'HOTEL'],
      };

      service.getConfigurations().subscribe((config) => {
        expect(config.point_of_interest_categories).toEqual([
          'RESTAURANT',
          'HOTEL',
        ]);
        expect(config.status).toEqual(['ACTIVE', 'INACTIVE']);
        done();
      });

      const req = httpMock.expectOne(`${apiUrl}hike/configurations`);
      expect(req.request.method).toBe('GET');
      req.flush(mockConfig);
    });

    it('should handle empty configurations', (done) => {
      const mockConfig = {
        difficulties: [],
        status: [],
        seasons: [],
        sources: [],
        point_of_interest_categories: [],
      };

      service.getConfigurations().subscribe((config) => {
        expect(config.point_of_interest_categories).toEqual([]);
        expect(config.status).toEqual([]);
        done();
      });

      const req = httpMock.expectOne(`${apiUrl}hike/configurations`);
      req.flush(mockConfig);
    });

    it('should fallback to map_element_categories when point_of_interest_categories is missing', (done) => {
      const mockConfig = {
        difficulties: ['EASY'],
        status: ['ACTIVE', 'INACTIVE'],
        seasons: ['SPRING'],
        sources: ['OFFICIAL', 'COMMUNITY'],
        map_element_categories: ['DANGER', 'WATER'],
      };

      service.getConfigurations().subscribe((config) => {
        expect(config.point_of_interest_categories).toEqual([
          'DANGER',
          'WATER',
        ]);
        expect(config.status).toEqual(['ACTIVE', 'INACTIVE']);
        done();
      });

      const req = httpMock.expectOne(`${apiUrl}hike/configurations`);
      expect(req.request.method).toBe('GET');
      req.flush(mockConfig);
    });

    it('should handle errors when fetching configurations', (done) => {
      service.getConfigurations().subscribe({
        next: () => fail('should have failed'),
        error: (error) => {
          expect(error).toBeTruthy();
          expect(messageService.add).toHaveBeenCalledWith({
            severity: 'error',
            summary: 'Erreur',
            detail: 'Impossible de récupérer les configurations',
          });
          done();
        },
      });

      const req = httpMock.expectOne(`${apiUrl}hike/configurations`);
      req.flush('Error', { status: 500, statusText: 'Server Error' });
    });
  });

  describe('getPendingApprovalCount', () => {
    it('should return the pending approval count', (done) => {
      service.getPendingApprovalCount().subscribe((count) => {
        expect(count).toBe(7);
        done();
      });

      const req = httpMock.expectOne(
        `${apiUrl}hike/administration/pois?page=1&limit=1&status=DRAFT`
      );
      expect(req.request.method).toBe('GET');
      req.flush({
        items: [mockIDBPOI],
        totalItems: 7,
        currentPage: 1,
        totalPages: 7,
        nextPage: 2,
        previousPage: null,
        limit: 1,
      });
    });
  });

  describe('uploadPoiImage', () => {
    it('should POST multipart to mapElement images endpoint', (done) => {
      const file = new File(['a'], 'x.png', { type: 'image/png' });
      service.uploadPoiImage('7', file).subscribe(() => done());

      const req = httpMock.expectOne(
        (r) =>
          r.url === `${apiUrl}hike/mapElement/7/images` &&
          r.params.get('type') === 'POINT_OF_INTEREST'
      );
      expect(req.request.method).toBe('POST');
      expect(req.request.body instanceof FormData).toBe(true);
      req.flush({});
    });

    it('should set image/jpeg when browser leaves file.type empty on .jpg', (done) => {
      const file = new File(['a'], 'photo.jpg', { type: '' });
      service.uploadPoiImage('7', file).subscribe(() => done());

      const req = httpMock.expectOne(
        (r) =>
          r.url === `${apiUrl}hike/mapElement/7/images` &&
          r.params.get('type') === 'POINT_OF_INTEREST'
      );
      const fd = req.request.body as FormData;
      const sent = fd.get('image') as File;
      expect(sent.type).toBe('image/jpeg');
      req.flush({});
    });
  });

  describe('deletePoiImage', () => {
    it('should DELETE administration mapElement image', (done) => {
      service.deletePoiImage('7', '99').subscribe(() => done());

      const req = httpMock.expectOne(
        (r) =>
          r.url ===
            `${apiUrl}hike/administration/mapElement/7/images/99` &&
          r.params.get('type') === 'POINT_OF_INTEREST'
      );
      expect(req.request.method).toBe('DELETE');
      req.flush({});
    });
  });
});
