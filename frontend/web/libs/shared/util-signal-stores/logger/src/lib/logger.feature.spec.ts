import { TestBed } from '@angular/core/testing';
import { patchState, signalStore, withMethods, withState } from '@ngrx/signals';
import { withLogger } from './logger.feature';

const LoggerStore = signalStore(
  withState({ count: 0 }),
  withLogger('Counter'),
  withMethods((store) => ({
    increment() {
      patchState(store, { count: store.count() + 1 });
    },
  }))
);

describe('withLogger', () => {
  let store: InstanceType<typeof LoggerStore>;
  let consoleSpy: jest.SpyInstance;

  beforeEach(() => {
    consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => undefined);

    TestBed.configureTestingModule({
      providers: [LoggerStore],
    });

    store = TestBed.inject(LoggerStore);
    TestBed.flushEffects();
  });

  afterEach(() => {
    consoleSpy.mockRestore();
  });

  it('logs the initial and updated state', () => {
    expect(consoleSpy).toHaveBeenCalledWith(
      '%c[Store - Counter]',
      'color: #007598; font-weight: bold;',
      expect.objectContaining({ count: 0 })
    );

    store.increment();
    TestBed.flushEffects();

    expect(consoleSpy).toHaveBeenLastCalledWith(
      '%c[Store - Counter]',
      'color: #007598; font-weight: bold;',
      expect.objectContaining({ count: 1 })
    );
  });
});
