import { ApplicationConfig, provideZonelessChangeDetection } from '@angular/core';
import { provideRouter } from '@angular/router';
import { appRoutes } from './app.routes';
import { providePrimeNG } from 'primeng/config';
import Lara from '@primeuix/themes/lara';
import { MessageService } from 'primeng/api';
import { provideHttpClient, withFetch } from '@angular/common/http';
import { API_URL } from '@web/shared/http-client';
import { TURNSTILE_SITE_KEY } from '@web/shared/util';

/** Re-export for components that inject API_URL */
export { API_URL };
import { environment } from '../environments/environment';

export const appConfig: ApplicationConfig = {
  providers: [
    provideZonelessChangeDetection(),
    provideRouter(appRoutes),
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
    MessageService,
    {
      provide: API_URL,
      useValue: environment.api_url,
    },
    {
      provide: TURNSTILE_SITE_KEY,
      useValue: import.meta.env.VITE_TURNSTILE_SITE_KEY ?? '',
    },
  ],
};
