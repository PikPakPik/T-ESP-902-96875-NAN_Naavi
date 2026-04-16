import { TestBed } from '@angular/core/testing';
import { Router } from '@angular/router';
import { AdminGuard } from './admin.guard';
import { AuthStore } from '../auth.store';
import { User } from '@web/shared/models/settings';

const mockAdminUser: User = {
  id: '1',
  fullName: 'Admin User',
  email: 'admin@example.com',
  firstname: 'Admin',
  lastname: 'User',
  roles: ['ROLE_USER', 'ROLE_ADMIN'],
  status: 'VERIFIED',
};

const mockRegularUser: User = {
  id: '2',
  fullName: 'John Doe',
  email: 'user@example.com',
  firstname: 'John',
  lastname: 'Doe',
  roles: ['ROLE_USER'],
  status: 'VERIFIED',
};

describe('AdminGuard', () => {
  let router: jest.Mocked<Pick<Router, 'navigateByUrl'>>;
  let authStoreMock: { user: jest.Mock };

  beforeEach(() => {
    authStoreMock = {
      user: jest.fn().mockReturnValue(mockAdminUser),
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

  it('should return true when user has ROLE_ADMIN', async () => {
    const result = await TestBed.runInInjectionContext(() => AdminGuard());
    expect(result).toBe(true);
    expect(router.navigateByUrl).not.toHaveBeenCalled();
  });

  it('should redirect to /login when user is not loaded (empty id)', async () => {
    authStoreMock.user.mockReturnValue({
      ...mockAdminUser,
      id: '',
    });

    const result = await TestBed.runInInjectionContext(() => AdminGuard());

    expect(router.navigateByUrl).toHaveBeenCalledWith('/login');
    expect(result).toBe(false);
  });

  it('should redirect to /login when user is null/undefined', async () => {
    authStoreMock.user.mockReturnValue(null as unknown as User);

    const result = await TestBed.runInInjectionContext(() => AdminGuard());

    expect(router.navigateByUrl).toHaveBeenCalledWith('/login');
    expect(result).toBe(false);
  });

  it('should redirect to /forbidden when user does not have ROLE_ADMIN', async () => {
    authStoreMock.user.mockReturnValue(mockRegularUser);

    const result = await TestBed.runInInjectionContext(() => AdminGuard());

    expect(router.navigateByUrl).toHaveBeenCalledWith('/forbidden');
    expect(result).toBe(false);
  });
});
