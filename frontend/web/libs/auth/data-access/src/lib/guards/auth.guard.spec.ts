import { TestBed } from '@angular/core/testing';
import { Router } from '@angular/router';
import { AuthGuard } from './auth.guard';
import { AuthStore } from '../auth.store';
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

const emptyUser: User = {
  ...mockUser,
  id: '',
};

describe('AuthGuard', () => {
  let router: jest.Mocked<Pick<Router, 'navigateByUrl'>>;
  let authStoreMock: {
    user: jest.Mock;
    currentUser: jest.Mock;
  };

  beforeEach(() => {
    authStoreMock = {
      user: jest.fn().mockReturnValue(mockUser),
      currentUser: jest.fn().mockResolvedValue(undefined),
    };

    router = {
      navigateByUrl: jest.fn().mockResolvedValue(true),
    };

    TestBed.configureTestingModule({
      providers: [
        { provide: AuthStore, useValue: authStoreMock },
        { provide: Router, useValue: router },
      ],
    });
  });

  it('should return true when user is already loaded with valid id', async () => {
    const result = await TestBed.runInInjectionContext(() => AuthGuard());
    expect(result).toBe(true);
    expect(authStoreMock.currentUser).not.toHaveBeenCalled();
    expect(router.navigateByUrl).not.toHaveBeenCalled();
  });

  it('should load user and return true when user is valid after load', async () => {
    // First call: empty user (before load), then after currentUser() user() is called again and must return valid user
    authStoreMock.user
      .mockReturnValueOnce(emptyUser)
      .mockReturnValue(mockUser);
    authStoreMock.currentUser.mockResolvedValue(undefined);

    const result = await TestBed.runInInjectionContext(() => AuthGuard());

    expect(authStoreMock.currentUser).toHaveBeenCalled();
    expect(result).toBe(true);
    expect(router.navigateByUrl).not.toHaveBeenCalled();
  });

  it('should redirect to /login when user is empty after load', async () => {
    authStoreMock.user.mockReturnValue(emptyUser);
    authStoreMock.currentUser.mockResolvedValue(undefined);

    const result = await TestBed.runInInjectionContext(() => AuthGuard());

    expect(authStoreMock.currentUser).toHaveBeenCalled();
    expect(router.navigateByUrl).toHaveBeenCalledWith('/login');
    expect(result).toBe(false);
  });

  it('should redirect to /login when currentUser throws', async () => {
    const warnSpy = jest
      .spyOn(console, 'warn')
      .mockImplementation(() => undefined);
    authStoreMock.user.mockReturnValue(emptyUser);
    authStoreMock.currentUser.mockRejectedValue(new Error('Network error'));

    const result = await TestBed.runInInjectionContext(() => AuthGuard());

    expect(router.navigateByUrl).toHaveBeenCalledWith('/login');
    expect(result).toBe(false);
    warnSpy.mockRestore();
  });
});
