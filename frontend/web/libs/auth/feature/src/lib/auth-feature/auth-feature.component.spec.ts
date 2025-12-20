import { ComponentFixture, TestBed } from '@angular/core/testing';
import { signal } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { NO_ERRORS_SCHEMA } from '@angular/core';
import { AuthFeatureComponent } from './auth-feature.component';
import { AuthStore } from '@web/auth/data-access';
import { Router } from '@angular/router';
import {
  TranslateService,
  TranslateModule,
  TranslateLoader,
} from '@ngx-translate/core';
import { of, Observable, firstValueFrom } from 'rxjs';
import { TURNSTILE_SITE_KEY } from '@web/shared/util';

describe('AuthFeatureComponent', () => {
  let fixture: ComponentFixture<AuthFeatureComponent>;
  let mockAuthStore: any;
  let mockRouter: { navigate: jest.Mock; url: string };
  let translateService: TranslateService;

  // Global mock objects
  const mockLoginResponse = { user: { id: '1', email: 'test@example.com' } };

  // Mock loader that returns key as translation for all keys
  class MockTranslateLoader implements TranslateLoader {
    getTranslation(lang: string): Observable<any> {
      // Return a function that returns the key itself
      return of({
        'AUTH.WELCOME.TITLE': 'Bienvenue',
        'AUTH.WELCOME.SUBTITLE': 'Connectez-vous à votre compte',
        'AUTH.LOGIN.TITLE': 'Connexion',
        'AUTH.LOGIN.SUBTITLE': 'Accédez à votre espace personnel',
        'AUTH.LOGIN.EMAIL_LABEL': 'Adresse email',
        'AUTH.LOGIN.EMAIL_PLACEHOLDER': 'votre@email.com',
        'AUTH.LOGIN.EMAIL_REQUIRED': "L'email est requis",
        'AUTH.LOGIN.EMAIL_INVALID': "Format d'email invalide",
        'AUTH.LOGIN.PASSWORD_LABEL': 'Mot de passe',
        'AUTH.LOGIN.PASSWORD_PLACEHOLDER': 'Votre mot de passe',
        'AUTH.LOGIN.PASSWORD_REQUIRED': 'Le mot de passe est requis',
        'AUTH.LOGIN.REMEMBER_ME': 'Se souvenir de moi',
        'AUTH.LOGIN.FORGOT_PASSWORD': 'Mot de passe oublié ?',
        'AUTH.LOGIN.BUTTON': 'Se connecter',
        'AUTH.LOGIN.ERROR.INVALID_CREDENTIALS': 'Identifiants incorrects',
      });
    }
  }

  beforeEach(async () => {
    mockRouter = {
      navigate: jest.fn(),
      url: '/auth/login',
    };

    mockAuthStore = {
      login: jest.fn().mockResolvedValue(undefined),
      getUser: jest.fn().mockResolvedValue(undefined),
      forgotPassword: jest.fn().mockResolvedValue(undefined),
      logout: jest.fn().mockResolvedValue(undefined),
      user: signal(null),
      pending: signal(false),
      error: signal(null),
      requestStatus: signal({ status: 'fulfilled' }),
      isPending: signal(false),
    };

    await TestBed.configureTestingModule({
      imports: [
        AuthFeatureComponent,
        TranslateModule.forRoot({
          loader: { provide: TranslateLoader, useClass: MockTranslateLoader },
          fallbackLang: 'fr',
        }),
      ],
      providers: [
        { provide: AuthStore, useValue: mockAuthStore },
        { provide: Router, useValue: mockRouter },
        { provide: TURNSTILE_SITE_KEY, useValue: 'test-site-key' },
      ],
      schemas: [NO_ERRORS_SCHEMA],
    }).compileComponents();

    fixture = TestBed.createComponent(AuthFeatureComponent);
    translateService = TestBed.inject(TranslateService);
    translateService.setFallbackLang('fr');
    await firstValueFrom(translateService.use('fr'));
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('component initialization', () => {
    it('Given component initialization When creating component Then should initialize with correct default values', () => {
      // GIVEN
      // None necessary

      // WHEN
      const component = fixture.componentInstance;

      // THEN
      expect(component.loginForm).toBeInstanceOf(FormGroup);
      expect(component.loginForm.get('email')?.value).toBe('');
      expect(component.loginForm.get('password')?.value).toBe('');
      expect(component.loginForm.get('rememberMe')?.value).toBe(false);
      expect(component.loading()).toBe(false);
      expect(component.showForgotPasswordModal).toBe(false);
    });

    it('Given component initialization When creating component Then should setup form with validators', () => {
      // GIVEN
      // None necessary

      // WHEN
      const component = fixture.componentInstance;

      // THEN
      const emailControl = component.loginForm.get('email');
      const passwordControl = component.loginForm.get('password');

      emailControl?.setValue('');
      emailControl?.markAsTouched();
      expect(emailControl?.hasError('required')).toBe(true);

      emailControl?.setValue('invalid-email');
      expect(emailControl?.hasError('email')).toBe(true);

      passwordControl?.setValue('');
      passwordControl?.markAsTouched();
      expect(passwordControl?.hasError('required')).toBe(true);
    });
  });

  describe('form validation', () => {
    it('Given form with empty email When validating email field Then should have required error', () => {
      // GIVEN
      const component = fixture.componentInstance;

      // WHEN
      const emailControl = component.loginForm.get('email');
      emailControl?.setValue('');
      emailControl?.markAsTouched();

      // THEN
      expect(emailControl?.hasError('required')).toBe(true);
      expect(emailControl?.invalid).toBe(true);
    });

    it('Given form with invalid email format When validating email field Then should have email error', () => {
      // GIVEN
      const component = fixture.componentInstance;

      // WHEN
      const emailControl = component.loginForm.get('email');
      emailControl?.setValue('invalid-email-format');
      emailControl?.markAsTouched();

      // THEN
      expect(emailControl?.hasError('email')).toBe(true);
      expect(emailControl?.invalid).toBe(true);
    });

    it('Given form with valid email When validating email field Then should not have errors', () => {
      // GIVEN
      const component = fixture.componentInstance;

      // WHEN
      const emailControl = component.loginForm.get('email');
      emailControl?.setValue('test@example.com');
      emailControl?.markAsTouched();

      // THEN
      expect(emailControl?.valid).toBe(true);
      expect(emailControl?.hasError('required')).toBe(false);
      expect(emailControl?.hasError('email')).toBe(false);
    });

    it('Given form with empty password When validating password field Then should have required error', () => {
      // GIVEN
      const component = fixture.componentInstance;

      // WHEN
      const passwordControl = component.loginForm.get('password');
      passwordControl?.setValue('');
      passwordControl?.markAsTouched();

      // THEN
      expect(passwordControl?.hasError('required')).toBe(true);
      expect(passwordControl?.invalid).toBe(true);
    });

    it('Given form with valid password When validating password field Then should not have errors', () => {
      // GIVEN
      const component = fixture.componentInstance;

      // WHEN
      const passwordControl = component.loginForm.get('password');
      passwordControl?.setValue('validPassword123');
      passwordControl?.markAsTouched();

      // THEN
      expect(passwordControl?.valid).toBe(true);
      expect(passwordControl?.hasError('required')).toBe(false);
    });
  });

  describe('login submission', () => {
    it('Given valid form data When submitting login form Then should call store login with correct credentials', async () => {
      // GIVEN
      const testEmail = 'test@example.com';
      const testPassword = 'password123';

      mockAuthStore.login.mockResolvedValue(mockLoginResponse);

      const component = fixture.componentInstance;

      component.loginForm.patchValue({
        email: testEmail,
        password: testPassword,
        rememberMe: true,
      });

      // Set turnstile token to allow login
      component.turnstileToken = 'test-token';

      // WHEN
      await component.onSubmit();

      // THEN
      expect(mockAuthStore.login).toHaveBeenCalledTimes(1);
      expect(mockAuthStore.login).toHaveBeenCalledWith(
        testEmail,
        testPassword,
        'test-token'
      );
      expect(component.loading()).toBe(false);
    });

    it('Given invalid form When submitting login form Then should mark all fields as touched and not call store login', async () => {
      // GIVEN
      mockAuthStore.login.mockResolvedValue(mockLoginResponse);

      const component = fixture.componentInstance;

      // Leave form invalid (empty values)
      component.loginForm.patchValue({
        email: '',
        password: '',
      });

      // WHEN
      await component.onSubmit();

      // THEN
      expect(mockAuthStore.login).not.toHaveBeenCalled();
      expect(component.loginForm.get('email')?.touched).toBe(true);
      expect(component.loginForm.get('password')?.touched).toBe(true);
      expect(component.loginForm.get('rememberMe')?.touched).toBe(true);
    });

    it('Given valid form When submitting login form Then should set loading to true during submission', async () => {
      // GIVEN
      const testEmail = 'test@example.com';
      const testPassword = 'password123';

      // Mock login to simulate async behavior with loading state
      let resolveLogin: (() => void) | undefined;
      const loginPromise = new Promise<void>((resolve) => {
        resolveLogin = resolve;
      });

      mockAuthStore.login.mockImplementation(async () => {
        // Simulate store setting isPending to true when login starts
        mockAuthStore.isPending.set(true);
        await loginPromise;
        // Simulate store setting isPending to false when login completes
        mockAuthStore.isPending.set(false);
      });

      const component = fixture.componentInstance;

      component.loginForm.patchValue({
        email: testEmail,
        password: testPassword,
      });

      // Set turnstile token to allow login
      component.turnstileToken = 'test-token';

      // WHEN - Start the submission
      const onSubmitPromise = component.onSubmit();

      // THEN - Check that loading is true during submission
      expect(component.loading()).toBe(true);

      // Resolve the login and wait for completion
      if (resolveLogin) {
        resolveLogin();
      }
      await onSubmitPromise;
      fixture.detectChanges();

      // Verify loading is false after completion
      expect(component.loading()).toBe(false);
    });
  });

  describe('forgot password modal', () => {
    it('Given component initialized When opening forgot password modal Then should set showForgotPasswordModal to true', () => {
      // GIVEN
      const component = fixture.componentInstance;

      // WHEN
      component.openForgotPasswordModal();

      // THEN
      expect(component.showForgotPasswordModal).toBe(true);
    });

    it('Given forgot password modal open When closing forgot password modal Then should set showForgotPasswordModal to false', () => {
      // GIVEN
      const component = fixture.componentInstance;
      component.showForgotPasswordModal = true;

      // WHEN
      component.closeForgotPasswordModal();

      // THEN
      expect(component.showForgotPasswordModal).toBe(false);
    });
  });

  describe('form getters', () => {
    it('Given component initialized When accessing email getter Then should return email form control', () => {
      // GIVEN
      const component = fixture.componentInstance;

      // WHEN
      const emailControl = component.email;

      // THEN
      expect(emailControl).toBe(component.loginForm.get('email'));
    });

    it('Given component initialized When accessing password getter Then should return password form control', () => {
      // GIVEN
      const component = fixture.componentInstance;

      // WHEN
      const passwordControl = component.password;

      // THEN
      expect(passwordControl).toBe(component.loginForm.get('password'));
    });
  });

  describe('markFormGroupTouched', () => {
    it('Given form with untouched controls When marking form group as touched Then should mark all controls as touched', () => {
      // GIVEN
      const component = fixture.componentInstance;

      // Verify initial state
      expect(component.loginForm.get('email')?.touched).toBe(false);
      expect(component.loginForm.get('password')?.touched).toBe(false);
      expect(component.loginForm.get('rememberMe')?.touched).toBe(false);

      // WHEN
      (
        component as unknown as { markFormGroupTouched(): void }
      ).markFormGroupTouched();

      // THEN
      expect(component.loginForm.get('email')?.touched).toBe(true);
      expect(component.loginForm.get('password')?.touched).toBe(true);
      expect(component.loginForm.get('rememberMe')?.touched).toBe(true);
    });
  });

  describe('visual state', () => {
    it('Given default component state When rendering component Then should display login form with email input, password input, remember me checkbox, login button and forgot password link', () => {
      // GIVEN
      // None necessary

      // WHEN
      // THEN
      expect(fixture).toMatchSnapshot();
    });

    it('Given form with validation errors When rendering component Then should display error messages for invalid fields', () => {
      // GIVEN
      const component = fixture.componentInstance;

      // WHEN
      // Make form invalid and touched to show errors
      component.loginForm.get('email')?.setValue('');
      component.loginForm.get('email')?.markAsTouched();
      component.loginForm.get('password')?.setValue('');
      component.loginForm.get('password')?.markAsTouched();
      fixture.detectChanges();

      // THEN
      expect(fixture).toMatchSnapshot();
    });

    it('Given loading state When rendering component Then should display loading button and disabled form', () => {
      // GIVEN
      const component = fixture.componentInstance;

      // WHEN
      mockAuthStore.isPending.set(true);
      fixture.detectChanges();

      // THEN
      expect(fixture).toMatchSnapshot();
    });

    it('Given forgot password modal open When rendering component Then should display modal with forgot password component', () => {
      // GIVEN
      const component = fixture.componentInstance;

      // WHEN
      component.showForgotPasswordModal = true;
      fixture.detectChanges();

      // THEN
      expect(fixture).toMatchSnapshot();
    });

    it('Given valid form data When rendering component Then should display enabled submit button with valid form inputs', () => {
      // GIVEN
      const component = fixture.componentInstance;

      // WHEN
      component.loginForm.patchValue({
        email: 'test@example.com',
        password: 'validPassword123',
        rememberMe: true,
      });
      fixture.detectChanges();

      // THEN
      expect(fixture).toMatchSnapshot();
    });
  });

  describe('setFormError', () => {
    it('Given form controls without existing errors When setting form error Then should add serverError to both email and password controls', () => {
      // GIVEN
      const component = fixture.componentInstance;
      component.loginForm.patchValue({
        email: 'test@example.com',
        password: 'password123',
      });

      // WHEN
      (component as unknown as { setFormError(): void }).setFormError();

      // THEN
      const emailControl = component.loginForm.get('email');
      const passwordControl = component.loginForm.get('password');

      expect(emailControl?.errors?.['serverError']).toBe(true);
      expect(passwordControl?.errors?.['serverError']).toBe(true);
      expect(emailControl?.touched).toBe(true);
      expect(passwordControl?.touched).toBe(true);
    });

    it('Given form controls with existing validation errors When setting form error Then should add serverError while keeping existing errors', () => {
      // GIVEN
      const component = fixture.componentInstance;
      component.loginForm.patchValue({
        email: 'invalid-email',
        password: '',
      });

      // Manually set errors to simulate existing validation errors
      const emailControl = component.loginForm.get('email');
      const passwordControl = component.loginForm.get('password');
      emailControl?.setErrors({ email: true });
      passwordControl?.setErrors({ required: true });

      // WHEN
      (component as unknown as { setFormError(): void }).setFormError();

      // THEN
      expect(emailControl?.errors?.['serverError']).toBe(true);
      expect(emailControl?.errors?.['email']).toBe(true);
      expect(passwordControl?.errors?.['serverError']).toBe(true);
      expect(passwordControl?.errors?.['required']).toBe(true);
    });
  });

  describe('clearFormErrors', () => {
    it('Given email with only serverError When clearing form errors Then should remove all errors from email', () => {
      // GIVEN
      const component = fixture.componentInstance;
      const emailControl = component.loginForm.get('email');
      emailControl?.setErrors({ serverError: true });

      // WHEN
      (component as unknown as { clearFormErrors(): void }).clearFormErrors();

      // THEN
      expect(emailControl?.errors).toBeNull();
    });

    it('Given password with only serverError When clearing form errors Then should remove all errors from password', () => {
      // GIVEN
      const component = fixture.componentInstance;
      const passwordControl = component.loginForm.get('password');
      passwordControl?.setErrors({ serverError: true });

      // WHEN
      (component as unknown as { clearFormErrors(): void }).clearFormErrors();

      // THEN
      expect(passwordControl?.errors).toBeNull();
    });

    it('Given email with serverError and other validation errors When clearing form errors Then should keep other validation errors', () => {
      // GIVEN
      const component = fixture.componentInstance;
      const emailControl = component.loginForm.get('email');
      emailControl?.setErrors({ serverError: true, email: true });

      // WHEN
      (component as unknown as { clearFormErrors(): void }).clearFormErrors();

      // THEN
      expect(emailControl?.errors?.['serverError']).toBeUndefined();
      expect(emailControl?.errors?.['email']).toBe(true);
    });

    it('Given password with serverError and other validation errors When clearing form errors Then should keep other validation errors', () => {
      // GIVEN
      const component = fixture.componentInstance;
      const passwordControl = component.loginForm.get('password');
      passwordControl?.setErrors({ serverError: true, required: true });

      // WHEN
      (component as unknown as { clearFormErrors(): void }).clearFormErrors();

      // THEN
      expect(passwordControl?.errors?.['serverError']).toBeUndefined();
      expect(passwordControl?.errors?.['required']).toBe(true);
    });

    it('Given controls without serverError When clearing form errors Then should not modify controls', () => {
      // GIVEN
      const component = fixture.componentInstance;
      const emailControl = component.loginForm.get('email');
      const passwordControl = component.loginForm.get('password');
      emailControl?.setErrors({ email: true });
      passwordControl?.setErrors({ required: true });

      // WHEN
      (component as unknown as { clearFormErrors(): void }).clearFormErrors();

      // THEN
      expect(emailControl?.errors?.['email']).toBe(true);
      expect(passwordControl?.errors?.['required']).toBe(true);
    });
  });

  describe('form error clearing on value changes', () => {
    it('Given email field with serverError When email value changes Then should clear form errors', (done) => {
      // GIVEN
      const component = fixture.componentInstance;
      const emailControl = component.loginForm.get('email');
      emailControl?.setErrors({ serverError: true, email: true });

      // WHEN
      emailControl?.setValue('new@example.com');

      // THEN
      setTimeout(() => {
        expect(emailControl?.errors?.['serverError']).toBeUndefined();
        expect(emailControl?.errors?.['email']).toBeUndefined();
        done();
      }, 10);
    });

    it('Given password field with serverError When password value changes Then should clear form errors', (done) => {
      // GIVEN
      const component = fixture.componentInstance;
      const passwordControl = component.loginForm.get('password');
      passwordControl?.setErrors({ serverError: true });

      // WHEN
      passwordControl?.setValue('newPassword');

      // THEN
      setTimeout(() => {
        expect(passwordControl?.errors?.['serverError']).toBeUndefined();
        done();
      }, 10);
    });
  });

  describe('login with error handling', () => {
    it('Given valid form When login fails with error Then should set form errors', async () => {
      // GIVEN
      const testEmail = 'test@example.com';
      const testPassword = 'wrongPassword';

      mockAuthStore.login.mockResolvedValue(undefined);
      mockAuthStore.error.set('Invalid credentials');

      const component = fixture.componentInstance;
      component.loginForm.patchValue({
        email: testEmail,
        password: testPassword,
      });

      // Set turnstile token to allow login
      component.turnstileToken = 'test-token';

      // WHEN
      await component.onSubmit();

      // THEN
      const emailControl = component.loginForm.get('email');
      const passwordControl = component.loginForm.get('password');

      expect(emailControl?.errors?.['serverError']).toBe(true);
      expect(passwordControl?.errors?.['serverError']).toBe(true);
      expect(emailControl?.touched).toBe(true);
      expect(passwordControl?.touched).toBe(true);
    });
  });

  describe('user navigation effect', () => {
    it('Given user is logged in and on auth page When component initializes Then should navigate to home', async () => {
      // GIVEN
      mockRouter.url = '/auth/login';
      const mockUser = { id: '1', email: 'test@example.com' };
      const userSignal = signal(mockUser);
      mockAuthStore.user = userSignal;

      // WHEN
      fixture = TestBed.createComponent(AuthFeatureComponent);
      await fixture.whenStable();

      // THEN
      // Effect should execute after component creation
      expect(mockRouter.navigate).toHaveBeenCalledWith(['/']);
    });

    it('Given user is logged in and on backoffice page When component initializes Then should not navigate', async () => {
      // GIVEN
      mockRouter.url = '/backoffice/users';
      const mockUser = { id: '1', email: 'test@example.com' };
      const userSignal = signal(mockUser);
      mockAuthStore.user = userSignal;

      // WHEN
      fixture = TestBed.createComponent(AuthFeatureComponent);
      await fixture.whenStable();

      // THEN
      expect(mockRouter.navigate).not.toHaveBeenCalled();
    });

    it('Given user is logged in and on dashboard page When component initializes Then should not navigate', async () => {
      // GIVEN
      mockRouter.url = '/dashboard/stats';
      const mockUser = { id: '1', email: 'test@example.com' };
      const userSignal = signal(mockUser);
      mockAuthStore.user = userSignal;

      // WHEN
      fixture = TestBed.createComponent(AuthFeatureComponent);
      await fixture.whenStable();

      // THEN
      expect(mockRouter.navigate).not.toHaveBeenCalled();
    });

    it('Given user is not logged in When component initializes Then should not navigate', async () => {
      // GIVEN
      mockRouter.url = '/auth/login';
      mockAuthStore.user = signal(null);

      // WHEN
      fixture = TestBed.createComponent(AuthFeatureComponent);
      await fixture.whenStable();

      // THEN
      expect(mockRouter.navigate).not.toHaveBeenCalled();
    });

    it('Given user is logged in with empty id When component initializes Then should not navigate', async () => {
      // GIVEN
      mockRouter.url = '/auth/login';
      const mockUser = { id: '', email: 'test@example.com' };
      const userSignal = signal(mockUser);
      mockAuthStore.user = userSignal;

      // WHEN
      fixture = TestBed.createComponent(AuthFeatureComponent);
      await fixture.whenStable();

      // THEN
      expect(mockRouter.navigate).not.toHaveBeenCalled();
    });
  });
});
