import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Users } from './users.component';
import { Router } from '@angular/router';
import { ConfirmationService, MessageService } from 'primeng/api';
import { TranslateService } from '@ngx-translate/core';
import { User } from '@web/shared/models/settings';
import { Table } from 'primeng/table';
import { NO_ERRORS_SCHEMA } from '@angular/core';

describe('Users', () => {
  let component: Users;
  let fixture: ComponentFixture<Users>;
  let routerMock: { navigate: jest.Mock };
  let confirmationServiceMock: { confirm: jest.Mock };
  let translateServiceMock: { instant: jest.Mock };

  const mockUser: User = {
    id: '1',
    firstname: 'John',
    lastname: 'Doe',
    fullName: 'John Doe',
    email: 'john.doe@example.com',
    status: 'VERIFIED',
    roles: ['ROLE_USER'],
  } as User;

  beforeEach(async () => {
    routerMock = {
      navigate: jest.fn(),
    };

    confirmationServiceMock = {
      confirm: jest.fn(),
    };

    translateServiceMock = {
      instant: jest.fn((key: string) => key),
    };

    await TestBed.configureTestingModule({
      imports: [Users],
      providers: [
        { provide: Router, useValue: routerMock },
        { provide: TranslateService, useValue: translateServiceMock },
      ],
      schemas: [NO_ERRORS_SCHEMA],
    })
      .overrideComponent(Users, {
        set: {
          template: '', // Template vide pour éviter le rendu
          providers: [
            { provide: ConfirmationService, useValue: confirmationServiceMock },
            { provide: MessageService, useValue: { add: jest.fn() } },
          ],
        },
      })
      .compileComponents();

    fixture = TestBed.createComponent(Users);
    component = fixture.componentInstance;
    // Ne pas appeler detectChanges() pour éviter le rendu du template
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  describe('clear', () => {
    it('should clear the table', () => {
      const tableMock = {
        clear: jest.fn(),
      } as unknown as Table;

      component.clear(tableMock);

      expect(tableMock.clear).toHaveBeenCalled();
    });
  });

  describe('openNew', () => {
    it('should navigate to new user page', () => {
      component.openNew();

      expect(routerMock.navigate).toHaveBeenCalledWith([
        '/backoffice/users/new',
      ]);
    });
  });

  describe('editUserDialog', () => {
    it('should navigate to edit user page', () => {
      component.editUserDialog(mockUser);

      expect(routerMock.navigate).toHaveBeenCalledWith([
        '/backoffice/users/edit',
        mockUser.id,
      ]);
    });
  });

  describe('hideDialog', () => {
    it('should hide dialog and reset submitted', () => {
      component.userDialog.set(true);
      component.submitted.set(true);

      component.hideDialog();

      expect(component.userDialog()).toBe(false);
      expect(component.submitted()).toBe(false);
    });
  });

  describe('onRolesChange', () => {
    it('should always include ROLE_USER and add selected roles', () => {
      component.user.set(mockUser);

      component.onRolesChange(['ROLE_ADMIN']);

      expect(component.user().roles).toEqual(['ROLE_USER', 'ROLE_ADMIN']);
    });

    it('should remove duplicates when ROLE_USER is already selected', () => {
      component.user.set({
        ...mockUser,
        roles: ['ROLE_USER', 'ROLE_ADMIN'],
      });

      component.onRolesChange(['ROLE_ADMIN', 'ROLE_MODERATOR']);

      expect(component.user().roles).toEqual([
        'ROLE_USER',
        'ROLE_ADMIN',
        'ROLE_MODERATOR',
      ]);
    });

    it('should filter out empty or whitespace roles', () => {
      component.user.set(mockUser);

      component.onRolesChange(['ROLE_ADMIN', '', '   ', 'ROLE_MODERATOR']);

      expect(component.user().roles).toEqual([
        'ROLE_USER',
        'ROLE_ADMIN',
        'ROLE_MODERATOR',
      ]);
    });

    it('should handle empty selectedRoles array', () => {
      component.user.set(mockUser);

      component.onRolesChange([]);

      expect(component.user().roles).toEqual(['ROLE_USER']);
    });

    it('should handle null selectedRoles', () => {
      component.user.set(mockUser);

      component.onRolesChange(null as any);

      expect(component.user().roles).toEqual(['ROLE_USER']);
    });
  });

  describe('saveUserDialog', () => {
    beforeEach(() => {
      component.user.set(mockUser);
      jest.clearAllMocks();
    });

    it('should emit saveUser and close dialog when form is valid', () => {
      const saveUserSpy = jest.spyOn(component.saveUser, 'emit');
      component.submitted.set(false);
      component.userDialog.set(true);

      component.saveUserDialog();

      expect(saveUserSpy).toHaveBeenCalledWith(mockUser);
      expect(component.userDialog()).toBe(false);
      expect(component.user()).toEqual({} as User);
      expect(component.submitted()).toBe(true);
    });

    it('should not save when firstname is empty', () => {
      const saveUserSpy = jest.spyOn(component.saveUser, 'emit');
      component.user.set({ ...mockUser, firstname: '' });

      component.saveUserDialog();

      expect(saveUserSpy).not.toHaveBeenCalled();
      expect(component.submitted()).toBe(true);
    });

    it('should not save when firstname is only whitespace', () => {
      const saveUserSpy = jest.spyOn(component.saveUser, 'emit');
      component.user.set({ ...mockUser, firstname: '   ' });

      component.saveUserDialog();

      expect(saveUserSpy).not.toHaveBeenCalled();
    });

    it('should not save when lastname is empty', () => {
      const saveUserSpy = jest.spyOn(component.saveUser, 'emit');
      component.user.set({ ...mockUser, lastname: '' });

      component.saveUserDialog();

      expect(saveUserSpy).not.toHaveBeenCalled();
    });

    it('should not save when email is empty', () => {
      const saveUserSpy = jest.spyOn(component.saveUser, 'emit');
      component.user.set({ ...mockUser, email: '' });

      component.saveUserDialog();

      expect(saveUserSpy).not.toHaveBeenCalled();
    });
  });

  describe('deleteUserConfirm', () => {
    it('should show confirmation dialog and emit deleteUser on accept', () => {
      const deleteUserSpy = jest.spyOn(component.deleteUser, 'emit');
      confirmationServiceMock.confirm.mockImplementation((config: any) => {
        config.accept();
      });

      component.deleteUserConfirm(mockUser);

      expect(confirmationServiceMock.confirm).toHaveBeenCalled();
      expect(deleteUserSpy).toHaveBeenCalledWith(mockUser);
      expect(translateServiceMock.instant).toHaveBeenCalled();
    });
  });

  describe('deleteSelectedUsersConfirm', () => {
    it('should show confirmation dialog and emit deleteSelectedUsers on accept', () => {
      component.selectedUsers = [mockUser];
      const deleteSelectedSpy = jest.spyOn(
        component.deleteSelectedUsers,
        'emit'
      );
      confirmationServiceMock.confirm.mockImplementation((config: any) => {
        config.accept();
      });

      component.deleteSelectedUsersConfirm();

      expect(confirmationServiceMock.confirm).toHaveBeenCalled();
      expect(deleteSelectedSpy).toHaveBeenCalledWith([mockUser]);
    });
  });

  describe('resetPasswordConfirm', () => {
    it('should show confirmation dialog and emit resetPassword on accept', () => {
      const resetPasswordSpy = jest.spyOn(component.resetPassword, 'emit');
      confirmationServiceMock.confirm.mockImplementation((config: any) => {
        config.accept();
      });

      component.resetPasswordConfirm(mockUser);

      expect(confirmationServiceMock.confirm).toHaveBeenCalled();
      expect(resetPasswordSpy).toHaveBeenCalledWith(mockUser);
      expect(translateServiceMock.instant).toHaveBeenCalled();
    });
  });

  describe('getSeverity', () => {
    it('should return success for active status', () => {
      expect(component.getSeverity('active')).toBe('success');
      expect(component.getSeverity('ACTIVE')).toBe('success');
      expect(component.getSeverity('available')).toBe('success');
      expect(component.getSeverity('ok')).toBe('success');
    });

    it('should return info for pending status', () => {
      expect(component.getSeverity('pending')).toBe('info');
      expect(component.getSeverity('PENDING')).toBe('info');
      expect(component.getSeverity('draft')).toBe('info');
    });

    it('should return danger for disabled status', () => {
      expect(component.getSeverity('disabled')).toBe('danger');
      expect(component.getSeverity('DISABLED')).toBe('danger');
      expect(component.getSeverity('blocked')).toBe('danger');
    });

    it('should return secondary for unknown status', () => {
      expect(component.getSeverity('unknown')).toBe('secondary');
      expect(component.getSeverity('')).toBe('secondary');
      expect(component.getSeverity(null)).toBe('secondary');
      expect(component.getSeverity(undefined)).toBe('secondary');
    });
  });

  describe('onSearchChange', () => {
    beforeEach(() => {
      jest.useFakeTimers();
    });

    afterEach(() => {
      jest.useRealTimers();
    });

    it('should emit searchChange after debounce', () => {
      const searchChangeSpy = jest.spyOn(component.searchChange, 'emit');
      const event = {
        target: { value: 'test query' },
      } as unknown as Event;

      component.onSearchChange(event);

      expect(searchChangeSpy).not.toHaveBeenCalled();

      jest.advanceTimersByTime(500);

      expect(searchChangeSpy).toHaveBeenCalledWith('test query');
    });

    it('should cancel previous timeout when called multiple times', () => {
      const searchChangeSpy = jest.spyOn(component.searchChange, 'emit');
      const event1 = {
        target: { value: 'first' },
      } as unknown as Event;
      const event2 = {
        target: { value: 'second' },
      } as unknown as Event;

      component.onSearchChange(event1);
      jest.advanceTimersByTime(300);
      component.onSearchChange(event2);
      jest.advanceTimersByTime(500);

      expect(searchChangeSpy).toHaveBeenCalledTimes(1);
      expect(searchChangeSpy).toHaveBeenCalledWith('second');
    });
  });

  describe('onPageChange', () => {
    it('should emit pageChange with correct page when page is provided', () => {
      const pageChangeSpy = jest.spyOn(component.pageChange, 'emit');
      const event = { first: 0, rows: 10, page: 0 };

      component.onPageChange(event);

      expect(pageChangeSpy).toHaveBeenCalledWith({ page: 1, rows: 10 });
    });

    it('should calculate page from first and rows when page is not provided', () => {
      const pageChangeSpy = jest.spyOn(component.pageChange, 'emit');
      const event = { first: 20, rows: 10 };

      component.onPageChange(event);

      expect(pageChangeSpy).toHaveBeenCalledWith({ page: 3, rows: 10 });
    });

    it('should handle page 0 correctly', () => {
      const pageChangeSpy = jest.spyOn(component.pageChange, 'emit');
      const event = { first: 0, rows: 10 };

      component.onPageChange(event);

      expect(pageChangeSpy).toHaveBeenCalledWith({ page: 1, rows: 10 });
    });
  });
});
