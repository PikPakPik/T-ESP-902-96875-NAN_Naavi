// This file can be replaced during build by using the `fileReplacements` array.
// `ng build` replaces `environment.ts` with `environment.dev.ts` or `environment.prod.ts`.
// The list of file replacements can be found in `project.json`.

export const environment = {
  production: false,
  api_url: 'https://backoffice.localhost/api/v1/',
  /** Base URL for S3/MinIO images (profile pictures). Override via VITE_IMAGES_BASE_URL in .env */
  images_base_url: 'https://s3.naavi.local/naavi-images',
  mock: false,
};

/*
 * For easier debugging in development mode, you can import the following file
 * to ignore zone related error stack frames such as `zone.run`, `zoneDelegate.invokeTask`.
 *
 * This import should be commented out in production mode because it will have a negative impact
 * on performance if an error is thrown.
 */
