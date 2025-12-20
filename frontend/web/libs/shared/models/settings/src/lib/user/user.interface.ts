export interface IDB_User {
  id: string;
  fullName: string;
  email: string;
  firstname: string;
  lastname: string;
  roles: string[];
  status: string;
  permissions?: string[];
  createdAt?: string;
  updatedAt?: string;
}

export interface UsersQueryParams {
  query?: string;
  page?: number;
  limit?: number;
  orderField?: string;
  order?: 'asc' | 'desc';
}

export interface PaginatedUsersResponse {
  items: IDB_User[];
  totalItems: number;
  currentPage: number;
  nextPage: number | null;
  previousPage: number | null;
  limit: number;
  totalPages: number;
}
