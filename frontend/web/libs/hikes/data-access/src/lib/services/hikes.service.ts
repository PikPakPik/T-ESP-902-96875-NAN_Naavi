import { MessageService } from 'primeng/api';
import { API_URL } from '@web/shared/http-client';
import { inject, Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { catchError, map, Observable, throwError } from 'rxjs';
import {
  Hike,
  IDB_Hike,
  HikesQueryParams,
  PaginatedHikesResponse,
  Coordinate,
  HikeConfiguration,
  HikeHistoryQueryParams,
  PaginatedHikeHistoryResponse,
} from '@web/shared/models/settings';
import { Geometry, LineString, Point } from 'wkx-ts';
import { Buffer } from 'buffer/';

@Injectable({
  providedIn: 'root',
})
export class HikesService {
  #http = inject(HttpClient);
  #messageService = inject(MessageService);
  #apiUrl = inject(API_URL);

  getHikes(
    queryParams?: HikesQueryParams
  ): Observable<PaginatedHikesResponse & { hikesInstances: Hike[] }> {
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
      .get<PaginatedHikesResponse>(`${this.#apiUrl}hike/administration/hikes`, { params })
      .pipe(
        map((response) => {
          return {
            ...response,
            hikesInstances: response.items.map((hike) => new Hike(hike)),
          };
        }),
        catchError((error) => {
          this.#messageService.add({
            severity: 'error',
            summary: 'Error',
            detail: 'Failed to get hikes',
          });
          return throwError(() => error);
        })
      );
  }

  getHikeById(id: string): Observable<Hike> {
    return this.#http.get<IDB_Hike>(`${this.#apiUrl}hike/hikes/${id}`).pipe(
      map((hike) => new Hike(hike)),
      catchError((error) => {
        this.#messageService.add({
          severity: 'error',
          summary: 'Error',
          detail: 'Failed to get hike',
        });
        return throwError(() => error);
      })
    );
  }

  getUserHikeHistory(
    userId: string,
    queryParams?: HikeHistoryQueryParams
  ): Observable<PaginatedHikeHistoryResponse> {
    let params = new HttpParams();

    const page = queryParams?.page ?? 1;
    const limit = queryParams?.limit ?? 20;

    params = params.set('page', page.toString());
    params = params.set('limit', limit.toString());

    if (queryParams?.query) {
      params = params.set('query', queryParams.query);
    }
    if (queryParams?.orderField) {
      params = params.set('orderField', queryParams.orderField);
    }
    if (queryParams?.order) {
      params = params.set('order', queryParams.order);
    }

    return this.#http
      .get<PaginatedHikeHistoryResponse>(
        `${this.#apiUrl}hike/administration/hikes/history/user/${userId}`,
        { params }
      )
      .pipe(
        catchError((error) => {
          this.#messageService.add({
            severity: 'error',
            summary: 'Error',
            detail: 'Failed to get user hike history',
          });
          return throwError(() => error);
        })
      );
  }

  addHike(hike: Hike): Observable<Hike> {
    const hikePayload = this.hikeToPayload(hike);
    return this.#http
      .post<IDB_Hike>(`${this.#apiUrl}hike/hikes`, hikePayload)
      .pipe(
        map((hike) => new Hike(hike)),
        catchError((error) => {
          this.#messageService.add({
            severity: 'error',
            summary: 'Error',
            detail: 'Failed to add hike',
          });
          return throwError(() => error);
        })
      );
  }

  updateHike(hike: Hike): Observable<Hike> {
    const hikePayload = this.hikeToPayload(hike);
    return this.#http
      .put<IDB_Hike>(
        `${this.#apiUrl}hike/administration/hikes/${hike.id}`,
        hikePayload
      )
      .pipe(
        map((hike) => new Hike(hike)),
        catchError((error) => {
          this.#messageService.add({
            severity: 'error',
            summary: 'Error',
            detail: 'Failed to update hike',
          });
          return throwError(() => error);
        })
      );
  }

  deleteHike(id: string): Observable<void> {
    return this.#http
      .delete<void>(`${this.#apiUrl}hike/administration/hikes/${id}`)
      .pipe(
        catchError((error) => {
          this.#messageService.add({
            severity: 'error',
            summary: 'Error',
            detail: 'Failed to delete hike',
          });
          return throwError(() => error);
        })
      );
  }

  getConfigurations(): Observable<HikeConfiguration> {
    return this.#http
      .get<HikeConfiguration>(`${this.#apiUrl}hike/configurations`)
      .pipe(
        catchError((error) => {
          this.#messageService.add({
            severity: 'error',
            summary: 'Error',
            detail: 'Failed to get configurations',
          });
          return throwError(() => error);
        })
      );
  }

  /**
   * Convertit un objet Hike en payload pour l'API
   */
  private hikeToPayload(hike: Hike): unknown {
    const coords = hike.coordinates || [];
    const waypoints = hike.waypoints || [];

    // Déterminer les points de départ et d'arrivée
    const startPoint = coords[0] || { latitude: 0, longitude: 0, elevation: 0 };
    const endPoint = coords[coords.length - 1] || {
      latitude: 0,
      longitude: 0,
      elevation: 0,
    };

    // Encoder les coordonnées en WKB avec gestion d'erreur
    let wkbGeometry = '';
    let wkbWaypoints = '';

    try {
      wkbGeometry = this.coordinatesToWkb(coords);
      wkbWaypoints = this.coordinatesToWkb(waypoints);
    } catch (error) {
      console.error('Error encoding coordinates to WKB:', error);
      // Continue with empty WKB strings rather than failing
    }

    // Calculer la durée en secondes à partir de estimatedDuration (en heures)
    const durationInSeconds = Math.round((hike.estimatedDuration || 0) * 3600);

    return {
      name: hike.name,
      startingPointLatitude: startPoint.latitude,
      startingPointLongitude: startPoint.longitude,
      startingElevation: startPoint.elevation || 0,
      arrivalPointLatitude: endPoint.latitude,
      arrivalPointLongitude: endPoint.longitude,
      arrivalElevation: endPoint.elevation || 0,
      wkbGeometry: wkbGeometry,
      wkbWaypoints: wkbWaypoints,
      distance: Math.round(hike.distance * 1000), // Convertir km en mètres
      duration: durationInSeconds,
      difficulty: hike.difficulty,
      status: hike.status || 'PUBLISHED',
      visibility: hike.visibility || 'PUBLIC',
      source: hike.source,
      userId: hike.userId,
    };
  }

  /**
   * Encode un tableau de coordonnées en WKB (Well-Known Binary) hexadécimal
   */
  private coordinatesToWkb(coordinates: Coordinate[]): string {
    if (!coordinates || coordinates.length === 0) {
      return '';
    }

    try {
      let geometry: Geometry;

      if (coordinates.length === 1) {
        // Point unique avec Z (altitude)
        const coord = coordinates[0];
        geometry = new Point(
          coord.longitude,
          coord.latitude,
          coord.elevation || 0,
          0 // M value (non utilisé)
        );
      } else {
        // LineString pour un tracé avec Z (altitude)
        const points = coordinates.map(
          (coord) =>
            new Point(
              coord.longitude,
              coord.latitude,
              coord.elevation || 0,
              0 // M value (non utilisé)
            )
        );
        geometry = new LineString(points);
      }

      // Convertir en buffer puis en hex
      const buffer = geometry.toWkb() as Buffer;
      return buffer.toString('hex');
    } catch (error) {
      console.error("Erreur lors de l'encodage WKB:", error);
      return '';
    }
  }
}
