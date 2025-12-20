import { Component, input, output, ViewChild } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { MenubarModule } from 'primeng/menubar';
import { PopoverModule } from 'primeng/popover';
import { MenuModule } from 'primeng/menu';
import { Menu } from 'primeng/menu';
import { MenuItem } from 'primeng/api';

@Component({
  selector: 'navigation',
  imports: [
    CommonModule,
    RouterModule,
    MenubarModule,
    PopoverModule,
    MenuModule,
  ],
  templateUrl: './navbar.component.html',
  styleUrl: './navbar.component.css',
})
export class NavbarComponent {
  brandName = input('Naavi');
  brandLogo = input<string | undefined>(undefined);
  menuItems = input<MenuItem[]>([]);
  showBrand = input(true);

  userName = input<string>('');
  userAvatar = input<string | undefined>(undefined);
  userMenuItems = input<MenuItem[]>([]);

  itemClick = output<MenuItem>();

  @ViewChild('userMenu') userMenu!: Menu;

  onItemClick(item: MenuItem) {
    this.itemClick.emit(item);
    if (item.command) {
      item.command({});
    }
  }
}
