import { Component, computed, input, output, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TranslateModule } from '@ngx-translate/core';
import { CardModule } from 'primeng/card';
import { FileUploadModule } from 'primeng/fileupload';
import { SelectModule } from 'primeng/select';
import { ButtonModule } from 'primeng/button';
import { TableModule } from 'primeng/table';
import { PanelModule } from 'primeng/panel';
import { InputTextModule } from 'primeng/inputtext';
import { TagModule } from 'primeng/tag';
import { DragDropModule, CdkDragDrop } from '@angular/cdk/drag-drop';
import {
  HIKE_API_FIELDS,
  ImportMappings,
  ColumnMapping,
} from '@web/hikes/data-access';

@Component({
  selector: 'hike-import',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    TranslateModule,
    CardModule,
    FileUploadModule,
    SelectModule,
    ButtonModule,
    TableModule,
    PanelModule,
    InputTextModule,
    TagModule,
    DragDropModule,
  ],
  templateUrl: './hike-import.component.html',
  styleUrls: ['./hike-import.component.scss'],
})
export class HikeImportComponent {
  loading = input<boolean>(false);

  fileSelected = output<File>();
  mappingsSubmit = output<{ file: File; mappings: ImportMappings }>();
  resetImport = output<void>();

  selectedFile = signal<File | null>(null);
  csvHeaders = signal<string[]>([]);
  csvPreview = signal<string[][]>([]);
  mappings = signal<Record<string, ColumnMapping | undefined>>({});

  apiFields = HIKE_API_FIELDS;

  csvColumnOptions = computed(() =>
    this.csvHeaders().map((header) => ({
      label: header,
      value: header,
    }))
  );

  apiDropLists = computed(() =>
    this.apiFields.map((f) => 'api-drop-' + f.key)
  );

  mappedCount = computed(() =>
    Object.values(this.mappings()).filter((v) => v?.source).length
  );

  requiresMapping = computed(() => this.isMappingFile(this.selectedFile()));

  showMappingBoard = computed(
    () => this.requiresMapping() && this.csvHeaders().length > 0
  );

  canSubmit = computed(() => {
    if (this.loading() || !this.selectedFile()) {
      return false;
    }
    if (!this.requiresMapping()) {
      return true;
    }
    const m = this.mappings();
    const hasMappings = Object.values(m).some((v) => v?.source);
    return hasMappings;
  });

  openFilePicker(event: Event, chooseCallback: () => void) {
    event.preventDefault();
    chooseCallback();
  }

  removeFile(
    event: Event,
    removeFileCallback: (index: number) => void,
    index: number
  ) {
    event.preventDefault();
    removeFileCallback(index);
    this.onFileClear();
  }

  getFileTypeIcon(file: File | null): string {
    if (!file) return 'pi pi-file';
    return this.getFileTypeIconByName(file.name);
  }

  getFileTypeIconByName(name: string): string {
    const lowerName = name.toLowerCase();
    if (lowerName.endsWith('.csv')) return 'pi pi-table';
    if (lowerName.endsWith('.json') || lowerName.endsWith('.geojson'))
      return 'pi pi-code';
    return 'pi pi-file';
  }

  getFileTypeLabel(file: File | null): string {
    if (!file) return '';
    return this.getFileTypeLabelByName(file.name);
  }

  getFileTypeLabelByName(name: string): string {
    const lowerName = name.toLowerCase();
    if (lowerName.endsWith('.csv')) return 'CSV';
    if (lowerName.endsWith('.json') || lowerName.endsWith('.geojson')) return 'JSON';
    return 'FILE';
  }

  isCsvFile(file: File | null): boolean {
    if (!file) return false;
    return file.name.toLowerCase().endsWith('.csv');
  }

  isJsonFile(file: File | null): boolean {
    if (!file) return false;
    const lowerName = file.name.toLowerCase();
    return lowerName.endsWith('.json') || lowerName.endsWith('.geojson');
  }

  isMappingFile(file: File | null): boolean {
    return this.isCsvFile(file) || this.isJsonFile(file);
  }

  getCardIconColorClassByName(name: string): string {
    const lowerName = name.toLowerCase();
    if (lowerName.endsWith('.csv')) return 'text-green-600';
    if (lowerName.endsWith('.json') || lowerName.endsWith('.geojson'))
      return 'text-blue-600';
    return 'text-gray-700';
  }

  getHeaderIconColorClass(file: File | null): string {
    if (!file) return 'text-green-600';
    return this.getCardIconColorClassByName(file.name);
  }

