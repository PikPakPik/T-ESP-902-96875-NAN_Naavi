import { InjectionToken } from '@angular/core';

export const API_URL = new InjectionToken<string>('API_URL');

/** Base URL for S3/MinIO images (e.g. profile pictures). Path is appended. */
export const IMAGES_BASE_URL = new InjectionToken<string>('IMAGES_BASE_URL');
