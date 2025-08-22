import { API_URL } from '@web/shared/http-client';
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
  provideZoneChangeDetection,
} from '@angular/core';
import { provideRouter, RouterModule } from '@angular/router';
import { appRoutes } from './app.routes';
import {
  provideClientHydration,
  withEventReplay,
} from '@angular/platform-browser';
import { provideAnimationsAsync } from '@angular/platform-browser/animations/async';
import { providePrimeNG } from 'primeng/config';
import Lara from '@primeng/themes/lara';
import { environment } from '../environments/environment';
import { NotificationModule } from '@web/ui/notification';
import { TranslateLoader, TranslateModule } from '@ngx-translate/core';
import { HTTP_INTERCEPTORS, HttpBackend } from '@angular/common/http';
import { HttpLoaderFactory } from '@web/shared/util';
import { provideHttpClient, withFetch } from '@angular/common/http';
import { LoaderInterceptor } from '@web/shared/data-access';

export const appConfig: ApplicationConfig = {
  providers: [
    provideClientHydration(withEventReplay()),
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(appRoutes),
    provideAnimationsAsync(),
    provideHttpClient(withFetch()),
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
    { provide: HTTP_INTERCEPTORS, useClass: LoaderInterceptor, multi: true },
    { provide: API_URL, useValue: environment.api_url },
  ],
};
