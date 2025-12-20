import { APP_BASE_HREF, PlatformLocation } from '@angular/common';
import { inject } from '@angular/core';

export function getBaseUrl(): string {
  const uri = document.getElementsByTagName('base')[0]?.baseURI;
  return uri?.endsWith('/') ? uri : `${uri}/`;
}

export function getBaseHref(): string {
  const baseHref = inject(APP_BASE_HREF);
  return baseHref.startsWith('/') ? baseHref.slice(1) : baseHref;
}

export function getPlatformBaseHref(
  platformLocation: PlatformLocation
): string {
  return platformLocation.getBaseHrefFromDOM();
}
