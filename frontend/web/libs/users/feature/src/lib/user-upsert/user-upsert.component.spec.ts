import { ComponentFixture, TestBed } from '@angular/core/testing';
import { UserUpsertComponent } from './user-upsert.component';
import { Router } from '@angular/router';
import { ActivatedRoute } from '@angular/router';
import { UsersStore } from '@web/users/data-access';
import { MessageService } from 'primeng/api';
import { TranslateModule } from '@ngx-translate/core';
import { User, Role, Status } from '@web/shared/models/settings';
import { FormsModule } from '@angular/forms';
import { signal } from '@angular/core';
import { NO_ERRORS_SCHEMA } from '@angular/core';

describe('UserUpsertComponent', () => {
  let component: UserUpsertComponent;
  let fixture: ComponentFixture<UserUpsertComponent>;
  let routerMock: { navigate: jest.Mock };
  let routeMock: { snapshot: any; params: any };
  let usersStoreMock: {
    entities: ReturnType<typeof signal>;
    getUserById: jest.Mock;
    update: jest.Mock;
    create: jest.Mock;
    resetPassword: jest.Mock;
  };
  let messageServiceMock: { add: jest.Mock };

  const mockUser: User = {
    id: '1',
    firstname: 'John',
    lastname: 'Doe',
    fullName: 'John Doe',
    email: 'john.doe@example.com',
    status: 'VERIFIED' as Status,
    roles: ['ROLE_USER', 'ROLE_ADMIN'] as Role[],
  } as User;

  beforeEach(async () => {
    routerMock = {
      navigate: jest.fn(),
    };

    routeMock = {
      snapshot: { params: {} },
      params: {
        subscribe: jest.fn((callback: any) => {
          callback({ id: undefined });
          return { unsubscribe: jest.fn() };
        }),
      },
    };

    usersStoreMock = {
      entities: signal([mockUser]),
      getUserById: jest.fn().mockResolvedValue(mockUser),
      update: jest.fn().mockResolvedValue(undefined),
      create: jest.fn().mockResolvedValue(undefined),
      resetPassword: jest.fn().mockResolvedValue(undefined),
    };

    messageServiceMock = {
      add: jest.fn(),
    };

    await TestBed.configureTestingModule({
      imports: [UserUpsertComponent, FormsModule, TranslateModule.forRoot()],
      providers: [
        { provide: Router, useValue: routerMock },
        { provide: ActivatedRoute, useValue: routeMock },
        { provide: UsersStore, useValue: usersStoreMock },
        { provide: MessageService, useValue: messageServiceMock },
      ],
      schemas: [NO_ERRORS_SCHEMA],
    })
      .overrideComponent(UserUpsertComponent, {
        set: {
          providers: [
            { provide: MessageService, useValue: messageServiceMock },
          ],
        },
      })
      .compileComponents();

    fixture = TestBed.createComponent(UserUpsertComponent);
    component = fixture.componentInstance;
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  describe('loadUserForEdit', () => {
    it('should load user from store if available', async () => {
      routeMock.snapshot.params = { id: '1' };
      usersStoreMock.entities = signal([mockUser]);

      await component.loadUserForEdit('1');

      expect(component.isEditMode()).toBe(true);
      expect(component.userId()).toBe('1');
      expect(component.firstname()).toBe('John');
      expect(component.lastname()).toBe('Doe');
      expect(component.email()).toBe('john.doe@example.com');
      expect(component.selectedRoles()).toEqual(['ROLE_ADMIN']);
      expect(component.status()).toBe('VERIFIED');
      expect(usersStoreMock.getUserById).not.toHaveBeenCalled();
    });

    it('should load user from service if not in store', async () => {
      routeMock.snapshot.params = { id: '2' };
      usersStoreMock.entities = signal([mockUser]);
      const user2 = { ...mockUser, id: '2' };
      usersStoreMock.getUserById.mockResolvedValue(user2);

      await component.loadUserForEdit('2');

      expect(component.isEditMode()).toBe(true);
      expect(usersStoreMock.getUserById).toHaveBeenCalledWith('2');
    });

    it('should handle error when loading user fails', async () => {
      routeMock.snapshot.params = { id: '999' };
      usersStoreMock.entities = signal([]);
      const error = new Error('User not found');
      usersStoreMock.getUserById.mockRejectedValue(error);
      jest.spyOn(console, 'error').mockImplementation();

      await component.loadUserForEdit('999');

      expect(console.error).toHaveBeenCalledWith('Error loading user:', error);
      expect(messageServiceMock.add).toHaveBeenCalledWith({
        severity: 'error',
        summary: 'COMMON.ERROR',
        detail: 'USER.ERROR.LOAD_FAILED',
      });

      jest.spyOn(console, 'error').mockRestore();
    });
  });

  describe('resetPassword', () => {
    beforeEach(() => {
      jest.clearAllMocks();
      component.userModel.set({
        firstname: 'John',
        lastname: 'Doe',
        email: 'test@example.com',
        selectedRoles: ['ROLE_ADMIN'],
        status: 'VERIFIED',
      });
      component.userId.set('1');
    });

    it('should show warn if email is empty', () => {
      component.userModel.update((model) => ({ ...model, email: '' }));

      component.resetPassword();

      expect(messageServiceMock.add).toHaveBeenCalledWith({
        severity: 'warn',
        summary: 'COMMON.WARNING',
        detail: 'USER.WARNING.EMAIL_REQUIRED',
      });
      expect(usersStoreMock.resetPassword).not.toHaveBeenCalled();
    });

    it('should call store resetPassword when email is set', async () => {
      await component.resetPassword();

      expect(usersStoreMock.resetPassword).toHaveBeenCalled();
      const callArgs = usersStoreMock.resetPassword.mock.calls[0][0];
      expect(callArgs.email).toBe('test@example.com');
      expect(callArgs.firstname).toBe('John');
      expect(callArgs.lastname).toBe('Doe');
    });

    it('should handle error when resetting password fails', async () => {
      const error = new Error('Reset failed');
      usersStoreMock.resetPassword.mockRejectedValue(error);
      jest.spyOn(console, 'error').mockImplementation();

      await component.resetPassword();

      expect(console.error).toHaveBeenCalledWith(
        'Error resetting password:',
        error
      );

      jest.spyOn(console, 'error').mockRestore();
    });
  });

  describe('saveUser', () => {
    beforeEach(() => {
      jest.clearAllMocks();
      component.userModel.set({
        firstname: 'John',
        lastname: 'Doe',
        email: 'john.doe@example.com',
        selectedRoles: ['ROLE_ADMIN'],
        status: 'VERIFIED',
      });
      fixture.detectChanges();
    });

    it('should not save if form is invalid', () => {
      component.userModel.set({
        firstname: '',
        lastname: '',
        email: '',
        selectedRoles: [],
        status: 'UNVERIFIED',
      });
      fixture.detectChanges();

      component.saveUser();

      expect(messageServiceMock.add).toHaveBeenCalledWith({
        severity: 'warn',
        summary: 'COMMON.WARNING',
        detail: 'USER.WARNING.FILL_REQUIRED',
      });
      expect(usersStoreMock.update).not.toHaveBeenCalled();
      expect(usersStoreMock.create).not.toHaveBeenCalled();
    });

    it('should update user in edit mode', async () => {
      component.isEditMode.set(true);
      component.userId.set('1');
      fixture.detectChanges();

      await component.saveUser();

      expect(usersStoreMock.update).toHaveBeenCalled();
      const callArgs = usersStoreMock.update.mock.calls[0][0];
      expect(callArgs.id).toBe('1');
      expect(callArgs.roles).toContain('ROLE_USER');
      expect(callArgs.roles).toContain('ROLE_ADMIN');
      expect(messageServiceMock.add).toHaveBeenCalledWith({
        severity: 'success',
        summary: 'COMMON.SUCCESS',
        detail: 'USER.SUCCESS.UPDATED',
      });
      expect(routerMock.navigate).toHaveBeenCalledWith(['/backoffice/users']);
    });

    it('should create user in create mode', async () => {
      component.isEditMode.set(false);
      component.userId.set(null);
      fixture.detectChanges();

      await component.saveUser();

      expect(usersStoreMock.create).toHaveBeenCalled();
      const callArgs = usersStoreMock.create.mock.calls[0][0];
      expect(callArgs.roles).toContain('ROLE_USER');
      expect(callArgs.roles).toContain('ROLE_ADMIN');
      expect(messageServiceMock.add).toHaveBeenCalledWith({
        severity: 'success',
        summary: 'COMMON.SUCCESS',
        detail: 'USER.SUCCESS.CREATED',
      });
      expect(routerMock.navigate).toHaveBeenCalledWith(['/backoffice/users']);
    });

    it('should always include ROLE_USER in roles', async () => {
      component.userModel.update((model) => ({ ...model, selectedRoles: ['ROLE_ADMIN'] }));
      component.isEditMode.set(false);
      fixture.detectChanges();

      await component.saveUser();

      const callArgs = usersStoreMock.create.mock.calls[0][0];
      expect(callArgs.roles).toContain('ROLE_USER');
      expect(callArgs.roles).toContain('ROLE_ADMIN');
      expect(callArgs.roles.length).toBe(2);
    });

    it('should remove duplicate roles', async () => {
      component.userModel.update((model) => ({ ...model, selectedRoles: ['ROLE_USER', 'ROLE_ADMIN'] }));
      component.isEditMode.set(false);
      fixture.detectChanges();

      await component.saveUser();

      const callArgs = usersStoreMock.create.mock.calls[0][0];
      const uniqueRoles = [...new Set(callArgs.roles)];
      expect(callArgs.roles.length).toBe(uniqueRoles.length);
    });

    it('should handle error when saving fails', async () => {
      component.isEditMode.set(true);
      component.userId.set('1');
      const error = new Error('Save failed');
      usersStoreMock.update.mockRejectedValue(error);
      jest.spyOn(console, 'error').mockImplementation();
      fixture.detectChanges();

      await component.saveUser();

      expect(console.error).toHaveBeenCalledWith('Error saving user:', error);
      expect(messageServiceMock.add).toHaveBeenCalledWith({
        severity: 'error',
        summary: 'COMMON.ERROR',
        detail: 'USER.ERROR.SAVE_FAILED',
      });
      expect(routerMock.navigate).not.toHaveBeenCalled();

      jest.spyOn(console, 'error').mockRestore();
    });

    it('should save without form parameter', async () => {
      component.isEditMode.set(false);
      fixture.detectChanges();

      await component.saveUser();

      expect(usersStoreMock.create).toHaveBeenCalled();
    });
  });

  describe('cancel', () => {
    it('should navigate back to users list', () => {
      component.cancel();

      expect(routerMock.navigate).toHaveBeenCalledWith(['/backoffice/users']);
    });
  });

  describe('computed properties', () => {
    it('should have roleOptions computed', () => {
      expect(component.roleOptions()).toEqual([
        { label: 'PROFILE.ROLE.ADMIN', value: 'ROLE_ADMIN' },
        { label: 'PROFILE.ROLE.MODERATOR', value: 'ROLE_MODERATOR' },
      ]);
    });

    it('should have statusOptions computed', () => {
      expect(component.statusOptions()).toEqual([
        { label: 'PROFILE.STATUS.VERIFIED', value: 'VERIFIED' },
        { label: 'PROFILE.STATUS.UNVERIFIED', value: 'UNVERIFIED' },
        { label: 'PROFILE.STATUS.DELETED', value: 'DELETED' },
      ]);
    });
  });
});
