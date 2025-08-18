import { Injectable, signal, computed, inject } from '@angular/core';
import { MessageService } from 'primeng/api';

export interface NotificationOptions {
  duration?: number;
  position?:
    | 'top-left'
    | 'top-center'
    | 'top-right'
    | 'bottom-left'
    | 'bottom-center'
    | 'bottom-right'
    | 'center';
  closable?: boolean;
  key?: string;
  id?: string;
  sticky?: boolean;
}

export type NotificationSeverity =
  | 'success'
  | 'info'
  | 'warn'
  | 'error'
  | 'secondary'
  | 'contrast';

export interface NotificationMessage {
  id: string;
  severity: NotificationSeverity;
  summary: string;
  detail?: string;
  options?: NotificationOptions;
  timestamp: number;
}

@Injectable({
  providedIn: 'root',
})
export class NotificationService {
  private readonly messageService = inject(MessageService);
  private readonly _notifications = signal<NotificationMessage[]>([]);
  private _idCounter = 0;

  // Signal en lecture seule pour exposer les notifications
  readonly notifications = this._notifications.asReadonly();

  // Computed pour obtenir le nombre de notifications
  readonly notificationCount = computed(() => this._notifications().length);

  // Computed pour filtrer les notifications par sévérité
  readonly notificationsBySeverity = computed(() => {
    const notifications = this._notifications();
    const grouped: Record<NotificationSeverity, NotificationMessage[]> = {
      success: [],
      info: [],
      warn: [],
      error: [],
      secondary: [],
      contrast: [],
    };

    notifications.forEach((notification) => {
      grouped[notification.severity].push(notification);
    });

    return grouped;
  });

  /**
   * Génère un ID unique pour la notification
   */
  private generateId(): string {
    return `notification_${++this._idCounter}_${Date.now()}`;
  }

  /**
   * Ajoute une notification au signal et à PrimeNG
   */
  private addNotification(notification: NotificationMessage): void {
    // Ajouter au signal pour la réactivité
    this._notifications.update((notifications) => [
      ...notifications,
      notification,
    ]);

    // Ajouter à PrimeNG MessageService pour l'affichage
    this.messageService.add({
      id: notification.id,
      severity: notification.severity,
      summary: notification.summary,
      detail: notification.detail,
      life: notification.options?.sticky
        ? 0
        : notification.options?.duration || 3000,
      key: notification.options?.key,
      closable: notification.options?.closable !== false,
    });

    // Auto-suppression du signal après la durée spécifiée (si pas sticky)
    if (!notification.options?.sticky) {
      const duration = notification.options?.duration || 3000;
      setTimeout(() => {
        this.removeFromSignal(notification.id);
      }, duration);
    }
  }

  /**
   * Supprime une notification du signal seulement
   */
  private removeFromSignal(id: string): void {
    this._notifications.update((notifications) =>
      notifications.filter((notification) => notification.id !== id)
    );
  }

  /**
   * Affiche une notification toast
   * @param summary Titre de la notification
   * @param detail Détail de la notification (optionnel)
   * @param severity Type de notification
   * @param options Options supplémentaires pour la notification
   */
  open(
    summary: string,
    detail?: string,
    severity: NotificationSeverity = 'info',
    options?: NotificationOptions
  ): string {
    const id = options?.id || this.generateId();
    const notification: NotificationMessage = {
      id,
      severity,
      summary,
      detail,
      options,
      timestamp: Date.now(),
    };

    this.addNotification(notification);
    return id;
  }

  /**
   * Affiche une notification de succès
   */
  success(
    summary: string,
    detail?: string,
    options?: NotificationOptions
  ): string {
    return this.open(summary, detail, 'success', options);
  }

  /**
   * Affiche une notification d'information
   */
  info(
    summary: string,
    detail?: string,
    options?: NotificationOptions
  ): string {
    return this.open(summary, detail, 'info', options);
  }

  /**
   * Affiche une notification d'avertissement
   */
  warn(
    summary: string,
    detail?: string,
    options?: NotificationOptions
  ): string {
    return this.open(summary, detail, 'warn', options);
  }

  /**
   * Affiche une notification d'erreur
   */
  error(
    summary: string,
    detail?: string,
    options?: NotificationOptions
  ): string {
    return this.open(summary, detail, 'error', options);
  }

  /**
   * Affiche une notification secondaire
   */
  secondary(
    summary: string,
    detail?: string,
    options?: NotificationOptions
  ): string {
    return this.open(summary, detail, 'secondary', options);
  }

  /**
   * Affiche une notification contrastée
   */
  contrast(
    summary: string,
    detail?: string,
    options?: NotificationOptions
  ): string {
    return this.open(summary, detail, 'contrast', options);
  }

  /**
   * Affiche plusieurs notifications
   */
  showAll(
    messages: Array<{
      summary: string;
      detail?: string;
      severity?: NotificationSeverity;
      options?: NotificationOptions;
    }>
  ): string[] {
    return messages.map((msg) =>
      this.open(msg.summary, msg.detail, msg.severity, msg.options)
    );
  }

  /**
   * Supprime une notification par son ID
   */
  remove(id: string): void {
    // Supprimer de PrimeNG
    this.messageService.clear(id);
    // Supprimer du signal
    this.removeFromSignal(id);
  }

  /**
   * Ferme toutes les notifications ou celles avec une clé spécifique
   */
  clear(key?: string): void {
    // Nettoyer PrimeNG
    this.messageService.clear(key);

    // Nettoyer le signal
    if (key) {
      this._notifications.update((notifications) =>
        notifications.filter(
          (notification) => notification.options?.key !== key
        )
      );
    } else {
      this._notifications.set([]);
    }
  }

  /**
   * Obtient les notifications actives
   */
  getActiveNotifications(): NotificationMessage[] {
    return this._notifications();
  }

  /**
   * Obtient les notifications par sévérité
   */
  getNotificationsBySeverity(
    severity: NotificationSeverity
  ): NotificationMessage[] {
    return this.notificationsBySeverity()[severity];
  }
}
