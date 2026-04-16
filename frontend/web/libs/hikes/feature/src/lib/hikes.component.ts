import { TagModule } from 'primeng/tag';
import { TableModule } from 'primeng/table';
import { Hike } from '@web/shared/models/settings';
import {
  Component,
  effect,
  inject,
  input,
  output,
  signal,
  ViewChild,
} from '@angular/core';
import { ButtonModule } from 'primeng/button';
import { InputTextModule } from 'primeng/inputtext';
import { TextareaModule } from 'primeng/textarea';
import { CommonModule } from '@angular/common';
import { IconFieldModule } from 'primeng/iconfield';
import { InputIconModule } from 'primeng/inputicon';
import { Table } from 'primeng/table';
import { ToolbarModule } from 'primeng/toolbar';
import { DialogModule } from 'primeng/dialog';
import { ConfirmDialogModule } from 'primeng/confirmdialog';
import { ConfirmationService, type FilterMetadata } from 'primeng/api';
import { TooltipModule } from 'primeng/tooltip';
import { PopoverModule, Popover } from 'primeng/popover';
import { PanelModule } from 'primeng/panel';
import { FormsModule } from '@angular/forms';
import {
  getDifficultySeverity,
  getStatusSeverity,
  getVisibilitySeverity,
} from '@web/hikes/data-access';
import { UsersService } from '@web/users/data-access';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { HikeMapComponent } from './hike-map/hike-map.component';

export type ColumnDef = {
  field: string;
  header: string;
  sortable?: boolean;
  filter?: boolean;
  editable?: boolean;
};

@Component({
  selector: 'hikes',
  standalone: true,
  imports: [
    TableModule,
    CommonModule,
    TagModule,
    ButtonModule,
    InputTextModule,
    TextareaModule,
    IconFieldModule,
    InputIconModule,
    ToolbarModule,
    DialogModule,
    ConfirmDialogModule,
    TooltipModule,
    PopoverModule,
    PanelModule,
    FormsModule,
    TranslateModule,
    HikeMapComponent,
  ],
  providers: [ConfirmationService],
  templateUrl: './hikes.component.html',
  styleUrls: ['./hikes.component.scss'],
})
export class Hikes {
  #confirmationService = inject(ConfirmationService);
  #translateService = inject(TranslateService);
  #usersService = inject(UsersService, { optional: true });
  #requestedOwnerIds = new Set<string>();
  rows = input<Hike[]>([]);
  columns = input<ColumnDef[]>([]);
  loading = input<boolean>(false);
  needsLocation = input<boolean>(false);
  totalRecords = input<number>(0);
  totalPages = input<number>(0);
  currentPage = input<number>(1);
  rowsPerPage = input<number>(20);
  selectedHikes: Hike[] = [];

  hikeDialog = signal(false);
  hike = signal<Partial<Hike>>({});
  submitted = signal(false);

  editHike = output<Hike>();
  deleteHike = output<Hike>();
  saveHike = output<Hike>();
  deleteSelectedHikes = output<Hike[]>();
  viewDetails = output<Hike>();
  newHike = output<void>();
  importHikes = output<void>();
  locationSearch = output<void>();
  setParisDefault = output<void>();
  pageChange = output<{ page: number; rows: number }>();
  searchChange = output<string>();

  tableFilters: { [s: string]: FilterMetadata | FilterMetadata[] } = {};

  // Signal pour stocker la randonnée actuelle pour le popover
  currentHikeForMap = signal<Hike | null>(null);
  // Clé unique pour forcer la reconstruction du Map
  mapKey = signal<string>('');
  ownerLabels = signal<Record<string, string>>({});

  @ViewChild('mapPopover') mapPopover!: Popover;

  // Timer pour le debounce de la recherche
  #searchTimeout: ReturnType<typeof setTimeout> | null = null;

