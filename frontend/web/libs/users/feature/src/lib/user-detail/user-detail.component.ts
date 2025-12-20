import { CommonModule } from '@angular/common';
import { Component, input, output } from '@angular/core';
import { User } from '@web/shared/models/settings';
import { TableModule } from 'primeng/table';
import { TagModule } from 'primeng/tag';
import { ButtonModule } from 'primeng/button';
import { SkeletonModule } from 'primeng/skeleton';
import { PaginatorModule } from 'primeng/paginator';
import { TranslateModule } from '@ngx-translate/core';
import { HikeHistoryItem } from '@web/shared/models/settings';
import { SecondsToTimePipe } from './seconds-to-time.pipe';

@Component({
  selector: 'user-detail',
  standalone: true,
  imports: [
    CommonModule,
    TableModule,
    TagModule,
    ButtonModule,
    SkeletonModule,
    PaginatorModule,
    TranslateModule,
    SecondsToTimePipe,
  ],
  templateUrl: './user-detail.component.html',
})
export class UserDetailComponent {
  user = input<User | null>(null);
  loadingUser = input<boolean>(false);

  history = input<HikeHistoryItem[]>([]);
  totalHistory = input<number>(0);
  totalPages = input<number>(0);
  currentPage = input<number>(0);
  nextPage = input<number | null>(null);
  previousPage = input<number | null>(null);
  limit = input<number>(20);
  loadingHistory = input<boolean>(false);

  back = output<void>();
  pageChange = output<{ page: number; rows: number }>();

  onPageChange(event: { page: number; rows: number }) {
    this.pageChange.emit({
      page: event.page + 1,
      rows: event.rows,
    });
  }
}
