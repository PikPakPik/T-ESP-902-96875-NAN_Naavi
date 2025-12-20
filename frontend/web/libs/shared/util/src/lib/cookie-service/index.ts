export type CookieOptions = {
  path?: string;
  domain?: string;
  secure?: boolean;
  sameSite?: 'Lax' | 'Strict' | 'None';
  maxAgeSeconds?: number;
};

export function setCookie(
  name: string,
  value: string,
  options: CookieOptions = {}
): void {
  const parts: string[] = [
    `${encodeURIComponent(name)}=${encodeURIComponent(value)}`,
  ];
  if (options.maxAgeSeconds != null)
    parts.push(`Max-Age=${options.maxAgeSeconds}`);
  if (options.path) parts.push(`Path=${options.path}`);
  if (options.domain) parts.push(`Domain=${options.domain}`);
  if (options.sameSite) parts.push(`SameSite=${options.sameSite}`);
  if (options.secure) parts.push('Secure');
  document.cookie = parts.join('; ');
}

export function getCookie(name: string): string | null {
  const cookies = document.cookie ? document.cookie.split('; ') : [];
  for (const c of cookies) {
    const [k, v] = c.split('=');
    if (decodeURIComponent(k) === name) {
      return decodeURIComponent(v ?? '');
    }
  }
  return null;
}

export function deleteCookie(name: string, options: CookieOptions = {}): void {
  setCookie(name, '', { ...options, maxAgeSeconds: 0 });
}

export const ACCESS_TOKEN_COOKIE = 'access_token';
export const REFRESH_TOKEN_COOKIE = 'refresh_token';
