import {
  Component,
  effect,
  inject,
  OnInit,
  OnDestroy,
  AfterViewInit,
} from '@angular/core';
import {
  FormBuilder,
  ReactiveFormsModule,
  type FormGroup,
  Validators,
  FormsModule,
} from '@angular/forms';
import { Button } from 'primeng/button';
import { InputText } from 'primeng/inputtext';
import { Checkbox } from 'primeng/checkbox';
import { Password } from 'primeng/password';
import { AutoFocus } from 'primeng/autofocus';
import { Dialog } from 'primeng/dialog';
import { AuthStore } from '@web/auth/data-access';
import { ForgotPasswordComponent } from './forgot-password/forgot-password.component';
import { Router } from '@angular/router';
import { TranslateModule } from '@ngx-translate/core';
import {
  TurnstileService,
  getCookie,
  ACCESS_TOKEN_COOKIE,
} from '@web/shared/util';

@Component({
  selector: 'web-auth-feature',
  templateUrl: './auth-feature.component.html',
  styleUrls: ['./auth-feature.component.scss'],
  standalone: true,
  imports: [
    Button,
    InputText,
    Checkbox,
    Password,
    AutoFocus,
    Dialog,
    ForgotPasswordComponent,
    ReactiveFormsModule,
    FormsModule,
    TranslateModule,
  ],
})
export class AuthFeatureComponent implements OnInit, OnDestroy, AfterViewInit {
  readonly #fb = inject(FormBuilder);
  readonly #store = inject(AuthStore);
  readonly #router = inject(Router);
  readonly #turnstileService = inject(TurnstileService);
  loginForm: FormGroup;
  loading = this.#store.isPending;
  error = this.#store.error;
  showForgotPasswordModal = false;
  turnstileToken: string | null = null;
  private turnstileElementId = 'turnstile-widget';

  constructor() {
    this.loginForm = this.#fb.group({
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required]],
      rememberMe: [false],
    });

    // Retirer automatiquement l'erreur serveur quand l'utilisateur modifie les champs
    this.loginForm.get('email')?.valueChanges.subscribe(() => {
      this.clearFormErrors();
    });

    this.loginForm.get('password')?.valueChanges.subscribe(() => {
      this.clearFormErrors();
    });

    effect(() => {
      const user = this.#store.user();
      if (user && user.id !== '') {
        // Vérifier qu'on n'est pas déjà sur la page de destination pour éviter les boucles
        const currentUrl = this.#router.url;
        if (
          !currentUrl.includes('/backoffice') &&
          !currentUrl.includes('/dashboard')
        ) {
          this.#router.navigate(['/']);
        }
      }
    });
  }

  async onSubmit() {
    if (this.loginForm.valid) {
      // Vérifier que le token Turnstile est disponible
      if (!this.turnstileToken) {
        // Réinitialiser Turnstile pour obtenir un nouveau token
        this.#turnstileService.reset(this.turnstileElementId);
        return;
      }

      // Réinitialiser les erreurs du formulaire avant une nouvelle tentative
      this.clearFormErrors();

      await this.#store.login(
        this.loginForm.value.email,
        this.loginForm.value.password,
        this.turnstileToken
      );

      // Si une erreur s'est produite, marquer le formulaire en erreur et réinitialiser Turnstile
      if (this.error()) {
        this.markFormGroupTouched();
        this.setFormError();
        // Réinitialiser Turnstile pour obtenir un nouveau token
        this.#turnstileService.reset(this.turnstileElementId);
        this.turnstileToken = null;
      }
    } else {
      this.markFormGroupTouched();
    }
  }

  markFormGroupTouched() {
    Object.keys(this.loginForm.controls).forEach((key) => {
      const control = this.loginForm.get(key);
      control?.markAsTouched();
    });
  }

  setFormError() {
    // Marquer les champs email et password en erreur
    const emailControl = this.loginForm.get('email');
    const passwordControl = this.loginForm.get('password');

    if (emailControl) {
      const currentErrors = emailControl.errors || {};
      emailControl.setErrors({ ...currentErrors, serverError: true });
      emailControl.markAsTouched();
    }

    if (passwordControl) {
      const currentErrors = passwordControl.errors || {};
      passwordControl.setErrors({ ...currentErrors, serverError: true });
      passwordControl.markAsTouched();
    }
  }

  clearFormErrors() {
    // Retirer l'erreur serveur des champs
    const emailControl = this.loginForm.get('email');
    const passwordControl = this.loginForm.get('password');

    if (emailControl && emailControl.errors?.['serverError']) {
      const restErrors = Object.fromEntries(
        Object.entries(emailControl.errors).filter(
          ([key]) => key !== 'serverError'
        )
      );
      emailControl.setErrors(
        Object.keys(restErrors).length > 0 ? restErrors : null
      );
    }

    if (passwordControl && passwordControl.errors?.['serverError']) {
      const restErrors = Object.fromEntries(
        Object.entries(passwordControl.errors).filter(
          ([key]) => key !== 'serverError'
        )
      );
      passwordControl.setErrors(
        Object.keys(restErrors).length > 0 ? restErrors : null
      );
    }
  }

  get email() {
    return this.loginForm.get('email');
  }
  get password() {
    return this.loginForm.get('password');
  }

  openForgotPasswordModal() {
    this.showForgotPasswordModal = true;
  }

  closeForgotPasswordModal() {
    this.showForgotPasswordModal = false;
  }

  ngOnInit(): void {
    // Clear any stale error from previous session (e.g. after logout)
    this.#store.clearError();
    // Si déjà connecté (token en cookie), charger l'utilisateur pour déclencher la redirection
    if (getCookie(ACCESS_TOKEN_COOKIE)) {
      this.#store.currentUser().catch(() => {
        /* token invalide - rester sur login */
      });
    }
    // Wait for Turnstile script to load
    this.waitForTurnstile();
  }

  ngAfterViewInit(): void {
    // Render Turnstile after view is initialized
    this.renderTurnstile();
  }

  ngOnDestroy(): void {
    // Clean up Turnstile widget
    this.#turnstileService.remove(this.turnstileElementId);
  }

  private waitForTurnstile(): void {
    const checkTurnstile = () => {
      if (this.#turnstileService.isReady()) {
        this.renderTurnstile();
      } else {
        setTimeout(checkTurnstile, 100);
      }
    };
    checkTurnstile();
  }

  private renderTurnstile(): void {
    if (!this.#turnstileService.isReady()) {
      return;
    }

    this.#turnstileService.render(
      this.turnstileElementId,
      (token: string) => {
        this.turnstileToken = token;
      },
      (error: string) => {
        console.error('Turnstile error:', error);
        this.turnstileToken = null;
      },
      () => {
        // Token expired
        this.turnstileToken = null;
      },
      'auto',
      'compact'
    );
  }
}
