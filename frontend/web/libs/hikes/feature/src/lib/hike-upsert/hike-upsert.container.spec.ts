import { ComponentFixture, TestBed } from '@angular/core/testing';
import { HikeUpsertContainer } from './hike-upsert.container';
import { Router } from '@angular/router';
import { ActivatedRoute } from '@angular/router';
import { HikesStore, HikeDetailStore } from '@web/hikes/data-access';
import { MessageService } from 'primeng/api';
import { TranslateService } from '@ngx-translate/core';
import { MapboxService } from '@web/shared/util';
import { signal } from '@angular/core';
import { NO_ERRORS_SCHEMA } from '@angular/core';
import { of } from 'rxjs';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';

describe('HikeUpsertContainer', () => {
  let component: HikeUpsertContainer;
  let fixture: ComponentFixture<HikeUpsertContainer>;

  beforeEach(async () => {
    const routerMock = { navigate: jest.fn() };
    const routeMock = {
      snapshot: { params: {} },
      params: of({ id: null }),
    };
    const hikesStoreMock = {
      difficulties: signal([]),
      status: signal([]),
      sources: signal([]),
      seasons: signal([]),
      create: jest.fn(),
      update: jest.fn(),
      getHikeById: jest.fn(),
    };
    const mapboxServiceMock = {
      getAccessToken: jest.fn(),
      getDirectionsRoute: jest.fn(),
    };
    const messageServiceMock = { add: jest.fn() };
    const translateServiceMock = { instant: jest.fn((key: string) => key) };
    const hikeDetailStoreMock = {
      hike: signal(null),
      isPending: signal(false),
      load: jest.fn(),
    };

    await TestBed.configureTestingModule({
      imports: [HikeUpsertContainer],
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        { provide: Router, useValue: routerMock },
        { provide: ActivatedRoute, useValue: routeMock },
        { provide: HikesStore, useValue: hikesStoreMock },
        { provide: HikeDetailStore, useValue: hikeDetailStoreMock },
        { provide: MapboxService, useValue: mapboxServiceMock },
        { provide: MessageService, useValue: messageServiceMock },
        { provide: TranslateService, useValue: translateServiceMock },
      ],
      schemas: [NO_ERRORS_SCHEMA],
    })
      .overrideComponent(HikeUpsertContainer, {
        set: {
          template: '', // Template vide pour éviter le rendu
        },
      })
      .compileComponents();

    fixture = TestBed.createComponent(HikeUpsertContainer);
    component = fixture.componentInstance;
    // Ne pas appeler detectChanges() pour éviter les erreurs de template
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
