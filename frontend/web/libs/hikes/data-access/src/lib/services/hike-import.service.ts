import { inject, Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { MessageService } from 'primeng/api';
import { API_URL } from '@web/shared/http-client';
import { catchError, Observable, throwError } from 'rxjs';

export interface ColumnMapping {
  source: string;
  unit?: string;
  values?: Record<string, string>;
}

export interface ImportMappings {
  [apiField: string]: ColumnMapping;
}

export interface ImportResponse {
  i18nKey: string;
  message: string;
  extra: unknown;
}

export const HIKE_API_FIELDS = [
  { key: 'name', label: 'IMPORT.FIELD.NAME', type: 'string' },
  { key: 'distance', label: 'IMPORT.FIELD.DISTANCE', type: 'number', units: ['METERS', 'KILOMETERS'] },
  { key: 'duration', label: 'IMPORT.FIELD.DURATION', type: 'number', units: ['SECONDS', 'MINUTES', 'HOURS'] },
  { key: 'location', label: 'IMPORT.FIELD.LOCATION', type: 'string' },
  {
    key: 'difficulty',
    label: 'IMPORT.FIELD.DIFFICULTY',
    type: 'enum',
    enumValues: ['EASY', 'MEDIUM', 'HARD'],
  },
  { key: 'startingPointLatitude', label: 'IMPORT.FIELD.STARTING_LAT', type: 'number' },
  { key: 'startingPointLongitude', label: 'IMPORT.FIELD.STARTING_LNG', type: 'number' },
  { key: 'startingElevation', label: 'IMPORT.FIELD.STARTING_ELEVATION', type: 'number' },
  { key: 'arrivalPointLatitude', label: 'IMPORT.FIELD.ARRIVAL_LAT', type: 'number' },
  { key: 'arrivalPointLongitude', label: 'IMPORT.FIELD.ARRIVAL_LNG', type: 'number' },
  { key: 'arrivalElevation', label: 'IMPORT.FIELD.ARRIVAL_ELEVATION', type: 'number' },
  { key: 'wkbGeometry', label: 'IMPORT.FIELD.WKB_GEOMETRY', type: 'string' },
  { key: 'wkbWaypoints', label: 'IMPORT.FIELD.WKB_WAYPOINTS', type: 'string' },
] as const;

export type HikeApiFieldKey = (typeof HIKE_API_FIELDS)[number]['key'];

@Injectable({
  providedIn: 'root',
})
export class HikeImportService {
  #http = inject(HttpClient);
  #messageService = inject(MessageService);
  #apiUrl = inject(API_URL);

  /**
   * Enrichit le fichier avec startingPoint/arrivalPoint dérivés de la géométrie
   * quand ils sont absents.
   */
  async enrichFileWithCoordinates(
    file: File,
    mappings: ImportMappings
  ): Promise<{ file: File; mappings: ImportMappings }> {
    const lowerName = file.name.toLowerCase();
    if (lowerName.endsWith('.geojson') || lowerName.endsWith('.json')) {
      return this.enrichGeoJsonFile(file, mappings);
    }
    if (lowerName.endsWith('.csv')) {
      return this.enrichCsvFile(file, mappings);
    }
    return { file, mappings };
  }

  private extractFirstLastFromGeometry(
    geometry: unknown
  ): { first: [number, number]; last: [number, number] } | null {
    if (!geometry || typeof geometry !== 'object') return null;
    const g = geometry as Record<string, unknown>;
    const coords = g['coordinates'];
    if (!coords || !Array.isArray(coords)) return null;

    const flat = this.flattenCoordinates(coords);
    if (flat.length < 2) {
      const pt = this.getPointFromCoords(coords);
      if (pt) return { first: pt, last: pt };
      return null;
    }
    return { first: flat[0], last: flat[flat.length - 1] };
  }

  /** GeoJSON: [lng, lat] ou [lng, lat, alt] */
  private getPointFromCoords(coords: unknown[]): [number, number] | null {
    const a = coords[0];
    const b = coords[1];
    if (typeof a === 'number' && typeof b === 'number') {
      return [a, b];
    }
    return null;
  }

  private flattenCoordinates(coords: unknown[]): [number, number][] {
    const result: [number, number][] = [];
    const first = coords[0];
    if (typeof first === 'number' && typeof coords[1] === 'number') {
      result.push([first, coords[1] as number]);
      return result;
    }
    if (Array.isArray(first)) {
      for (const c of coords) {
        if (Array.isArray(c)) {
          const pts = this.flattenCoordinates(c);
          result.push(...pts);
        }
      }
    }
    return result;
  }

  private getNested(obj: Record<string, unknown>, path: string): unknown {
    const parts = path.split('.');
    let current: unknown = obj;
    for (const p of parts) {
      if (current == null || typeof current !== 'object') return undefined;
      current = (current as Record<string, unknown>)[p];
    }
    return current;
  }

  private async enrichGeoJsonFile(
    file: File,
    mappings: ImportMappings
  ): Promise<{ file: File; mappings: ImportMappings }> {
    const text = await file.text();
    const parsed = JSON.parse(text) as Record<string, unknown>;
    const features = parsed['features'];
    if (!Array.isArray(features)) return { file, mappings };

    const startMapping = mappings['startingPointLatitude']?.source;
    const startLngMapping = mappings['startingPointLongitude']?.source;
    const arrivalMapping = mappings['arrivalPointLatitude']?.source;
    const arrivalLngMapping = mappings['arrivalPointLongitude']?.source;
    const geometrySource =
      mappings['wkbGeometry']?.source ?? 'geometry';

    let enriched = false;
    for (const f of features) {
      if (!f || typeof f !== 'object') continue;
      const feature = f as Record<string, unknown>;
      const props = feature['properties'] as Record<string, unknown> | undefined;
      if (!props) continue;
      const geom =
        feature['geometry'] ??
        (geometrySource && this.getNested(props, geometrySource));
      const pts = this.extractFirstLastFromGeometry(geom);
      if (!pts) continue;

      const [startLng, startLat] = pts.first;
      const [arrLng, arrLat] = pts.last;

      const hasStartLat =
        startMapping && this.getNested(props, startMapping) != null;
      const hasStartLng =
        startLngMapping && this.getNested(props, startLngMapping) != null;
      if (!hasStartLat || !hasStartLng) {
        props['startingPointLatitude'] = startLat;
        props['startingPointLongitude'] = startLng;
        enriched = true;
      }

      const hasArrLat =
        arrivalMapping && this.getNested(props, arrivalMapping) != null;
      const hasArrLng =
        arrivalLngMapping && this.getNested(props, arrivalLngMapping) != null;
      if (!hasArrLat || !hasArrLng) {
        props['arrivalPointLatitude'] = arrLat;
        props['arrivalPointLongitude'] = arrLng;
        enriched = true;
      }
    }

    const newMappings = { ...mappings };
    if (enriched) {
      if (!newMappings['startingPointLatitude']) {
        newMappings['startingPointLatitude'] = {
          source: 'startingPointLatitude',
        };
      }
      if (!newMappings['startingPointLongitude']) {
        newMappings['startingPointLongitude'] = {
          source: 'startingPointLongitude',
        };
      }
      if (!newMappings['arrivalPointLatitude']) {
        newMappings['arrivalPointLatitude'] = {
          source: 'arrivalPointLatitude',
        };
      }
      if (!newMappings['arrivalPointLongitude']) {
        newMappings['arrivalPointLongitude'] = {
          source: 'arrivalPointLongitude',
        };
      }
    }

    if (!enriched) return { file, mappings };
    const blob = new Blob([JSON.stringify(parsed)], {
      type: file.type || 'application/json',
    });
    const newFile = new File([blob], file.name, { type: blob.type });
    return { file: newFile, mappings: newMappings };
  }

  private async enrichCsvFile(
    file: File,
    mappings: ImportMappings
  ): Promise<{ file: File; mappings: ImportMappings }> {
    const text = await file.text();
    const lines = text.split(/\r?\n/).filter((l) => l.trim());
    if (lines.length < 2) return { file, mappings };

    const firstLine = lines[0];
    const separators = [';', ',', '\t'];
    let separator = ';';
    let maxCount = 0;
    for (const sep of separators) {
      const count = firstLine.split(sep).length;
      if (count > maxCount) {
        maxCount = count;
        separator = sep;
      }
    }

    const headers = this.parseCsvLine(firstLine, separator);
    const geometryCol =
      mappings['wkbGeometry']?.source ?? mappings['geometry']?.source;
    if (!geometryCol) return { file, mappings };

    const geomIdx = headers.indexOf(geometryCol);
    if (geomIdx === -1) return { file, mappings };

    const startLatCol = mappings['startingPointLatitude']?.source;
    const startLngCol = mappings['startingPointLongitude']?.source;
    const arrivalLatCol = mappings['arrivalPointLatitude']?.source;
    const arrivalLngCol = mappings['arrivalPointLongitude']?.source;

    let startLatIdx = startLatCol ? headers.indexOf(startLatCol) : -1;
    let startLngIdx = startLngCol ? headers.indexOf(startLngCol) : -1;
    let arrivalLatIdx = arrivalLatCol ? headers.indexOf(arrivalLatCol) : -1;
    let arrivalLngIdx = arrivalLngCol ? headers.indexOf(arrivalLngCol) : -1;

    const newHeaders = [...headers];
    if (startLatIdx === -1) {
      newHeaders.push('startingPointLatitude');
      startLatIdx = newHeaders.length - 1;
    }
    if (startLngIdx === -1) {
      newHeaders.push('startingPointLongitude');
      startLngIdx = newHeaders.length - 1;
    }
    if (arrivalLatIdx === -1) {
      newHeaders.push('arrivalPointLatitude');
      arrivalLatIdx = newHeaders.length - 1;
    }
    if (arrivalLngIdx === -1) {
      newHeaders.push('arrivalPointLongitude');
      arrivalLngIdx = newHeaders.length - 1;
    }

    let enriched = false;
    const newRows: string[][] = [];
    for (let i = 1; i < lines.length; i++) {
      const row = this.parseCsvLine(lines[i], separator);
      const geomRaw = row[geomIdx];
      let geom: unknown = null;
      if (geomRaw) {
        try {
          geom = typeof geomRaw === 'string' ? JSON.parse(geomRaw) : geomRaw;
        } catch {
          geom = null;
        }
      }
      const pts = geom ? this.extractFirstLastFromGeometry(geom) : null;

      const newRow = [...row];
      while (newRow.length < newHeaders.length) {
        newRow.push('');
      }

      if (pts) {
        const [startLng, startLat] = pts.first;
        const [arrLng, arrLat] = pts.last;
        const hasStart =
          (startLatIdx < row.length && row[startLatIdx]?.trim()) ||
          (startLngIdx < row.length && row[startLngIdx]?.trim());
        if (!hasStart) {
          newRow[startLatIdx] = String(startLat);
          newRow[startLngIdx] = String(startLng);
          enriched = true;
        }
        const hasArrival =
          (arrivalLatIdx < row.length && row[arrivalLatIdx]?.trim()) ||
          (arrivalLngIdx < row.length && row[arrivalLngIdx]?.trim());
        if (!hasArrival) {
          newRow[arrivalLatIdx] = String(arrLat);
          newRow[arrivalLngIdx] = String(arrLng);
          enriched = true;
        }
      }
      newRows.push(newRow);
    }

    if (!enriched) return { file, mappings };

    const newMappings = { ...mappings };
    if (!newMappings['startingPointLatitude']) {
      newMappings['startingPointLatitude'] = {
        source: 'startingPointLatitude',
      };
    }
    if (!newMappings['startingPointLongitude']) {
      newMappings['startingPointLongitude'] = {
        source: 'startingPointLongitude',
      };
    }
    if (!newMappings['arrivalPointLatitude']) {
      newMappings['arrivalPointLatitude'] = {
        source: 'arrivalPointLatitude',
      };
    }
    if (!newMappings['arrivalPointLongitude']) {
      newMappings['arrivalPointLongitude'] = {
        source: 'arrivalPointLongitude',
      };
    }

    const csvContent = [
      newHeaders.join(separator),
      ...newRows.map((r) =>
        r
          .map((c) => (c.includes(separator) || c.includes('"') ? `"${c}"` : c))
          .join(separator)
      ),
    ].join('\n');
    const blob = new Blob([csvContent], { type: file.type || 'text/csv' });
    const newFile = new File([blob], file.name, { type: blob.type });
    return { file: newFile, mappings: newMappings };
  }

  importHikes(file: File, mappings: ImportMappings): Observable<ImportResponse> {
    const formData = new FormData();
    formData.append('file', file);
    formData.append(
      'mapping',
      JSON.stringify({
        mappings,
      })
    );

    return this.#http
      .post<ImportResponse>(`${this.#apiUrl}hike/import/hike`, formData)
      .pipe(
        catchError((error) => {
          const detail =
            error?.error?.extra?.message ||
            error?.error?.message ||
            'Failed to import hikes';
          this.#messageService.add({
            severity: 'error',
            summary: 'Import Error',
            detail,
          });
          return throwError(() => error);
        })
      );
  }

  parseImportHeaders(file: File): Promise<{ headers: string[]; preview: string[][] }> {
    const lowerName = file.name.toLowerCase();

    if (lowerName.endsWith('.csv')) {
      return this.parseCsvHeaders(file);
    }

    if (lowerName.endsWith('.geojson') || lowerName.endsWith('.json')) {
      return this.parseJsonLikeHeaders(file);
    }

    return Promise.reject(new Error('Unsupported file format'));
  }

  /**
   * Parse les headers d'un fichier CSV côté client pour le preview
   */
  parseCsvHeaders(file: File): Promise<{ headers: string[]; preview: string[][] }> {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = (e) => {
        try {
          const text = e.target?.result as string;
          const lines = text.split(/\r?\n/).filter((line) => line.trim());
          if (lines.length === 0) {
            reject(new Error('Empty file'));
            return;
          }

          // Détecter le séparateur (virgule, point-virgule, tab)
          const firstLine = lines[0];
          const separators = [';', ',', '\t'];
          let separator = ',';
          let maxCount = 0;
          for (const sep of separators) {
            const count = firstLine.split(sep).length;
            if (count > maxCount) {
              maxCount = count;
              separator = sep;
            }
          }

          const headers = this.parseCsvLine(firstLine, separator);
          const preview: string[][] = [];
          for (let i = 1; i < Math.min(lines.length, 6); i++) {
            preview.push(this.parseCsvLine(lines[i], separator));
          }

          resolve({ headers, preview });
        } catch (error) {
          reject(error);
        }
      };
      reader.onerror = () => reject(new Error('Failed to read file'));
      reader.readAsText(file);
    });
  }

  private parseJsonLikeHeaders(
    file: File
  ): Promise<{ headers: string[]; preview: string[][] }> {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = (e) => {
        try {
          const text = e.target?.result as string;
          const parsed = JSON.parse(text);

          const rows = this.extractRowsFromJson(parsed);
          if (!rows.length) {
            reject(new Error('No data found in JSON file'));
            return;
          }

          const headers = Object.keys(rows[0]);
          const preview = rows.slice(0, 5).map((row) =>
            headers.map((header) => this.stringifyPreviewValue(row[header]))
          );

          resolve({ headers, preview });
        } catch (error) {
          reject(error);
        }
      };
      reader.onerror = () => reject(new Error('Failed to read file'));
      reader.readAsText(file);
    });
  }

  private extractRowsFromJson(data: unknown): Record<string, unknown>[] {
    if (!data || typeof data !== 'object') {
      return [];
    }

    const typed = data as Record<string, unknown>;
    const features = typed['features'];

    if (Array.isArray(features) && features.length > 0) {
      const rows: Record<string, unknown>[] = [];
      for (const feature of features) {
        if (!feature || typeof feature !== 'object') {
          continue;
        }
        const featureObj = feature as Record<string, unknown>;
        const rawProperties = featureObj['properties'];
        const properties =
          rawProperties && typeof rawProperties === 'object'
            ? (rawProperties as Record<string, unknown>)
            : {};
        const geometry = featureObj['geometry'] ?? null;
        rows.push({
          ...properties,
          geometry,
        });
      }
      return rows;
    }

    if (Array.isArray(data)) {
      return data.filter(
        (row): row is Record<string, unknown> =>
          !!row && typeof row === 'object' && !Array.isArray(row)
      );
    }

    return [typed];
  }

  private stringifyPreviewValue(value: unknown): string {
    if (value === null || value === undefined) {
      return '';
    }
    if (typeof value === 'string') {
      return value;
    }
    if (typeof value === 'number' || typeof value === 'boolean') {
      return String(value);
    }
    try {
      return JSON.stringify(value);
    } catch {
      return String(value);
    }
  }

  private parseCsvLine(line: string, separator: string): string[] {
    const result: string[] = [];
    let current = '';
    let inQuotes = false;

    for (let i = 0; i < line.length; i++) {
      const char = line[i];
      if (char === '"') {
        if (inQuotes && line[i + 1] === '"') {
          current += '"';
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char === separator && !inQuotes) {
        result.push(current.trim());
        current = '';
      } else {
        current += char;
      }
    }
    result.push(current.trim());
    return result;
  }
}
