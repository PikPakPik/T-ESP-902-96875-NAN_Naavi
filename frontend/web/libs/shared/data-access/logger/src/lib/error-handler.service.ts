import { NotificationService } from '@web/ui/notification';
import { ErrorHandler, Inject, Injectable, Injector } from '@angular/core';

import { HttpErrorResponse } from '@angular/common/http';
import { LoggerService } from './logger.service';
import { TranslateService } from '@ngx-translate/core';

@Injectable()
export class GlobalErrorHandler implements ErrorHandler {
  private _httpErrorMessage: string | null = null;

  // Have to do this to avoid circular dependency with Notification Service
  // because of calls of ApplicationRef && RendererFactory2 in constructor
  // method to resolve founded in https://github.com/ngneat/hot-toast/issues/70
  private get _notification() {
    return this._injector.get(NotificationService);
  }

  constructor(
    private readonly _loggerService: LoggerService,
    private readonly _translateSrv: TranslateService,
    @Inject(Injector) private readonly _injector: Injector
  ) {
    this._httpErrorMessage = this._translateSrv.instant(
      'ERROR_HANDLER.HTTP_ERROR.MESSAGE'
    );
  }

  handleError(error: Error | HttpErrorResponse) {
    if (error instanceof HttpErrorResponse) {
      this._notification.open(this._httpErrorMessage || '', '', 'warn', {
        duration: 5000,
      });
      this._loggerService.log_error({
        date: new Date(),
        type: 'http-error',
        params: error,
      });
    } else {
      this._loggerService.log_error({
        date: new Date(),
        type: 'code-based',
        params: error,
      });
    }
  }
}
