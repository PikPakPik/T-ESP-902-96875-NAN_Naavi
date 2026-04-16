import { Tag, TagModule } from 'primeng/tag';
import { TableModule } from 'primeng/table';
import { User } from '@web/shared/models/settings';
import { Component, inject, input, output, signal } from '@angular/core';
import { ButtonModule } from 'primeng/button';
import { IMAGES_BASE_URL } from '@web/shared/http-client';
import { InputTextModule } from 'primeng/inputtext';
import { SelectModule } from 'primeng/select';

import { FormsModule } from '@angular/forms';
import { SelectItem } from 'primeng/api';
import { MultiSelectModule } from 'primeng/multiselect';
import { IconFieldModule } from 'primeng/iconfield';
import { InputIconModule } from 'primeng/inputicon';
import { Table } from 'primeng/table';
import { ToolbarModule } from 'primeng/toolbar';
import { DialogModule } from 'primeng/dialog';
import { ConfirmDialogModule } from 'primeng/confirmdialog';
import { ConfirmationService, MessageService } from 'primeng/api';
import { ToastModule } from 'primeng/toast';
import { TooltipModule } from 'primeng/tooltip';
import { Router } from '@angular/router';
import { TranslateModule, TranslateService } from '@ngx-translate/core';

export type ColumnDef = {
  field: string;
  header: string;
  sortable?: boolean;
  filter?: boolean;
  editable?: boolean;
};

@Component({
  selector: 'users',
  standalone: true,
  imports: [
    TableModule,
    TagModule,
    SelectModule,
    ButtonModule,
    InputTextModule,
    FormsModule,
    MultiSelectModule,
    IconFieldModule,
    InputIconModule,
    ToolbarModule,
    DialogModule,
    ConfirmDialogModule,
    ToastModule,
    TooltipModule,
    TranslateModule
],
  providers: [ConfirmationService, MessageService],
  templateUrl: './users.component.html',
  styleUrls: ['./users.component.scss'],
})
export class Users {
  #confirmationService = inject(ConfirmationService);
  #router = inject(Router);
  #translateService = inject(TranslateService);
  #imagesBaseUrl = inject(IMAGES_BASE_URL, { optional: true });
  rows = input<User[]>([]);
  columns = input<ColumnDef[]>([]);
  statuses = input<SelectItem[]>([]);
  roles = input<SelectItem[]>([]);
  loading = input<boolean>(false);
  totalRecords = input<number>(0);
  totalPages = input<number>(0);
  currentPage = input<number>(1);
  rowsPerPage = input<number>(10);
  selectedUsers: User[] = [];

  userDialog = signal(false);
  user = signal<User>({} as User);
  submitted = signal(false);

  editUser = output<User>();
  deleteUser = output<User>();
  saveUser = output<User>();
  deleteSelectedUsers = output<User[]>();
  resetPassword = output<User>();
  pageChange = output<{ page: number; rows: number }>();
  searchChange = output<string>();

  // Timer pour le debounce de la recherche
  #searchTimeout: ReturnType<typeof setTimeout> | null = null;

  clear(table: Table) {
    table.clear();
  }

  onSearchChange(event: Event) {
    const value = (event.target as HTMLInputElement).value;

    // Annuler le timer précédent s'il existe
    if (this.#searchTimeout) {
      clearTimeout(this.#searchTimeout);
    }

    // Débouncer la recherche (500ms)
    this.#searchTimeout = setTimeout(() => {
      this.searchChange.emit(value);
    }, 500);
  }

  onPageChange(event: { first: number; rows: number; page?: number }) {
    // Avec lazy="true", PrimeNG fournit 'page' (0-based) dans l'événement
    // On convertit en 1-based pour notre store
    const page =
      event.page !== undefined
        ? event.page + 1
        : Math.floor(event.first / event.rows) + 1;

    this.pageChange.emit({
      page,
      rows: event.rows,
    });
  }

  openNew() {
    this.#router.navigate(['/backoffice/users/new']);
  }

  editUserDialog(user: User) {
    this.#router.navigate(['/backoffice/users/edit', user.id]);
  }

  viewUserDetails(user: User) {
    this.#router.navigate(['/backoffice/users', user.id]);
  }

  hideDialog() {
    this.userDialog.set(false);
    this.submitted.set(false);
  }

  onRolesChange(selectedRoles: string[]) {
    // Always include USER role along with selected roles, avoiding duplicates
    const currentUser = this.user();
    const validRoles = selectedRoles
      ? selectedRoles.filter((role) => role && role.trim())
      : [];

    // Combine USER role with selected roles and remove duplicates
    const allRoles = ['ROLE_USER', ...validRoles];
    const uniqueRoles = [...new Set(allRoles)] as User['roles'];

    this.user.set({
      ...currentUser,
      roles: uniqueRoles,
    });
  }

  saveUserDialog() {
    this.submitted.set(true);

    if (
      this.user().firstname?.trim() &&
      this.user().lastname?.trim() &&
      this.user().email?.trim()
    ) {
      // USER role is already ensured by onRolesChange method
      this.saveUser.emit(this.user());
      this.userDialog.set(false);
      this.user.set({} as User);
    }
  }

  deleteUserConfirm(user: User) {
    this.#confirmationService.confirm({
      message: this.#translateService.instant('USER.CONFIRM.DELETE', {
        name: `${user.firstname} ${user.lastname}`,
      }),
      header: this.#translateService.instant('COMMON.CONFIRM') || 'Confirm',
      icon: 'pi pi-exclamation-triangle',
      accept: () => {
        this.deleteUser.emit(user);
      },
    });
  }

  deleteSelectedUsersConfirm() {
    this.#confirmationService.confirm({
      message: this.#translateService.instant('USER.CONFIRM.DELETE_SELECTED'),
      header: this.#translateService.instant('COMMON.CONFIRM') || 'Confirm',
      icon: 'pi pi-exclamation-triangle',
      accept: () => {
        this.deleteSelectedUsers.emit(this.selectedUsers);
        this.selectedUsers = [];
      },
    });
  }

  resetPasswordConfirm(user: User) {
    this.#confirmationService.confirm({
      message: this.#translateService.instant('USER.CONFIRM.RESET_PASSWORD', {
        name: `${user.firstname} ${user.lastname}`,
      }),
      header: this.#translateService.instant('COMMON.CONFIRM') || 'Confirm',
      icon: 'pi pi-key',
      accept: () => {
        this.resetPassword.emit(user);
      },
    });
  }

  getProfilePictureUrl(user: User): string | null {
    const path = user.profilePicture;
    const base = this.#imagesBaseUrl?.trim().replace(/\/$/, '') ?? '';
    console.log('path', path);
    console.log('base', base);
    if (!path || !base) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    const cleanPath = path.replace(/^\//, '');
    console.log('base', base);
    console.log('cleanPath', cleanPath);
    return `${base}/${cleanPath}`;
  }

  getSeverity(status: string | null | undefined): Tag['severity'] {
    switch ((status || '').toLowerCase()) {
      case 'active':
      case 'available':
      case 'ok':
        return 'success';
      case 'pending':
      case 'draft':
        return 'info';
      case 'disabled':
      case 'blocked':
        return 'danger';
      default:
        return 'secondary';
    }
  }
}
