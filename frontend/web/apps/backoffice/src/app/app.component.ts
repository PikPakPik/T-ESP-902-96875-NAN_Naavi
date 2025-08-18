import { Component, inject } from '@angular/core';
import { RouterModule } from '@angular/router';
import { ToastModule } from 'primeng/toast';
import { TranslateModule, TranslateService } from '@ngx-translate/core';

@Component({
  imports: [RouterModule, ToastModule, TranslateModule],
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrl: './app.component.css',
})
export class AppComponent {
  readonly #translate = inject(TranslateService);

  constructor() {
    const lang = this.#translate.getBrowserLang();
    this.#translate.setDefaultLang(lang || 'fr');
  }
}
