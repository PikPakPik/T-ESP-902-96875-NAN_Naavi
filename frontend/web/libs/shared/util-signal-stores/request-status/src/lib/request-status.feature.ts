import { computed } from '@angular/core';
import { signalStoreFeature, withComputed, withState } from '@ngrx/signals';

export type RequestStatus = 'idle' | 'pending' | 'fulfilled' | 'error';

export type RequestStatusState = {
  requestStatus: RequestStatus;
  error: string | null;
};

export function withRequestStatus() {
  return signalStoreFeature(
    withState<RequestStatusState>({ requestStatus: 'idle', error: null }),
    withComputed(({ requestStatus }) => ({
      isPending: computed(() => requestStatus() === 'pending'),
      isFulfilled: computed(() => requestStatus() === 'fulfilled'),
    }))
  );
}

export function setPending(): RequestStatusState {
  return { requestStatus: 'pending', error: null };
}

export function setFulfilled(): RequestStatusState {
  return { requestStatus: 'fulfilled', error: null };
}

export function setError(error: string): RequestStatusState {
  return { requestStatus: 'error', error };
}
