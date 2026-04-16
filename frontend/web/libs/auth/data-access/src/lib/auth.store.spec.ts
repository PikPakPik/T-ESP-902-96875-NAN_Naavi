import { TestBed } from '@angular/core/testing';
import { HttpErrorResponse } from '@angular/common/http';
import { of, throwError } from 'rxjs';
import { TranslateService } from '@ngx-translate/core';
import { AuthStore } from './auth.store';
import { AuthService } from './services/auth.service';
import { User } from '@web/shared/models/settings';

const mockUser: User = {
  id: '1',
  fullName: 'John Doe',
  email: 'user@example.com',
  firstname: 'John',
  lastname: 'Doe',
  roles: ['ROLE_USER'],
  status: 'VERIFIED',
};

describe('AuthStore', () => {
  let store: InstanceType<typeof AuthStore>;
  let authService: jest.Mocked<Pick<AuthService, 'currentUser' | 'login' | 'forgotPassword' | 'logout'>>;
  let translateService: { instant: jest.Mock };

  beforeEach(() => {
    authService = {
      currentUser: jest.fn(),
      login: jest.fn(),
      forgotPassword: jest.fn(),
      logout: jest.fn(),
    };
    translateService = {
      instant: jest.fn((key: string) => key),
    };

    TestBed.configureTestingModule({
      providers: [
        AuthStore,
        { provide: AuthService, useValue: authService },
        { provide: TranslateService, useValue: translateService },
      ],
    });

    store = TestBed.inject(AuthStore);
  });

  it('should be created', () => {
    expect(store).toBeTruthy();
  });

  it('should have initial state with default user', () => {
    expect(store.user().id).toBe('');
    expect(store.user().email).toBe('');
    expect(store.requestStatus()).toBe('idle');
    expect(store.error()).toBeNull();
  });

  describe('currentUser', () => {
    it('should load current user successfully', async () => {
      authService.currentUser.mockReturnValue(of(mockUser));

      await store.currentUser();

      expect(authService.currentUser).toHaveBeenCalled();
      expect(store.user()).toEqual(mockUser);
      expect(store.requestStatus()).toBe('fulfilled');
      expect(store.error()).toBeNull();
    });

    it('should set error state and reset user on currentUser failure', async () => {
      const httpError = new HttpErrorResponse({
        status: 401,
        statusText: 'Unauthorized',
        error: { message: 'Unauthorized' },
      });
      authService.currentUser.mockReturnValue(throwError(() => httpError));

      await expect(store.currentUser()).rejects.toBe(httpError);

      expect(store.user().id).toBe('');
      expect(store.requestStatus()).toBe('error');
      expect(store.error()).toBe('Unauthorized');
    });

    it('should use status map message when error has no message', async () => {
      const httpError = new HttpErrorResponse({
        status: 401,
        statusText: 'Unauthorized',
      });
      authService.currentUser.mockReturnValue(throwError(() => httpError));

      await expect(store.currentUser()).rejects.toBe(httpError);

      expect(store.requestStatus()).toBe('error');
      expect(translateService.instant).toHaveBeenCalled();
    });

    it('should use status map for 400 and 403', async () => {
      const httpError400 = new HttpErrorResponse({
        status: 400,
        statusText: 'Bad Request',
      });
      authService.currentUser.mockReturnValue(throwError(() => httpError400));
      await expect(store.currentUser()).rejects.toBe(httpError400);
      expect(store.requestStatus()).toBe('error');

      authService.currentUser.mockReturnValue(
        throwError(
          () =>
            new HttpErrorResponse({
              status: 403,
              statusText: 'Forbidden',
            })
        )
      );
      await store.currentUser().catch(() => undefined);
      expect(store.requestStatus()).toBe('error');
    });

    it('should handle error with string error body', async () => {
      const httpError = new HttpErrorResponse({
        status: 500,
        error: 'Internal Server Error',
      });
      authService.currentUser.mockReturnValue(throwError(() => httpError));

      await expect(store.currentUser()).rejects.toBe(httpError);

      expect(store.error()).toBe('Internal Server Error');
    });

    it('should handle standard Error', async () => {
      const err = new Error('Network failure');
      authService.currentUser.mockReturnValue(throwError(() => err));

      await expect(store.currentUser()).rejects.toBe(err);

      expect(store.error()).toBe('Network failure');
    });

    it('should handle HttpErrorResponse with error.error property', async () => {
      const httpError = new HttpErrorResponse({
        status: 500,
        error: { error: 'Custom error field' },
      });
      authService.currentUser.mockReturnValue(throwError(() => httpError));

      await expect(store.currentUser()).rejects.toBe(httpError);

      expect(store.error()).toBe('Custom error field');
    });

    it('should use generic message for unknown status when no message in body', async () => {
      const httpError = new HttpErrorResponse({
        status: 500,
        statusText: 'Server Error',
      });
      authService.currentUser.mockReturnValue(throwError(() => httpError));

      await expect(store.currentUser()).rejects.toBe(httpError);

      expect(store.requestStatus()).toBe('error');
      expect(store.error()).toBeTruthy();
    });
  });

  describe('login', () => {
    it('should login successfully and load user', async () => {
      authService.login.mockReturnValue(
        of({ accessToken: 'at', refreshToken: 'rt' })
      );
      authService.currentUser.mockReturnValue(of(mockUser));

      await store.login('user@example.com', 'password', 'token');

      expect(authService.login).toHaveBeenCalledWith(
        'user@example.com',
        'password',
        'token'
      );
      expect(authService.currentUser).toHaveBeenCalled();
      expect(store.user()).toEqual(mockUser);
      expect(store.requestStatus()).toBe('fulfilled');
    });

    it('should set error state on login failure', async () => {
      const httpError = new HttpErrorResponse({
        status: 400,
        error: { message: 'Invalid credentials' },
      });
      authService.login.mockReturnValue(throwError(() => httpError));

      await store.login('bad@example.com', 'wrong', 'token');

      expect(store.requestStatus()).toBe('error');
      expect(store.error()).toBe('Invalid credentials');
    });
  });

  describe('forgotPassword', () => {
    it('should call forgotPassword successfully', async () => {
      authService.forgotPassword.mockReturnValue(of(undefined));

      await store.forgotPassword('user@example.com');

      expect(authService.forgotPassword).toHaveBeenCalledWith('user@example.com');
      expect(store.requestStatus()).toBe('fulfilled');
    });

    it('should set error state on forgotPassword failure', async () => {
      const httpError = new HttpErrorResponse({
        status: 404,
        error: { message: 'User not found' },
      });
      authService.forgotPassword.mockReturnValue(throwError(() => httpError));

      await store.forgotPassword('unknown@example.com');

      expect(store.requestStatus()).toBe('error');
      expect(store.error()).toBe('User not found');
    });
  });

  describe('logout', () => {
    it('should logout successfully and reset user', async () => {
      authService.logout.mockReturnValue(of(undefined));

      await store.logout();

      expect(authService.logout).toHaveBeenCalled();
      expect(store.user().id).toBe('');
      expect(store.requestStatus()).toBe('fulfilled');
    });

    it('should reset user locally on logout failure (best-effort)', async () => {
      const httpError = new HttpErrorResponse({
        status: 500,
        error: { error: 'Server error' },
      });
      authService.logout.mockReturnValue(throwError(() => httpError));

      await store.logout();

      // Logout always resets user locally (cookies, user) even if API fails
      expect(store.user().id).toBe('');
      expect(store.requestStatus()).toBe('fulfilled');
    });
  });
});
