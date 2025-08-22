import { Component, inject, output } from '@angular/core';
import { CommonModule } from '@angular/common';
import {
  FormBuilder,
  ReactiveFormsModule,
  Validators,
  FormGroup,
} from '@angular/forms';
import { Button } from 'primeng/button';
import { InputText } from 'primeng/inputtext';
import { AutoFocus } from 'primeng/autofocus';
import { AuthStore } from '@web/auth/data-access';

@Component({
  selector: 'forgot-password',
  imports: [CommonModule, ReactiveFormsModule, Button, InputText, AutoFocus],
  templateUrl: './forgot-password.component.html',
  styleUrl: './forgot-password.component.scss',
})
export class ForgotPasswordComponent {
  readonly #fb = inject(FormBuilder);
  readonly #store = inject(AuthStore);
  closeModal = output<void>();

  forgotPasswordForm: FormGroup;
  loading = false;
  submitted = false;

  constructor() {
    this.forgotPasswordForm = this.#fb.group({
      email: ['', [Validators.required, Validators.email]],
    });
  }

  async onSubmit() {
    this.submitted = true;

    if (this.forgotPasswordForm.valid) {
      this.loading = true;

      try {
        await this.#store.forgotPassword(this.forgotPasswordForm.value.email);

        this.closeModal.emit();
      } catch (error) {
        console.error("Erreur lors de l'envoi:", error);
      } finally {
        this.loading = false;
      }
    }
  }

  onCancel() {
    this.closeModal.emit();
  }

  get email() {
    return this.forgotPasswordForm.get('email');
  }
}
