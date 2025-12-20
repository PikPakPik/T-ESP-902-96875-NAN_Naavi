import { Component } from '@angular/core';
import { UserUpsertComponent } from './user-upsert.component';

@Component({
  selector: 'user-upsert-container',
  standalone: true,
  imports: [UserUpsertComponent],
  template: ` <user-upsert /> `,
})
export class UserUpsertContainer {}
