import { HikesStore } from '@web/hikes/data-access';
import { Component, inject, ViewChild, computed } from '@angular/core';
import { Router, RouterModule } from '@angular/router';
import { Hikes, ColumnDef } from './hikes.component';
import { Hike } from '@web/shared/models/settings';
import {
  LocationSearchComponent,
  LocationSearchParams,
} from '@web/shared/ui/location-search';

@Component({
  selector: 'hikes-container',
  standalone: true,
  imports: [RouterModule, Hikes, LocationSearchComponent],
  template: `
    <hikes
      [rows]="rows()"
      [columns]="columns"
      [loading]="loading()"
      [needsLocation]="needsLocation()"
      [totalRecords]="totalRecords()"
      [currentPage]="currentPage()"
      [rowsPerPage]="rowsPerPage()"
      [totalPages]="totalPages()"
      (editHike)="onEditHike($event)"
      (deleteHike)="onDeleteHike($event)"
      (saveHike)="onSaveHike($event)"
      (deleteSelectedHikes)="onDeleteSelectedHikes($event)"
      (viewDetails)="onViewDetails($event)"
      (newHike)="onNewHike()"
      (importHikes)="onImportHikes()"
      (locationSearch)="onLocationSearch()"
      (setParisDefault)="onSetParisDefault()"
      (pageChange)="onPageChange($event)"
      (searchChange)="onSearchChange($event)"
    ></hikes>

    <location-search
      #locationSearch
      (searchLocation)="onSearchByLocation($event)"
      (clearLocation)="onClearLocationSearch()"
    />
  `,
})
export class HikesContainer {
  #hikesStore = inject(HikesStore);
  #router = inject(Router);
  loading = this.#hikesStore.isPending;
  rows = this.#hikesStore.entities;
  totalRecords = this.#hikesStore.total;
  currentPage = this.#hikesStore.page;
  rowsPerPage = this.#hikesStore.limit;
  totalPages = this.#hikesStore.totalPages;
  needsLocation = computed(
    () =>
      this.#hikesStore.latitude() === null ||
      this.#hikesStore.longitude() === null
  );

  @ViewChild('locationSearch')
  locationSearchComponent!: LocationSearchComponent;

  columns: ColumnDef[] = [
    { field: 'name', header: 'Nom', sortable: true, filter: true },
    { field: 'location', header: 'Localisation', sortable: true, filter: true },
    { field: 'difficulty', header: 'Difficulté', sortable: true, filter: true },
    { field: 'distance', header: 'Distance (km)', sortable: true },
    { field: 'elevationGain', header: 'Dénivelé +', sortable: true },
    { field: 'estimatedDuration', header: 'Durée (h)', sortable: true },
  ];

  onEditHike(hike: Hike) {
    this.#router.navigate(['/backoffice/hikes/edit', hike.id]);
  }

  onDeleteHike(hike: Hike) {
    this.#hikesStore.delete(hike.id);
  }

  onSaveHike(hike: Hike) {
    console.log('Save hike:', hike);
    const index = this.rows().findIndex((h) => h.id === hike.id);
    if (index !== -1) {
      this.#hikesStore.update(hike);
    } else {
      this.#hikesStore.create(hike);
    }
  }

  async onDeleteSelectedHikes(hikes: Hike[]) {
    console.log('Delete selected hikes:', hikes);
    const hikeIds = hikes.map((h) => h.id);
    for (const hikeId of hikeIds) {
      await this.#hikesStore.delete(hikeId);
    }
  }

  onViewDetails(hike: Hike) {
    this.#router.navigate(['/backoffice/hikes', hike.id]);
  }

  onNewHike() {
    this.#router.navigate(['/backoffice/hikes/new']);
  }

  onImportHikes() {
    this.#router.navigate(['/backoffice/hikes/import']);
  }

  onLocationSearch() {
    this.locationSearchComponent.open();
  }

  async onSearchByLocation(params: LocationSearchParams) {
    console.log('Recherche par localisation:', params);
    // D'abord mettre à jour la localisation dans le store
    this.#hikesStore.setDefaultLocation(params.latitude, params.longitude);
    // Puis recharger les randonnées avec les nouvelles coordonnées
    await this.#hikesStore.getHikes({
      latitude: params.latitude,
      longitude: params.longitude,
      radius: params.radius,
    });
  }

  async onClearLocationSearch() {
    console.log('Réinitialisation de la recherche');
    await this.#hikesStore.getHikes();
  }

  async onSetParisDefault() {
    // Paris: 48.8566° N, 2.3522° E
    this.#hikesStore.setDefaultLocation(48.8566, 2.3522);
    await this.#hikesStore.getHikes();
  }

  async onPageChange(event: { page: number; rows: number }) {
    this.#hikesStore.setPage(event.page);
    this.#hikesStore.setLimit(event.rows);
    // Recharger les hikes avec les nouveaux paramètres de pagination
    // Inclure aussi les paramètres de localisation s'ils sont définis
    const params: any = {
      page: event.page,
      limit: event.rows,
    };

    const lat = this.#hikesStore.latitude();
    const lon = this.#hikesStore.longitude();
    if (lat !== null && lon !== null) {
      params.latitude = lat;
      params.longitude = lon;
      params.radius = 50; // Valeur par défaut
    }

    await this.#hikesStore.getHikes(params);
  }

  async onSearchChange(query: string) {
    // Réinitialiser à la page 1 lors d'une nouvelle recherche
    this.#hikesStore.setPage(1);

    // Construire les paramètres de recherche
    const params: any = {
      page: 1,
      limit: this.#hikesStore.limit(),
      query: query.trim() || undefined, // Ne pas envoyer de query vide
    };

    // Inclure les paramètres de localisation s'ils sont définis
    const lat = this.#hikesStore.latitude();
    const lon = this.#hikesStore.longitude();
    if (lat !== null && lon !== null) {
      params.latitude = lat;
      params.longitude = lon;
      params.radius = 50; // Valeur par défaut
    }

    await this.#hikesStore.getHikes(params);
  }
}
