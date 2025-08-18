import { HttpErrorResponse } from '@angular/common/http';

export interface ILogInfo {
  userId: string;
  date: Date;
  type: 'log' | 'http-error';
  params: HttpErrorResponse;
}

export interface ILogError {
  userId: string;
  date: Date;
  type: 'log' | 'http-error';
  params: HttpErrorResponse;
}
