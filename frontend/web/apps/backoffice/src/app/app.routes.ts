import { Route } from '@angular/router';
import { HomeComponent } from '@web/home';
import { LayoutComponent } from './layout.component';
import { AdminGuard, AuthGuard } from '@web/auth/data-access';
import {
  UsersContainer,
  UserUpsertContainer,
  UserDetailContainer,
} from '@web/users/feature';
import {
  HikeDetailComponent,
  HikesContainer,
  HikeUpsertContainer,
  HikeImportContainer,
} from '@web/hikes/feature';
import { ProfileContainer } from '@web/profile/features';
import { PoisContainer, PoiUpsertContainer } from '@web/pois/features';

export const appRoutes: Route[] = [
  {
    path: '',
    pathMatch: 'full',
    redirectTo: '/backoffice',
  },
  {
    path: 'backoffice',
    canActivate: [AuthGuard],
    component: LayoutComponent,
    children: [
      {
        path: '',
        canActivate: [AdminGuard],
        component: HomeComponent,
      },
      {
        path: 'users',
        children: [
          {
            path: '',
            canActivate: [AdminGuard],
            component: UsersContainer,
          },
          {
            path: 'new',
            canActivate: [AdminGuard],
            component: UserUpsertContainer,
          },
          {
            path: 'edit/:id',
            canActivate: [AdminGuard],
            component: UserUpsertContainer,
          },
          {
            path: ':id',
            canActivate: [AdminGuard],
            component: UserDetailContainer,
          },
        ],
      },
      {
        path: 'hikes',
        canActivate: [AdminGuard],
        children: [
          {
            path: '',
            component: HikesContainer,
          },
          {
            path: 'new',
            component: HikeUpsertContainer,
          },
          {
            path: 'edit/:id',
            component: HikeUpsertContainer,
          },
          {
            path: 'import',
            component: HikeImportContainer,
          },
          {
            path: ':id',
            component: HikeDetailComponent,
          },
        ],
      },
      {
        path: 'pois',
        canActivate: [AdminGuard],
        children: [
          {
            path: '',
            component: PoisContainer,
          },
          {
            path: 'new',
            component: PoiUpsertContainer,
          },
          {
            path: 'edit/:id',
            component: PoiUpsertContainer,
          },
        ],
      },
      {
        path: 'profile',
        component: ProfileContainer,
      },
    ],
  },
  {
    path: 'login',
    loadComponent: () =>
      import('@web/auth/feature').then((m) => m.AuthFeatureComponent),
  },
  {
    path: 'forbidden',
    canActivate: [AuthGuard],
    loadComponent: () =>
      import('./forbidden/forbidden.component').then(
        (m) => m.ForbiddenComponent
      ),
  },
  {
    path: '**',
    redirectTo: '/',
  },
];
