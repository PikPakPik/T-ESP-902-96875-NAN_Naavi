import { LocalStorageService } from '@web/shared/util';
import { ILogError, ILogDebug, ILogWarn } from './models/log-input';
import { inject, Inject, Injectable } from '@angular/core';
import { ConsoleLoggerService } from './console.logger.service';
import { LogLevel } from './models/log-level';

@Injectable({ providedIn: 'root' })
export class LoggerService {
  private _level: LogLevel | null = null;
  private localStorage = inject(LocalStorageService);
  constructor(
    private readonly _srv: ConsoleLoggerService,
    @Inject('LOG_LEVEL') logLevel: LogLevel
  ) {
    this._level = logLevel || LogLevel.None;

    // Init the LocalStorage
    const storage_logs = JSON.parse(this.localStorage.getItem('logs') ?? '[]');
    if (!storage_logs) this.localStorage.setItem('logs', '[]');
  }

  log_error(payload: ILogError): void {
    this.update_storage(payload);
    this._srv.log_error(payload);
  }

  log_warning(payload: ILogWarn): void {
    if (!this.currentLogLevelIsEqualOrSmallerThan(LogLevel.Warn)) return;
    this.update_storage(payload);
    this._srv.log_warning(payload);
  }

  log_debug(payload: ILogDebug): void {
    if (!this.currentLogLevelIsEqualOrSmallerThan(LogLevel.Debug)) return;
    this.update_storage(payload);
    this._srv.log_debug(payload);
  }

  private update_storage(payload: ILogError | ILogDebug | ILogWarn) {
    const storage_logs = JSON.parse(this.localStorage.getItem('logs') ?? '[]');
    const log =
      payload.params instanceof Error
        ? payload.params.toString()
        : { ...payload, params: JSON.stringify(payload.params) };

    this.localStorage.setItem('logs', JSON.stringify([...storage_logs, log]));
  }

  private currentLogLevelIsEqualOrSmallerThan(
    logLevelToCompare: LogLevel
  ): boolean {
    return (this._level ?? LogLevel.None) <= logLevelToCompare;
  }
}
