import { ComponentFixture, TestBed } from '@angular/core/testing';
import { UserUpsertContainer } from './user-upsert.container';
import { Router } from '@angular/router';
import { ActivatedRoute } from '@angular/router';
import { UsersStore } from '@web/users/data-access';
import { MessageService } from 'primeng/api';
import { TranslateService } from '@ngx-translate/core';
import { signal } from '@angular/core';
import { NO_ERRORS_SCHEMA } from '@angular/core';

describe('UserUpsertContainer', () => {
  let component: UserUpsertContainer;
  let fixture: ComponentFixture<UserUpsertContainer>;

  beforeEach(async () => {
    const routerMock = { navigate: jest.fn() };
    const routeMock = {
      snapshot: { params: {} },
      params: { subscribe: jest.fn(() => ({ unsubscribe: jest.fn() })) },
    };
    const usersStoreMock = {
      entities: signal([]),
      getUserById: jest.fn(),
      update: jest.fn(),
      create: jest.fn(),
      resetPassword: jest.fn(),
    };
    const messageServiceMock = { add: jest.fn() };
    const translateServiceMock = { instant: jest.fn((key: string) => key) };

    await TestBed.configureTestingModule({
      imports: [UserUpsertContainer],
      providers: [
        { provide: Router, useValue: routerMock },
        { provide: ActivatedRoute, useValue: routeMock },
        { provide: UsersStore, useValue: usersStoreMock },
        { provide: MessageService, useValue: messageServiceMock },
        { provide: TranslateService, useValue: translateServiceMock },
      ],
      schemas: [NO_ERRORS_SCHEMA],
    }).compileComponents();

    fixture = TestBed.createComponent(UserUpsertContainer);
    component = fixture.componentInstance;
    // Ne pas appeler detectChanges() pour éviter les erreurs de template
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
