
import { Component, inject, signal, OnDestroy } from '@angular/core';
import { RouterModule } from '@angular/router';
import { MenuItem } from 'primeng/api';
import { NavbarComponent } from '@web/shared/ui/navbar';
import { AuthStore } from '@web/auth/data-access';
import { TranslateService } from '@ngx-translate/core';
import { Subscription } from 'rxjs';

@Component({
  imports: [RouterModule, NavbarComponent],
  selector: 'naavi-layout',
  templateUrl: './layout.component.html',
})
export class LayoutComponent implements OnDestroy {
  readonly #authStore = inject(AuthStore);
  readonly #translateService = inject(TranslateService);
  readonly #langChangeSubscription: Subscription;

  user = this.#authStore.user;

  menuItems = signal<MenuItem[]>([]);
  userMenuItems = signal<MenuItem[]>([]);

  constructor() {
    // Update menu items when language changes
    this.#langChangeSubscription =
      this.#translateService.onLangChange.subscribe(() => {
        this.updateMenuItems();
      });

    // Initial load
    this.updateMenuItems();
  }

  ngOnDestroy(): void {
    this.#langChangeSubscription?.unsubscribe();
  }

  private updateMenuItems(): void {
    this.menuItems.set([
      {
        label: this.#translateService.instant('COMMON.DASHBOARD'),
        icon: 'pi pi-home',
        routerLink: '/dashboard',
      },
      {
        label: this.#translateService.instant('COMMON.USERS'),
        icon: 'pi pi-users',
        routerLink: '/users',
      },
      {
        label: this.#translateService.instant('COMMON.HIKES'),
        icon: 'pi pi-map',
        items: [
          {
            label: this.#translateService.instant('COMMON.HIKES_LIST'),
            icon: 'pi pi-list',
            routerLink: '/hikes',
          },
          {
            label: this.#translateService.instant('COMMON.CREATE_HIKE'),
            icon: 'pi pi-plus',
            routerLink: '/hikes/new',
          },
        ],
      },
      {
        label: this.#translateService.instant('COMMON.POIS'),
        icon: 'pi pi-map-marker',
        routerLink: '/pois',
      },
    ]);

    this.userMenuItems.set([
      {
        label: this.#translateService.instant('COMMON.MY_PROFILE'),
        icon: 'pi pi-user',
        routerLink: '/profile',
      },
      {
        label: this.#translateService.instant('COMMON.SETTINGS'),
        icon: 'pi pi-cog',
        routerLink: '/settings',
      },
      {
        separator: true,
      },
      {
        label: this.#translateService.instant('COMMON.LOGOUT'),
        icon: 'pi pi-sign-out',
        command: () => {
          this.#authStore.logout();
        },
      },
    ]);
  }
}
