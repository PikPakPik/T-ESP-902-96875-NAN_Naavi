import { Injectable, InjectionToken, inject } from '@angular/core';

export const MAPBOX_TOKEN = new InjectionToken<string>('MAPBOX_TOKEN');

@Injectable({
  providedIn: 'root',
})
export class MapboxService {
  #token = inject(MAPBOX_TOKEN);

  getAccessToken(): string {
    if (!this.#token) {
      console.warn('Mapbox token is not configured');
      return '';
    }
    return this.#token;
  }

  getStaticMapUrl(
    coordinates: { latitude: number; longitude: number }[],
    options: {
      width?: number;
      height?: number;
      retina?: boolean;
      padding?: number;
    } = {}
  ): string {
    const { width = 400, height = 300, retina = true, padding = 40 } = options;
    const size = `${width}x${height}${retina ? '@2x' : ''}`;
    const token = this.getAccessToken();

    if (!token || coordinates.length === 0) {
      return '';
    }

    if (coordinates.length === 1) {
      // Un seul point - centrer la carte sur ce point
      const coord = coordinates[0];
      return `https://api.mapbox.com/styles/v1/mapbox/outdoors-v12/static/pin-s-marker+285A98(${coord.longitude},${coord.latitude})/${coord.longitude},${coord.latitude},10,0,0/${size}?access_token=${token}`;
    } else {
      // Plusieurs points - créer un polyline pour afficher le tracé
      const polyline = coordinates
        .map((c) => `${c.longitude},${c.latitude}`)
        .join(';');

      return `https://api.mapbox.com/styles/v1/mapbox/outdoors-v12/static/path-5+f44-0.5(${encodeURIComponent(
        polyline
      )})/auto/${size}?access_token=${token}&padding=${padding}`;
    }
  }

