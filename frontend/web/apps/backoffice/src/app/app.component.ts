import { Component, inject } from '@angular/core';
import { RouterModule } from '@angular/router';
import { TranslateService } from '@ngx-translate/core';
import { PrimeNG } from 'primeng/config';
import { LanguageService } from '@web/shared/util';
import { ToastModule } from 'primeng/toast';

@Component({
  imports: [RouterModule, ToastModule],
  selector: 'naavi-root',
  templateUrl: './app.component.html',
  styleUrl: './app.component.css',
})
export class AppComponent {
  readonly #translateService = inject(TranslateService);
  readonly #primeng = inject(PrimeNG);
  readonly #languageService = inject(LanguageService);

  constructor() {
    // Initialize language from localStorage or browser default
    this.#languageService.initializeLanguage();

    // Set fallback language
    this.#translateService.setFallbackLang('fr');

    // Load PrimeNG translations
    this.#translateService
      .get('primeng')
      .subscribe((res) => this.#primeng.setTranslation(res));
  }
}
