import { inject } from '@angular/core';
import { Hike } from '@web/shared/models/settings';
import {
  patchState,
  signalStore,
  withState,
  withMethods,
  withHooks,
} from '@ngrx/signals';
import { withLogger } from '@web/shared/util/signal-stores/logger';
import { withDevtools } from '@angular-architects/ngrx-toolkit';
import { lastValueFrom } from 'rxjs';
import { HikesService } from '../services/hikes.service';
import {
  setError,
  setFulfilled,
  setPending,
  withRequestStatus,
} from '@web/shared/util/signal-stores/request-status';
import { withRouteParams } from '@web/shared/util/signal-stores/route-params';
import { ParamsConfigClass } from '@web/shared/util/signal-stores';

export interface HikeDetailState {
  hike: Hike | null;
}

export const initialState: HikeDetailState = {
  hike: null,
};

export const HikeDetailStore = signalStore(
  withState(initialState),
  withLogger('HikeDetail'),
  withDevtools('HikeDetail'),
  withRequestStatus(),
  withRouteParams({
    id: (param) => ParamsConfigClass.asString(param),
  }),
  withMethods((store, hikesService = inject(HikesService)) => ({
    async loadHike(id: string): Promise<void> {
      patchState(store, setPending());
      try {
        const hike = await lastValueFrom(hikesService.getHikeById(id));
        patchState(store, { hike: hike || null }, setFulfilled());
      } catch (error: unknown) {
        patchState(store, { hike: null }, setError(error as string));
      }
    },
  })),
  withHooks({
    onInit(store) {
      const id = store.id();
      if (id) {
        store.loadHike(id);
      }
    },
  })
);
