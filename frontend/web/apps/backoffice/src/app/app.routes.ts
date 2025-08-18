import { CombinedAuthGuard } from '@web/auth/data-access';
import { Route } from '@angular/router';

export const appRoutes: Route[] = [
  {
    path: '',
    canActivate: [CombinedAuthGuard],
    loadComponent: () => import('@web/home').then((m) => m.HomeComponent),
  },
  {
    path: 'login',
    loadComponent: () =>
      import('@web/auth/feature').then((m) => m.AuthFeatureComponent),
  },
];