  constructor() {
    effect(() => {
      this.preloadOwnerLabels(this.rows());
    });
  }

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
    // Créer un objet partiel qui sera converti en Hike par le service
    const newHike: Partial<Hike> = {
      id: '',
      name: '',
      difficulty: 'Facile',
      distance: 0,
      location: '',
      status: 'ACTIVE',
    };
    this.hike.set(newHike);
    this.submitted.set(false);
    this.hikeDialog.set(true);
  }

  openNewDialog() {
    this.newHike.emit();
  }

  setParisLocation() {
    this.setParisDefault.emit();
  }

  editHikeDialog(hike: Hike) {
    this.hike.set(hike);
    this.hikeDialog.set(true);
  }

  hideDialog() {
    this.hikeDialog.set(false);
    this.submitted.set(false);
  }

  saveHikeDialog() {
    this.submitted.set(true);

    if (this.hike().name?.trim() && this.hike().difficulty?.trim()) {
      this.saveHike.emit(this.hike() as Hike);
      this.hikeDialog.set(false);
      this.hike.set({});
    }
  }

  deleteHikeConfirm(hike: Hike) {
    this.#confirmationService.confirm({
      message: this.#translateService.instant('HIKE.CONFIRM.DELETE', {
        name: hike.name,
      }),
      header: this.#translateService.instant('COMMON.CONFIRM') || 'Confirm',
      icon: 'pi pi-exclamation-triangle',
      accept: () => {
        this.deleteHike.emit(hike);
      },
    });
  }

  deleteSelectedHikesConfirm() {
    this.#confirmationService.confirm({
      message: this.#translateService.instant('HIKE.CONFIRM.DELETE_SELECTED'),
      header: this.#translateService.instant('COMMON.CONFIRM') || 'Confirm',
      icon: 'pi pi-exclamation-triangle',
      accept: () => {
        this.deleteSelectedHikes.emit(this.selectedHikes);
      },
    });
  }

  viewDetailsClick(hike: Hike) {
    this.viewDetails.emit(hike);
  }

  displayHikeMap(event: MouseEvent, hike: Hike) {
    // Toggle si on clique sur la même randonnée
    if (this.currentHikeForMap()?.id === hike.id) {
      this.currentHikeForMap.set(null);
      this.mapKey.set('');
      this.mapPopover.hide();
      return;
    }

    // Fermer d'abord la popover si elle est ouverte
    if (this.currentHikeForMap()) {
      this.mapPopover.hide();
      // Attendre que la fermeture soit complète avant d'ouvrir la nouvelle
      setTimeout(() => {
        this.currentHikeForMap.set(hike);
        // Générer une nouvelle clé pour forcer la reconstruction du Map
        this.mapKey.set(`map-${hike.id}-${Date.now()}`);
        this.mapPopover.show(event);
      }, 150);
    } else {
      // Si aucune popover n'est ouverte, mettre à jour et afficher directement
      this.currentHikeForMap.set(hike);
      this.mapKey.set(`map-${hike.id}-${Date.now()}`);
      this.mapPopover.show(event);
    }
  }

  getSeverity = getDifficultySeverity;
  getStatusSeverity = getStatusSeverity;
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

  getOwnerLabel(hike: Hike): string {
    if (!hike.userId) {
      return 'Officielle';
    }

    return this.ownerLabels()[hike.userId] ?? `Utilisateur #${hike.userId}`;
  }

  private preloadOwnerLabels(hikes: Hike[]): void {
    const userIds = [...new Set(hikes.map((hike) => hike.userId).filter(Boolean))];

    for (const userId of userIds) {
      if (!userId || this.ownerLabels()[userId] || this.#requestedOwnerIds.has(userId)) {
        continue;
      }

      this.#requestedOwnerIds.add(userId);
      if (!this.#usersService) {
        this.ownerLabels.update((labels) => ({
          ...labels,
          [userId]: `Utilisateur #${userId}`,
        }));
        continue;
      }

      this.#usersService.getUserById(userId).subscribe({
        next: (user) => {
          const fullName =
            user.fullName?.trim() ||
            `${user.firstname || ''} ${user.lastname || ''}`.trim() ||
            `Utilisateur #${userId}`;

          this.ownerLabels.update((labels) => ({
            ...labels,
            [userId]: fullName,
          }));
        },
        error: () => {
          this.ownerLabels.update((labels) => ({
            ...labels,
            [userId]: `Utilisateur #${userId}`,
          }));
        },
      });
    }
  }

  /**
   * Calcule le dénivelé positif et négatif à partir des coordonnées
   */
  calculateElevation(
    coordinates: { latitude: number; longitude: number; elevation?: number }[]
  ): { gain: number; loss: number } {
    let gain = 0;
    let loss = 0;

    if (coordinates.length < 2) {
      return { gain: 0, loss: 0 };
    }

    for (let i = 1; i < coordinates.length; i++) {
      const prevElevation = coordinates[i - 1].elevation || 0;
      const currentElevation = coordinates[i].elevation || 0;

      const diff = currentElevation - prevElevation;

      if (diff > 0) {
        gain += diff;
      } else {
        loss += Math.abs(diff);
      }
    }

    return {
      gain: Math.round(gain),
      loss: Math.round(loss),
    };
  }

  /**
   * Retourne le dénivelé total (gain positif) pour l'affichage
   */
  getElevationGain(hike: Hike): number {
    // Priorité 1: Calculer depuis les coordonnées si elles ont de l'élévation (plus précis)
    if (hike.coordinates && hike.coordinates.length >= 2) {
      const hasElevation = hike.coordinates.some(
        (coord) =>
          coord.elevation !== undefined &&
          coord.elevation !== null &&
          coord.elevation !== 0
      );

      if (hasElevation) {
        const elevation = this.calculateElevation(hike.coordinates);
        if (elevation.gain > 0) {
          return elevation.gain;
        }
      }
    }

    // Priorité 2: Utiliser le dénivelé calculé dans le modèle si disponible
    if (hike.elevationGain !== undefined && hike.elevationGain > 0) {
      return hike.elevationGain;
    }

    // Priorité 3: Utiliser les élévations de départ et d'arrivée si disponibles
    if (
      hike.startingElevation !== undefined &&
      hike.arrivalElevation !== undefined &&
      hike.startingElevation > 0 &&
      hike.arrivalElevation > 0
    ) {
      const netElevation = hike.arrivalElevation - hike.startingElevation;
      if (netElevation > 0) {
        return Math.round(netElevation);
      }
    }

    // Dernier recours: calculer depuis les coordonnées même sans élévation (retournera 0)
    if (hike.coordinates && hike.coordinates.length >= 2) {
      const elevation = this.calculateElevation(hike.coordinates);
      return elevation.gain;
    }

    return 0;
  }
}
