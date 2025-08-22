import { Signal } from '@angular/core';

export type ParamsConfig<T> = Record<string, (param: T | undefined) => unknown>;

export class ParamsConfigClass {
  static asString(param: string | string[] | undefined) {
    return Array.isArray(param) ? param[0] : param ?? null;
  }
  static asStringArray(param: string | string[] | undefined) {
    return Array.isArray(param) ? param : param ? [param] : null;
  }
  static asBoolean(param: string | string[] | undefined) {
    return Array.isArray(param)
      ? param[0] === 'true'
      : param === 'true'
      ? true
      : null;
  }
  static asNumber(param: string | string[] | undefined) {
    return Array.isArray(param)
      ? parseInt(param[0])
      : param
      ? parseInt(param)
      : null;
  }
  static asNumberArray(param: string | string[] | undefined) {
    return Array.isArray(param)
      ? param.map((p) => parseInt(p))
      : param
      ? [parseInt(param)]
      : null;
  }
  static asDate(param: string | string[] | undefined) {
    return Array.isArray(param)
      ? new Date(param[0])
      : param
      ? new Date(param)
      : null;
  }
  static asDateArray(param: string | string[] | undefined) {
    return Array.isArray(param)
      ? param.map((p) => new Date(p))
      : param
      ? [new Date(param)]
      : null;
  }
  static asObject(param: string | string[] | undefined) {
    return Array.isArray(param)
      ? JSON.parse(param[0])
      : param
      ? JSON.parse(param)
      : null;
  }
  static asArray(param: string | string[] | undefined): string[] | null {
    return Array.isArray(param) ? param : param ? [param] : null;
  }
}

export type ParamsComputed<Config extends ParamsConfig<string>> = {
  [Key in keyof Config]: Config[Key] extends infer TransformFn
    ? TransformFn extends (...args: unknown[]) => unknown
      ? Signal<ReturnType<TransformFn>>
      : never
    : never;
};
