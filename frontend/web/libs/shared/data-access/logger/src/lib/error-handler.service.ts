import { NotificationService } from '@web/shared/ui/notification';
import { ErrorHandler, inject, Injectable, Injector } from '@angular/core';

import { HttpErrorResponse } from '@angular/common/http';
import { LoggerService } from './logger.service';
import { TranslateService } from '@ngx-translate/core';

@Injectable()
export class GlobalErrorHandler implements ErrorHandler {
  #_httpErrorMessage: string | null = null;
  readonly #injector = inject(Injector);
  readonly #loggerService = inject(LoggerService);
  readonly #translateService = inject(TranslateService);

  // Have to do this to avoid circular dependency with Notification Service
  // because of calls of ApplicationRef && RendererFactory2 in constructor
  // method to resolve founded in https://github.com/ngneat/hot-toast/issues/70
  get #_notification(): NotificationService {
    return this.#injector.get(NotificationService);
  }

  constructor() {
    this.#_httpErrorMessage = this.#translateService.instant(
      'ERROR_HANDLER.HTTP_ERROR.MESSAGE'
    );
  }

  handleError(error: Error | HttpErrorResponse) {
    if (error instanceof HttpErrorResponse) {
      this.#_notification.open(this.#_httpErrorMessage || '', '', 'warn', {
        duration: 5000,
      });
      this.#loggerService.log_error({
        date: new Date(),
        type: 'http-error',
        params: error,
      });
    } else {
      this.#loggerService.log_error({
        date: new Date(),
        type: 'code-based',
        params: error,
      });
    }
  }
}
