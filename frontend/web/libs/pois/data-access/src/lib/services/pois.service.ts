import { MessageService } from 'primeng/api';
import { API_URL } from '@web/shared/http-client';
import { inject, Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { catchError, map, Observable, throwError } from 'rxjs';
import {
  POI,
  IDB_POI,
  POIsQueryParams,
  PaginatedPOIsResponse,
  POIConfiguration,
} from '@web/shared/models/settings';

@Injectable({
  providedIn: 'root',
})
export class POIsService {
  #http = inject(HttpClient);
  #messageService = inject(MessageService);
  #apiUrl = inject(API_URL);

  getPOIs(): Observable<POI[]> {
    return this.#http
      .get<{ items: IDB_POI[] }>(`${this.#apiUrl}/hike/pois`)
      .pipe(
        map((response) => {
          return response.items.map((poi) => new POI(poi));
        }),
        catchError((error) => {
          this.#messageService.add({
            severity: 'error',
            summary: 'Erreur',
            detail: 'Impossible de charger les POIs',
          });
          return throwError(() => error);
        })
      );
  }

  searchPOIs(
    queryParams?: POIsQueryParams
  ): Observable<PaginatedPOIsResponse & { poisInstances: POI[] }> {
    let params = new HttpParams();

    // Valeurs par défaut obligatoires
    const page = queryParams?.page ?? 1;
    const limit = queryParams?.limit ?? 20;

    params = params.set('page', page.toString());
    params = params.set('limit', limit.toString());

    // Paramètres optionnels
    if (queryParams?.query) {
      params = params.set('query', queryParams.query);
    }
    if (queryParams?.orderField) {
      params = params.set('orderField', queryParams.orderField);
    }
    if (queryParams?.order) {
      params = params.set('order', queryParams.order);
    }
    if (queryParams?.latitude !== undefined) {
      params = params.set('latitude', queryParams.latitude.toString());
    }
    if (queryParams?.longitude !== undefined) {
      params = params.set('longitude', queryParams.longitude.toString());
    }
    if (queryParams?.radius !== undefined) {
      params = params.set('radius', queryParams.radius.toString());
    }
    if (queryParams?.distance !== undefined) {
      params = params.set('distance', queryParams.distance.toString());
    }
    if (queryParams?.difficulty) {
      params = params.set('difficulty', queryParams.difficulty);
    }

    return this.#http
      .get<PaginatedPOIsResponse>(`${this.#apiUrl}/hike/pois`, { params })
      .pipe(
        map((response) => {
          // Filter out items without id before creating POI instances
          const validItems = response.items.filter((poi) => poi.id != null);
          return {
            ...response,
            limit: response.limit ?? limit,
            poisInstances: validItems.map((poi) => new POI(poi)),
          };
        }),
        catchError((error) => {
          this.#messageService.add({
            severity: 'error',
            summary: 'Erreur',
            detail: 'Impossible de rechercher les POIs',
          });
          return throwError(() => error);
        })
      );
  }

  getPOIById(id: string): Observable<POI> {
    return this.#http.get<IDB_POI>(`${this.#apiUrl}/hike/pois/${id}`).pipe(
      map((poi) => new POI(poi)),
      catchError((error) => {
        this.#messageService.add({
          severity: 'error',
          summary: 'Erreur',
          detail: 'Impossible de charger le POI',
        });
        return throwError(() => error);
      })
    );
  }

  addPOI(poi: POI | Partial<IDB_POI>): Observable<POI> {
    // Convertir types en categories pour l'API
    const poiAsPOI = poi as POI;
    const poiAsIDB = poi as Partial<IDB_POI>;
    const categories = poiAsPOI.types || poiAsIDB.categories || [];

    // Créer le payload pour l'API avec 'categories' au lieu de 'types'
    const apiPayload: Partial<IDB_POI> = {
      id: poi.id,
      name: poi.name,
      description: poi.description,
      comment: poi.comment,
      categories,
      photos: poi.photos || [],
      latitude: poi.latitude,
      longitude: poi.longitude,
      status: poi.status,
      createdAt: poi.createdAt
        ? typeof poi.createdAt === 'string'
          ? poi.createdAt
          : poi.createdAt.toISOString()
        : undefined,
      updatedAt: poi.updatedAt
        ? typeof poi.updatedAt === 'string'
          ? poi.updatedAt
          : poi.updatedAt.toISOString()
        : undefined,
    };

    return this.#http
      .post<IDB_POI>(`${this.#apiUrl}/hike/pois`, apiPayload)
      .pipe(
        map((poi) => new POI(poi)),
        catchError((error) => {
          this.#messageService.add({
            severity: 'error',
            summary: 'Erreur',
            detail: 'Impossible de créer le POI',
          });
          return throwError(() => error);
        })
      );
  }

  updatePOI(poi: POI | Partial<IDB_POI>): Observable<POI> {
    // Convertir types en categories pour l'API
    const poiAsPOI = poi as POI;
    const poiAsIDB = poi as Partial<IDB_POI>;
    const categories = poiAsPOI.types || poiAsIDB.categories || [];

    // Créer le payload pour l'API avec 'categories' au lieu de 'types'
    const apiPayload: Partial<IDB_POI> = {
      id: poi.id,
      name: poi.name,
      description: poi.description,
      comment: poi.comment,
      categories,
      photos: poi.photos || [],
      latitude: poi.latitude,
      longitude: poi.longitude,
      status: poi.status,
      createdAt: poi.createdAt
        ? typeof poi.createdAt === 'string'
          ? poi.createdAt
          : poi.createdAt.toISOString()
        : undefined,
      updatedAt: poi.updatedAt
        ? typeof poi.updatedAt === 'string'
          ? poi.updatedAt
          : poi.updatedAt.toISOString()
        : undefined,
    };

    return this.#http
      .put<IDB_POI>(`${this.#apiUrl}/hike/pois/${poi.id}`, apiPayload)
      .pipe(
        map((poi) => new POI(poi)),
        catchError((error) => {
          this.#messageService.add({
            severity: 'error',
            summary: 'Erreur',
            detail: 'Impossible de mettre à jour le POI',
          });
          return throwError(() => error);
        })
      );
  }

  deletePOI(id: string): Observable<void> {
    return this.#http.delete<void>(`${this.#apiUrl}/hike/pois/${id}`).pipe(
      catchError((error) => {
        this.#messageService.add({
          severity: 'error',
          summary: 'Erreur',
          detail: 'Impossible de supprimer le POI',
        });
        return throwError(() => error);
      })
    );
  }

  getConfigurations(): Observable<POIConfiguration> {
    return this.#http
      .get<{
        difficulties: string[];
        status: string[];
        seasons: string[];
        sources: string[];
        point_of_interest_categories: string[];
      }>(`${this.#apiUrl}hike/configurations`)
      .pipe(
        map((response) => {
          // Extraire seulement les catégories POI et les status
          return {
            point_of_interest_categories:
              response.point_of_interest_categories || [],
            status: response.status || [],
          };
        }),
        catchError((error) => {
          this.#messageService.add({
            severity: 'error',
            summary: 'Erreur',
            detail: 'Impossible de récupérer les configurations',
          });
          return throwError(() => error);
        })
      );
  }
}
