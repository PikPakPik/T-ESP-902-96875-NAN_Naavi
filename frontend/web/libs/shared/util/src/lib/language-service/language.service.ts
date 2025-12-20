import { Injectable, inject } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { LocalStorageService } from '../local-storage-service/localstorage.service';

export type Language = 'fr' | 'en';

const LANGUAGE_STORAGE_KEY = 'naavi_language';
const DEFAULT_LANGUAGE: Language = 'fr';

@Injectable({
  providedIn: 'root',
})
export class LanguageService {
  readonly #translateService = inject(TranslateService);
  readonly #localStorage = inject(LocalStorageService);

  /**
   * Initialize language from localStorage or browser default
   */
  initializeLanguage(): void {
    const storedLanguage =
      this.#localStorage.getItem<Language>(LANGUAGE_STORAGE_KEY);
    const browserLang = this.#translateService.getBrowserLang() as Language;
    const languageToUse =
      storedLanguage || (browserLang === 'en' ? 'en' : DEFAULT_LANGUAGE);

    this.setLanguage(languageToUse);
  }

  /**
   * Get current language
   */
  getCurrentLanguage(): Language {
    return (this.#translateService.currentLang ||
      this.#translateService.defaultLang ||
      DEFAULT_LANGUAGE) as Language;
  }

  /**
   * Set language and save to localStorage
   */
  setLanguage(language: Language): void {
    this.#translateService.use(language);
    this.#localStorage.setItem(LANGUAGE_STORAGE_KEY, language);
  }

  /**
   * Get available languages
   */
  getAvailableLanguages(): { code: Language; label: string }[] {
    return [
      { code: 'fr', label: 'Français' },
      { code: 'en', label: 'English' },
    ];
  }
}
