import {
  HttpEvent,
  HttpHandler,
  HttpInterceptor,
  HttpRequest,
} from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { finalize } from 'rxjs/operators';
import { LoaderService } from '../services/loader.service';

@Injectable()
export class LoaderInterceptor implements HttpInterceptor {
  private _loaderService = inject(LoaderService);
  intercept(
    request: HttpRequest<unknown>,
    next: HttpHandler
  ): Observable<HttpEvent<unknown>> {
    if (
      (request.method === 'GET' && request.url.includes('jwks')) ||
      (request.method === 'POST' && request.url.includes('token'))
    ) {
      return next.handle(request);
    }

    this._loaderService.show();
    console.log('LoaderInterceptor');

    return next
      .handle(request)
      .pipe(finalize(() => this._loaderService.hide()));
  }
}
