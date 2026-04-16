import { TestBed } from '@angular/core/testing';
import { patchState, signalStore } from '@ngrx/signals';
import {
  setError,
  setFulfilled,
  setPending,
  withRequestStatus,
} from './request-status.feature';

const RequestStatusStore = signalStore(withRequestStatus());

describe('withRequestStatus', () => {
  let store: InstanceType<typeof RequestStatusStore>;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [RequestStatusStore],
    });

    store = TestBed.inject(RequestStatusStore);
  });

  it('initializes with an idle state', () => {
    expect(store.requestStatus()).toBe('idle');
    expect(store.error()).toBeNull();
    expect(store.isPending()).toBe(false);
    expect(store.isFulfilled()).toBe(false);
  });

  it('marks the store as pending', () => {
    patchState(store, setPending());

    expect(store.requestStatus()).toBe('pending');
    expect(store.error()).toBeNull();
    expect(store.isPending()).toBe(true);
    expect(store.isFulfilled()).toBe(false);
  });

  it('marks the store as fulfilled', () => {
    patchState(store, setFulfilled());

    expect(store.requestStatus()).toBe('fulfilled');
    expect(store.error()).toBeNull();
    expect(store.isPending()).toBe(false);
    expect(store.isFulfilled()).toBe(true);
  });

  it('marks the store as failed with an error message', () => {
    patchState(store, setError('boom'));

    expect(store.requestStatus()).toBe('error');
    expect(store.error()).toBe('boom');
    expect(store.isPending()).toBe(false);
    expect(store.isFulfilled()).toBe(false);
  });
});
