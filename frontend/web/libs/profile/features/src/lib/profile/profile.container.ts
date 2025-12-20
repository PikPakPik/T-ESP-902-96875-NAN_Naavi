import { Component } from '@angular/core';
import { ProfileComponent } from './profile.component';

@Component({
  selector: 'profile-container',
  standalone: true,
  imports: [ProfileComponent],
  template: ` <profile /> `,
})
export class ProfileContainer {}
