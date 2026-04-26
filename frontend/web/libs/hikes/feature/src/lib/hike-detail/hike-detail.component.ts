import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ButtonModule } from 'primeng/button';
import { TagModule } from 'primeng/tag';
import { DividerModule } from 'primeng/divider';
import { CardModule } from 'primeng/card';
import { Router } from '@angular/router';
import { IMAGES_BASE_URL } from '@web/shared/http-client';
import { naaviMediaDisplayUrl } from '@web/shared/util';
import {
  HikeDetailStore,
  getDifficultySeverity,
  getSourceSeverity,
  getVisibilitySeverity,
} from '@web/hikes/data-access';
import { TranslateModule } from '@ngx-translate/core';
import { HikeMapComponent } from '../hike-map/hike-map.component';

@Component({
  selector: 'hike-detail',
  standalone: true,
  imports: [
    CommonModule,
    ButtonModule,
    TagModule,
    DividerModule,
    CardModule,
    TranslateModule,
    HikeMapComponent,
  ],
  providers: [HikeDetailStore],
  templateUrl: './hike-detail.component.html',
  styleUrl: './hike-detail.component.scss',
})
export class HikeDetailComponent {
  #router = inject(Router);
  #hikeDetailStore = inject(HikeDetailStore);
  #imagesBaseUrl = inject(IMAGES_BASE_URL, { optional: true });

  hike = this.#hikeDetailStore.hike;
  loading = this.#hikeDetailStore.isPending;

  getSeverity = getDifficultySeverity;
  getSourceSeverity = getSourceSeverity;
  getVisibilitySeverity = getVisibilitySeverity;

  getVisibilityLabel(visibility: string | undefined): string {
    switch ((visibility || 'PUBLIC').toUpperCase()) {
      case 'PUBLIC':
        return 'Public';
      case 'PRIVATE':
        return 'Privé';
      case 'UNLISTED':
        return 'Non listée';
      default:
        return visibility || '—';
    }
  }

  getOwnerLabel(userId: string | undefined): string {
    return userId ? `User #${userId}` : 'Officielle';
  }

  getHikeImageUrl(path: string | undefined | null): string | null {
    return naaviMediaDisplayUrl(path, this.#imagesBaseUrl);
  }

  getPrimaryImageUrl(): string {
    const firstImage = this.hike()?.images?.[0]?.filename;
    return (
      this.getHikeImageUrl(firstImage) ||
      `https://via.placeholder.com/1200x500?text=${encodeURIComponent(
        this.hike()?.name ?? ''
      )}`
    );
  }

  goBack() {
    this.#router.navigate(['/backoffice/hikes']);
  }
}
