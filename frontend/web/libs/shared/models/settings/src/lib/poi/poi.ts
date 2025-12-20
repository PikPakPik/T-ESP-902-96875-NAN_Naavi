import { IDB_POI } from './poi.interface';

export class POI {
  id: string; // NgRx entities requires non-null id
  name: string;
  description: string;
  types: string[];
  photos: string[];
  latitude: number;
  longitude: number;
  comment?: string;
  createdAt: Date;
  updatedAt: Date;
  status: string;

  constructor(poi: IDB_POI) {
    // NgRx entities requires non-null id, so we must have an id when creating POI instances
    if (!poi.id) {
      throw new Error('POI must have an id');
    }
    this.id = poi.id;
    this.name = poi.name;
    this.description = poi.description;
    // L'API peut renvoyer 'categories' mais on utilise 'types' en interne
    this.types = poi.types || poi.categories || [];
    this.photos = poi.photos || [];
    this.latitude = poi.latitude;
    this.longitude = poi.longitude;
    this.comment = poi.comment;
    this.createdAt = new Date(poi.createdAt);
    this.updatedAt = new Date(poi.updatedAt);
    this.status = poi.status;
  }

  getCoordinates(): { latitude: number; longitude: number } {
    return {
      latitude: this.latitude,
      longitude: this.longitude,
    };
  }

  getFormattedTypes(): string {
    return this.types.join(', ');
  }
}
