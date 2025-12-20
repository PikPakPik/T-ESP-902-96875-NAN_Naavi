import { HttpBackend, HttpClient } from '@angular/common/http';
import { TranslationObject, TranslateLoader } from '@ngx-translate/core';
import { deepmerge } from 'deepmerge-ts';
import { forkJoin, Observable, of } from 'rxjs';
import { catchError, map } from 'rxjs/operators';

export interface ITranslationResource {
  prefix: string;
  suffix?: string;
  optional?: boolean;
}

export class MultiTranslateHttpLoader implements TranslateLoader {
  constructor(
    private _handler: HttpBackend,
    private _resourcesPrefix: string[] | ITranslationResource[]
  ) {}

  public getTranslation(lang: string): Observable<TranslationObject> {
    const requests: Observable<object>[] = this._resourcesPrefix.map(
      (resource) => {
        let path: string;
        if ((<ITranslationResource>resource).prefix)
          path = `${(<ITranslationResource>resource).prefix}${lang}${
            (<ITranslationResource>resource).suffix || '.json'
          }`;
        else path = `${<string>resource}${lang}.json`;

        return new HttpClient(this._handler).get(path).pipe(
          catchError((res) => {
            if (!(<ITranslationResource>resource).optional) {
              console.group();
              console.error(
                'Something went wrong for the following translation file:',
                path
              );
              console.error(res);
              console.groupEnd();
            }
            return of({});
          })
        );
      }
    );

    return forkJoin(requests).pipe(
      map((response) => deepmerge(...response))
    ) as Observable<TranslationObject>;
  }
}

export function HttpLoaderFactory(_httpBackend: HttpBackend) {
  return new MultiTranslateHttpLoader(_httpBackend, ['/assets/i18n/']);
}
