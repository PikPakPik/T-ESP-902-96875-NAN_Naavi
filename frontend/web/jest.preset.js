const nxPreset = require('@nx/jest/preset').default;

module.exports = {
  ...nxPreset,
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
  ],
  coverageReporters: [
    'text',
    'text-summary',
    'html',
    'lcov',
    'cobertura',
    'json-summary',
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80,
    },
  },
};
