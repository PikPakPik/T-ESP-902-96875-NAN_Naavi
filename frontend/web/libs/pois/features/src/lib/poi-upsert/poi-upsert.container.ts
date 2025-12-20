import { Component } from '@angular/core';
import { PoiUpsertComponent } from './poi-upsert.component';

@Component({
  selector: 'poi-upsert-container',
  standalone: true,
  imports: [PoiUpsertComponent],
  template: ` <poi-upsert /> `,
})
export class PoiUpsertContainer {}
