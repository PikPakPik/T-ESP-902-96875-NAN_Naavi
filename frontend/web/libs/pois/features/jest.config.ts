export default {
  displayName: 'pois-features',
  preset: '../../../jest.preset.js',
  setupFilesAfterEnv: ['<rootDir>/src/test-setup.ts'],
  coverageDirectory: '../../../coverage/libs/pois/features',
  transform: {
    '^.+\\.(ts|mjs|js|html)$': [
      'jest-preset-angular',
      {
        tsconfig: '<rootDir>/tsconfig.spec.json',
        stringifyContentPathRegex: '\\.(html|svg)$',
      },
    ],
  },
  transformIgnorePatterns: [
    'node_modules/(?!.*\\.mjs$|.*ngx-mapbox-gl|.*mapbox-gl)',
  ],
  moduleNameMapper: {
    '^mapbox-gl$': '<rootDir>/../../../__mocks__/mapbox-gl.ts',
    '^ngx-mapbox-gl$': '<rootDir>/../../../__mocks__/ngx-mapbox-gl.ts',
  },
  snapshotSerializers: [
    'jest-preset-angular/build/serializers/no-ng-attributes',
    'jest-preset-angular/build/serializers/ng-snapshot',
    'jest-preset-angular/build/serializers/html-comment',
  ],
};
