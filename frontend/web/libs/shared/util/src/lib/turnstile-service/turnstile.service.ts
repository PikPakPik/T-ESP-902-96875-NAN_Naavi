import { Injectable, InjectionToken, inject } from '@angular/core';

export const TURNSTILE_SITE_KEY = new InjectionToken<string>(
  'TURNSTILE_SITE_KEY'
);

declare global {
  interface Window {
    turnstile: {
      render: (
        element: HTMLElement | string,
        options: {
          sitekey: string;
          callback?: (token: string) => void;
          'error-callback'?: (error: string) => void;
          'expired-callback'?: () => void;
          theme?: 'light' | 'dark' | 'auto';
          size?: 'normal' | 'compact';
        }
      ) => string;
      reset: (widgetId?: string) => void;
      remove: (widgetId: string) => void;
    };
  }
}

@Injectable({
  providedIn: 'root',
})
export class TurnstileService {
  private siteKey = inject(TURNSTILE_SITE_KEY);
  private widgetIds: Map<string, string> = new Map();

  /**
   * Renders a Turnstile widget and returns the widget ID
   * @param elementId The ID of the HTML element where Turnstile should be rendered
   * @param onSuccess Callback when a token is received
   * @param onError Callback when an error occurs
   * @param onExpired Callback when the token expires
   * @param theme Theme for the widget ('light', 'dark', or 'auto')
   * @param size Size of the widget ('normal' or 'compact')
   * @returns The widget ID
   */
  render(
    elementId: string,
    onSuccess?: (token: string) => void,
    onError?: (error: string) => void,
    onExpired?: () => void,
    theme: 'light' | 'dark' | 'auto' = 'auto',
    size: 'normal' | 'compact' = 'compact'
  ): string | null {
    if (!this.siteKey) {
      console.error('Turnstile site key is not configured');
      return null;
    }

    if (typeof window === 'undefined' || !window.turnstile) {
      console.error('Turnstile script is not loaded');
      return null;
    }

    const element = document.getElementById(elementId);
    if (!element) {
      console.error(`Element with ID ${elementId} not found`);
      return null;
    }

    // Remove existing widget if any
    const existingWidgetId = this.widgetIds.get(elementId);
    if (existingWidgetId) {
      this.remove(elementId);
    }

    const widgetId = window.turnstile.render(element, {
      sitekey: this.siteKey,
      callback: (token: string) => {
        if (onSuccess) {
          onSuccess(token);
        }
      },
      'error-callback': (error: string) => {
        if (onError) {
          onError(error);
        }
      },
      'expired-callback': () => {
        if (onExpired) {
          onExpired();
        }
      },
      theme,
      size,
    });

    this.widgetIds.set(elementId, widgetId);
    return widgetId;
  }

  /**
   * Resets a Turnstile widget
   * @param elementId The ID of the element where the widget was rendered
   */
  reset(elementId: string): void {
    const widgetId = this.widgetIds.get(elementId);
    if (widgetId && window.turnstile) {
      window.turnstile.reset(widgetId);
    }
  }

  /**
   * Removes a Turnstile widget
   * @param elementId The ID of the element where the widget was rendered
   */
  remove(elementId: string): void {
    const widgetId = this.widgetIds.get(elementId);
    if (widgetId && window.turnstile) {
      window.turnstile.remove(widgetId);
      this.widgetIds.delete(elementId);
    }
  }

  /**
   * Checks if Turnstile is loaded and ready
   */
  isReady(): boolean {
    return typeof window !== 'undefined' && !!window.turnstile;
  }
}
