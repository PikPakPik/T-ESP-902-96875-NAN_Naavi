import { Injectable } from '@angular/core';

/**
 * LocalStorageService
 * Service to manage localStorage, SSR compatible
 *
 * @example
 * const localStorage = inject(LocalStorageService);
 * localStorage.setItem('key', 'value');
 * localStorage.getItem<string>('key');
 * localStorage.removeItem('key');
 * localStorage.clear();
 */
@Injectable({
  providedIn: 'root',
})
export class LocalStorageService {
  /**
   * Set an item in localStorage
   * @param key Storage key
   * @param value Value to store
   */
  setItem(key: string, value: unknown): void {
    localStorage.setItem(key, JSON.stringify(value));
  }

  /**
   * Get an item from localStorage
   * @param key Storage key
   * @returns The stored value or null if not found
   */
  getItem<T>(key: string): T | null {
    const item = localStorage.getItem(key);
    return item ? JSON.parse(item) : null;
  }

  /**
   * Remove an item from localStorage
   * @param key Storage key
   */
  removeItem(key: string): void {
    localStorage.removeItem(key);
  }

  /**
   * Clear all items from localStorage
   */
  clear(): void {
    localStorage.clear();
  }
}
