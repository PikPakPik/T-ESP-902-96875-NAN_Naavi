import { provideAnimationsAsync } from '@angular/platform-browser/animations/async';
import { applicationConfig, moduleMetadata, Preview } from '@storybook/angular';
import { providePrimeNG } from 'primeng/config';
import Lara from '@primeng/themes/lara';
import '!style-loader!css-loader!sass-loader!../../../../apps/backoffice/src/styles.scss';
import { CommonModule } from '@angular/common';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

const preview: Preview = {
  decorators: [
    moduleMetadata({
      imports: [CommonModule, BrowserAnimationsModule],
    }),
    applicationConfig({
      providers: [
        provideAnimationsAsync(),
        providePrimeNG({
          theme: {
            preset: Lara,
            options: {
              darkModeSelector: 'dark',
            },
          },
          ripple: true,
        }),
      ],
    }),
  ],
};

export default preview;
