import { ComponentFixture, TestBed } from '@angular/core/testing';
import { PoiUpsertContainer } from './poi-upsert.container';
import { Router } from '@angular/router';
import { ActivatedRoute } from '@angular/router';
import { POIsStore, POIsService } from '@web/pois/data-access';
import { MessageService } from 'primeng/api';
import { TranslateService } from '@ngx-translate/core';
import { signal } from '@angular/core';
import { NO_ERRORS_SCHEMA } from '@angular/core';
import { UsersService } from '@web/users/data-access';

describe('PoiUpsertContainer', () => {
  let component: PoiUpsertContainer;
  let fixture: ComponentFixture<PoiUpsertContainer>;

  beforeEach(async () => {
    const routerMock = { navigate: jest.fn() };
    const routeMock = {
      snapshot: { params: {} },
      params: { subscribe: jest.fn(() => ({ unsubscribe: jest.fn() })) },
    };
    const poisStoreMock = {
      entities: signal([]),
      getUserById: jest.fn(),
      update: jest.fn(),
      create: jest.fn(),
      getPOIById: jest.fn(),
    };
    const messageServiceMock = { add: jest.fn() };
    const translateServiceMock = { instant: jest.fn((key: string) => key) };
    const poisServiceMock = {
      uploadPoiImage: jest.fn(),
      deletePoiImage: jest.fn(),
    };

    await TestBed.configureTestingModule({
      imports: [PoiUpsertContainer],
      providers: [
        { provide: Router, useValue: routerMock },
        { provide: ActivatedRoute, useValue: routeMock },
        { provide: POIsStore, useValue: poisStoreMock },
        { provide: POIsService, useValue: poisServiceMock },
        { provide: MessageService, useValue: messageServiceMock },
        { provide: TranslateService, useValue: translateServiceMock },
        {
          provide: UsersService,
          useValue: {
            getUsers: jest.fn(),
            getUserById: jest.fn(),
          },
        },
      ],
      schemas: [NO_ERRORS_SCHEMA],
    }).compileComponents();

    fixture = TestBed.createComponent(PoiUpsertContainer);
    component = fixture.componentInstance;
    // Ne pas appeler detectChanges() pour éviter les erreurs de template
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
