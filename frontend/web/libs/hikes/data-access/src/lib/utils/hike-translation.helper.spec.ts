import {
  getDifficultyTranslationKey,
  getStatusTranslationKey,
  getSourceTranslationKey,
  getSeasonTranslationKey,
  getDifficultySeverity,
  getStatusSeverity,
  getSourceSeverity,
  getSeasonSeverity,
} from './hike-translation.helper';

describe('Hike Translation Helper', () => {
  describe('getDifficultyTranslationKey', () => {
    it('should return correct translation key for EASY', () => {
      expect(getDifficultyTranslationKey('EASY')).toBe('HIKE.DIFFICULTY.EASY');
    });

    it('should return correct translation key for MEDIUM', () => {
      expect(getDifficultyTranslationKey('MEDIUM')).toBe(
        'HIKE.DIFFICULTY.MEDIUM'
      );
    });

    it('should return correct translation key for HARD', () => {
      expect(getDifficultyTranslationKey('HARD')).toBe('HIKE.DIFFICULTY.HARD');
    });
  });

  describe('getStatusTranslationKey', () => {
    it('should return correct translation key for DRAFT', () => {
      expect(getStatusTranslationKey('DRAFT')).toBe('HIKE.STATUS.DRAFT');
    });

    it('should return correct translation key for PUBLISHED', () => {
      expect(getStatusTranslationKey('PUBLISHED')).toBe(
        'HIKE.STATUS.PUBLISHED'
      );
    });

    it('should return correct translation key for UNPUBLISHED', () => {
      expect(getStatusTranslationKey('UNPUBLISHED')).toBe(
        'HIKE.STATUS.UNPUBLISHED'
      );
    });

    it('should return correct translation key for DELETED', () => {
      expect(getStatusTranslationKey('DELETED')).toBe('HIKE.STATUS.DELETED');
    });
  });

  describe('getSourceTranslationKey', () => {
    it('should return correct translation key for OFFICIAL', () => {
      expect(getSourceTranslationKey('OFFICIAL')).toBe('HIKE.SOURCE.OFFICIAL');
    });

    it('should return correct translation key for COMMUNITY', () => {
      expect(getSourceTranslationKey('COMMUNITY')).toBe(
        'HIKE.SOURCE.COMMUNITY'
      );
    });
  });

  describe('getSeasonTranslationKey', () => {
    it('should return correct translation key for SPRING', () => {
      expect(getSeasonTranslationKey('SPRING')).toBe('HIKE.SEASON.SPRING');
    });

    it('should return correct translation key for SUMMER', () => {
      expect(getSeasonTranslationKey('SUMMER')).toBe('HIKE.SEASON.SUMMER');
    });

    it('should return correct translation key for FALL', () => {
      expect(getSeasonTranslationKey('FALL')).toBe('HIKE.SEASON.FALL');
    });

    it('should return correct translation key for WINTER', () => {
      expect(getSeasonTranslationKey('WINTER')).toBe('HIKE.SEASON.WINTER');
    });
  });

  describe('getDifficultySeverity', () => {
    it('should return success for EASY', () => {
      expect(getDifficultySeverity('EASY')).toBe('success');
    });

    it('should return warn for MEDIUM', () => {
      expect(getDifficultySeverity('MEDIUM')).toBe('warn');
    });

    it('should return danger for HARD', () => {
      expect(getDifficultySeverity('HARD')).toBe('danger');
    });

    it('should return secondary for unknown difficulty', () => {
      expect(getDifficultySeverity('UNKNOWN')).toBe('secondary');
    });

    it('should handle null and return secondary', () => {
      expect(getDifficultySeverity(null)).toBe('secondary');
    });

    it('should handle undefined and return secondary', () => {
      expect(getDifficultySeverity(undefined)).toBe('secondary');
    });

    it('should handle lowercase difficulty', () => {
      expect(getDifficultySeverity('easy')).toBe('success');
      expect(getDifficultySeverity('medium')).toBe('warn');
      expect(getDifficultySeverity('hard')).toBe('danger');
    });
  });

  describe('getStatusSeverity', () => {
    it('should return success for PUBLISHED', () => {
      expect(getStatusSeverity('PUBLISHED')).toBe('success');
    });

    it('should return info for DRAFT', () => {
      expect(getStatusSeverity('DRAFT')).toBe('info');
    });

    it('should return warn for UNPUBLISHED', () => {
      expect(getStatusSeverity('UNPUBLISHED')).toBe('warn');
    });

    it('should return danger for DELETED', () => {
      expect(getStatusSeverity('DELETED')).toBe('danger');
    });

    it('should return secondary for unknown status', () => {
      expect(getStatusSeverity('UNKNOWN')).toBe('info');
    });

    it('should handle null and return info', () => {
      expect(getStatusSeverity(null)).toBe('info');
    });

    it('should handle undefined and return info', () => {
      expect(getStatusSeverity(undefined)).toBe('info');
    });

    it('should handle lowercase status', () => {
      expect(getStatusSeverity('published')).toBe('success');
      expect(getStatusSeverity('draft')).toBe('info');
    });
  });

  describe('getSourceSeverity', () => {
    it('should return success for OFFICIAL', () => {
      expect(getSourceSeverity('OFFICIAL')).toBe('success');
    });

    it('should return warn for COMMUNITY', () => {
      expect(getSourceSeverity('COMMUNITY')).toBe('warn');
    });

    it('should return secondary for unknown source', () => {
      expect(getSourceSeverity('UNKNOWN')).toBe('secondary');
    });

    it('should handle null and return secondary', () => {
      expect(getSourceSeverity(null)).toBe('secondary');
    });

    it('should handle undefined and return secondary', () => {
      expect(getSourceSeverity(undefined)).toBe('secondary');
    });

    it('should handle lowercase source', () => {
      expect(getSourceSeverity('official')).toBe('success');
      expect(getSourceSeverity('community')).toBe('warn');
    });
  });

  describe('getSeasonSeverity', () => {
    it('should return success for SPRING', () => {
      expect(getSeasonSeverity('SPRING')).toBe('success');
    });

    it('should return warn for SUMMER', () => {
      expect(getSeasonSeverity('SUMMER')).toBe('warn');
    });

    it('should return info for FALL', () => {
      expect(getSeasonSeverity('FALL')).toBe('info');
    });

    it('should return info for WINTER', () => {
      expect(getSeasonSeverity('WINTER')).toBe('info');
    });

    it('should return info for unknown season', () => {
      expect(getSeasonSeverity('UNKNOWN')).toBe('secondary');
    });

    it('should handle null and return secondary', () => {
      expect(getSeasonSeverity(null)).toBe('secondary');
    });

    it('should handle undefined and return secondary', () => {
      expect(getSeasonSeverity(undefined)).toBe('secondary');
    });

    it('should handle lowercase season', () => {
      expect(getSeasonSeverity('spring')).toBe('success');
      expect(getSeasonSeverity('summer')).toBe('warn');
      expect(getSeasonSeverity('fall')).toBe('info');
      expect(getSeasonSeverity('winter')).toBe('info');
    });
  });
});
