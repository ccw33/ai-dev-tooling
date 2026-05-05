---
name: coverage-and-ci
description: >
  Vitest coverage configuration, CI integration, and StrykerJS mutation testing.
  Includes coverage thresholds, CI-recommended vitest.config.ts settings, StrykerJS
  setup, and coverage gate patterns.
  Use when: configuring test coverage, setting up CI pipelines, adding mutation testing.
  Triggers: "coverage", "CI", "mutation testing", "stryker", "coverage threshold",
  "quality gate", "覆盖率", "持续集成".
---

# Coverage and CI

> Source: [SKILL.md](../SKILL.md)


> Source: [SKILL.md](../SKILL.md)

## Coverage Configuration

### Recommended vitest.config.ts for CI

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    restoreMocks: true,

    // CI settings
    include: ['src/**/*.{test,spec}.{ts,tsx}'],
    reporters: ['default', 'junit'],
    outputFile: 'test-results/junit.xml',

    // Coverage
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov', 'html'],
      reportsDirectory: './coverage',
      include: ['src/**/*.{ts,tsx}'],
      exclude: [
        'src/**/*.d.ts',
        'src/**/*.test.{ts,tsx}',
        'src/**/*.spec.{ts,tsx}',
        'src/types/**',
        'src/mocks/**',
      ],
      thresholds: {
        statements: 80,
        branches: 75,
        functions: 80,
        lines: 80,
      },
    },
  },
})
```

### Coverage Commands

```bash
npx vitest run --coverage              # Run with coverage
npx vitest run --coverage --watch      # Watch mode with coverage
npx vitest run --coverage.changed      # Coverage for changed files only
```

### Threshold Enforcement

When coverage drops below configured thresholds, Vitest exits with code 1. This
makes CI fail, which is the desired behavior. Do not lower thresholds to make CI pass.
Fix the missing tests instead.

```
ERROR: Coverage for statements (78.45%) does not meet threshold (80%)
ERROR: Coverage for branches (72.10%) does not meet threshold (75%)
```

Exit code 1 in CI blocks the merge. This is the coverage gate.

## CI Pipeline Integration

### GitHub Actions Example

```yaml
name: Test
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm
      - run: npm ci
      - run: npx vitest run --coverage
      - uses: codecov/codecov-action@v4
        if: always()
        with:
          files: ./coverage/lcov.info
```

### CI Rules

| Rule | Why |
|------|-----|
| Use `vitest run`, not `vitest` | Single run, no watch mode, deterministic exit |
| Fail on coverage threshold violation | Vitest exits 1 when thresholds not met |
| Run coverage in CI, not locally | CI enforces the gate; local runs are for feedback |
| Cache node_modules | Speeds up CI runs |

## StrykerJS Mutation Testing

### What It Does

StrykerJS modifies your source code (mutates it) and checks if tests catch the change.
If a mutant survives, your tests have a gap. This catches tests that pass despite
broken logic.

Mutation testing is especially valuable for AI-generated tests because AI tends to
write tests that are structurally correct but logically weak (see ai-anti-patterns.md).

### Setup

```bash
npm install -D @stryker-mutator/core @stryker-mutator/vitest-runner
npx stryker init
```

### Configuration

```typescript
// stryker.config.mjs
export default {
  packageManager: 'npm',
  reporters: ['html', 'clear-text', 'progress'],
  testRunner: 'vitest',
  vitest: {
    configFile: 'vitest.config.ts',
  },
  coverageAnalysis: 'perTest',
  mutate: [
    'src/**/*.{ts,tsx}',
    '!src/**/*.d.ts',
    '!src/**/*.test.{ts,tsx}',
    '!src/**/*.spec.{ts,tsx}',
    '!src/types/**',
  ],
  thresholds: {
    high: 80,
    low: 60,
    break: 50,
  },
}
```

### Reading Results

```
Ran all tests for this mutation:
- Killed: test caught the mutation (good)
- Survived: test did not catch the mutation (gap in test coverage)
- Timeout: mutation caused infinite loop (test gap or reveals real issue)
```

A mutation score below 50% means tests are weak. Aim for 70%+ mutation score.

### When to Run

- Not every CI run (slow). Run on schedule (nightly) or before merges.
- After AI generates a batch of tests, run StrykerJS to verify they actually catch mutations.
- When coverage is high but bugs still slip through, mutation testing reveals why.

## Quick Reference

| Tool | Command | Purpose |
|------|---------|---------|
| Vitest coverage | `npx vitest run --coverage` | Line/branch/function coverage |
| Coverage gate | `thresholds` in config | Fail CI when coverage drops |
| StrykerJS | `npx stryker run` | Mutation testing for test quality |
| JUnit report | `reporters: ['junit']` | CI test result display |
