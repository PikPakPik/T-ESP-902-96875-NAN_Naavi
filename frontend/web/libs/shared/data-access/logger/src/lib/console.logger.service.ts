import { ILogDebug, ILogError, ILogWarn } from './models/log-input'

import { AbstractLoggerService } from './abstract-logger.service'
import { Injectable } from '@angular/core'

@Injectable({ providedIn: 'root' })
export class ConsoleLoggerService implements AbstractLoggerService {
    log_error(payload: ILogError): void {
        console.error(payload)
    }

    log_warning({ message, where }: ILogWarn): void {
        console.warn(where, message)
    }

    log_debug(payload: ILogDebug): void {
        console.debug(payload)
    }
}
