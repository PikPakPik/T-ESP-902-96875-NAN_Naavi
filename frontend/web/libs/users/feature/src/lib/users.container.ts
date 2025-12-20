import { Component, inject, computed } from '@angular/core';
import { RouterModule } from '@angular/router';
import { Users, ColumnDef } from './users.component';
import { User } from '@web/shared/models/settings';
import { UsersStore } from '@web/users/data-access';

@Component({
  selector: 'users-container',
  standalone: true,
  imports: [RouterModule, Users],
  template: `
    <users
      [rows]="rows()"
      [columns]="columns"
      [statuses]="statuses()"
      [roles]="roles()"
      [loading]="loading()"
      [totalRecords]="totalRecords()"
      [currentPage]="currentPage()"
      [rowsPerPage]="rowsPerPage()"
      [totalPages]="totalPages()"
      (editUser)="onEditUser($event)"
      (deleteUser)="onDeleteUser($event)"
      (saveUser)="onSaveUser($event)"
      (deleteSelectedUsers)="onDeleteSelectedUsers($event)"
      (resetPassword)="onResetPassword($event)"
      (pageChange)="onPageChange($event)"
      (searchChange)="onSearchChange($event)"
    ></users>
  `,
})
export class UsersContainer {
  #usersStore = inject(UsersStore);
  loading = this.#usersStore.isPending;
  rows = this.#usersStore.entities;
  totalRecords = this.#usersStore.total;
  currentPage = this.#usersStore.page;
  rowsPerPage = this.#usersStore.limit;
  totalPages = this.#usersStore.totalPages;

  constructor() {
    // Charger les users au démarrage
    this.#usersStore.getUsers();
  }

  // Données statiques pour les filtres
  statuses = computed(() => {
    return [
      { label: 'PROFILE.STATUS.VERIFIED', value: 'VERIFIED' },
      { label: 'PROFILE.STATUS.UNVERIFIED', value: 'UNVERIFIED' },
    ];
  });

  roles = computed(() => {
    return [
      { label: 'PROFILE.ROLE.ADMIN', value: 'ROLE_ADMIN' },
      { label: 'PROFILE.ROLE.USER', value: 'ROLE_USER' },
      { label: 'PROFILE.ROLE.MODERATOR', value: 'ROLE_MODERATOR' },
    ];
  });

  columns: ColumnDef[] = [
    { field: 'id', header: 'ID', sortable: true, editable: false },
    {
      field: 'firstname',
      header: 'First Name',
      sortable: true,
      filter: true,
      editable: true,
    },
    {
      field: 'lastname',
      header: 'Last Name',
      sortable: true,
      filter: true,
      editable: true,
    },
    { field: 'email', header: 'Email', filter: true, editable: true },
    { field: 'status', header: 'Status', sortable: true, editable: true },
    { field: 'roles', header: 'Role', sortable: true, editable: true },
  ];

  onEditUser(user: User) {
    console.log('Edit user:', user);
    // Implement edit logic here
  }

  onDeleteUser(user: User) {
    this.#usersStore.delete(user.id);
  }

  onSaveUser(user: User) {
    console.log('Save user:', user);
    const index = this.rows().findIndex((u) => u.id === user.id);
    if (index !== -1) {
      this.#usersStore.update(user);
    } else {
      this.#usersStore.create(user);
    }
  }

  onDeleteSelectedUsers(users: User[]) {
    console.log('Delete selected users:', users);
    const userIds = users.map((u) => u.id);
    for (const userId of userIds) {
      this.#usersStore.delete(userId);
    }
  }

  onResetPassword(user: User) {
    this.#usersStore.resetPassword(user);
  }

  async onPageChange(event: { page: number; rows: number }) {
    this.#usersStore.setPage(event.page);
    this.#usersStore.setLimit(event.rows);
    // Recharger les users avec les nouveaux paramètres de pagination
    const params: any = {
      page: event.page,
      limit: event.rows,
    };

    await this.#usersStore.getUsers(params);
  }

  async onSearchChange(query: string) {
    // Réinitialiser à la page 1 lors d'une nouvelle recherche
    this.#usersStore.setPage(1);

    // Construire les paramètres de recherche
    const params: any = {
      page: 1,
      limit: this.#usersStore.limit(),
      query: query.trim() || undefined, // Ne pas envoyer de query vide
    };

    await this.#usersStore.getUsers(params);
  }
}
