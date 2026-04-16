import { TestBed } from '@angular/core/testing';
import { ActivatedRoute, Router } from '@angular/router';
import { BehaviorSubject } from 'rxjs';
import { signalStore } from '@ngrx/signals';
import { withQueryParams } from './query-params.feature';

const queryParams$ = new BehaviorSubject<Record<string, string | string[]>>({});
const navigate = jest.fn();

const QueryParamsStore = signalStore(
  withQueryParams({
    page: (param) =>
      Array.isArray(param) ? Number.parseInt(param[0], 10) : param ? Number.parseInt(param, 10) : null,
    search: (param) => (Array.isArray(param) ? param[0] : param ?? null),
  })
);

describe('withQueryParams', () => {
  let store: InstanceType<typeof QueryParamsStore>;

  beforeEach(() => {
    queryParams$.next({});
    navigate.mockReset();

    TestBed.configureTestingModule({
      providers: [
        QueryParamsStore,
        {
          provide: ActivatedRoute,
          useValue: {
            queryParams: queryParams$.asObservable(),
          },
        },
        {
          provide: Router,
          useValue: {
            navigate,
          },
        },
      ],
    });

    store = TestBed.inject(QueryParamsStore);
  });

  it('returns null defaults when query params are absent', () => {
    expect(store.page()).toBeNull();
    expect(store.search()).toBeNull();
  });

  it('maps query params through the provided config', () => {
    queryParams$.next({ page: '3', search: ['alps', 'ignored'] });

    expect(store.page()).toBe(3);
    expect(store.search()).toBe('alps');
  });

  it('exposes update methods that merge query params in the router', () => {
    store.updatePage(5);
    store.updateSearch('vosges');

    expect(navigate).toHaveBeenNthCalledWith(1, [], {
      queryParams: { page: 5 },
      queryParamsHandling: 'merge',
    });
    expect(navigate).toHaveBeenNthCalledWith(2, [], {
      queryParams: { search: 'vosges' },
      queryParamsHandling: 'merge',
    });
  });
});
