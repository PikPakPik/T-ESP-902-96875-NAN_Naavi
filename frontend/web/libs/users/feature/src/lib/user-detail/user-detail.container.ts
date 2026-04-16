import { Component, computed, inject } from '@angular/core';
import { Router, RouterModule } from '@angular/router';
import { UserDetailsStore } from '@web/users/data-access';
import { IMAGES_BASE_URL } from '@web/shared/http-client';
import { UserDetailComponent } from './user-detail.component';
import { ConfirmDialogModule } from 'primeng/confirmdialog';
import { ConfirmationService } from 'primeng/api';
import { TranslateModule, TranslateService } from '@ngx-translate/core';

@Component({
  selector: 'user-detail-container',
  standalone: true,
  imports: [
    RouterModule,
    UserDetailComponent,
    ConfirmDialogModule,
    TranslateModule,
  ],
  providers: [UserDetailsStore, ConfirmationService],
  template: `
    <p-confirmDialog [style]="{ width: '450px' }" />
    <user-detail
      [user]="userDetailsStore.user()"
      [profilePictureUrl]="profilePictureUrl()"
      [loadingUser]="loading()"
      [history]="userDetailsStore.history()"
      [totalHistory]="userDetailsStore.totalItems()"
      [totalPages]="userDetailsStore.totalPages()"
      [currentPage]="userDetailsStore.currentPage()"
      [nextPage]="userDetailsStore.nextPage()"
      [previousPage]="userDetailsStore.previousPage()"
      [limit]="userDetailsStore.limit()"
      [loadingHistory]="loading()"
      (back)="onBack()"
      (pageChange)="onPageChange($event)"
      (deleteProfilePicture)="onDeleteProfilePicture()"
    />
  `,
})
export class UserDetailContainer {
  #router = inject(Router);
  #confirmationService = inject(ConfirmationService);
  #translateService = inject(TranslateService);
  #imagesBaseUrl = inject(IMAGES_BASE_URL, { optional: true });
  userDetailsStore = inject(UserDetailsStore);

  loading = this.userDetailsStore.isPending;

  profilePictureUrl = computed(() => {
    const user = this.userDetailsStore.user();
    const path = user?.profilePicture;
    const base = this.#imagesBaseUrl?.trim().replace(/\/$/, '') ?? '';
    if (!path || !base) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    const cleanPath = path.replace(/^\//, '');
    return `${base}/${cleanPath}`;
  });

  onBack() {
    this.#router.navigate(['/backoffice/users']);
  }

  onPageChange(event: { page: number; rows: number }) {
    this.userDetailsStore.setPage(event.page);
    this.userDetailsStore.setLimit(event.rows);
    this.userDetailsStore.loadHistory(this.userDetailsStore.user()?.id ?? '', {
      page: event.page,
      limit: event.rows,
    });
  }

  onDeleteProfilePicture() {
    const userId = this.userDetailsStore.user()?.id;
    if (!userId) return;
    this.#confirmationService.confirm({
      message: this.#translateService.instant('USER.CONFIRM.DELETE_PROFILE_PICTURE'),
      header: this.#translateService.instant('COMMON.CONFIRM') || 'Confirm',
      icon: 'pi pi-exclamation-triangle',
      accept: () => {
        this.userDetailsStore.deleteProfilePicture(userId);
      },
    });
  }
}
