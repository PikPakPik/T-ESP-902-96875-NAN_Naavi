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
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
