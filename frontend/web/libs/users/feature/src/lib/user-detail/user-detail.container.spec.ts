import { ComponentFixture, TestBed } from '@angular/core/testing';
import { UserDetailContainer } from './user-detail.container';
import { Router, ActivatedRoute } from '@angular/router';
import { UserDetailsStore } from '@web/users/data-access';
import { signal } from '@angular/core';
import { of } from 'rxjs';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { MessageService } from 'primeng/api';
import { API_URL } from '@web/shared/http-client';
import { TranslateService } from '@ngx-translate/core';

describe('UserDetailContainer', () => {
  let component: UserDetailContainer;
  let fixture: ComponentFixture<UserDetailContainer>;
  let mockRouter: Partial<Router>;
  let mockActivatedRoute: Partial<ActivatedRoute>;
  let mockUserDetailsStore: Partial<InstanceType<typeof UserDetailsStore>>;

  beforeEach(async () => {
    mockRouter = {
      navigate: jest.fn(),
    };

    mockActivatedRoute = {
      params: of({ id: '123' }),
    };

    mockUserDetailsStore = {
      user: signal({
        id: '123',
        firstname: 'John',
        lastname: 'Doe',
        fullName: 'John Doe',
        email: 'john@example.com',
        status: 'VERIFIED',
        roles: ['ROLE_USER'],
      }),
      isPending: signal(false),
      history: signal([]),
      totalItems: signal(0),
      totalPages: signal(0),
      currentPage: signal(1),
      nextPage: signal(null),
      previousPage: signal(null),
      limit: signal(20),
      id: signal('123'),
      setPage: jest.fn(),
      setLimit: jest.fn(),
      loadHistory: jest.fn(),
    };

    await TestBed.configureTestingModule({
      imports: [UserDetailContainer],
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        { provide: Router, useValue: mockRouter },
        { provide: ActivatedRoute, useValue: mockActivatedRoute },
        { provide: MessageService, useValue: { add: jest.fn() } },
        { provide: TranslateService, useValue: { instant: jest.fn((key: string) => key) } },
        { provide: API_URL, useValue: 'http://test-api' },
      ],
    })
      .overrideProvider(UserDetailsStore, { useValue: mockUserDetailsStore })
      .overrideComponent(UserDetailContainer, {
        set: {
          template: '<div>user-detail-container-stub</div>',
        },
      })
      .compileComponents();

    fixture = TestBed.createComponent(UserDetailContainer);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  describe('onBack', () => {
    it('Given component initialized When onBack is called Then should navigate to users list', () => {
      // WHEN
      component.onBack();

      // THEN
      expect(mockRouter.navigate).toHaveBeenCalledWith(['/backoffice/users']);
    });
  });

  describe('onPageChange', () => {
    it('Given page change event When onPageChange is called Then should update store and reload history', () => {
      // GIVEN
      const event = { page: 2, rows: 10 };

      // WHEN
      component.onPageChange(event);

      // THEN
      expect(mockUserDetailsStore.setPage).toHaveBeenCalledWith(2);
      expect(mockUserDetailsStore.setLimit).toHaveBeenCalledWith(10);
      expect(mockUserDetailsStore.loadHistory).toHaveBeenCalledWith('123', {
        page: 2,
        limit: 10,
      });
    });
  });

  describe('visual state', () => {
    it('Given container rendered When component is created Then should match snapshot', () => {
      expect(fixture).toMatchSnapshot();
    });
  });
});
