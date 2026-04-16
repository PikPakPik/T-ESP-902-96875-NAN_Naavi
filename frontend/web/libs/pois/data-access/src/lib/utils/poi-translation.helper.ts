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

/**
 * Retourne le chemin vers l'icone Flutter d'une categorie POI.
 * Les assets sont copies dans `shared-assets` pour etre servis par Angular.
 */
export function getPOICategoryIconPath(category: string | null | undefined): string {
  switch ((category || '').toUpperCase()) {
    case 'MUST_SEE_SPOT':
      return '/assets/icons/poi/must_see_spot.png';
    case 'MONUMENT':
      return '/assets/icons/poi/monument.png';
    case 'WATER':
      return '/assets/icons/poi/water.png';
    case 'ACCOMMODATION':
      return '/assets/icons/poi/accomodation.png';
    case 'BIVOUAC':
      return '/assets/icons/poi/camping.png';
    case 'RESTAURANT':
      return '/assets/icons/poi/restaurant.png';
    case 'TOILET':
      return '/assets/icons/poi/toilets.png';
    case 'PARKING':
      return '/assets/icons/report/parking.png';
    case 'ACTIVITY':
      return '/assets/icons/poi/activity.png';
    case 'DANGER':
      return '/assets/icons/poi/hazard.png';
    case 'SLIPPERY_GROUND':
    case 'SLIPPERY_GROUD':
      return '/assets/icons/poi/terrain_glissant.png';
    case 'MUDDY_GROUND':
      return '/assets/icons/poi/muddy.png';
    case 'AVALANCHE_RISK':
      return '/assets/icons/poi/eboulement.png';
    case 'ANIMAL_CROSSING':
      return '/assets/icons/poi/animals.png';
    case 'INACCESSIBLE_PASSAGE':
      return '/assets/icons/poi/passage_inaccessible.png';
    default:
      return '/assets/icons/poi/hazard.png';
  }
}
