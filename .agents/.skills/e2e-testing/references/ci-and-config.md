---
name: ci-and-config
description: >
  Playwright configuration best practices, CI-specific settings, reporter configuration,
  multi-project setup, webServer, sharding for parallel execution, and base URL configuration.
  Use when: setting up playwright.config.ts, configuring CI pipelines, adding reporters,
  sharding tests. Triggers: "playwright config", "CI", "sharding", "reporter", "webServer",
  "multi-project", "parallel".
---

> Source: [SKILL.md](../SKILL.md)

# CI and Configuration

## Complete playwright.config.ts

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  // Test discovery
  testDir: './tests/e2e',
  testMatch: /.*\.spec\.ts/,
  fullyParallel: true,

  // CI safety
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,

  // Reporting
  reporter: [
    ['html', { open: 'never' }],
    process.env.CI ? ['github'] : ['list'],
  ],

  // Global settings
  timeout: 30_000,
  expect: { timeout: 5_000 },
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    actionTimeout: 10_000,
    navigationTimeout: 30_000,
  },

  // Projects
  projects: [
    {
      name: 'setup',
      testMatch: /.*\.setup\.ts/,
    },
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
      dependencies: ['setup'],
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
      dependencies: ['setup'],
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
      dependencies: ['setup'],
    },
    {
      name: 'mobile-chrome',
      use: { ...devices['Pixel 5'] },
      dependencies: ['setup'],
    },
    {
      name: 'mobile-safari',
      use: { ...devices['iPhone 13'] },
      dependencies: ['setup'],
    },
  ],

  // Auto-start dev server
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
  },
});
```

## CI-Specific Settings Explained

### retries

```typescript
retries: process.env.CI ? 2 : 0,
```

CI environments are flaky. Network issues, slower hardware, and shared resources cause intermittent failures. Two retries balances reliability with speed. Local development gets zero retries so failures surface immediately.

### workers

```typescript
workers: process.env.CI ? 1 : undefined,
```

CI runners often have limited resources. Single worker avoids contention and memory issues. Local runs default to half of available CPU cores.

### forbidOnly

```typescript
forbidOnly: !!process.env.CI,
```

Prevents accidentally committing `test.only()` which would skip most of your test suite in CI. The `!!` converts the string `'true'` (or any truthy value) to boolean.

## Reporter Configuration

### HTML Reporter (always)

Generates a full report with traces, screenshots, and videos. Open with `npx playwright show-report`.

```typescript
['html', { open: 'never' }],
```

### GitHub Annotations (CI only)

Adds inline annotations to PR diffs when tests fail.

```typescript
process.env.CI ? ['github'] : ['list'],
```

### List Reporter (local)

Shows real-time test progress in the terminal.

```typescript
['list'],
```

### JSON Reporter (optional)

Machine-readable output for custom dashboards or CI tools.

```typescript
['json', { outputFile: 'test-results.json' }],
```

### Blob Reporter (for sharding)

Collects results from parallel shards into a single report.

```typescript
['blob', { outputDir: 'blob-report' }],
```

## Multi-Project Setup

Projects let you run the same tests against different browsers and devices. The `setup` project runs first and saves auth state. Other projects depend on it.

```typescript
projects: [
  {
    name: 'setup',
    testMatch: /.*\.setup\.ts/,
  },
  {
    name: 'chromium',
    use: { ...devices['Desktop Chrome'] },
    dependencies: ['setup'],
    testIgnore: /.*mobile.*\.spec\.ts/,  // skip mobile-specific tests
  },
  {
    name: 'mobile-chrome',
    use: {
      ...devices['Pixel 5'],
      hasTouch: true,
    },
    dependencies: ['setup'],
    testMatch: /.*mobile.*\.spec\.ts/,  // only mobile-specific tests
  },
],
```

Run a specific project:

```bash
npx playwright test --project=chromium
npx playwright test --project=mobile-safari
```

## webServer Configuration

Auto-starts your dev server before tests and stops it after.

```typescript
webServer: {
  command: 'npm run dev',
  url: 'http://localhost:3000',
  reuseExistingServer: !process.env.CI,   // reuse local server if running
  timeout: 120_000,                        // give server time to start
},
```

For monorepos with multiple servers:

```typescript
webServer: [
  {
    command: 'npm run dev:api',
    url: 'http://localhost:4000/health',
    reuseExistingServer: !process.env.CI,
  },
  {
    command: 'npm run dev:web',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
],
```

## Sharding for Parallel CI Execution

Split tests across multiple CI machines, then merge results.

### Run with Sharding

```bash
# Shard 1 of 4
npx playwright test --shard=1/4
npx playwright test --shard=2/4
npx playwright test --shard=3/4
npx playwright test --shard=4/4
```

### GitHub Actions Example

```yaml
jobs:
  test:
    strategy:
      matrix:
        shard: [1, 2, 3, 4]
    steps:
      - run: npx playwright test --shard=${{ matrix.shard }}/4
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: blob-report-${{ matrix.shard }}
          path: blob-report
          retention-days: 1

  merge-reports:
    needs: [test]
    steps:
      - uses: actions/download-artifact@v4
        with:
          path: all-blob-reports
      - run: npx playwright merge-reports --reporter=html ./all-blob-reports
```

## Base URL Configuration

Always use `baseURL` instead of hardcoding URLs. Combined with `page.goto('/path')`, this makes tests portable across environments.

```typescript
use: {
  baseURL: process.env.BASE_URL || 'http://localhost:3000',
},
```

```typescript
// In tests: use relative paths
await page.goto('/login');       // not https://staging.app.com/login
await page.goto('/dashboard');   // works in every environment
```

```bash
# Run against staging
BASE_URL=https://staging.app.com npx playwright test

# Run against local
npx playwright test  # defaults to localhost:3000
```

## Useful CLI Commands

```bash
# Run all tests
npx playwright test

# Run a single file
npx playwright test tests/e2e/auth/login.spec.ts

# Run tests matching a pattern
npx playwright test -g "login"

# Run with browser visible
npx playwright test --headed

# Interactive UI mode
npx playwright test --ui

# Debug mode (step through)
npx playwright test --debug

# View trace from a failed test
npx playwright show-trace test-results/.../trace.zip

# Generate code by recording actions
npx playwright codegen http://localhost:3000

# Show HTML report
npx playwright show-report
```
