import { LocalStorageService } from '@web/shared/util';
import { ILogError, ILogDebug, ILogWarn } from './models/log-input';
import { inject, Injectable, InjectionToken } from '@angular/core';
import { ConsoleLoggerService } from './console.logger.service';
import { LogLevel } from './models/log-level';

export const LOG_LEVEL_TOKEN = new InjectionToken<LogLevel>('LOG_LEVEL');

@Injectable({ providedIn: 'root' })
export class LoggerService {
  #_level: LogLevel | null = null;
  #localStorage = inject(LocalStorageService);
  readonly #consoleLogger = inject(ConsoleLoggerService);
  readonly #logLevel = inject(LOG_LEVEL_TOKEN);

  constructor() {
    this.#_level = (this.#logLevel as LogLevel) || LogLevel.None;

    // Init the LocalStorage
    const storage_logs = JSON.parse(this.#localStorage.getItem('logs') ?? '[]');
    if (!storage_logs) this.#localStorage.setItem('logs', '[]');
  }

  log_error(payload: ILogError): void {
    this.#update_storage(payload);
    this.#consoleLogger.log_error(payload);
  }

  log_warning(payload: ILogWarn): void {
    if (!this.#currentLogLevelIsEqualOrSmallerThan(LogLevel.Warn)) return;
    this.#update_storage(payload);
    this.#consoleLogger.log_warning(payload);
  }

  log_debug(payload: ILogDebug): void {
    if (!this.#currentLogLevelIsEqualOrSmallerThan(LogLevel.Debug)) return;
    this.#update_storage(payload);
    this.#consoleLogger.log_debug(payload);
  }

  #update_storage(payload: ILogError | ILogDebug | ILogWarn) {
    const storage_logs = JSON.parse(this.#localStorage.getItem('logs') ?? '[]');
    const log =
      payload.params instanceof Error
        ? payload.params.toString()
        : { ...payload, params: JSON.stringify(payload.params) };

    this.#localStorage.setItem('logs', JSON.stringify([...storage_logs, log]));
  }

  #currentLogLevelIsEqualOrSmallerThan(logLevelToCompare: LogLevel): boolean {
    return (this.#_level ?? LogLevel.None) <= logLevelToCompare;
  }
}
