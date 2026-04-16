import { TestBed } from '@angular/core/testing';
import { patchState, signalStore } from '@ngrx/signals';
import { setAllEntities, withEntities } from '@ngrx/signals/entities';
import { withSelectedEntity } from './selected-entity.feature';

type TestEntity = { id: string; name: string };

const SelectedEntityStore = signalStore(
  withEntities<TestEntity>(),
  withSelectedEntity<TestEntity>()
);

describe('withSelectedEntity', () => {
  let store: InstanceType<typeof SelectedEntityStore>;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [SelectedEntityStore],
    });

    store = TestBed.inject(SelectedEntityStore);
    patchState(
      store,
      setAllEntities([
        { id: '1', name: 'First' },
        { id: '2', name: 'Second' },
      ])
    );
  });

  it('returns null when no entity is selected', () => {
    expect(store.selectedEntityId()).toBeNull();
    expect(store.selectedEntity()).toBeNull();
  });

  it('returns the selected entity when an id is provided', () => {
    store.selectEntity('2');

    expect(store.selectedEntityId()).toBe('2');
    expect(store.selectedEntity()).toEqual({ id: '2', name: 'Second' });
  });

  it('clears the selection when null or undefined is provided', () => {
    store.selectEntity('1');
    store.selectEntity(null);

    expect(store.selectedEntityId()).toBeNull();
    expect(store.selectedEntity()).toBeNull();

    store.selectEntity(undefined);

    expect(store.selectedEntityId()).toBeUndefined();
    expect(store.selectedEntity()).toBeNull();
  });
});
