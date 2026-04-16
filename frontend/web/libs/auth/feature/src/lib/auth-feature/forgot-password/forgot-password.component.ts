import { Component, inject, output, signal } from '@angular/core';

import { form, FormField, required, email } from '@angular/forms/signals';
import { Button } from 'primeng/button';
import { InputText } from 'primeng/inputtext';
import { AutoFocus } from 'primeng/autofocus';
import { AuthStore } from '@web/auth/data-access';

interface ForgotPasswordData {
  email: string;
}

@Component({
  selector: 'forgot-password',
  imports: [FormField, Button, InputText, AutoFocus],
  templateUrl: './forgot-password.component.html',
  styleUrl: './forgot-password.component.scss',
})
export class ForgotPasswordComponent {
  readonly #store = inject(AuthStore);
  closeModal = output<void>();

  forgotPasswordModel = signal<ForgotPasswordData>({
    email: '',
  });

  forgotPasswordForm = form(this.forgotPasswordModel, (schemaPath) => {
    required(schemaPath.email, { message: "L'email est requis" });
    email(schemaPath.email, { message: 'Format d\'email invalide' });
  });

  loading = signal(false);
  submitted = signal(false);

  async onSubmit() {
    this.submitted.set(true);

    const emailField = this.forgotPasswordForm.email();
    if (emailField.valid()) {
      this.loading.set(true);

      try {
        await this.#store.forgotPassword(this.forgotPasswordModel().email);

        this.closeModal.emit();
      } catch (error) {
        console.error("Erreur lors de l'envoi:", error);
      } finally {
        this.loading.set(false);
      }
    }
  }

  onCancel() {
    this.closeModal.emit();
  }
}
