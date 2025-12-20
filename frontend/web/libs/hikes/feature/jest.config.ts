export default {
  displayName: 'hikes-feature',
  preset: '../../../jest.preset.js',
  setupFilesAfterEnv: ['<rootDir>/src/test-setup.ts'],
  coverageDirectory: '../../../coverage/libs/hikes/feature',
  collectCoverageFrom: [
    'src/**/*.{ts,js}',
    '!**/*.spec.{ts,js}',
    '!**/*.test.{ts,js}',
    '!**/node_modules/**',
    '!**/coverage/**',
    '!**/*.d.ts',
    '!**/main.ts',
    '!**/*.config.{ts,js}',
    '!**/jest.config.{ts,js}',
    '!**/webpack.config.{ts,js}',
    '!**/tailwind.config.{ts,js}',
    '!**/test-setup.{ts,js}',
    '!**/index.{ts,js}',
    '!**/hike-map.component.ts', // Exclure car difficile à tester (Mapbox)
    '!**/hike-location-search.component.ts', // Exclure car difficile à tester (Mapbox)
  ],
  transform: {
    '^.+\\.(ts|mjs|js|html)$': [
      'jest-preset-angular',
      {
        tsconfig: '<rootDir>/tsconfig.spec.json',
        stringifyContentPathRegex: '\\.(html|svg)$',
      },
    ],
  },
  transformIgnorePatterns: ['node_modules/(?!.*\\.mjs$)'],
  snapshotSerializers: [
    'jest-preset-angular/build/serializers/no-ng-attributes',
    'jest-preset-angular/build/serializers/ng-snapshot',
    'jest-preset-angular/build/serializers/html-comment',
  ],
};
