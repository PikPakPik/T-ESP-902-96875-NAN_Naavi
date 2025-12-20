import { ComponentFixture, TestBed } from '@angular/core/testing';
import { UsersContainer } from './users.container';
import { UsersStore } from '@web/users/data-access';
import { signal } from '@angular/core';
import { User } from '@web/shared/models/settings';
import { NO_ERRORS_SCHEMA } from '@angular/core';

describe('UsersContainer', () => {
  let component: UsersContainer;
  let fixture: ComponentFixture<UsersContainer>;
  let usersStoreMock: {
    isPending: ReturnType<typeof signal>;
    entities: ReturnType<typeof signal>;
    total: ReturnType<typeof signal>;
    page: ReturnType<typeof signal>;
    limit: ReturnType<typeof signal>;
    totalPages: ReturnType<typeof signal>;
    delete: jest.Mock;
    update: jest.Mock;
    create: jest.Mock;
    resetPassword: jest.Mock;
    getUsers: jest.Mock;
    setPage: jest.Mock;
    setLimit: jest.Mock;
  };

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
    usersStoreMock = {
      isPending: signal(false),
      entities: signal([mockUser]),
      total: signal(1),
      page: signal(1),
      limit: signal(10),
      totalPages: signal(1),
      delete: jest.fn(),
      update: jest.fn(),
      create: jest.fn(),
      resetPassword: jest.fn(),
      getUsers: jest.fn().mockResolvedValue(undefined),
      setPage: jest.fn(),
      setLimit: jest.fn(),
    };

    await TestBed.configureTestingModule({
      imports: [UsersContainer],
      providers: [{ provide: UsersStore, useValue: usersStoreMock }],
      schemas: [NO_ERRORS_SCHEMA],
    })
      .overrideComponent(UsersContainer, {
        set: {
          template: '', // Template vide pour éviter le rendu
        },
      })
      .compileComponents();

    fixture = TestBed.createComponent(UsersContainer);
    component = fixture.componentInstance;
    // Ne pas appeler detectChanges() pour éviter le rendu du template
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should have loading signal from store', () => {
    expect(component.loading()).toBe(false);
    expect(component.loading()).toBe(usersStoreMock.isPending());
  });

  it('should have rows signal from store', () => {
    expect(component.rows()).toEqual([mockUser]);
  });

  it('should have statuses computed', () => {
    expect(component.statuses()).toEqual([
      { label: 'PROFILE.STATUS.VERIFIED', value: 'VERIFIED' },
      { label: 'PROFILE.STATUS.UNVERIFIED', value: 'UNVERIFIED' },
    ]);
  });

  it('should have roles computed', () => {
    expect(component.roles()).toEqual([
      { label: 'PROFILE.ROLE.ADMIN', value: 'ROLE_ADMIN' },
      { label: 'PROFILE.ROLE.USER', value: 'ROLE_USER' },
      { label: 'PROFILE.ROLE.MODERATOR', value: 'ROLE_MODERATOR' },
    ]);
  });

  it('should have columns defined', () => {
    expect(component.columns).toBeDefined();
    expect(component.columns.length).toBeGreaterThan(0);
    expect(component.columns[0].field).toBe('id');
  });

  describe('onEditUser', () => {
    it('should log edit user action', () => {
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation();

      component.onEditUser(mockUser);

      expect(consoleSpy).toHaveBeenCalledWith('Edit user:', mockUser);

      consoleSpy.mockRestore();
    });
  });

  describe('onDeleteUser', () => {
    it('should call store delete with user id', () => {
      component.onDeleteUser(mockUser);

      expect(usersStoreMock.delete).toHaveBeenCalledWith(mockUser.id);
    });
  });

  describe('onSaveUser', () => {
    it('should update existing user when user id is found', () => {
      component.onSaveUser(mockUser);

      expect(usersStoreMock.update).toHaveBeenCalledWith(mockUser);
      expect(usersStoreMock.create).not.toHaveBeenCalled();
    });

    it('should create new user when user id is not found', () => {
      const newUser: User = {
        ...mockUser,
        id: '2',
      };
      usersStoreMock.entities = signal([mockUser]);

      component.onSaveUser(newUser);

      expect(usersStoreMock.create).toHaveBeenCalledWith(newUser);
      expect(usersStoreMock.update).not.toHaveBeenCalled();
    });

    it('should log save user action', () => {
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation();

      component.onSaveUser(mockUser);

      expect(consoleSpy).toHaveBeenCalledWith('Save user:', mockUser);

      consoleSpy.mockRestore();
    });
  });

  describe('onDeleteSelectedUsers', () => {
    it('should delete all selected users', () => {
      const users: User[] = [
        mockUser,
        {
          ...mockUser,
          id: '2',
        },
      ];

      component.onDeleteSelectedUsers(users);

      expect(usersStoreMock.delete).toHaveBeenCalledWith('1');
      expect(usersStoreMock.delete).toHaveBeenCalledWith('2');
      expect(usersStoreMock.delete).toHaveBeenCalledTimes(2);
    });

    it('should log delete selected users action', () => {
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation();
      const users: User[] = [mockUser];

      component.onDeleteSelectedUsers(users);

      expect(consoleSpy).toHaveBeenCalledWith('Delete selected users:', users);

      consoleSpy.mockRestore();
    });
  });

  describe('onResetPassword', () => {
    it('should call store resetPassword', () => {
      component.onResetPassword(mockUser);

      expect(usersStoreMock.resetPassword).toHaveBeenCalledWith(mockUser);
    });
  });

  describe('onPageChange', () => {
    it('should update page and limit, then reload users', async () => {
      const event = { page: 2, rows: 20 };

      await component.onPageChange(event);

      expect(usersStoreMock.setPage).toHaveBeenCalledWith(2);
      expect(usersStoreMock.setLimit).toHaveBeenCalledWith(20);
      expect(usersStoreMock.getUsers).toHaveBeenCalledWith({
        page: 2,
        limit: 20,
      });
    });
  });

  describe('onSearchChange', () => {
    it('should reset to page 1 and search with query', async () => {
      usersStoreMock.limit = signal(10);

      await component.onSearchChange('test query');

      expect(usersStoreMock.setPage).toHaveBeenCalledWith(1);
      expect(usersStoreMock.getUsers).toHaveBeenCalledWith({
        page: 1,
        limit: 10,
        query: 'test query',
      });
    });

    it('should handle empty query', async () => {
      usersStoreMock.limit = signal(10);

      await component.onSearchChange('   ');

      expect(usersStoreMock.setPage).toHaveBeenCalledWith(1);
      expect(usersStoreMock.getUsers).toHaveBeenCalledWith({
        page: 1,
        limit: 10,
        query: undefined,
      });
    });

    it('should handle empty string query', async () => {
      usersStoreMock.limit = signal(10);

      await component.onSearchChange('');

      expect(usersStoreMock.setPage).toHaveBeenCalledWith(1);
      expect(usersStoreMock.getUsers).toHaveBeenCalledWith({
        page: 1,
        limit: 10,
        query: undefined,
      });
    });

    it('should trim query before searching', async () => {
      usersStoreMock.limit = signal(10);

      await component.onSearchChange('  test  ');

      expect(usersStoreMock.getUsers).toHaveBeenCalledWith({
        page: 1,
        limit: 10,
        query: 'test',
      });
    });
  });
});
