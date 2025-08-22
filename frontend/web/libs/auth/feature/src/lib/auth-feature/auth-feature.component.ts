import { Component, inject } from '@angular/core';
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
  ],
})
export class AuthFeatureComponent {
  readonly #fb = inject(FormBuilder);
  readonly #store = inject(AuthStore);
  loginForm: FormGroup;
  loading = false;
  showForgotPasswordModal = false;

  constructor() {
    this.loginForm = this.#fb.group({
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required]],
      rememberMe: [false],
    });
  }

  async onSubmit() {
    if (this.loginForm.valid) {
      this.loading = true;

      await this.#store.login(
        this.loginForm.value.email,
        this.loginForm.value.password
      );
      this.loading = false;
    } else {
      this.markFormGroupTouched();
    }
  }

  private markFormGroupTouched() {
    Object.keys(this.loginForm.controls).forEach((key) => {
      const control = this.loginForm.get(key);
      control?.markAsTouched();
    });
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
}
