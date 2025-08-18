import { effect } from '@angular/core';
import { getState, signalStoreFeature, withHooks } from '@ngrx/signals';

export function withLogger(_name: string) {
  return signalStoreFeature(
    withHooks({
      onInit(_store) {
        effect(() => {
          const state = getState(_store);
          console.log(
            `%c[Store - ${_name}]`,
            'color: #007598; font-weight: bold;',
            state
          );
        });
      },
    })
  );
}
