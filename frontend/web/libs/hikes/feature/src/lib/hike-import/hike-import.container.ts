import { Component, inject, signal, ViewChild } from '@angular/core';
import { MessageService } from 'primeng/api';
import { HikeImportComponent } from './hike-import.component';
import { HikeImportService, ImportMappings } from '@web/hikes/data-access';
import { TranslateService } from '@ngx-translate/core';
import { AuthStore } from '@web/auth/data-access';

@Component({
  selector: 'hike-import-container',
  standalone: true,
  imports: [HikeImportComponent],
  template: `
    <hike-import
      #importComponent
      [loading]="loading()"
      (fileSelected)="onFileSelected($event)"
      (mappingsSubmit)="onSubmit($event)"
      (resetImport)="onReset()"
    />
  `,
})
export class HikeImportContainer {
  #importService = inject(HikeImportService);
  #authStore = inject(AuthStore);
  #messageService = inject(MessageService);
  #translateService = inject(TranslateService);

  @ViewChild('importComponent') importComponent!: HikeImportComponent;

  loading = signal(false);

  async onFileSelected(file: File) {
    try {
      const { headers, preview } =
        await this.#importService.parseImportHeaders(file);
      this.importComponent.setCsvData(headers, preview);
    } catch {
      this.#messageService.add({
        severity: 'error',
        summary: this.#translateService.instant('COMMON.ERROR'),
        detail: this.#translateService.instant('IMPORT.PARSE_ERROR'),
      });
    }
  }

  async onSubmit(event: { file: File; mappings: ImportMappings }) {
    this.loading.set(true);
    try {
      // Rafraîchir le token avant l'import pour éviter 401 (FormData ne peut pas être retenté)
      await this.#authStore.currentUser().catch(() => {
        /* ignore - l'import échouera si non authentifié */
      });
      const { file, mappings } =
        await this.#importService.enrichFileWithCoordinates(
          event.file,
          event.mappings
        );
      this.#importService.importHikes(file, mappings).subscribe({
        next: () => {
          this.loading.set(false);
          this.#messageService.add({
            severity: 'success',
            summary: this.#translateService.instant('COMMON.SUCCESS'),
            detail: this.#translateService.instant('IMPORT.SUCCESS'),
          });
        },
        error: () => {
          this.loading.set(false);
        },
      });
    } catch {
      this.loading.set(false);
    }
  }

  onReset() {
    this.loading.set(false);
  }
}
