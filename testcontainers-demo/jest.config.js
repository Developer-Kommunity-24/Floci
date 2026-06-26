/** @type {import('jest').Config} */
module.exports = {
  preset: "ts-jest",
  testEnvironment: "node",
  testTimeout: 120000, // container startup can take ~30s
  verbose: true,
};