  getHeaderBadgeClass(file: File | null): string {
    if (!file) return 'border-green-200 bg-green-50 text-green-800';
    if (this.isCsvFile(file)) return 'border-green-200 bg-green-50 text-green-800';
    return 'border-blue-200 bg-blue-50 text-blue-800';
  }

  formatFileSize(sizeInBytes: number): string {
    const mb = sizeInBytes / (1024 * 1024);
    if (mb >= 1) return `${mb.toFixed(2)} MB`;
    const kb = sizeInBytes / 1024;
    return `${kb.toFixed(2)} KB`;
  }

  isColumnUsed(header: string): boolean {
    return Object.values(this.mappings()).some((m) => m?.source === header);
  }

  onDrop(event: CdkDragDrop<unknown>, fieldKey: string) {
    const csvColumn = event.item.data as string;
    if (csvColumn) {
      this.onMappingChange(fieldKey, csvColumn);
    }
  }

  onDisconnect(fieldKey: string) {
    this.onMappingChange(fieldKey, null);
  }

  onFileSelect(event: { files: File[]; currentFiles: File[] }) {
    const file = event.currentFiles?.[0] || event.files?.[0];
    if (file) {
      this.selectedFile.set(file);
      this.mappings.set({});
      this.fileSelected.emit(file);
    }
  }

  onFileClear() {
    this.selectedFile.set(null);
    this.csvHeaders.set([]);
    this.csvPreview.set([]);
    this.mappings.set({});
  }

  setCsvData(headers: string[], preview: string[][]) {
    this.csvHeaders.set(headers);
    this.csvPreview.set(preview);
  }

  onMappingChange(fieldKey: string, csvColumn: string | null) {
    const current = { ...this.mappings() };
    if (csvColumn) {
      current[fieldKey] = { source: csvColumn };
    } else {
      delete current[fieldKey];
    }
    this.mappings.set(current);
  }

  onUnitChange(fieldKey: string, unit: string) {
    const current = { ...this.mappings() };
    const existing = current[fieldKey];
    if (existing) {
      current[fieldKey] = { ...existing, unit };
      this.mappings.set(current);
    }
  }

  onValueMappingChange(fieldKey: string, enumValue: string, csvValue: string) {
    const current = { ...this.mappings() };
    const existing = current[fieldKey];
    if (existing) {
      const values = { ...(existing.values || {}) };
      if (csvValue) {
        values[csvValue] = enumValue;
      }
      current[fieldKey] = { ...existing, values };
      this.mappings.set(current);
    }
  }

  getValueMapping(fieldKey: string, enumValue: string): string {
    const mapping = this.mappings()[fieldKey];
    if (!mapping?.values) return '';
    const entry = Object.entries(mapping.values).find(
      ([, v]) => v === enumValue
    );
    return entry?.[0] || '';
  }

  getUnitOptions(units: readonly string[]): { label: string; value: string }[] {
    return units.map((u) => ({ label: u, value: u }));
  }

  getPreviewForColumn(columnName: string): string {
    const idx = this.csvHeaders().indexOf(columnName);
    if (idx === -1 || this.csvPreview().length === 0) return '';
    const values = this.csvPreview()
      .slice(0, 3)
      .map((row) => row[idx])
      .filter((v) => v);
    return values.join(', ');
  }

  getMappedPreviewColumns(): {
    apiField: string;
    csvColumn: string;
    csvColumnIndex: number;
  }[] {
    const m = this.mappings();
    const headers = this.csvHeaders();
    return Object.entries(m)
      .filter(([, v]) => v?.source)
      .map(([apiField, mapping]) => ({
        apiField,
        csvColumn: mapping?.source || '',
        csvColumnIndex: headers.indexOf(mapping?.source || ''),
      }))
      .filter((col) => col.csvColumnIndex !== -1);
  }

  getPreviewCellValue(rowIndex: number, colIndex: number): string {
    const preview = this.csvPreview();
    if (rowIndex >= preview.length || colIndex >= preview[rowIndex].length)
      return '';
    return preview[rowIndex][colIndex];
  }

  onSubmit() {
    const file = this.selectedFile();
    if (!file) return;

    // Build clean mappings (only those with source)
    const cleanMappings: ImportMappings = {};
    for (const [key, mapping] of Object.entries(this.mappings())) {
      if (mapping?.source) {
        cleanMappings[key] = { ...mapping };
      }
    }

    this.mappingsSubmit.emit({ file, mappings: cleanMappings });
  }

  onReset() {
    this.selectedFile.set(null);
    this.csvHeaders.set([]);
    this.csvPreview.set([]);
    this.mappings.set({});
    this.resetImport.emit();
  }
}
