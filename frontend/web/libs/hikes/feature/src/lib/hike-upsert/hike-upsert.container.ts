import { Component } from '@angular/core';
import { HikeUpsertComponent } from './hike-upsert.component';

@Component({
  selector: 'hike-upsert-container',
  standalone: true,
  imports: [HikeUpsertComponent],
  template: ` <hike-upsert /> `,
})
export class HikeUpsertContainer {}
