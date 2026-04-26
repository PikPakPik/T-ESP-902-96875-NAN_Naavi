/**
 * When the API stores an external URL inside the S3-style key
 * (e.g. `points_of_interest/8/https://images.unsplash.com/...`),
 * return that absolute URL instead of prefixing the images base URL.
 */
function absoluteUrlEmbeddedInPath(raw: string): string | null {
  const httpsIdx = raw.indexOf('https://');
  if (httpsIdx > 0) {
    return raw.slice(httpsIdx);
  }
  const httpIdx = raw.indexOf('http://');
  if (httpIdx > 0) {
    return raw.slice(httpIdx);
  }
  return null;
}

/**
 * Builds a display URL for Naavi media (same idea as Flutter
 * [NaaviImageUrl.build] / [displayUrlFromApiImagesListItem]).
 *
 * - Absolute `http(s)://` → unchanged
 * - Key embedding `https://` / `http://` → use the embedded URL
 * - Otherwise → `{imagesBaseUrl}/{path}`
 */
export function naaviMediaDisplayUrl(
  path: string | null | undefined,
  imagesBaseUrl: string | null | undefined
): string | null {
  const p = path?.trim();
  if (!p) {
    return null;
  }
  if (p.startsWith('http://') || p.startsWith('https://')) {
    return p;
  }
  const embedded = absoluteUrlEmbeddedInPath(p);
  if (embedded) {
    return embedded;
  }
  const base = imagesBaseUrl?.trim().replace(/\/$/, '') ?? '';
  if (!base) {
    return null;
  }
  const cleanPath = p.replace(/^\//, '');
  return `${base}/${cleanPath}`;
}
