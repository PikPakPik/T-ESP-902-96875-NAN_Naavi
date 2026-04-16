export default {
  displayName: 'signal-stores',
  preset: '../../../jest.preset.js',
  setupFilesAfterEnv: ['<rootDir>/src/test-setup.ts'],
  coverageDirectory: '../../../coverage/libs/shared/util-signal-stores',
  collectCoverageFrom: [
    '<rootDir>/**/src/**/*.{ts,js}',
    '!**/*.spec.{ts,js}',
    '!**/*.test.{ts,js}',
    '!**/node_modules/**',
    '!**/coverage/**',
    '!**/*.d.ts',
    '!**/index.{ts,js}',
    '!**/test-setup.{ts,js}',
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
