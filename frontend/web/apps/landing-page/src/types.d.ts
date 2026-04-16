interface ImportMetaEnv {
  /**
   * Cloudflare Turnstile site key for bot protection.
   * Required for authentication forms.
   */
  readonly VITE_TURNSTILE_SITE_KEY?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
