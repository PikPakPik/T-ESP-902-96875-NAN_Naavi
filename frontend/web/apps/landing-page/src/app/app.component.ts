import { RouterModule } from '@angular/router';
import { DividerModule } from 'primeng/divider';
import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { LoadingService } from './loading/loading.service';
import { LoadingComponent } from './loading/loading.component';
import { MenubarModule } from 'primeng/menubar';
import { MenuItem } from 'primeng/api';

@Component({
  imports: [
    CommonModule,
    DividerModule,
    RouterModule,
    LoadingComponent,
    MenubarModule,
  ],
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrl: './app.component.scss',
})
export class AppComponent implements OnInit {
  title = 'NAavi - Votre solution de navigation intelligente';

  public loadingService = inject(LoadingService);

  items: MenuItem[] | undefined;

  ngOnInit() {
    // Simuler un chargement initial
    setTimeout(() => {
      this.loadingService.hide();
    }, 2500); // 2.5 secondes de chargement

    this.items = [
      {
        label: 'Accueil',
        routerLink: '/',
      },
      {
        label: "L'équipe",
        routerLink: '/team',
      },
      {
        label: 'Contact',
        routerLink: '/contact',
      },
    ];
  }
}
