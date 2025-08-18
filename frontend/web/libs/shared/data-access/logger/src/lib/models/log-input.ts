import { HttpErrorResponse } from '@angular/common/http'

export interface ILogDebug {
    date: Date
    params: string
}

export interface ILogWarn {
    date: Date
    where: string
    message: string
    params: any
}

export interface ILogError {
    date: Date
    type: 'http-error' | 'code-based'
    params: HttpErrorResponse | any
}
