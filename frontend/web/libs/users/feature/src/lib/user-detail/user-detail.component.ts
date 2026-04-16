import { CommonModule } from '@angular/common';
import { Component, computed, inject, input, output, signal } from '@angular/core';
import { User } from '@web/shared/models/settings';
import { TableModule } from 'primeng/table';
import { TagModule } from 'primeng/tag';
import { ButtonModule } from 'primeng/button';
import { SkeletonModule } from 'primeng/skeleton';
import { PaginatorModule } from 'primeng/paginator';
import { TooltipModule } from 'primeng/tooltip';
import { ImageModule } from 'primeng/image';
import { DialogModule } from 'primeng/dialog';
import { TranslateModule } from '@ngx-translate/core';
import { HikeHistoryItem } from '@web/shared/models/settings';
import { SecondsToTimePipe } from './seconds-to-time.pipe';
import { GeoJSONSourceComponent, LayerComponent, MapComponent } from 'ngx-mapbox-gl';
import { MAPBOX_TOKEN } from '@web/shared/util';
import { Geometry, LineString, Point } from 'wkx-ts';
import { Buffer } from 'buffer/';

type HistoryTraceGeoJson = {
  type: 'FeatureCollection';
  features: HistoryTraceFeature[];
};

type HistoryTraceFeature =
  | {
      type: 'Feature';
      properties: Record<string, never>;
      geometry: {
        type: 'Point';
        coordinates: [number, number];
      };
    }
  | {
      type: 'Feature';
      properties: Record<string, never>;
      geometry: {
        type: 'LineString';
        coordinates: [number, number][];
      };
    };

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
    TooltipModule,
    ImageModule,
    DialogModule,
    TranslateModule,
    SecondsToTimePipe,
    MapComponent,
    LayerComponent,
    GeoJSONSourceComponent,
  ],
  templateUrl: './user-detail.component.html',
})
export class UserDetailComponent {
  #mapboxToken = inject(MAPBOX_TOKEN, { optional: true });

  user = input<User | null>(null);
  profilePictureUrl = input<string | null>(null);
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
  deleteProfilePicture = output<void>();

  selectedHistory = signal<HikeHistoryItem | null>(null);
  historyDialogVisible = signal(false);
  traceCoordinates = signal<[number, number][]>([]);

  hasMapboxToken = computed(() => !!this.#mapboxToken?.trim());

  traceGeoJson: ReturnType<typeof computed<HistoryTraceGeoJson>> = computed<
    HistoryTraceGeoJson
  >(() => {
    const coordinates = this.traceCoordinates();

    if (coordinates.length === 0) {
      return {
        type: 'FeatureCollection',
        features: [],
      };
    }

    const feature: HistoryTraceFeature =
      coordinates.length === 1
        ? {
            type: 'Feature',
            properties: {},
            geometry: {
              type: 'Point',
              coordinates: coordinates[0],
            },
          }
        : {
            type: 'Feature',
            properties: {},
            geometry: {
              type: 'LineString',
              coordinates,
            },
          };

    return {
      type: 'FeatureCollection',
      features: [feature],
    };
  });

  mapCenter = computed<[number, number]>(() => {
    const coordinates = this.traceCoordinates();
    if (coordinates.length > 0) {
      return coordinates[0];
    }

    const history = this.selectedHistory();
    if (
      history?.startingPointLatitude !== undefined &&
      history.startingPointLongitude !== undefined
    ) {
      return [history.startingPointLongitude, history.startingPointLatitude];
    }

    return [2.3522, 48.8566];
  });

  onPageChange(event: { page: number; rows: number }) {
    this.pageChange.emit({
      page: event.page + 1,
      rows: event.rows,
    });
  }

  openHistoryDetail(item: HikeHistoryItem): void {
    this.selectedHistory.set(item);
    this.traceCoordinates.set(this.decodeWkbGeometry(item.wkbGeometry));
    this.historyDialogVisible.set(true);
  }

  closeHistoryDetail(): void {
    this.historyDialogVisible.set(false);
    this.selectedHistory.set(null);
    this.traceCoordinates.set([]);
  }

  distanceInKm(distance?: number): number | null {
    if (distance === undefined || distance === null) {
      return null;
    }
    return Math.round((distance / 1000) * 100) / 100;
  }

  private decodeWkbGeometry(wkbHex?: string): [number, number][] {
    if (!wkbHex) {
      return [];
    }

    try {
      const geometry = Geometry.parse(Buffer.from(wkbHex, 'hex') as never);

      if (geometry instanceof LineString) {
        const lineString = geometry as unknown as {
          points: Array<{ x: number; y: number }>;
        };
        return lineString.points.map((point) => [point.x, point.y]);
      }

      if (geometry instanceof Point) {
        const point = geometry as unknown as { x: number; y: number };
        return [[point.x, point.y]];
      }
    } catch {
      return [];
    }

    return [];
  }
}
