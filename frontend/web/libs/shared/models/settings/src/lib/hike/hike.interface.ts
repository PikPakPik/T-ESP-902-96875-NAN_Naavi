import { HikeHistoryItem } from './hike-history.interface';

export interface IDB_Hike {
  id: string;
  name: string;
  startingPointLatitude: number;
  startingPointLongitude: number;
  startingElevation: number;
  arrivalPointLatitude: number;
  arrivalPointLongitude: number;
  arrivalElevation: number;
  wkbGeometry: string;
  wkbWaypoints?: string; // Points cliqués par l'utilisateur (max 25)
  distance: number;
  location: string;
  difficulty: string;
  status: string;
  source?: string; // OFFICIAL, COMMUNITY
  seasons?: string[]; // SPRING, SUMMER, FALL, WINTER
  estimatedDuration?: number; // durée en secondes depuis le backend
  createdAt: string;
  updatedAt: string;
}

export interface Coordinate {
  latitude: number;
  longitude: number;
  elevation?: number;
}

export interface HikesQueryParams {
  query?: string;
  page?: number;
  limit?: number;
  orderField?: string;
  order?: 'asc' | 'desc';
  latitude?: number;
  longitude?: number;
  radius?: number;
  distance?: number;
  difficulty?: string;
}

export interface PaginatedHikesResponse {
  items: IDB_Hike[];
  totalItems: number;
  currentPage: number;
  nextPage: number | null;
  previousPage: number | null;
  limit: number;
  totalPages: number;
}

export interface HikeHistoryQueryParams {
  query?: string;
  page?: number;
  limit?: number;
  orderField?: string;
  order?: 'asc' | 'desc';
}

export interface PaginatedHikeHistoryResponse {
  items: HikeHistoryItem[];
  totalItems: number;
  currentPage: number;
  nextPage: number | null;
  previousPage: number | null;
  limit: number;
  totalPages: number;
}

export interface HikeConfiguration {
  difficulties: string[];
  status: string[];
  sources: string[];
  seasons: string[];
}
