import { Tag, TagModule } from 'primeng/tag';
import { TableModule } from 'primeng/table';
import { POI } from '@web/shared/models/settings';
import {
  Component,
  inject,
  input,
  output,
  signal,
  ViewChild,
} from '@angular/core';
import { ButtonModule } from 'primeng/button';
import { InputTextModule } from 'primeng/inputtext';
import { SelectModule } from 'primeng/select';
import { DialogModule } from 'primeng/dialog';

import { FormsModule } from '@angular/forms';
import { IconFieldModule } from 'primeng/iconfield';
import { InputIconModule } from 'primeng/inputicon';
import { Table } from 'primeng/table';
import { ConfirmDialogModule } from 'primeng/confirmdialog';
import {
  ConfirmationService,
  MessageService,
  type FilterMetadata,
} from 'primeng/api';
import { ToastModule } from 'primeng/toast';
import { TooltipModule } from 'primeng/tooltip';
import { PopoverModule, Popover } from 'primeng/popover';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import {
  getPOICategoryIconPath,
  getPOICategoryTranslationKey,
} from '@web/pois/data-access';
import { IMAGES_BASE_URL } from '@web/shared/http-client';
import { naaviMediaDisplayUrl } from '@web/shared/util';
import { UsersService } from '@web/users/data-access';
import { lastValueFrom } from 'rxjs';
import { PoiMapComponent } from './poi-map/poi-map.component';

export type ColumnDef = {
  field: string;
  header: string;
  sortable?: boolean;
  filter?: boolean;
};

@Component({
  selector: 'pois',
  standalone: true,
  imports: [
    TableModule,
    TagModule,
    SelectModule,
    ButtonModule,
    InputTextModule,
    FormsModule,
    IconFieldModule,
    InputIconModule,
    ConfirmDialogModule,
    ToastModule,
    TooltipModule,
    PopoverModule,
    DialogModule,
    TranslateModule,
    PoiMapComponent,
  ],
  providers: [ConfirmationService, MessageService],
  templateUrl: './pois.component.html',
  styleUrls: ['./pois.component.scss'],
})
export class Pois {
  #confirmationService = inject(ConfirmationService);
  #translateService = inject(TranslateService);
  #usersService = inject(UsersService);
  #imagesBaseUrl = inject(IMAGES_BASE_URL, { optional: true });
  rows = input<POI[]>([]);
  columns = input<ColumnDef[]>([]);
  loading = input<boolean>(false);
  needsLocation = input<boolean>(false);
  totalRecords = input<number>(0);
  totalPages = input<number>(0);
  currentPage = input<number>(1);
  rowsPerPage = input<number>(20);
  pendingApprovalCount = input<number>(0);
  selectedStatus = input<string | null>(null);
  selectedPOIs: POI[] = [];

  editPOI = output<POI>();
  deletePOI = output<POI>();
  approvePOI = output<POI>();
  rejectPOI = output<POI>();
  deleteSelectedPOIs = output<POI[]>();
  newPOI = output<void>();
  pageChange = output<{ page: number; rows: number }>();
  searchChange = output<string>();
  statusFilterChange = output<string | null>();

  tableFilters: { [s: string]: FilterMetadata | FilterMetadata[] } = {
    status: { value: 'DELETED', matchMode: 'notEquals' },
  };

  // Signal pour stocker le POI actuel pour le popover
  currentPOIForMap = signal<POI | null>(null);
  selectedPOIForDetail = signal<POI | null>(null);
  ownerDisplay = signal('');
  // Clé unique pour forcer la reconstruction du Map
  mapKey = signal<string>('');

  @ViewChild('mapPopover') mapPopover!: Popover;

  // Timer pour le debounce de la recherche
  #searchTimeout: ReturnType<typeof setTimeout> | null = null;

  clear(table: Table) {
    table.clear();
  }