  async getDirectionsRoute(
    waypoints: { longitude: number; latitude: number }[],
    profile: 'walking' | 'cycling' | 'driving' = 'walking'
  ): Promise<{
    code: string;
    routes?: Array<{
      geometry: {
        coordinates: [number, number, number?][]; // [lng, lat, elevation?]
      };
      legs?: Array<{
        steps?: Array<{
          geometry: {
            coordinates: [number, number, number?][];
          };
        }>;
      }>;
    }>;
  }> {
    const token = this.getAccessToken();

    if (!token) {
      console.warn('Cannot get directions: Mapbox token is not configured');
      return { code: 'NoToken' };
    }

    const waypointString = waypoints
      .map((c) => `${c.longitude},${c.latitude}`)
      .join(';');

    // Note: annotations=elevation nécessite un token premium, donc on l'a retiré
    const url = `https://api.mapbox.com/directions/v5/mapbox/${profile}/${waypointString}?geometries=geojson&steps=true&access_token=${token}`;

    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`Mapbox Directions API error: ${response.statusText}`);
    }

    return response.json();
  }

  /**
   * Convertit des coordonnées géographiques en coordonnées de tuile
   */
  private lonLatToTile(
    lon: number,
    lat: number,
    zoom: number
  ): {
    x: number;
    y: number;
  } {
    const n = Math.pow(2, zoom);
    const x = Math.floor(((lon + 180) / 360) * n);
    const latRad = (lat * Math.PI) / 180;
    const y = Math.floor(
      ((1 - Math.log(Math.tan(latRad) + 1 / Math.cos(latRad)) / Math.PI) / 2) *
        n
    );
    return { x, y };
  }

  /**
   * Convertit des coordonnées géographiques en position de pixel dans une tuile
   */
  private lonLatToPixel(
    lon: number,
    lat: number,
    tileX: number,
    tileY: number,
    zoom: number
  ): { px: number; py: number } {
    const n = Math.pow(2, zoom);
    const x = ((lon + 180) / 360) * n;
    const latRad = (lat * Math.PI) / 180;
    const y =
      ((1 - Math.log(Math.tan(latRad) + 1 / Math.cos(latRad)) / Math.PI) / 2) *
      n;

    const px = Math.floor((x - tileX) * 256);
    const py = Math.floor((y - tileY) * 256);

    return { px, py };
  }

  /**
   * Décode les valeurs RGB en élévation selon la formule Mapbox Terrain-RGB
   * Formule: elevation = -10000 + ((R * 256 * 256 + G * 256 + B) * 0.1)
   */
  private decodeElevation(r: number, g: number, b: number): number {
    return -10000 + (r * 256 * 256 + g * 256 + b) * 0.1;
  }

  /**
   * Charge et décode une tuile Terrain-RGB en ImageData
   * Cette méthode est utilisée pour éviter de charger plusieurs fois la même tuile
   */
  private async loadTileImageData(
    tileX: number,
    tileY: number,
    zoom: number,
    token: string
  ): Promise<ImageData | null> {
    try {
      // Récupérer l'image terrain-rgb
      const url = `https://api.mapbox.com/v4/mapbox.terrain-rgb/${zoom}/${tileX}/${tileY}.pngraw?access_token=${token}`;
      const response = await fetch(url);

      if (!response.ok) {
        console.warn(
          `Failed to fetch elevation tile ${zoom}/${tileX}/${tileY}`
        );
        return null;
      }

      // Convertir la réponse en blob puis en image
      const blob = await response.blob();
      const imageUrl = URL.createObjectURL(blob);

      return new Promise((resolve) => {
        const img = new Image();
        img.crossOrigin = 'anonymous';
        img.onload = () => {
          try {
            // Créer un canvas pour lire les pixels
            const canvas = document.createElement('canvas');
            canvas.width = img.width;
            canvas.height = img.height;
            const ctx = canvas.getContext('2d');

            if (!ctx) {
              URL.revokeObjectURL(imageUrl);
              resolve(null);
              return;
            }

            ctx.drawImage(img, 0, 0);

            // Récupérer toutes les données de l'image
            const imageData = ctx.getImageData(
              0,
              0,
              canvas.width,
              canvas.height
            );

            URL.revokeObjectURL(imageUrl);
            resolve(imageData);
          } catch (error) {
            console.error('Error decoding elevation tile:', error);
            URL.revokeObjectURL(imageUrl);
            resolve(null);
          }
        };

        img.onerror = () => {
          console.error(
            `Error loading elevation tile ${zoom}/${tileX}/${tileY}`
          );
          URL.revokeObjectURL(imageUrl);
          resolve(null);
        };

        img.src = imageUrl;
      });
    } catch (error) {
      console.error('Error loading tile:', error);
      return null;
    }
  }

  /**
   * Extrait l'élévation d'un pixel spécifique depuis une ImageData
   */
  private getElevationFromImageData(
    imageData: ImageData,
    pixelX: number,
    pixelY: number
  ): number | null {
    try {
      // S'assurer que les coordonnées du pixel sont dans les limites
      const x = Math.max(0, Math.min(imageData.width - 1, pixelX));
      const y = Math.max(0, Math.min(imageData.height - 1, pixelY));

      // Calculer l'index dans le tableau ImageData (4 valeurs par pixel: R, G, B, A)
      const index = (y * imageData.width + x) * 4;
      const [r, g, b] = imageData.data.slice(index, index + 3);

      // Décoder l'élévation
      return this.decodeElevation(r, g, b);
    } catch (error) {
      console.error('Error extracting elevation from image data:', error);
      return null;
    }
  }

  /**
   * Récupère l'élévation pour un point donné en utilisant l'API Mapbox Terrain-RGB
   * Cette méthode ne nécessite pas de token premium et fonctionne avec n'importe quel token Mapbox
   */
  async getElevationForPoint(
    latitude: number,
    longitude: number
  ): Promise<number | null> {
    const token = this.getAccessToken();

    if (!token) {
      console.warn('Cannot get elevation: Mapbox token is not configured');
      return null;
    }

    try {
      // Utiliser un zoom élevé (14-15) pour une bonne précision
      const zoom = 14;
      const { x: tileX, y: tileY } = this.lonLatToTile(
        longitude,
        latitude,
        zoom
      );

      // Charger la tuile
      const imageData = await this.loadTileImageData(tileX, tileY, zoom, token);

      if (!imageData) {
        return null;
      }

      // Obtenir la position du pixel dans la tuile
      const { px, py } = this.lonLatToPixel(
        longitude,
        latitude,
        tileX,
        tileY,
        zoom
      );

      // Extraire l'élévation
      return this.getElevationFromImageData(imageData, px, py);
    } catch (error) {
      console.error('Error getting elevation:', error);
      return null;
    }
  }

  /**
   * Récupère les élévations pour plusieurs points en utilisant l'API Mapbox Terrain-RGB.
   * Optimisé pour grouper les points par tuile et télécharger chaque tuile une seule fois.
   * Cela améliore significativement les performances avec beaucoup de points.
   */
  async getElevationsForCoordinates(
    coordinates: { latitude: number; longitude: number }[]
  ): Promise<{ latitude: number; longitude: number; elevation: number }[]> {
    if (coordinates.length === 0) {
      return [];
    }

    const token = this.getAccessToken();

    if (!token) {
      console.warn('Cannot get elevations: Mapbox token is not configured');
      return coordinates.map((c) => ({ ...c, elevation: 0 }));
    }

    const zoom = 14;

    // Grouper les coordonnées par tuile
    interface PointWithTile {
      coord: { latitude: number; longitude: number };
      tileX: number;
      tileY: number;
      pixelX: number;
      pixelY: number;
      originalIndex: number;
    }

    const pointsByTile = new Map<string, PointWithTile[]>();

    coordinates.forEach((coord, index) => {
      const { x: tileX, y: tileY } = this.lonLatToTile(
        coord.longitude,
        coord.latitude,
        zoom
      );
      const { px, py } = this.lonLatToPixel(
        coord.longitude,
        coord.latitude,
        tileX,
        tileY,
        zoom
      );

      const tileKey = `${zoom}/${tileX}/${tileY}`;
      if (!pointsByTile.has(tileKey)) {
        pointsByTile.set(tileKey, []);
      }

      const tilePoints = pointsByTile.get(tileKey);
      if (tilePoints) {
        tilePoints.push({
          coord,
          tileX,
          tileY,
          pixelX: px,
          pixelY: py,
          originalIndex: index,
        });
      }
    });

    // Charger toutes les tuiles uniques en parallèle
    const tileLoadPromises = Array.from(pointsByTile.entries()).map(
      async ([tileKey, points]) => {
        const { tileX, tileY } = points[0];
        const imageData = await this.loadTileImageData(
          tileX,
          tileY,
          zoom,
          token
        );
        return { tileKey, imageData, points };
      }
    );

    const tileResults = await Promise.all(tileLoadPromises);

    // Créer un Map pour stocker les résultats par index original
    const elevations = new Map<number, number>();

    // Extraire les élévations pour chaque point
    tileResults.forEach(({ imageData, points }) => {
      if (!imageData) {
        // Si la tuile n'a pas pu être chargée, mettre 0 pour tous les points de cette tuile
        points.forEach((point) => {
          elevations.set(point.originalIndex, 0);
        });
        return;
      }

      points.forEach((point) => {
        const elevation =
          this.getElevationFromImageData(
            imageData,
            point.pixelX,
            point.pixelY
          ) ?? 0;
        elevations.set(point.originalIndex, elevation);
      });
    });

    // Retourner les résultats dans l'ordre original
    return coordinates.map((coord, index) => ({
      ...coord,
      elevation: elevations.get(index) ?? 0,
    }));
  }
}
