import { TestBed } from '@angular/core/testing';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { MessageService } from 'primeng/api';
import { AuthService } from './auth.service';
import { API_URL } from '@web/shared/http-client';

describe('AuthService', () => {
  let service: AuthService;
  let httpMock: HttpTestingController;
  const apiUrl = 'http://localhost:8080/';

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        AuthService,
        MessageService,
        provideHttpClientTesting(),
        { provide: API_URL, useValue: apiUrl },
      ],
    });

    service = TestBed.inject(AuthService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  describe('currentUser', () => {
    it('should return current user', (done) => {
      const mockUser = {
        id: '1',
        email: 'user@example.com',
        firstName: 'John',
        lastName: 'Doe',
      };

      service.currentUser().subscribe({
        next: (user) => {
          expect(user).toEqual(mockUser);
          done();
        },
        error: done.fail,
      });

      const req = httpMock.expectOne(`${apiUrl}identity/user`);
      expect(req.request.method).toBe('GET');
      req.flush(mockUser);
    });
  });

  describe('login', () => {
    it('should login and return tokens', (done) => {
      const email = 'user@example.com';
      const password = 'password';
      const token = 'turnstile-token';
      const mockResponse = {
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      };

      service.login(email, password, token).subscribe({
        next: (response) => {
          expect(response).toEqual(mockResponse);
          done();
        },
        error: done.fail,
      });

      const req = httpMock.expectOne(`${apiUrl}identity/login`);
      expect(req.request.method).toBe('POST');
      expect(req.request.body).toEqual({ email, password, token });
      req.flush(mockResponse);
    });

    it('should handle login error', (done) => {
      const messageService = TestBed.inject(MessageService);
      const addSpy = jest.spyOn(messageService, 'add');

      service.login('bad@example.com', 'wrong', 'token').subscribe({
        next: () => done.fail('should have failed'),
        error: (error) => {
          expect(error.status).toBe(401);
          expect(addSpy).toHaveBeenCalledWith({
            severity: 'error',
            summary: 'Error',
            detail: 'Invalid credentials',
          });
          done();
        },
      });

      const req = httpMock.expectOne(`${apiUrl}identity/login`);
      req.flush(
        { message: 'Invalid credentials' },
        { status: 401, statusText: 'Unauthorized' }
      );
    });
  });

  describe('refreshToken', () => {
    it('should call refresh endpoint', (done) => {
      service.refreshToken().subscribe({
        next: () => done(),
        error: done.fail,
      });

      const req = httpMock.expectOne(`${apiUrl}identity/refresh`);
      expect(req.request.method).toBe('POST');
      req.flush(null);
    });
  });

  describe('logout', () => {
    it('should call logout endpoint', (done) => {
      service.logout().subscribe({
        next: () => done(),
        error: done.fail,
      });

      const req = httpMock.expectOne(`${apiUrl}identity/logout`);
      expect(req.request.method).toBe('DELETE');
      req.flush(null);
    });
  });

  describe('forgotPassword', () => {
    it('should call forgot-password endpoint', (done) => {
      const email = 'user@example.com';

      service.forgotPassword(email).subscribe({
        next: () => done(),
        error: done.fail,
      });

      const req = httpMock.expectOne(`${apiUrl}identity/forgot-password`);
      expect(req.request.method).toBe('POST');
      expect(req.request.body).toEqual({ email });
      req.flush(null);
    });
  });

  describe('processAuthorization', () => {
    it('should process authorization successfully', (done) => {
      const authorizationToken = 'test-auth-token';
      const turnstileToken = 'test-turnstile-token';
      const mockResponse = {
        i18nKey: 'authorization.success',
        message: 'Your authorization request has been successfully completed.',
        extra: null,
      };

      service
        .processAuthorization(authorizationToken, turnstileToken)
        .subscribe({
          next: (response) => {
            expect(response).toEqual(mockResponse);
            done();
          },
          error: done.fail,
        });

      const req = httpMock.expectOne(`${apiUrl}identity/authorization`);
      expect(req.request.method).toBe('POST');
      expect(req.request.body).toEqual({
        authorizationToken,
        token: turnstileToken,
      });
      req.flush(mockResponse);
    });

    it('should handle 404 authorization error', (done) => {
      const authorizationToken = 'invalid-token';
      const turnstileToken = 'test-turnstile-token';
      const mockError = {
        i18nKey: 'authorization.request_not_found',
        message: 'The authorization request is invalid or has expired.',
        extra: null,
      };

      service
        .processAuthorization(authorizationToken, turnstileToken)
        .subscribe({
          next: () => done.fail('should have failed'),
          error: (error) => {
            expect(error.status).toBe(404);
            expect(error.error?.message).toBe(
              'The authorization request is invalid or has expired.'
            );
            done();
          },
        });

      const req = httpMock.expectOne(`${apiUrl}identity/authorization`);
      req.flush(mockError, {
        status: 404,
        statusText: 'Not Found',
      });
    });

    it('should handle 422 validation error', (done) => {
      const authorizationToken = 'test-token';
      const turnstileToken = 'test-turnstile-token';
      const mockError = {
        i18nKey: 'validation.failed',
        message: 'Validation failed',
        extra: { key: 'message' },
      };

      service
        .processAuthorization(authorizationToken, turnstileToken)
        .subscribe({
          next: () => done.fail('should have failed'),
          error: (error) => {
            expect(error.status).toBe(422);
            expect(error.error?.message).toBe('Validation failed');
            done();
          },
        });

      const req = httpMock.expectOne(`${apiUrl}identity/authorization`);
      req.flush(mockError, {
        status: 422,
        statusText: 'Unprocessable Entity',
      });
    });
  });
});
