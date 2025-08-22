import { ComponentFixture, TestBed } from '@angular/core/testing';
import { signal } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { NO_ERRORS_SCHEMA } from '@angular/core';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { provideHttpClient } from '@angular/common/http';
import { provideNoopAnimations } from '@angular/platform-browser/animations';
import { ForgotPasswordComponent } from './forgot-password.component';
import { AuthStore } from '@web/auth/data-access';
import { NotificationService } from '@web/ui/notification';
import { LocalStorageService } from '@web/shared/util';
import { API_URL } from '@web/shared/http-client';

describe('ForgotPasswordComponent', () => {
  let component: ForgotPasswordComponent;
  let fixture: ComponentFixture<ForgotPasswordComponent>;
  let mockAuthStore: any;

  beforeEach(async () => {
    mockAuthStore = {
      forgotPassword: jest.fn().mockResolvedValue(undefined),
      login: jest.fn().mockResolvedValue(undefined),
      getUser: jest.fn().mockResolvedValue(undefined),
      logout: jest.fn().mockResolvedValue(undefined),
      user: signal(null),
      pending: signal(false),
      error: signal(null),
      requestStatus: signal({ status: 'fulfilled' }),
    };

    await TestBed.configureTestingModule({
      imports: [ForgotPasswordComponent],
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        provideNoopAnimations(),
        { provide: AuthStore, useValue: mockAuthStore },
        {
          provide: NotificationService,
          useValue: { success: jest.fn(), error: jest.fn() },
        },
        {
          provide: LocalStorageService,
          useValue: {
            getItem: jest.fn(),
            setItem: jest.fn(),
            removeItem: jest.fn(),
          },
        },
        { provide: API_URL, useValue: 'http://test-api.com' },
      ],
      schemas: [NO_ERRORS_SCHEMA],
    }).compileComponents();

    fixture = TestBed.createComponent(ForgotPasswordComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('component initialization', () => {
    it('should create', () => {
      expect(component).toBeTruthy();
    });

    it('should initialize form with email field', () => {
      expect(component.forgotPasswordForm).toBeInstanceOf(FormGroup);
      expect(component.forgotPasswordForm.get('email')).toBeTruthy();
      expect(component.email?.value).toBe('');
    });

    it('should set default values', () => {
      expect(component.loading).toBe(false);
      expect(component.submitted).toBe(false);
    });
  });

  describe('form validation', () => {
    it('should require email field', () => {
      const emailControl = component.email;

      emailControl?.setValue('');
      emailControl?.markAsTouched();

      expect(emailControl?.invalid).toBe(true);
      expect(emailControl?.errors?.['required']).toBe(true);
    });

    it('should validate email format', () => {
      const emailControl = component.email;

      emailControl?.setValue('invalid-email');
      emailControl?.markAsTouched();

      expect(emailControl?.invalid).toBe(true);
      expect(emailControl?.errors?.['email']).toBe(true);
    });

    it('should accept valid email', () => {
      const emailControl = component.email;

      emailControl?.setValue('test@example.com');
      emailControl?.markAsTouched();

      expect(emailControl?.valid).toBe(true);
    });
  });

  describe('form submission', () => {
    it('should call forgotPassword with valid email', async () => {
      component.forgotPasswordForm.patchValue({ email: 'test@example.com' });

      await component.onSubmit();

      expect(mockAuthStore.forgotPassword).toHaveBeenCalledWith(
        'test@example.com'
      );
    });

    it('should emit closeModal on successful submission', async () => {
      jest.spyOn(component.closeModal, 'emit');
      component.forgotPasswordForm.patchValue({ email: 'test@example.com' });

      await component.onSubmit();

      expect(component.closeModal.emit).toHaveBeenCalled();
    });

    it('should not submit with invalid form', async () => {
      component.forgotPasswordForm.patchValue({ email: '' });

      await component.onSubmit();

      expect(mockAuthStore.forgotPassword).not.toHaveBeenCalled();
      expect(component.submitted).toBe(true);
    });

    it('should handle loading state', async () => {
      component.forgotPasswordForm.patchValue({ email: 'test@example.com' });

      const submitPromise = component.onSubmit();
      expect(component.loading).toBe(true);

      await submitPromise;
      expect(component.loading).toBe(false);
    });
  });

  describe('cancel functionality', () => {
    it('should emit closeModal when cancelled', () => {
      jest.spyOn(component.closeModal, 'emit');

      component.onCancel();

      expect(component.closeModal.emit).toHaveBeenCalled();
    });
  });

  describe('form getters', () => {
    it('should return email form control', () => {
      const emailControl = component.email;
      expect(emailControl).toBe(component.forgotPasswordForm.get('email'));
    });
  });
});
