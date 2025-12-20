export interface IDB_POI {
  id: string | null;
  name: string;
  description: string;
  types?: string[];
  categories?: string[];
  photos: string[];
  latitude: number;
  longitude: number;
  comment?: string;
  createdAt: string;
  updatedAt: string;
  status: string;
}

export interface POICoordinate {
  latitude: number;
  longitude: number;
}

export interface POIsQueryParams {
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

export interface PaginatedPOIsResponse {
  items: IDB_POI[];
  totalItems: number;
  totalPages: number;
  currentPage: number;
  nextPage: number | null;
  previousPage: number | null;
  limit?: number;
}

export interface POIConfiguration {
  point_of_interest_categories: string[];
  status: string[];
}
