/**
 * Helper pour obtenir les clés de traduction pour les points d'intérêt
 */

/**
 * Retourne la clé de traduction pour une catégorie POI donnée
 * @param category - La catégorie (ex: "MUST_SEE_SPOT", "MONUMENT", etc.)
 * @returns La clé de traduction (ex: "POI.CATEGORY.MUST_SEE_SPOT")
 */
export function getPOICategoryTranslationKey(category: string): string {
  return `POI.CATEGORY.${category}`;
}

/**
 * Retourne la clé de traduction pour un statut POI donné
 * @param status - Le statut (ex: "DRAFT", "PUBLISHED", etc.)
 * @returns La clé de traduction (ex: "POI.STATUS.DRAFT")
 */
export function getPOIStatusTranslationKey(status: string): string {
  return `POI.STATUS.${status}`;
}
