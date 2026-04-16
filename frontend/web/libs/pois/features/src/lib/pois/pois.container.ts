import { Component, inject } from '@angular/core';
import { Router, RouterModule } from '@angular/router';
import { POIsStore } from '@web/pois/data-access';
import { Pois, ColumnDef } from './pois.component';
import { IDB_POI, POI } from '@web/shared/models/settings';

@Component({
  selector: 'pois-container',
  standalone: true,
  imports: [RouterModule, Pois],
  template: `
    <pois
      [rows]="rows()"
      [columns]="columns"
      [loading]="loading()"
      [totalRecords]="totalRecords()"
      [currentPage]="currentPage()"
      [rowsPerPage]="rowsPerPage()"
      [totalPages]="totalPages()"
      [pendingApprovalCount]="pendingApprovalCount()"
      [selectedStatus]="selectedStatus()"
      (editPOI)="onEditPOI($event)"
      (deletePOI)="onDeletePOI($event)"
      (approvePOI)="onApprovePOI($event)"
      (rejectPOI)="onRejectPOI($event)"
      (deleteSelectedPOIs)="onDeleteSelectedPOIs($event)"
      (newPOI)="onNewPOI()"
      (pageChange)="onPageChange($event)"
      (searchChange)="onSearchChange($event)"
      (statusFilterChange)="onStatusFilterChange($event)"
    ></pois>
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
  pendingApprovalCount = this.#poisStore.pendingApprovalCount;
  selectedStatus = this.#poisStore.selectedStatus;

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

  async onApprovePOI(poi: POI) {
    await this.#poisStore.update(this.#toModerationPayload(poi, 'PUBLISHED'));
    await this.#poisStore.loadPendingApprovalCount();
    await this.#poisStore.getPOIs();
  }

  async onRejectPOI(poi: POI) {
    await this.#poisStore.update(this.#toModerationPayload(poi, 'UNPUBLISHED'));
    await this.#poisStore.loadPendingApprovalCount();
    await this.#poisStore.getPOIs();
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

  async onPageChange(event: { page: number; rows: number }) {
    this.#poisStore.setPage(event.page);
    this.#poisStore.setLimit(event.rows);
    const params = {
      page: event.page,
      limit: event.rows,
      status: this.#poisStore.selectedStatus() ?? undefined,
    };
    await this.#poisStore.getPOIs(params);
  }

  async onSearchChange(query: string) {
    this.#poisStore.setPage(1);
    const params = {
      page: 1,
      limit: this.#poisStore.limit(),
      query: query.trim() || undefined,
      status: this.#poisStore.selectedStatus() ?? undefined,
    };
    await this.#poisStore.getPOIs(params);
  }

  async onStatusFilterChange(status: string | null) {
    this.#poisStore.setSelectedStatus(status);
    this.#poisStore.setPage(1);
    await this.#poisStore.getPOIs({
      page: 1,
      limit: this.#poisStore.limit(),
      status: status ?? undefined,
    });
  }

  #toModerationPayload(poi: POI, status: string): Partial<IDB_POI> {
    return {
      id: poi.id,
      name: poi.name,
      description: poi.description,
      categories: poi.types,
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
