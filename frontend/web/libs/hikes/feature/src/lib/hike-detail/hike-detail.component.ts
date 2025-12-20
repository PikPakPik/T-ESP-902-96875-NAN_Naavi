import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ButtonModule } from 'primeng/button';
import { TagModule } from 'primeng/tag';
import { DividerModule } from 'primeng/divider';
import { CardModule } from 'primeng/card';
import { Router } from '@angular/router';
import { HikeDetailStore, getDifficultySeverity } from '@web/hikes/data-access';
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

  hike = this.#hikeDetailStore.hike;
  loading = this.#hikeDetailStore.isPending;

  getSeverity = getDifficultySeverity;

  goBack() {
    this.#router.navigate(['/backoffice/hikes']);
  }
}
