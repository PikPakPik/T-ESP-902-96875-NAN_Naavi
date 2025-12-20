import { ComponentFixture, TestBed } from '@angular/core/testing';
import { signal } from '@angular/core';
import { NO_ERRORS_SCHEMA } from '@angular/core';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { provideHttpClient } from '@angular/common/http';
import { ForgotPasswordComponent } from './forgot-password.component';
import { AuthStore } from '@web/auth/data-access';
import { NotificationService } from '@web/shared/ui/notification';
import { LocalStorageService } from '@web/shared/util';
import { API_URL } from '@web/shared/http-client';

describe('ForgotPasswordComponent', () => {
  let component: ForgotPasswordComponent;
  let fixture: ComponentFixture<ForgotPasswordComponent>;
  let mockAuthStore: Record<string, jest.Mock | ReturnType<typeof signal>>;

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
      expect(component.forgotPasswordForm).toBeTruthy();
      expect(component.forgotPasswordForm.email).toBeTruthy();
      expect(component.forgotPasswordModel().email).toBe('');
    });

    it('should set default values', () => {
      expect(component.loading()).toBe(false);
      expect(component.submitted()).toBe(false);
    });
  });

  describe('form validation', () => {
    it('should require email field', () => {
      const emailField = component.forgotPasswordForm.email();
      
      component.forgotPasswordModel.set({ email: '' });
      emailField.value.set('');
      // Trigger validation by accessing the field state
      fixture.detectChanges();

      expect(emailField.valid()).toBe(false);
      const errors = emailField.errors();
      expect(errors.some(e => e.message === "L'email est requis")).toBe(true);
    });

    it('should validate email format', () => {
      const emailField = component.forgotPasswordForm.email();
      
      component.forgotPasswordModel.set({ email: 'invalid-email' });
      emailField.value.set('invalid-email');
      fixture.detectChanges();

      expect(emailField.valid()).toBe(false);
      const errors = emailField.errors();
      expect(errors.some(e => e.message === 'Format d\'email invalide')).toBe(true);
    });

    it('should accept valid email', () => {
      const emailField = component.forgotPasswordForm.email();
      
      component.forgotPasswordModel.set({ email: 'test@example.com' });
      emailField.value.set('test@example.com');
      fixture.detectChanges();

      expect(emailField.valid()).toBe(true);
    });
  });

  describe('form submission', () => {
    it('should call forgotPassword with valid email', async () => {
      component.forgotPasswordModel.set({ email: 'test@example.com' });
      fixture.detectChanges();

      await component.onSubmit();

      expect(mockAuthStore['forgotPassword']).toHaveBeenCalledWith(
        'test@example.com'
      );
    });

    it('should emit closeModal on successful submission', async () => {
      jest.spyOn(component.closeModal, 'emit');
      component.forgotPasswordModel.set({ email: 'test@example.com' });
      fixture.detectChanges();

      await component.onSubmit();

      expect(component.closeModal.emit).toHaveBeenCalled();
    });

    it('should not submit with invalid form', async () => {
      component.forgotPasswordModel.set({ email: '' });
      fixture.detectChanges();

      await component.onSubmit();

      expect(mockAuthStore['forgotPassword']).not.toHaveBeenCalled();
      expect(component.submitted()).toBe(true);
    });

    it('should handle loading state', async () => {
      component.forgotPasswordModel.set({ email: 'test@example.com' });
      fixture.detectChanges();

      const submitPromise = component.onSubmit();
      expect(component.loading()).toBe(true);

      await submitPromise;
      expect(component.loading()).toBe(false);
    });
  });

  describe('cancel functionality', () => {
    it('should emit closeModal when cancelled', () => {
      jest.spyOn(component.closeModal, 'emit');

      component.onCancel();

      expect(component.closeModal.emit).toHaveBeenCalled();
    });
  });

  describe('form access', () => {
    it('should return email field from form', () => {
      const emailField = component.forgotPasswordForm.email();
      expect(emailField).toBeTruthy();
      expect(emailField.value).toBeTruthy();
    });
  });
});
