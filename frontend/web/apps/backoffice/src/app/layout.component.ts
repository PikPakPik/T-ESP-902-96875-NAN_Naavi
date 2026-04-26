import { Component, inject, signal, computed, OnDestroy } from '@angular/core';
import { Router, RouterModule } from '@angular/router';
import { MenuItem } from 'primeng/api';
import { NavbarComponent } from '@web/shared/ui/navbar';
import { AuthStore } from '@web/auth/data-access';
import { TranslateService } from '@ngx-translate/core';
import { IMAGES_BASE_URL } from '@web/shared/http-client';
import { Subscription } from 'rxjs';
import { POIsStore } from '@web/pois/data-access';
import { naaviMediaDisplayUrl } from '@web/shared/util';

@Component({
  imports: [RouterModule, NavbarComponent],
  selector: 'naavi-layout',
  templateUrl: './layout.component.html',
})
export class LayoutComponent implements OnDestroy {
  readonly #authStore = inject(AuthStore);
  readonly #router = inject(Router);
  readonly #translateService = inject(TranslateService);
  readonly #imagesBaseUrl = inject(IMAGES_BASE_URL, { optional: true });
  readonly #poisStore = inject(POIsStore);
  readonly #langChangeSubscription: Subscription;
  readonly #menuRefreshTick = signal(0);

  user = this.#authStore.user;

  userProfilePictureUrl = computed(() => {
    const path = this.user()?.profilePicture;
    return (
      naaviMediaDisplayUrl(path ?? null, this.#imagesBaseUrl) ?? undefined
    );
  });

  menuItems = computed<MenuItem[]>(() => {
    this.#menuRefreshTick();
    const pendingApprovalCount = this.#poisStore.pendingApprovalCount();

    return [
      {
        label: this.#translateService.instant('COMMON.DASHBOARD'),
        icon: 'pi pi-home',
        routerLink: '',
      },
      {
        label: this.#translateService.instant('COMMON.USERS'),
        icon: 'pi pi-users',
        routerLink: 'users',
      },
      {
        label: this.#translateService.instant('COMMON.HIKES'),
        icon: 'pi pi-map',
        items: [
          {
            label: this.#translateService.instant('COMMON.HIKES_LIST'),
            icon: 'pi pi-list',
            routerLink: 'hikes',
          },
          {
            label: this.#translateService.instant('COMMON.CREATE_HIKE'),
            icon: 'pi pi-plus',
            routerLink: 'hikes/new',
          },
          {
            label: this.#translateService.instant('COMMON.IMPORT_HIKES'),
            icon: 'pi pi-file-import',
            routerLink: 'hikes/import',
          },
        ],
      },
      {
        label: this.#translateService.instant('COMMON.POIS'),
        icon: 'pi pi-map-marker',
        routerLink: 'pois',
        badge: pendingApprovalCount > 0 ? String(pendingApprovalCount) : undefined,
      },
    ];
  });
  userMenuItems = computed<MenuItem[]>(() => {
    this.#menuRefreshTick();

    return [
      {
        label: this.#translateService.instant('COMMON.MY_PROFILE'),
        icon: 'pi pi-user',
        routerLink: 'profile',
      },
      {
        label: this.#translateService.instant('COMMON.SETTINGS'),
        icon: 'pi pi-cog',
        routerLink: 'settings',
      },
      {
        separator: true,
      },
      {
        label: this.#translateService.instant('COMMON.LOGOUT'),
        icon: 'pi pi-sign-out',
        command: () => {
          this.#authStore.logout().finally(() => {
            this.#router.navigate(['/login']);
          });
        },
      },
    ];
  });

  constructor() {
    // Update menu items when language changes
    this.#langChangeSubscription =
      this.#translateService.onLangChange.subscribe(() => {
        this.#menuRefreshTick.update((value) => value + 1);
      });
  }

  ngOnDestroy(): void {
    this.#langChangeSubscription?.unsubscribe();
  }
}
