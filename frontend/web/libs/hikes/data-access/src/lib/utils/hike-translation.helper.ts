/**
 * Helper pour obtenir les clés de traduction pour les randonnées
 */

import { Tag } from 'primeng/tag';

/**
 * Retourne la clé de traduction pour une difficulté donnée
 * @param difficulty - La difficulté (ex: "EASY", "MEDIUM", "HARD")
 * @returns La clé de traduction (ex: "HIKE.DIFFICULTY.EASY")
 */
export function getDifficultyTranslationKey(difficulty: string): string {
  return `HIKE.DIFFICULTY.${difficulty}`;
}

/**
 * Retourne la clé de traduction pour un statut donné
 * @param status - Le statut (ex: "DRAFT", "PUBLISHED", etc.)
 * @returns La clé de traduction (ex: "HIKE.STATUS.DRAFT")
 */
export function getStatusTranslationKey(status: string): string {
  return `HIKE.STATUS.${status}`;
}

/**
 * Retourne la clé de traduction pour une source donnée
 * @param source - La source (ex: "OFFICIAL", "COMMUNITY")
 * @returns La clé de traduction (ex: "HIKE.SOURCE.OFFICIAL")
 */
export function getSourceTranslationKey(source: string): string {
  return `HIKE.SOURCE.${source}`;
}

/**
 * Retourne la clé de traduction pour une visibilité donnée
 * @param visibility - La visibilité (ex: "PUBLIC", "PRIVATE", "UNLISTED")
 * @returns La clé de traduction (ex: "HIKE.VISIBILITY.PUBLIC")
 */
export function getVisibilityTranslationKey(visibility: string): string {
  return `HIKE.VISIBILITY.${visibility}`;
}

/**
 * Retourne la clé de traduction pour une saison donnée
 * @param season - La saison (ex: "SPRING", "SUMMER", "FALL", "WINTER")
 * @returns La clé de traduction (ex: "HIKE.SEASON.SPRING")
 */
export function getSeasonTranslationKey(season: string): string {
  return `HIKE.SEASON.${season}`;
}

/**
 * Retourne le niveau de sévérité pour une difficulté donnée (pour les badges PrimeNG)
 * @param difficulty - La difficulté (ex: "EASY", "MEDIUM", "HARD")
 * @returns Le niveau de sévérité correspondant
 */
export function getDifficultySeverity(
  difficulty: string | null | undefined
): Tag['severity'] {
  switch ((difficulty || '').toUpperCase()) {
    case 'EASY':
      return 'success';
    case 'MEDIUM':
      return 'warn';
    case 'HARD':
      return 'danger';
    default:
      return 'secondary';
  }
}

/**
 * Retourne le niveau de sévérité pour un statut donné (pour les badges PrimeNG)
 * @param status - Le statut (ex: "DRAFT", "PUBLISHED", etc.)
 * @returns Le niveau de sévérité correspondant
 */
export function getStatusSeverity(
  status: string | null | undefined
): Tag['severity'] {
  switch ((status || '').toUpperCase()) {
    case 'PUBLISHED':
      return 'success';
    case 'DRAFT':
      return 'info';
    case 'UNPUBLISHED':
      return 'warn';
    case 'DELETED':
      return 'danger';
    default:
      return 'info';
  }
}

/**
 * Retourne le niveau de sévérité pour une source donnée (pour les badges PrimeNG)
 * @param source - La source (ex: "OFFICIAL", "COMMUNITY")
 * @returns Le niveau de sévérité correspondant
 */
export function getSourceSeverity(
  source: string | null | undefined
): Tag['severity'] {
  switch ((source || '').toUpperCase()) {
    case 'OFFICIAL':
      return 'success';
    case 'COMMUNITY':
      return 'warn';
    default:
      return 'secondary';
  }
}

/**
 * Retourne le niveau de sévérité pour une visibilité donnée (pour les badges PrimeNG)
 * @param visibility - La visibilité (ex: "PUBLIC", "PRIVATE", "UNLISTED")
 * @returns Le niveau de sévérité correspondant
 */
export function getVisibilitySeverity(
  visibility: string | null | undefined
): Tag['severity'] {
  switch ((visibility || '').toUpperCase()) {
    case 'PUBLIC':
      return 'success';
    case 'PRIVATE':
      return 'danger';
    case 'UNLISTED':
      return 'warn';
    default:
      return 'secondary';
  }
}

/**
 * Retourne le niveau de sévérité pour une saison donnée (pour les badges PrimeNG)
 * @param season - La saison (ex: "SPRING", "SUMMER", "FALL", "WINTER")
 * @returns Le niveau de sévérité correspondant
 */
export function getSeasonSeverity(
  season: string | null | undefined
): Tag['severity'] {
  switch ((season || '').toUpperCase()) {
    case 'SPRING':
      return 'success';
    case 'SUMMER':
      return 'warn';
    case 'FALL':
      return 'info';
    case 'WINTER':
      return 'info';
    default:
      return 'secondary';
  }
}
