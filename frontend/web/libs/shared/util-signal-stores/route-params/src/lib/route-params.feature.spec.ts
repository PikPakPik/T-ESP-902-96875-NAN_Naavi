import { TestBed } from '@angular/core/testing';
import { ActivatedRoute } from '@angular/router';
import { BehaviorSubject } from 'rxjs';
import { signalStore } from '@ngrx/signals';
import { withRouteParams } from './route-params.feature';

const params$ = new BehaviorSubject<Record<string, string | string[]>>({});

const RouteParamsStore = signalStore(
  withRouteParams({
    id: (param) => (Array.isArray(param) ? param[0] : param ?? null),
    tags: (param) => (Array.isArray(param) ? param : param ? [param] : null),
  })
);

describe('withRouteParams', () => {
  let store: InstanceType<typeof RouteParamsStore>;

  beforeEach(() => {
    params$.next({});

    TestBed.configureTestingModule({
      providers: [
        RouteParamsStore,
        {
          provide: ActivatedRoute,
          useValue: {
            params: params$.asObservable(),
          },
        },
      ],
    });

    store = TestBed.inject(RouteParamsStore);
  });

  it('returns null defaults when route params are absent', () => {
    expect(store.id()).toBeNull();
    expect(store.tags()).toBeNull();
  });

  it('maps scalar route params', () => {
    params$.next({ id: '42', tags: 'easy' });

    expect(store.id()).toBe('42');
    expect(store.tags()).toEqual(['easy']);
  });

  it('maps array route params', () => {
    params$.next({ id: ['99', '100'], tags: ['forest', 'river'] });

    expect(store.id()).toBe('99');
    expect(store.tags()).toEqual(['forest', 'river']);
  });
});
