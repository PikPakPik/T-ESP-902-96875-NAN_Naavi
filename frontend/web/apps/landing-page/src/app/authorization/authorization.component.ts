import {
  Component,
  OnInit,
  OnDestroy,
  inject,
  ChangeDetectorRef,
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, RouterModule } from '@angular/router';
import { firstValueFrom } from 'rxjs';
import { CardModule } from 'primeng/card';
import { ButtonModule } from 'primeng/button';
import { MessageModule } from 'primeng/message';
import { TurnstileService } from '@web/shared/util';
import { AuthService } from '@web/auth/data-access';

interface AppMessage {
  severity: 'success' | 'info' | 'warn' | 'error';
  summary: string;
  detail: string;
}

@Component({
  selector: 'app-authorization',
  standalone: true,
  imports: [
    CommonModule,
    RouterModule,
    CardModule,
    ButtonModule,
    MessageModule,
  ],
  templateUrl: './authorization.component.html',
  styleUrl: './authorization.component.scss',
})
export class AuthorizationComponent implements OnInit, OnDestroy {
  private route = inject(ActivatedRoute);
  private turnstileService = inject(TurnstileService);
  private authService = inject(AuthService);
  private cdr = inject(ChangeDetectorRef);

  authorizationToken: string | null = null;
  turnstileToken: string | null = null;
  isSubmitting = false;
  isSuccess = false;
  successMessage = '';
  messages: AppMessage[] = [];

  ngOnInit(): void {
    this.authorizationToken = this.route.snapshot.queryParamMap.get('token');

    if (!this.authorizationToken) {
      this.messages = [
        {
          severity: 'error',
          summary: 'Erreur',
          detail:
            "Token d'autorisation manquant. Veuillez utiliser le lien envoyé par email.",
        },
      ];
      return;
    }

    this.loadTurnstileScript();
  }

  ngOnDestroy(): void {
    this.turnstileService.remove('turnstile-container');
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
    script.onload = () => this.initializeTurnstile();
    document.head.appendChild(script);
  }

  private initializeTurnstile(): void {
    setTimeout(() => {
      this.turnstileService.render(
        'turnstile-container',
        (token: string) => {
          this.turnstileToken = token;
          if (
            this.authorizationToken &&
            !this.isSubmitting &&
            !this.isSuccess
          ) {
            this.onAuthorize();
          }
        },
        () => {
          this.turnstileToken = null;
          this.messages = [
            {
              severity: 'error',
              summary: 'Erreur',
              detail: 'Erreur de vérification de sécurité. Veuillez réessayer.',
            },
          ];
        },
        () => {
          this.turnstileToken = null;
        },
        'light'
      );
    }, 500);
  }

  async onAuthorize(): Promise<void> {
    if (!this.turnstileToken) {
      this.messages = [
        {
          severity: 'warn',
          summary: 'Attention',
          detail: 'Veuillez compléter la vérification de sécurité.',
        },
      ];
      return;
    }

    if (!this.authorizationToken) {
      this.messages = [
        {
          severity: 'error',
          summary: 'Erreur',
          detail: "Token d'autorisation invalide.",
        },
      ];
      return;
    }

    this.isSubmitting = true;
    this.messages = [];

    try {
      const result = await firstValueFrom(
        this.authService.processAuthorization(
          this.authorizationToken,
          this.turnstileToken
        )
      );

      if (result) {
        const message =
          result.message ||
          "Votre demande d'autorisation a été traitée avec succès.";
        // Defer UI update to avoid ExpressionChangedAfterItHasBeenCheckedError
        setTimeout(() => {
          this.isSuccess = true;
          this.successMessage = message;
          this.messages = [
            {
              severity: 'success',
              summary: 'Succès',
              detail: message,
            },
          ];
          this.cdr.detectChanges();
        }, 0);
      }
    } catch (err: unknown) {
      const error = err as { status?: number; error?: { message?: string } };
      console.error('Authorization error:', error);

      let errorMessage =
        "Une erreur est survenue lors du traitement de la demande d'autorisation.";

      if (error?.error?.message) {
        errorMessage = error.error.message;
      } else if (error?.status === 404) {
        errorMessage =
          "Le token d'autorisation est invalide ou a expiré.";
      } else if (error?.status === 422) {
        errorMessage = 'Les données fournies ne sont pas valides.';
      }

      const messageToShow = errorMessage;
      // Defer update and do NOT reset Turnstile: reset would re-trigger callbacks and cause an infinite loop
      setTimeout(() => {
        this.messages = [
          { severity: 'error', summary: 'Erreur', detail: messageToShow },
        ];
        this.isSubmitting = false;
        this.cdr.detectChanges();
      }, 0);
      return;
    } finally {
      this.isSubmitting = false;
    }
  }
}
