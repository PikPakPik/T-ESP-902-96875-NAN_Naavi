import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';

@Injectable({
  providedIn: 'root',
})
export class LoadingService {
  #loadingSubject = new BehaviorSubject<boolean>(true);
  public loading$: Observable<boolean> = this.#loadingSubject.asObservable();

  show() {
    this.#loadingSubject.next(true);
  }

  hide() {
    this.#loadingSubject.next(false);
  }

  get isLoading(): boolean {
    return this.#loadingSubject.value;
  }
}
