import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ProfileContainer } from './profile.container';
import { UsersStore } from '@web/users/data-access';
import { signal } from '@angular/core';
import { AuthStore } from '@web/auth/data-access';
import { TranslateModule } from '@ngx-translate/core';

describe('ProfileContainer', () => {
  let component: ProfileContainer;
  let fixture: ComponentFixture<ProfileContainer>;

  beforeEach(async () => {
    const mockUser = {
      id: '1',
      firstname: 'John',
      lastname: 'Doe',
      fullName: 'John Doe',
      email: 'john.doe@example.com',
      status: 'VERIFIED' as const,
      roles: ['ROLE_USER' as const],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    const authStoreMock = {
      user: signal(mockUser),
      userId: signal('1'),
      currentUser: jest.fn(),
    };

    const usersStoreMock = {
      update: jest.fn(),
    };

    await TestBed.configureTestingModule({
      imports: [ProfileContainer, TranslateModule.forRoot()],
      providers: [
        { provide: AuthStore, useValue: authStoreMock },
        { provide: UsersStore, useValue: usersStoreMock },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(ProfileContainer);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
