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
      .get<{ items: IDB_POI[] }>(`${this.#apiUrl}hike/mapElements`, {
        params: new HttpParams().set('type', 'POINT_OF_INTEREST'),
      })
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
    if (queryParams?.status) {
      params = params.set('status', queryParams.status);
    }

    return this.#http
      .get<PaginatedPOIsResponse>(`${this.#apiUrl}hike/administration/pois`, {
        params,
      })
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
    return this.#http
      .get<IDB_POI>(`${this.#apiUrl}hike/mapElement/${id}`, {
        params: new HttpParams().set('type', 'POINT_OF_INTEREST'),
      })
      .pipe(
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
      type: 'POINT_OF_INTEREST',
      source: poi.source,
      userId: poi.userId ?? null,
      categories,
      latitude: poi.latitude,
      longitude: poi.longitude,
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
      .post<IDB_POI>(`${this.#apiUrl}hike/mapElement`, apiPayload)
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

  deletePOI(id: string): Observable<void> {
    return this.#http
      .delete<void>(`${this.#apiUrl}hike/administration/mapElement/${id}`, {
        params: new HttpParams().set('type', 'POINT_OF_INTEREST'),
      })
      .pipe(
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
      type: 'POINT_OF_INTEREST',
      source: poi.source,
      userId: poi.userId ?? null,
      categories,
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
      .put<IDB_POI>(
        `${this.#apiUrl}hike/administration/mapElement/${poi.id}`,
        apiPayload
      )
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

  getConfigurations(): Observable<POIConfiguration> {
    return this.#http
      .get<{
        difficulties: string[];
        status: string[];
        seasons: string[];
        sources: string[];
        point_of_interest_categories: string[];
        map_element_categories?: string[];
      }>(`${this.#apiUrl}hike/configurations`)
      .pipe(
        map((response) => {
          // Extraire seulement les catégories POI et les status
          return {
            point_of_interest_categories:
              response.point_of_interest_categories ||
              response.map_element_categories ||
              [],
            status: response.status || [],
            sources: response.sources || [],
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

  getPendingApprovalCount(): Observable<number> {
    return this.searchPOIs({ page: 1, limit: 1, status: 'DRAFT' }).pipe(
      map((response) => response.totalItems ?? 0)
    );
  }

  /**
   * Spring exige un Content-Type image exact ; certains navigateurs laissent
   * `file.type` vide — on le déduit de l'extension.
   */
  #fileWithImageMimeForUpload(file: File): File {
    const type = (file.type || '').toLowerCase();
    const allowed = new Set([
      'image/png',
      'image/jpeg',
      'image/jpg',
      'image/webp',
      'image/svg+xml',
      'image/heic',
    ]);
    if (allowed.has(type)) {
      return file;
    }
    const ext = file.name.split('.').pop()?.toLowerCase() ?? '';
    const mimeByExt: Record<string, string> = {
      png: 'image/png',
      jpg: 'image/jpeg',
      jpeg: 'image/jpeg',
      webp: 'image/webp',
      svg: 'image/svg+xml',
      heic: 'image/heic',
    };
    const guessed = mimeByExt[ext];
    if (!guessed) {
      return file;
    }
    return new File([file], file.name, {
      type: guessed,
      lastModified: file.lastModified,
    });
  }

  /**
   * Upload brut d'une image POI (multipart, champ `image`), comme le service hike
   * {@code POST /hike/mapElement/{id}/images?type=POINT_OF_INTEREST}.
   */
  uploadPoiImage(poiId: string, file: File): Observable<void> {
    const uploadFile = this.#fileWithImageMimeForUpload(file);
    const formData = new FormData();
    formData.append('image', uploadFile, uploadFile.name);
    return this.#http
      .post<void>(`${this.#apiUrl}hike/mapElement/${poiId}/images`, formData, {
        params: new HttpParams().set('type', 'POINT_OF_INTEREST'),
      })
      .pipe(
        catchError((error) => {
          this.#messageService.add({
            severity: 'error',
            summary: 'Erreur',
            detail: "Impossible d'envoyer l'image du POI",
          });
          return throwError(() => error);
        })
      );
  }

  deletePoiImage(elementId: string, imageId: string): Observable<void> {
    return this.#http
      .delete<void>(
        `${this.#apiUrl}hike/administration/mapElement/${elementId}/images/${imageId}`,
        { params: new HttpParams().set('type', 'POINT_OF_INTEREST') }
      )
      .pipe(
        catchError((error) => {
          this.#messageService.add({
            severity: 'error',
            summary: 'Erreur',
            detail: "Impossible de supprimer l'image du POI",
          });
          return throwError(() => error);
        })
      );
  }
}
