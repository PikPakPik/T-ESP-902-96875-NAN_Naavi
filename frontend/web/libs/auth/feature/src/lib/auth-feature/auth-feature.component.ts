import { Component, inject } from '@angular/core';
import {
  FormBuilder,
  ReactiveFormsModule,
  type FormGroup,
  Validators,
} from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { InputTextModule } from 'primeng/inputtext';
import { CheckboxModule } from 'primeng/checkbox';
import { PasswordModule } from 'primeng/password';

@Component({
  selector: 'web-auth-feature',
  templateUrl: './auth-feature.component.html',
  styleUrls: ['./auth-feature.component.scss'],
  standalone: true,
  imports: [
    ButtonModule,
    InputTextModule,
    CheckboxModule,
    PasswordModule,
    ReactiveFormsModule,
  ],
})
export class AuthFeatureComponent {
  readonly #fb = inject(FormBuilder);
  loginForm: FormGroup;
  loading = false;

  constructor() {
    this.loginForm = this.#fb.group({
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required]],
      rememberMe: [false],
    });
  }

  onSubmit() {
    if (this.loginForm.valid) {
      this.loading = true;

      // Simulation d'une connexion
      setTimeout(() => {
        this.loading = false;
        console.log('Connexion réussie', this.loginForm.value);
        // Redirection après connexion
        // this.router.navigate(['/dashboard']);
      }, 2000);
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
}
