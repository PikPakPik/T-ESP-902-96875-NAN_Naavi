export interface POIImage {
  id?: string | number | null;
  filename: string;
  createdAt?: string;
}

export interface IDB_POI {
  id: string | null;
  name: string;
  description: string;
  type?: string;
  source?: string;
  userId?: string | null;
  types?: string[];
  categories?: string[];
  photos?: string[];
  images?: POIImage[];
  latitude: number;
  longitude: number;
  comment?: string;
  likes?: number;
  dislikes?: number;
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
  status?: string;
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
  sources: string[];
}
