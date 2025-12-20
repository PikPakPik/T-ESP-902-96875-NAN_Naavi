import { ChipModule } from 'primeng/chip';
import { Component, effect, inject, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, NgForm } from '@angular/forms';
import { Router, ActivatedRoute } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { InputTextModule } from 'primeng/inputtext';
import { TextareaModule } from 'primeng/textarea';
import { CardModule } from 'primeng/card';
import { SelectModule } from 'primeng/select';
import { MultiSelectModule } from 'primeng/multiselect';
import { InputNumberModule } from 'primeng/inputnumber';
import { ToastModule } from 'primeng/toast';
import { MessageService } from 'primeng/api';
import { MapComponent, MarkerComponent } from 'ngx-mapbox-gl';
import {
  POIsStore,
  getPOICategoryTranslationKey,
  getPOIStatusTranslationKey,
} from '@web/pois/data-access';
import { IDB_POI } from '@web/shared/models/settings';
import { TranslateModule, TranslateService } from '@ngx-translate/core';

@Component({
  selector: 'poi-upsert',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    ButtonModule,
    InputTextModule,
    TextareaModule,
    CardModule,
    SelectModule,
    MultiSelectModule,
    InputNumberModule,
    ChipModule,
    ToastModule,
    MapComponent,
    MarkerComponent,
    TranslateModule,
  ],
  providers: [MessageService],
  templateUrl: './poi-upsert.component.html',
  styleUrl: './poi-upsert.component.scss',
})
export class PoiUpsertComponent {
  #router = inject(Router);
  #route = inject(ActivatedRoute);
  #poisStore = inject(POIsStore);
  #messageService = inject(MessageService);
  #translateService = inject(TranslateService);

  // Form data
  name = signal('');
  description = signal('');
  comment = signal('');
  types = signal<string[]>([]);
  photos = signal<string[]>([]);
  latitude = signal(45.764);
  longitude = signal(4.8357);
  status = signal('DRAFT');
  isEditMode = signal(false);
  poiId = signal<string | null>(null);

  // Map configuration
  mapStyle = 'mapbox://styles/mapbox/outdoors-v12';
  mapCenter: [number, number] = [this.longitude(), this.latitude()];
  mapZoom = 10;

  // Options from store with translation keys
  categoryOptions = computed(() => {
    const categories = this.#poisStore.point_of_interest_categories();
    return categories.map((category) => ({
      label: getPOICategoryTranslationKey(category),
      value: category,
    }));
  });

  statusOptions = computed(() => {
    const statuses = this.#poisStore.status();
    return statuses.map((status) => ({
      label: getPOIStatusTranslationKey(status),
      value: status,
    }));
  });

  // Méthode helper pour traduire une catégorie (utilisée dans le template)
  getCategoryTranslationKey(category: string): string {
    return getPOICategoryTranslationKey(category);
  }

  // Méthode helper pour traduire un statut (utilisée dans le template)
  getStatusTranslationKey(status: string): string {
    return getPOIStatusTranslationKey(status);
  }

  constructor() {
    effect(() => {
      const id = this.#route.snapshot.params['id'];
      if (id) {
        this.loadPOIForEdit(id);
      }
    });

    this.#route.params.subscribe((params) => {
      if (params['id'] && params['id'] !== this.poiId()) {
        this.loadPOIForEdit(params['id']);
      }
    });
  }

  async loadPOIForEdit(id: string) {
    try {
      let poi = this.#poisStore.entities().find((p) => p.id === id);
      if (!poi) {
        poi = await this.#poisStore.getPOIById(id);
      }

      if (poi) {
        this.isEditMode.set(true);
        this.poiId.set(poi.id);
        this.name.set(poi.name);
        this.description.set(poi.description);
        this.comment.set(poi.comment || '');
        this.types.set([...(poi.types as string[])]);
        this.photos.set([...(poi.photos || [])]);
        this.latitude.set(poi.latitude);
        this.longitude.set(poi.longitude);
        this.status.set(poi.status || 'DRAFT');
        this.updateMapCenter();
      }
    } catch (error) {
      console.error('Error loading POI:', error);
      this.#messageService.add({
        severity: 'error',
        summary: this.#translateService.instant('COMMON.ERROR'),
        detail: this.#translateService.instant('POI.ERROR.LOAD_FAILED'),
      });
    }
  }

  onMapClick(event: unknown) {
    const mapEvent = event as { lngLat: { lat: number; lng: number } };
    const { lat, lng } = mapEvent.lngLat;
    this.latitude.set(Number(lat.toFixed(6)));
    this.longitude.set(Number(lng.toFixed(6)));
    this.updateMapCenter();
    this.#messageService.add({
      severity: 'info',
      summary: this.#translateService.instant('COMMON.SUCCESS'),
      detail: this.#translateService.instant('POI.POSITION.UPDATED', {
        lat: lat.toFixed(5),
        lng: lng.toFixed(5),
      }),
    });
  }

  updateMapCenter() {
    this.mapCenter = [this.longitude(), this.latitude()];
  }

  addPhoto(photoUrl: string) {
    if (!photoUrl) {
      return;
    }
    const trimmed = photoUrl.trim();
    if (!trimmed) {
      return;
    }
    this.photos.update((photos) =>
      photos.includes(trimmed) ? photos : [...photos, trimmed]
    );
  }

  removePhoto(index: number) {
    this.photos.update((photos) => photos.filter((_, i) => i !== index));
  }

  async savePOI(form?: NgForm) {
    if (form && !form.valid) {
      form.control.markAllAsTouched();
      this.#messageService.add({
        severity: 'warn',
        summary: this.#translateService.instant('COMMON.WARNING'),
        detail: this.#translateService.instant('POI.WARNING.FILL_REQUIRED'),
      });
      return;
    }

    if (this.types().length === 0) {
      this.#messageService.add({
        severity: 'warn',
        summary: this.#translateService.instant('COMMON.WARNING'),
        detail: this.#translateService.instant('POI.WARNING.SELECT_TYPE'),
      });
      return;
    }

    const poiData: Partial<IDB_POI> = {
      name: this.name(),
      description: this.description(),
      comment: this.comment(),
      categories: this.types(),
      photos: this.photos(),
      latitude: this.latitude(),
      longitude: this.longitude(),
      status: this.status(),
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    if (this.poiId()) poiData.id = this.poiId();

    try {
      if (this.isEditMode()) {
        await this.#poisStore.update(poiData);
        this.#messageService.add({
          severity: 'success',
          summary: this.#translateService.instant('COMMON.SUCCESS'),
          detail: this.#translateService.instant('POI.SUCCESS.UPDATED'),
        });
      } else {
        await this.#poisStore.create(poiData);
        this.#messageService.add({
          severity: 'success',
          summary: this.#translateService.instant('COMMON.SUCCESS'),
          detail: this.#translateService.instant('POI.SUCCESS.CREATED'),
        });
      }

      this.#router.navigate(['/backoffice/pois']);
    } catch (error) {
      console.error('Error saving POI:', error);
      this.#messageService.add({
        severity: 'error',
        summary: this.#translateService.instant('COMMON.ERROR'),
        detail: this.#translateService.instant('POI.ERROR.SAVE_FAILED'),
      });
    }
  }

  cancel() {
    this.#router.navigate(['/backoffice/pois']);
  }
}
