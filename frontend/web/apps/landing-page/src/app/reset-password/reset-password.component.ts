import { Component, OnInit, OnDestroy, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { CardModule } from 'primeng/card';
import { InputTextModule } from 'primeng/inputtext';
import { PasswordModule } from 'primeng/password';
import { ButtonModule } from 'primeng/button';
import { MessageModule } from 'primeng/message';
import { TurnstileService, strongPasswordValidator, getPasswordValidationMessage, validatePasswordStrength, PasswordValidationResult } from '@web/shared/util';
import { API_URL } from '../app.config';

interface AppMessage {
  severity: 'success' | 'info' | 'warn' | 'error';
  summary: string;
  detail: string;
}

@Component({
  selector: 'app-reset-password',
  standalone: true,
  imports: [
    CommonModule,
    RouterModule,
    ReactiveFormsModule,
    CardModule,
    InputTextModule,
    PasswordModule,
    ButtonModule,
    MessageModule,
  ],
  templateUrl: './reset-password.component.html',
  styleUrl: './reset-password.component.scss',
})
export class ResetPasswordComponent implements OnInit, OnDestroy {
  private fb = inject(FormBuilder);
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private turnstileService = inject(TurnstileService);
  private apiUrl = inject(API_URL);

  resetPasswordForm!: FormGroup;
  resetPasswordToken: string | null = null;
  turnstileToken: string | null = null;
  isSubmitting = false;
  isSuccess = false;
  messages: AppMessage[] = [];

  ngOnInit(): void {
    // Get reset token from URL
    this.resetPasswordToken = this.route.snapshot.queryParamMap.get('token');

    if (!this.resetPasswordToken) {
      this.messages = [{
        severity: 'error',
        summary: 'Erreur',
        detail: 'Token de réinitialisation manquant. Veuillez utiliser le lien envoyé par email.'
      }];
    }

    // Initialize form
    this.resetPasswordForm = this.fb.group({
      password: ['', [Validators.required, strongPasswordValidator()]],
      confirmPassword: ['', [Validators.required]]
    }, {
      validators: this.passwordMatchValidator
    });

    // Load Turnstile script
    this.loadTurnstileScript();
  }

  ngOnDestroy(): void {
    // Clean up Turnstile widget
    this.turnstileService.remove('turnstile-container');
  }

  private passwordMatchValidator(group: FormGroup): { [key: string]: boolean } | null {
    const password = group.get('password')?.value;
    const confirmPassword = group.get('confirmPassword')?.value;

    if (password !== confirmPassword) {
      return { passwordMismatch: true };
    }
    return null;
  }

  private loadTurnstileScript(): void {
    if (document.getElementById('turnstile-script')) {
      this.initializeTurnstile();
      return;
    }

    const script = document.createElement('script');
    script.id = 'turnstile-script';
    script.src = 'https://challenges.cloudflare.com/turnstile/v0/api.js';
    script.async = true;
    script.defer = true;
    script.onload = () => {
      this.initializeTurnstile();
    };
    document.head.appendChild(script);
  }

  private initializeTurnstile(): void {
    setTimeout(() => {
      this.turnstileService.render(
        'turnstile-container',
        (token: string) => {
          this.turnstileToken = token;
        },
        () => {
          this.turnstileToken = null;
          this.messages = [{
            severity: 'error',
            summary: 'Erreur',
            detail: 'Erreur de vérification de sécurité. Veuillez réessayer.'
          }];
        },
        () => {
          this.turnstileToken = null;
        },
        'light'
      );
    }, 500);
  }

  async onSubmit(): Promise<void> {
    if (this.resetPasswordForm.invalid) {
      this.resetPasswordForm.markAllAsTouched();
      return;
    }

    if (!this.turnstileToken) {
      this.messages = [{
        severity: 'warn',
        summary: 'Attention',
        detail: 'Veuillez compléter la vérification de sécurité.'
      }];
      return;
    }

    if (!this.resetPasswordToken) {
      this.messages = [{
        severity: 'error',
        summary: 'Erreur',
        detail: 'Token de réinitialisation invalide.'
      }];
      return;
    }

    this.isSubmitting = true;
    this.messages = [];

    try {
      const response = await fetch(`${this.apiUrl}identity/reset-password`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          resetPasswordToken: this.resetPasswordToken,
          password: this.resetPasswordForm.value.password,
          confirmPassword: this.resetPasswordForm.value.confirmPassword,
          token: this.turnstileToken
        })
      });

      const data = await response.json();

      if (response.ok) {
        this.isSuccess = true;
      } else {
        // Handle different error codes
        let errorMessage = data.message || 'Une erreur est survenue.';
        
        if (response.status === 404) {
          errorMessage = 'Le lien de réinitialisation est invalide ou a expiré.';
        } else if (response.status === 422) {
          errorMessage = 'Les données fournies ne sont pas valides.';
        }

        this.messages = [{
          severity: 'error',
          summary: 'Erreur',
          detail: errorMessage
        }];

        // Reset Turnstile
        this.turnstileService.reset('turnstile-container');
        this.turnstileToken = null;
      }
    } catch (error) {
      console.error('Reset password error:', error);
      this.messages = [{
        severity: 'error',
        summary: 'Erreur',
        detail: 'Erreur de connexion au serveur. Veuillez réessayer.'
      }];

      // Reset Turnstile
      this.turnstileService.reset('turnstile-container');
      this.turnstileToken = null;
    } finally {
      this.isSubmitting = false;
    }
  }

  get password() {
    return this.resetPasswordForm.get('password');
  }

  get confirmPassword() {
    return this.resetPasswordForm.get('confirmPassword');
  }

  get passwordMismatch() {
    return this.resetPasswordForm.hasError('passwordMismatch') && 
           this.resetPasswordForm.get('confirmPassword')?.touched;
  }

  get passwordValidationMessage(): string {
    const errors = this.password?.errors;
    if (errors?.['strongPassword']) {
      return getPasswordValidationMessage(errors['strongPassword'] as PasswordValidationResult);
    }
    return '';
  }

  get passwordRequirements(): PasswordValidationResult {
    const value = this.password?.value || '';
    return validatePasswordStrength(value);
  }
}
