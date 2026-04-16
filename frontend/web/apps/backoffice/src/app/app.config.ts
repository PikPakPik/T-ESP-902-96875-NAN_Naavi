import { API_URL, IMAGES_BASE_URL } from '@web/shared/http-client';
import { provideStoreDevtools } from '@ngrx/store-devtools';
import {
  GlobalErrorHandler,
  LogLevel,
  LOG_LEVEL_TOKEN,
} from '@web/shared/data-access/logger';
import {
  ApplicationConfig,
  ErrorHandler,
  importProvidersFrom,
  isDevMode,
  provideZonelessChangeDetection,
} from '@angular/core';
import { provideRouter, RouterModule } from '@angular/router';
import { appRoutes } from './app.routes';

import { providePrimeNG } from 'primeng/config';
import Lara from '@primeuix/themes/lara';
import { environment } from '../environments/environment';
import { NotificationModule } from '@web/shared/ui/notification';
import { TranslateLoader, TranslateModule } from '@ngx-translate/core';
import { HttpBackend } from '@angular/common/http';
import { HttpLoaderFactory } from '@web/shared/util';
import {
  provideHttpClient,
  withFetch,
  withInterceptors,
} from '@angular/common/http';
import { authInterceptor } from '@web/shared/data-access';
import { provideMapboxGL } from 'ngx-mapbox-gl';
import { MAPBOX_TOKEN, TURNSTILE_SITE_KEY } from '@web/shared/util';

export const appConfig: ApplicationConfig = {
  providers: [
    provideZonelessChangeDetection(),
    provideRouter(appRoutes),
    provideHttpClient(withFetch(), withInterceptors([authInterceptor])),
    // Only provide Mapbox if token is available
    ...(import.meta.env['VITE_MAPBOX_TOKEN']
      ? [
          provideMapboxGL({
            accessToken: import.meta.env['VITE_MAPBOX_TOKEN'],
          }),
        ]
      : []),
    providePrimeNG({
      theme: {
        preset: Lara,
        options: {
          darkModeSelector: 'dark',
        },
      },
      ripple: true,
    }),
    provideStoreDevtools({
      name: 'Backoffice',
      logOnly: !isDevMode(),
    }),
    importProvidersFrom([
      NotificationModule,
      RouterModule,
      TranslateModule.forRoot({
        loader: {
          provide: TranslateLoader,
          useFactory: HttpLoaderFactory,
          deps: [HttpBackend],
        },
      }),
    ]),
    {
      provide: LOG_LEVEL_TOKEN,
      useValue: environment.production ? LogLevel.Error : LogLevel.Debug,
    },
    { provide: ErrorHandler, useClass: GlobalErrorHandler },
    { provide: API_URL, useValue: environment.api_url },
    {
      provide: IMAGES_BASE_URL,
      useValue:
        import.meta.env['VITE_IMAGES_BASE_URL'] ??
        environment.images_base_url ??
        '',
    },
    {
      provide: MAPBOX_TOKEN,
      useValue: import.meta.env['VITE_MAPBOX_TOKEN'] ?? '',
    },
    {
      provide: TURNSTILE_SITE_KEY,
      useValue: import.meta.env['VITE_TURNSTILE_SITE_KEY'] ?? '',
    },
  ],
};
