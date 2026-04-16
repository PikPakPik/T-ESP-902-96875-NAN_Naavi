import {
  getPOICategoryIconPath,
  getPOICategoryTranslationKey,
  getPOIStatusTranslationKey,
} from './poi-translation.helper';

describe('poi-translation.helper', () => {
  it('should return a translation key for a POI category', () => {
    expect(getPOICategoryTranslationKey('WATER')).toBe('POI.CATEGORY.WATER');
  });

  it('should return a translation key for a POI status', () => {
    expect(getPOIStatusTranslationKey('DRAFT')).toBe('POI.STATUS.DRAFT');
  });

  it('should return the Flutter icon path for a category', () => {
    expect(getPOICategoryIconPath('MUST_SEE_SPOT')).toBe(
      '/assets/icons/poi/must_see_spot.png'
    );
    expect(getPOICategoryIconPath('MONUMENT')).toBe('/assets/icons/poi/monument.png');
    expect(getPOICategoryIconPath('WATER')).toBe('/assets/icons/poi/water.png');
    expect(getPOICategoryIconPath('ACCOMMODATION')).toBe(
      '/assets/icons/poi/accomodation.png'
    );
    expect(getPOICategoryIconPath('BIVOUAC')).toBe('/assets/icons/poi/camping.png');
    expect(getPOICategoryIconPath('RESTAURANT')).toBe(
      '/assets/icons/poi/restaurant.png'
    );
    expect(getPOICategoryIconPath('TOILET')).toBe('/assets/icons/poi/toilets.png');
    expect(getPOICategoryIconPath('PARKING')).toBe('/assets/icons/report/parking.png');
    expect(getPOICategoryIconPath('ACTIVITY')).toBe('/assets/icons/poi/activity.png');
    expect(getPOICategoryIconPath('DANGER')).toBe('/assets/icons/poi/hazard.png');
    expect(getPOICategoryIconPath('SLIPPERY_GROUND')).toBe(
      '/assets/icons/poi/terrain_glissant.png'
    );
    expect(getPOICategoryIconPath('SLIPPERY_GROUD')).toBe(
      '/assets/icons/poi/terrain_glissant.png'
    );
    expect(getPOICategoryIconPath('MUDDY_GROUND')).toBe('/assets/icons/poi/muddy.png');
    expect(getPOICategoryIconPath('AVALANCHE_RISK')).toBe(
      '/assets/icons/poi/eboulement.png'
    );
    expect(getPOICategoryIconPath('ANIMAL_CROSSING')).toBe(
      '/assets/icons/poi/animals.png'
    );
    expect(getPOICategoryIconPath('INACCESSIBLE_PASSAGE')).toBe(
      '/assets/icons/poi/passage_inaccessible.png'
    );
  });

  it('should fallback to hazard icon for unknown categories', () => {
    expect(getPOICategoryIconPath('UNKNOWN')).toBe('/assets/icons/poi/hazard.png');
    expect(getPOICategoryIconPath(undefined)).toBe('/assets/icons/poi/hazard.png');
  });
});
