import { setupZonelessTestEnv } from 'jest-preset-angular/setup-env/zoneless';

setupZonelessTestEnv({
  errorOnUnknownElements: true,
  errorOnUnknownProperties: true,
});

// Polyfill performance.mark for mapbox-gl
if (typeof performance !== 'undefined' && !performance.mark) {
  performance.mark = jest.fn();
  performance.measure = jest.fn();
  performance.getEntriesByType = jest.fn(() => []);
  performance.clearMarks = jest.fn();
  performance.clearMeasures = jest.fn();
}
