import { ILogDebug, ILogError, ILogWarn } from './models/log-input'

import { Injectable } from '@angular/core'

// Implement this class-interface to create a custom logger service.
@Injectable()
export abstract class AbstractLoggerService {
    abstract log_error(payload: ILogError): void
    abstract log_warning(payload: ILogWarn): void
    abstract log_debug(payload: ILogDebug): void
}
