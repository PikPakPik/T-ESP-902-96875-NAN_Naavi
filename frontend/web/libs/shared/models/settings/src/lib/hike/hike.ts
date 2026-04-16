import { IDB_Hike, Coordinate, HikeImage } from './hike.interface';
import { Geometry, Point, LineString, Polygon, MultiPoint } from 'wkx-ts';
import { Buffer } from 'buffer/';

export class Hike {
  id: IDB_Hike['id'];
  name: string;
  difficulty: string;
  distance: number; // en km
  location: string;
  coordinates: Coordinate[];
  waypoints: Coordinate[]; // Points cliqués par l'utilisateur (max 25)
  elevationGain: number; // dénivelé positif en mètres
  elevationLoss: number; // dénivelé négatif en mètres
  startingElevation: number; // élévation du point de départ en mètres
  arrivalElevation: number; // élévation du point d'arrivée en mètres
  estimatedDuration: number; // durée estimée en heures
  createdAt: Date;
  updatedAt: Date;
  status: string;
  source?: string; // OFFICIAL, COMMUNITY
  userId?: string;
  visibility?: string; // PUBLIC, PRIVATE, UNLISTED
  seasons?: string[]; // SPRING, SUMMER, FALL, WINTER
  images: HikeImage[];

  constructor(hike: IDB_Hike) {
    this.id = hike.id;
    this.name = hike.name;
    this.difficulty = hike.difficulty;
    // Convertir la distance de mètres en kilomètres
    this.distance = Math.round((hike.distance / 1000) * 100) / 100;
    this.location = hike.location;
    this.coordinates = this.decodeWkbGeometry(hike.wkbGeometry);
    this.waypoints = hike.wkbWaypoints
      ? this.decodeWkbGeometry(hike.wkbWaypoints)
      : this.coordinates.length > 0
      ? [this.coordinates[0], this.coordinates[this.coordinates.length - 1]]
      : [];
    this.createdAt = new Date(hike.createdAt);
    this.updatedAt = new Date(hike.updatedAt);
    this.status = hike.status;
    this.source = hike.source;
    this.userId = hike.userId;
    this.visibility = hike.visibility || 'PUBLIC';
    this.images = Array.isArray(hike.images) ? hike.images : [];
    // Gérer les saisons : s'assurer que c'est toujours un tableau
    if (Array.isArray(hike.seasons)) {
      this.seasons = hike.seasons;
    } else if (hike.seasons) {
      // Si c'est une seule valeur (ancien format), la convertir en tableau
      this.seasons = [hike.seasons];
    } else {
      this.seasons = [];
    }

    // Stocker les élévations de départ et d'arrivée
    this.startingElevation = hike.startingElevation || 0;
    this.arrivalElevation = hike.arrivalElevation || 0;

    // Calcul du dénivelé
    // Prioriser le calcul depuis les coordonnées si disponibles avec élévation (dénivelé cumulé précis)
    // Sinon utiliser directement la différence entre arrival et starting elevation
    const elevation = this.calculateElevation();
    if (elevation.gain > 0 || elevation.loss > 0) {
      // Si on a des coordonnées avec élévation, utiliser ce calcul (dénivelé cumulé)
      this.elevationGain = elevation.gain;
      this.elevationLoss = elevation.loss;
    } else {
      // Utiliser directement la différence entre les élévations de départ et d'arrivée
      const netElevation = this.arrivalElevation - this.startingElevation;
      this.elevationGain = netElevation > 0 ? Math.round(netElevation) : 0;
      this.elevationLoss =
        netElevation < 0 ? Math.round(Math.abs(netElevation)) : 0;
    }

    // Durée estimée : utiliser la valeur du backend si disponible (en secondes), sinon calculer
    if (
      hike.estimatedDuration !== undefined &&
      hike.estimatedDuration !== null
    ) {
      // Convertir les secondes en heures
      this.estimatedDuration =
        Math.round((hike.estimatedDuration / 3600) * 10) / 10;
    } else {
      // Calcul de la durée estimée (formule de Naismith)
      // Temps de base: 5 km/h + 10min par 100m de dénivelé positif
      this.estimatedDuration = this.calculateEstimatedDuration();
    }
  }

  /**
   * Décode la géométrie WKB en coordonnées
   */
  private decodeWkbGeometry(wkbHex: string): Coordinate[] {
    if (!wkbHex || wkbHex.length === 0) {
      return [];
    }

    try {
      // Convertir la chaîne hex en Buffer pour wkx-ts
      const buffer = Buffer.from(wkbHex, 'hex');

      // Parser la géométrie WKB
      const geometry = Geometry.parse(buffer as never);

      // Extraire les coordonnées selon le type de géométrie
      if (geometry instanceof Point) {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const point = geometry as any;
        return [
          {
            latitude: point.y,
            longitude: point.x,
            elevation: point.z,
          },
        ];
      } else if (geometry instanceof LineString) {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const lineString = geometry as any;
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        return lineString.points.map((point: any) => ({
          latitude: point.y,
          longitude: point.x,
          elevation: point.z,
        }));
      } else if (geometry instanceof Polygon) {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const polygon = geometry as any;
        // Retourner uniquement l'anneau extérieur
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        return polygon.exteriorRing.map((point: any) => ({
          latitude: point.y,
          longitude: point.x,
          elevation: point.z,
        }));
      } else if (geometry instanceof MultiPoint) {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const multiPoint = geometry as any;
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        return multiPoint.points.map((point: any) => ({
          latitude: point.y,
          longitude: point.x,
          elevation: point.z,
        }));
      }
      return [];
    } catch (error) {
      console.error('Erreur lors du décodage WKB:', error);
      return [];
    }
  }

  /**
   * Calcule le dénivelé positif et négatif
   */
  private calculateElevation(): { gain: number; loss: number } {
    let gain = 0;
    let loss = 0;

    for (let i = 1; i < this.coordinates.length; i++) {
      const prevElevation = this.coordinates[i - 1].elevation || 0;
      const currentElevation = this.coordinates[i].elevation || 0;

      const diff = currentElevation - prevElevation;

      if (diff > 0) {
        gain += diff;
      } else {
        loss += Math.abs(diff);
      }
    }

    return {
      gain: Math.round(gain),
      loss: Math.round(loss),
    };
  }

  /**
   * Calcule la durée estimée selon la formule de Naismith
   * Temps de base: 5 km/h + 10 minutes par 100m de dénivelé positif
   */
  private calculateEstimatedDuration(): number {
    // Temps de base pour la distance (en heures)
    const baseTime = this.distance / 5;

    // Temps supplémentaire pour le dénivelé (10 min par 100m = 1/6 heure par 100m)
    const elevationTime = (this.elevationGain / 100) * (1 / 6);

    return Math.round((baseTime + elevationTime) * 10) / 10; // arrondi à 1 décimale
  }

  /**
   * Retourne la durée formatée (ex: "2h 30min")
   */
  getFormattedDuration(): string {
    if (!this.estimatedDuration || this.estimatedDuration === 0) {
      return '0min';
    }

    const hours = Math.floor(this.estimatedDuration);
    const minutes = Math.round((this.estimatedDuration - hours) * 60);

    if (hours === 0) {
      return `${minutes}min`;
    }

    if (minutes === 0) {
      return `${hours}h`;
    }

    return `${hours}h ${minutes}min`;
  }
}
