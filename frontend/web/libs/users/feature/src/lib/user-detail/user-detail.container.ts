import { Component, inject } from '@angular/core';
import { Router, RouterModule } from '@angular/router';
import { UserDetailsStore } from '@web/users/data-access';
import { UserDetailComponent } from './user-detail.component';

@Component({
  selector: 'user-detail-container',
  standalone: true,
  imports: [RouterModule, UserDetailComponent],
  providers: [UserDetailsStore],
  template: `
    <user-detail
      [user]="userDetailsStore.user()"
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
    />
  `,
})
export class UserDetailContainer {
  #router = inject(Router);
  userDetailsStore = inject(UserDetailsStore);

  loading = this.userDetailsStore.isPending;

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
}
