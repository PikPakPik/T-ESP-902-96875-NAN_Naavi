import { ComponentFixture, TestBed } from '@angular/core/testing';
import { signal } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { NO_ERRORS_SCHEMA } from '@angular/core';
import { provideNoopAnimations } from '@angular/platform-browser/animations';
import { AuthFeatureComponent } from './auth-feature.component';
import { AuthStore } from '@web/auth/data-access';

describe('AuthFeatureComponent', () => {
  let fixture: ComponentFixture<AuthFeatureComponent>;
  let mockAuthStore: any;

  // Global mock objects
  const mockLoginResponse = { user: { id: '1', email: 'test@example.com' } };

  beforeEach(async () => {
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
      imports: [AuthFeatureComponent],
      providers: [
        { provide: AuthStore, useValue: mockAuthStore },
        provideNoopAnimations(),
      ],
      schemas: [NO_ERRORS_SCHEMA],
    }).compileComponents();

    fixture = TestBed.createComponent(AuthFeatureComponent);
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
      expect(component.loading).toBe(false);
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

      // WHEN
      await component.onSubmit();

      // THEN
      expect(mockAuthStore.login).toHaveBeenCalledTimes(1);
      expect(mockAuthStore.login).toHaveBeenCalledWith(testEmail, testPassword);
      expect(component.loading).toBe(false);
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

      // Mock login to return a pending promise to test loading state
      let resolveLogin: (() => void) | undefined;
      const loginPromise = new Promise<void>((resolve) => {
        resolveLogin = resolve;
      });

      mockAuthStore.login.mockReturnValue(loginPromise);

      const component = fixture.componentInstance;

      component.loginForm.patchValue({
        email: testEmail,
        password: testPassword,
      });

      // WHEN
      const submitPromise = component.onSubmit();

      // THEN
      expect(component.loading).toBe(true);

      // Resolve the login and wait for completion
      if (resolveLogin) {
        resolveLogin();
      }
      await submitPromise;

      expect(component.loading).toBe(false);
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
      component.loading = true;
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
});