  onSearchChange(event: Event) {
    const value = (event.target as HTMLInputElement).value;

    // Annuler le timer précédent s'il existe
    if (this.#searchTimeout) {
      clearTimeout(this.#searchTimeout);
    }

    // Débouncer la recherche (500ms)
    this.#searchTimeout = setTimeout(() => {
      this.searchChange.emit(value);
    }, 500);
  }

  onPageChange(event: { first: number; rows: number; page?: number }) {
    // Avec lazy="true", PrimeNG fournit 'page' (0-based) dans l'événement
    // On convertit en 1-based pour notre store
    const page =
      event.page !== undefined
        ? event.page + 1
        : Math.floor(event.first / event.rows) + 1;

    this.pageChange.emit({
      page,
      rows: event.rows,
    });
  }

  openNew() {
    this.newPOI.emit();
  }

  editPOIAction(poi: POI) {
    this.editPOI.emit(poi);
  }

  deletePOIConfirm(poi: POI) {
    this.#confirmationService.confirm({
      message: this.#translateService.instant('POI.CONFIRM.DELETE', {
        name: poi.name,
      }),
      header: this.#translateService.instant('COMMON.CONFIRM') || 'Confirm',
      icon: 'pi pi-exclamation-triangle',
      accept: () => {
        this.deletePOI.emit(poi);
      },
    });
  }

  deleteSelectedPOIsConfirm() {
    this.#confirmationService.confirm({
      message: this.#translateService.instant('POI.CONFIRM.DELETE_SELECTED'),
      header: this.#translateService.instant('COMMON.CONFIRM') || 'Confirm',
      icon: 'pi pi-exclamation-triangle',
      accept: () => {
        this.deleteSelectedPOIs.emit(this.selectedPOIs);
      },
    });
  }

  getSeverity(status: string | null | undefined): Tag['severity'] {
    switch ((status || '').toLowerCase()) {
      case 'published':
        return 'success';
      case 'draft':
        return 'warn';
      case 'unpublished':
        return 'secondary';
      case 'deleted':
        return 'danger';
      default:
        return 'secondary';
    }
  }

  getTypesLabel(types: string[]): string {
    return types.join(', ');
  }

  getCategoryTranslationKey(category: string): string {
    return getPOICategoryTranslationKey(category);
  }

  getCategoryIconPath(category: string | null | undefined): string {
    return getPOICategoryIconPath(category);
  }

  getPOIPhotoUrl(path: string | undefined | null): string | null {
    return naaviMediaDisplayUrl(path, this.#imagesBaseUrl);
  }

  displayPOIMap(event: MouseEvent, poi: POI) {
    // Toggle si on clique sur le même POI
    if (this.currentPOIForMap()?.id === poi.id) {
      this.currentPOIForMap.set(null);
      this.mapKey.set('');
      this.mapPopover.hide();
      return;
    }

    // Fermer d'abord la popover si elle est ouverte
    if (this.currentPOIForMap()) {
      this.mapPopover.hide();
      // Attendre que la fermeture soit complète avant d'ouvrir la nouvelle
      setTimeout(() => {
        this.currentPOIForMap.set(poi);
        // Générer une nouvelle clé pour forcer la reconstruction du Map
        this.mapKey.set(`map-${poi.id}-${Date.now()}`);
        this.mapPopover.show(event);
      }, 150);
    } else {
      // Si aucune popover n'est ouverte, mettre à jour et afficher directement
      this.currentPOIForMap.set(poi);
      this.mapKey.set(`map-${poi.id}-${Date.now()}`);
      this.mapPopover.show(event);
    }
  }

  async openDetail(poi: POI) {
    this.selectedPOIForDetail.set(poi);
    await this.loadOwnerDisplay(poi.userId, poi.source);
  }

  closeDetail() {
    this.selectedPOIForDetail.set(null);
    this.ownerDisplay.set('');
  }

  applyStatusFilter(status: string | null) {
    this.statusFilterChange.emit(status);
  }

  /** Le détail œil : pas d’action « approuver » si le POI est déjà publié. */
  showApproveInPoiDetail(): boolean {
    const poi = this.selectedPOIForDetail();
    if (!poi) {
      return false;
    }
    return poi.status?.toUpperCase() !== 'PUBLISHED';
  }

  approveSelectedPOI() {
    const poi = this.selectedPOIForDetail();
    if (!poi || poi.status?.toUpperCase() === 'PUBLISHED') {
      return;
    }
    this.approvePOI.emit(poi);
  }

  rejectSelectedPOI() {
    const poi = this.selectedPOIForDetail();
    if (poi) {
      this.rejectPOI.emit(poi);
    }
  }

  getSourceTranslationKey(source: string | null | undefined): string {
    return `HIKE.SOURCE.${(source || 'OFFICIAL').toUpperCase()}`;
  }

  private async loadOwnerDisplay(
    userId: string | null | undefined,
    source?: string
  ) {
    const normalizedUserId = this.normalizeUserId(userId);

    if (!normalizedUserId) {
      this.ownerDisplay.set(
        (source || '').toUpperCase() === 'COMMUNITY'
          ? this.#translateService.instant('HIKE.SOURCE.COMMUNITY')
          : this.#translateService.instant('HIKE.SOURCE.OFFICIAL')
      );
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

  private normalizeUserId(
    userId: string | number | null | undefined
  ): string | null {
    if (userId === null || userId === undefined) {
      return null;
    }

    const normalized = String(userId).trim();
    return normalized.length > 0 ? normalized : null;
  }
}
