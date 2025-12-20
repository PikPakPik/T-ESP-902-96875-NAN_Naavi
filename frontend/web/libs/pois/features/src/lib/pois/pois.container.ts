import { Component, inject, ViewChild, computed } from '@angular/core';
import { Router, RouterModule } from '@angular/router';
import { POIsStore } from '@web/pois/data-access';
import { Pois, ColumnDef } from './pois.component';
import { POI } from '@web/shared/models/settings';
import {
  LocationSearchComponent,
  LocationSearchParams,
} from '@web/shared/ui/location-search';

@Component({
  selector: 'pois-container',
  standalone: true,
  imports: [RouterModule, Pois, LocationSearchComponent],
  template: `
    <pois
      [rows]="rows()"
      [columns]="columns"
      [loading]="loading()"
      [needsLocation]="needsLocation()"
      [totalRecords]="totalRecords()"
      [currentPage]="currentPage()"
      [rowsPerPage]="rowsPerPage()"
      [totalPages]="totalPages()"
      (editPOI)="onEditPOI($event)"
      (deletePOI)="onDeletePOI($event)"
      (deleteSelectedPOIs)="onDeleteSelectedPOIs($event)"
      (newPOI)="onNewPOI()"
      (locationSearch)="onLocationSearch()"
      (setParisDefault)="onSetParisDefault()"
      (pageChange)="onPageChange($event)"
      (searchChange)="onSearchChange($event)"
    ></pois>

    <location-search
      #locationSearch
      (searchLocation)="onSearchByLocation($event)"
      (clearLocation)="onClearLocationSearch()"
    />
  `,
})
export class PoisContainer {
  #router = inject(Router);
  #poisStore = inject(POIsStore);

  loading = this.#poisStore.isPending;
  rows = this.#poisStore.entities;
  totalRecords = this.#poisStore.total;
  currentPage = this.#poisStore.page;
  rowsPerPage = this.#poisStore.limit;
  totalPages = this.#poisStore.totalPages;
  needsLocation = computed(
    () =>
      this.#poisStore.latitude() === null ||
      this.#poisStore.longitude() === null
  );

  @ViewChild('locationSearch')
  locationSearchComponent!: LocationSearchComponent;

  // Colonnes du tableau
  columns: ColumnDef[] = [
    { field: 'name', header: 'Nom', sortable: true, filter: true },
    { field: 'types', header: 'Types', sortable: true, filter: true },
    { field: 'description', header: 'Description', filter: true },
    { field: 'latitude', header: 'Latitude', sortable: true },
    { field: 'longitude', header: 'Longitude', sortable: true },
    { field: 'status', header: 'Statut', sortable: true },
  ];

  onDeletePOI(poi: POI) {
    this.#poisStore.delete(poi.id);
  }

  async onDeleteSelectedPOIs(pois: POI[]) {
    for (const poi of pois) {
      await this.#poisStore.delete(poi.id);
    }
  }

  onEditPOI(poi: POI) {
    this.#router.navigate(['/backoffice/pois/edit', poi.id]);
  }

  onNewPOI() {
    this.#router.navigate(['/backoffice/pois/new']);
  }

  onLocationSearch() {
    this.locationSearchComponent.open();
  }

  async onSearchByLocation(params: LocationSearchParams) {
    console.log('Recherche par localisation:', params);
    // D'abord mettre à jour la localisation dans le store
    this.#poisStore.setDefaultLocation(params.latitude, params.longitude);
    // Puis recharger les POIs avec les nouvelles coordonnées
    await this.#poisStore.getPOIs({
      latitude: params.latitude,
      longitude: params.longitude,
      radius: params.radius,
    });
  }

  async onClearLocationSearch() {
    console.log('Réinitialisation de la recherche');
    await this.#poisStore.getPOIs();
  }

  async onSetParisDefault() {
    // Paris: 48.8566° N, 2.3522° E
    this.#poisStore.setDefaultLocation(48.8566, 2.3522);
    await this.#poisStore.getPOIs();
  }

  async onPageChange(event: { page: number; rows: number }) {
    this.#poisStore.setPage(event.page);
    this.#poisStore.setLimit(event.rows);
    // Recharger les POIs avec les nouveaux paramètres de pagination
    const params: any = {
      page: event.page,
      limit: event.rows,
    };

    const lat = this.#poisStore.latitude();
    const lon = this.#poisStore.longitude();
    if (lat !== null && lon !== null) {
      params.latitude = lat;
      params.longitude = lon;
      params.radius = 20; // Valeur par défaut
    }

    await this.#poisStore.getPOIs(params);
  }

  async onSearchChange(query: string) {
    // Réinitialiser à la page 1 lors d'une nouvelle recherche
    this.#poisStore.setPage(1);

    // Construire les paramètres de recherche
    const params: any = {
      page: 1,
      limit: this.#poisStore.limit(),
      query: query.trim() || undefined, // Ne pas envoyer de query vide
    };

    // Inclure les paramètres de localisation s'ils sont définis
    const lat = this.#poisStore.latitude();
    const lon = this.#poisStore.longitude();
    if (lat !== null && lon !== null) {
      params.latitude = lat;
      params.longitude = lon;
      params.radius = 20; // Valeur par défaut
    }

    await this.#poisStore.getPOIs(params);
  }
}
