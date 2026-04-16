interface ImportMetaEnv {
  /**
   * Mapbox access token for map rendering and API calls.
   * Optional - application will work without it but map features will be disabled.
   */
  readonly VITE_MAPBOX_TOKEN?: string;
  /**
   * Cloudflare Turnstile site key for bot protection.
   * Required for authentication forms.
   */
  readonly VITE_TURNSTILE_SITE_KEY?: string;
  /**
   * Base URL for S3/MinIO images (e.g. profile pictures). Path is appended.
   * Must be prefixed with VITE_ to be exposed by Vite.
   */
  readonly VITE_IMAGES_BASE_URL?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
