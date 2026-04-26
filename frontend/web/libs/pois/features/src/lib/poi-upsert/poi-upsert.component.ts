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
import { InputNumberModule } from 'primeng/inputnumber';
import { ToastModule } from 'primeng/toast';
import { MessageService } from 'primeng/api';
import { IMAGES_BASE_URL } from '@web/shared/http-client';
import { naaviMediaDisplayUrl } from '@web/shared/util';
import { MapComponent, MarkerComponent } from 'ngx-mapbox-gl';
import {
  POIsStore,
  getPOICategoryIconPath,
  getPOICategoryTranslationKey,
  getPOIStatusTranslationKey,
} from '@web/pois/data-access';
import { IDB_POI } from '@web/shared/models/settings';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { UsersService } from '@web/users/data-access';
import { lastValueFrom } from 'rxjs';
import { POI } from '@web/shared/models/settings';

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
  #usersService = inject(UsersService);
  #imagesBaseUrl = inject(IMAGES_BASE_URL, { optional: true });

  // Form data
  name = signal('');
  description = signal('');
  comment = signal('');
  types = signal<string[]>([]);
  photos = signal<string[]>([]);
  latitude = signal(45.764);
  longitude = signal(4.8357);
  status = signal('DRAFT');
  source = signal('OFFICIAL');
  selectedUserId = signal<string | null>(null);
  usersOptions = signal<Array<{ label: string; value: string }>>([]);
  ownerDisplay = signal('Officielle');
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

  sourceOptions = computed(() => {
    const sources = this.#poisStore.sources() ?? [];
    const values = sources.length > 0 ? sources : ['OFFICIAL', 'COMMUNITY'];
    return values.map((source) => ({
      label: source,
      value: source,
    }));
  });

  isCommunitySource = computed(
    () => this.source().toUpperCase() === 'COMMUNITY'
  );

  // Méthode helper pour traduire une catégorie (utilisée dans le template)
  getCategoryTranslationKey(category: string): string {
    return getPOICategoryTranslationKey(category);
  }

  // Méthode helper pour traduire un statut (utilisée dans le template)
  getStatusTranslationKey(status: string): string {
    return getPOIStatusTranslationKey(status);
  }

  getSelectedCategory(): string | null {
    return this.types()[0] ?? null;
  }

  getSelectedCategoryIconPath(): string {
    return getPOICategoryIconPath(this.getSelectedCategory());
  }

  getCategoryIconPath(category: string | null | undefined): string {
    return getPOICategoryIconPath(category);
  }

  constructor() {
    void this.loadUsersOptions();

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
        this.source.set(poi.source || (poi.userId ? 'COMMUNITY' : 'OFFICIAL'));
        const normalizedUserId = this.normalizeUserId(poi.userId);
        this.selectedUserId.set(normalizedUserId);
        await this.loadOwnerDisplay(normalizedUserId, poi.source);
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

  onTypeChange(value: string | null) {
    this.types.set(value ? [value] : []);
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

  getPhotoUrl(path: string | undefined | null): string | null {
    return naaviMediaDisplayUrl(path, this.#imagesBaseUrl);
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

    if (this.isCommunitySource() && !this.selectedUserId()) {
      this.#messageService.add({
        severity: 'warn',
        summary: this.#translateService.instant('COMMON.WARNING'),
        detail: 'Veuillez sélectionner un propriétaire pour une source communauté.',
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
      source: this.source(),
      userId:
        this.source().toUpperCase() === 'COMMUNITY'
          ? this.selectedUserId()
          : null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    if (this.isEditMode()) {
      poiData.status = this.status();
    }

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
        const createdPOI = await this.#poisStore.create(poiData);
        if (createdPOI?.id) {
          await this.#poisStore.update(
            this.toPublishedPayload(createdPOI, 'PUBLISHED')
          );
        }
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

  async onSourceChange(value: string | null) {
    const normalized = (value || 'OFFICIAL').toUpperCase();
    this.source.set(normalized);

    if (normalized === 'OFFICIAL') {
      this.selectedUserId.set(null);
      this.ownerDisplay.set('Officielle');
      return;
    }

    const selected = this.normalizeUserId(this.selectedUserId());
    if (!selected) {
      this.ownerDisplay.set('Communauté');
      return;
    }

    await this.onOwnerUserChange(selected);
  }

  async onOwnerUserChange(userId: string | null) {
    const normalizedUserId = this.normalizeUserId(userId);
    this.selectedUserId.set(normalizedUserId);

    if (!normalizedUserId) {
      this.ownerDisplay.set('Communauté');
      return;
    }

    try {
      const owner = await lastValueFrom(
        this.#usersService.getUserById(normalizedUserId)
      );
      const lastname = (owner.lastname || '').trim();
      const firstname = (owner.firstname || '').trim();
      const fullName = `${lastname.toUpperCase()} ${firstname}`.trim();

      this.ownerDisplay.set(
        fullName.length > 0
          ? `(#${owner.id}) ${fullName}`
          : `(#${owner.id})`
      );
    } catch {
      this.ownerDisplay.set(`(#${normalizedUserId}) Utilisateur introuvable`);
    }
  }

  private async loadUsersOptions() {
    try {
      const response = await lastValueFrom(
        this.#usersService.getUsers({ page: 1, limit: 200 })
      );

      this.usersOptions.set(
        response.usersInstances.map((user) => {
          const lastname = (user.lastname || '').trim();
          const firstname = (user.firstname || '').trim();
          const fullName = `${lastname.toUpperCase()} ${firstname}`.trim();

          return {
            value: String(user.id),
            label: fullName.length > 0 ? `(#${user.id}) ${fullName}` : `(#${user.id})`,
          };
        })
      );
    } catch {
      this.usersOptions.set([]);
    }
  }

  private async loadOwnerDisplay(
    userId: string | null | undefined,
    source?: string
  ) {
    const normalizedUserId = this.normalizeUserId(userId);

    if (!normalizedUserId) {
      this.ownerDisplay.set(
        (source || '').toUpperCase() === 'COMMUNITY'
          ? 'Communauté'
          : 'Officielle'
      );
      return;
    }

    await this.onOwnerUserChange(normalizedUserId);
  }

  private normalizeUserId(
    userId: string | number | null | undefined
  ): string | null {
    if (userId === null || userId === undefined) {
      return null;
    }

    const normalized = String(userId).trim();
    return normalized.length > 0 ? normalized : null;
  }

  private toPublishedPayload(poi: POI, status: string): Partial<IDB_POI> {
    return {
      id: poi.id,
      name: poi.name,
      description: poi.description,
      categories: poi.types,
      photos: poi.photos,
      latitude: poi.latitude,
      longitude: poi.longitude,
      comment: poi.comment,
      source: poi.source,
      userId: poi.userId ?? undefined,
      createdAt: poi.createdAt.toISOString(),
      updatedAt: poi.updatedAt.toISOString(),
      status,
    };
  }
}
