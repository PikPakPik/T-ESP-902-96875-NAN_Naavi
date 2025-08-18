import { APP_BASE_HREF, PlatformLocation } from '@angular/common';
import { inject, DOCUMENT } from '@angular/core';


export function getBaseUrl(): string {
  // Vérifier si nous sommes dans un environnement navigateur
  if (typeof document !== 'undefined') {
    const uri = document.getElementsByTagName('base')[0]?.baseURI;
    return uri?.endsWith('/') ? uri : `${uri}/`;
  }

  // Fallback pour SSR - retourner une valeur par défaut
  return '/';
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

// Alternative plus robuste utilisant l'injection de dépendances Angular
export function getBaseUrlWithDocument(): string {
  const document = inject(DOCUMENT);
  const uri = document.getElementsByTagName('base')[0]?.baseURI;
  return uri?.endsWith('/') ? uri : `${uri}/`;
}
