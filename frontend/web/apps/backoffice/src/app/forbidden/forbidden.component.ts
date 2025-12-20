import { Component } from '@angular/core';
import { Router } from '@angular/router';

import { ButtonModule } from 'primeng/button';
import { CardModule } from 'primeng/card';
import { inject } from '@angular/core';
import { AuthStore } from '@web/auth/data-access';

@Component({
  selector: 'app-forbidden',
  standalone: true,
  imports: [ButtonModule, CardModule],
  template: `
    <div class="forbidden-container">
      <p-card class="forbidden-card">
        <ng-template pTemplate="header">
          <div class="header-content">
            <i class="pi pi-ban forbidden-icon"></i>
            <h2>Accès Interdit</h2>
          </div>
        </ng-template>

        <div class="content">
          <p class="description">
            Vous êtes connecté mais vous n'avez pas les permissions nécessaires
            pour accéder à cette page.
          </p>
          <p class="sub-description">
            Cette section est réservée aux administrateurs uniquement.
          </p>
        </div>

        <ng-template pTemplate="footer">
          <div class="actions">
            <p-button
              label="Retour à l'accueil"
              icon="pi pi-home"
              (onClick)="goToHome()"
              class="p-button-outlined"
            >
            </p-button>
            <p-button
              label="Se déconnecter"
              icon="pi pi-sign-out"
              (onClick)="logout()"
              severity="secondary"
            >
            </p-button>
          </div>
        </ng-template>
      </p-card>
    </div>
  `,
  styles: [
    `
      .forbidden-container {
        display: flex;
        justify-content: center;
        align-items: center;
        min-height: 100vh;
        background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
        padding: 2rem;
      }

      .forbidden-card {
        max-width: 500px;
        width: 100%;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
      }

      .header-content {
        text-align: center;
        padding: 2rem 0;
      }

      .forbidden-icon {
        font-size: 4rem;
        color: #ff6b6b;
        margin-bottom: 1rem;
      }

      .header-content h2 {
        margin: 0;
        color: #333;
        font-size: 1.8rem;
        font-weight: 600;
      }

      .content {
        text-align: center;
        padding: 1rem 0;
      }

      .description {
        font-size: 1.1rem;
        color: #666;
        margin-bottom: 0.5rem;
        font-weight: 500;
      }

      .sub-description {
        color: #999;
        font-size: 0.95rem;
        margin: 0;
      }

      .actions {
        display: flex;
        gap: 1rem;
        justify-content: center;
        flex-wrap: wrap;
        padding-top: 1rem;
      }

      @media (max-width: 480px) {
        .actions {
          flex-direction: column;
        }

        .actions ::ng-deep .p-button {
          width: 100%;
          justify-content: center;
        }
      }
    `,
  ],
})
export class ForbiddenComponent {
  #router = inject(Router);
  #authStore = inject(AuthStore);
  goToHome(): void {
    this.#router.navigate(['/']);
  }

  async logout(): Promise<void> {
    try {
      await this.#authStore.logout();
      this.#router.navigate(['/login']);
    } catch (error) {
      console.error('❌ ForbiddenComponent - Erreur lors du logout:', error);
      this.#router.navigate(['/login']);
    }
  }
}
