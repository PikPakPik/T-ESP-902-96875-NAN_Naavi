import { Component, input, output, ViewChild, inject, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import {
  Router,
  RouterModule,
  NavigationEnd,
  ActivatedRoute,
} from '@angular/router';
import { MenubarModule } from 'primeng/menubar';
import { PopoverModule } from 'primeng/popover';
import { MenuModule } from 'primeng/menu';
import { Menu } from 'primeng/menu';
import { TieredMenuModule } from 'primeng/tieredmenu';
import { TieredMenu } from 'primeng/tieredmenu';
import { MenuItem } from 'primeng/api';
import { filter } from 'rxjs';

@Component({
  selector: 'navigation',
  imports: [
    CommonModule,
    RouterModule,
    MenubarModule,
    PopoverModule,
    MenuModule,
    TieredMenuModule,
  ],
  templateUrl: './navbar.component.html',
  styleUrl: './navbar.component.css',
})
export class NavbarComponent {
  readonly #router = inject(Router);
  readonly #route = inject(ActivatedRoute);

  brandName = input('Naavi');
  brandLogo = input<string | undefined>(undefined);
  menuItems = input<MenuItem[]>([]);
  showBrand = input(true);

  userName = input<string>('');
  userAvatar = input<string | undefined>(undefined);
  userMenuItems = input<MenuItem[]>([]);

  itemClick = output<MenuItem>();

  @ViewChild('userMenu') userMenu!: Menu;
  @ViewChild('mobileMenu') mobileMenu!: TieredMenu;

  /** Menu mobile avec dropdowns (TieredMenu) + command au lieu de routerLink */
  mobileMenuModel = computed(() =>
    this.#itemsWithCommand(this.menuItems())
  );

  /** Menu user avec command au lieu de routerLink */
  userMenuModel = computed(() =>
    this.#itemsWithCommand(this.userMenuItems())
  );

  constructor() {
    this.#router.events
      .pipe(filter((e): e is NavigationEnd => e instanceof NavigationEnd))
      .subscribe(() => {
        this.mobileMenu?.hide();
      });
  }

  #itemWithCommand(item: MenuItem): MenuItem {
    const { routerLink, command, items, ...rest } = item;
    const result: MenuItem = { ...rest };

    if (items?.length) {
      result.items = this.#itemsWithCommand(items);
    }

    if (routerLink !== undefined && routerLink !== null) {
      const path = typeof routerLink === 'string' ? routerLink : routerLink;
      const segments =
        typeof path === 'string'
          ? path.split('/').filter(Boolean)
          : Array.isArray(path)
            ? path
            : [path];
      result.command = () => {
        this.#router.navigate(segments, { relativeTo: this.#route });
        this.mobileMenu?.hide();
        this.userMenu?.hide();
      };
    } else if (command) {
      result.command = command;
    }

    return result;
  }

  #itemsWithCommand(items: MenuItem[]): MenuItem[] {
    return items.map((item) => this.#itemWithCommand(item));
  }

  onItemClick(item: MenuItem) {
    this.itemClick.emit(item);
    if (item.command) {
      item.command({});
    }
  }
}
