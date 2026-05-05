---
name: new-project-e2e
description: >
  Step-by-step guide to set up Playwright E2E testing for a new project.
  Includes page object model, fixtures, directory structure, and first test.
  Use when: starting a new project and need E2E test infrastructure.
  Triggers: "playwright setup", "e2e testing setup", "new project e2e", "end to end testing".
---

# New Project: E2E Testing (Playwright)

> Source: [testing-setup-guide.md](../testing-setup-guide.md)

This guide sets up Playwright with a scalable structure: page objects, fixtures, and organized test files.

## Step 1: Install Playwright

```bash
pnpm add -D @playwright/test
pnpm exec playwright install
```

The second command downloads browser binaries. It takes a minute.

## Step 2: Create playwright.config.ts

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e/tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['html', { open: 'never' }],
    ['list'],
  ],
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
    },
  ],
  webServer: {
    command: 'pnpm dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
```

Adjust `baseURL` and `webServer.command` to match your project.

## Step 3: Create Directory Structure

```bash
mkdir -p e2e/pages e2e/fixtures e2e/tests
```

The structure:

```
e2e/
├── pages/          ← Page Object Models
├── fixtures/       ← Shared test fixtures (auth, test data)
└── tests/          ← Test specs
```

## Step 4: Create Base Page and First Page Object

**Base page** (`e2e/pages/base.page.ts`):

```typescript
import type { Page, Locator } from '@playwright/test';

export class BasePage {
  readonly page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  async goto(path: string): Promise<void> {
    await this.page.goto(path);
  }

  async getTitle(): Promise<string> {
    return this.page.title();
  }
}
```

**First page object** (`e2e/pages/home.page.ts`):

```typescript
import type { Locator } from '@playwright/test';
import { BasePage } from './base.page';

export class HomePage extends BasePage {
  readonly heading: Locator;

  constructor(page: import('@playwright/test').Page) {
    super(page);
    this.heading = page.getByRole('heading', { level: 1 });
  }

  async getHeadingText(): Promise<string> {
    return this.heading.textContent() ?? '';
  }
}
```

## Step 5: Create First Test

**Auth fixture** (`e2e/fixtures/auth.fixture.ts`):

```typescript
import { test as base } from '@playwright/test';
import { HomePage } from '../pages/home.page';

type Fixtures = {
  homePage: HomePage;
};

export const test = base.extend<Fixtures>({
  homePage: async ({ page }, use) => {
    const homePage = new HomePage(page);
    await use(homePage);
  },
});

export { expect } from '@playwright/test';
```

**Test file** (`e2e/tests/home.spec.ts`):

```typescript
import { test, expect } from '../fixtures/auth.fixture';

test.describe('Home Page', () => {
  test('displays the main heading', async ({ homePage }) => {
    await homePage.goto('/');
    const heading = await homePage.getHeadingText();
    expect(heading).toBeTruthy();
  });

  test('has correct page title', async ({ homePage }) => {
    await homePage.goto('/');
    const title = await homePage.getTitle();
    expect(title).toContain('App');
  });
});
```

## Step 6: Verify It Works

Start your dev server in one terminal (if not using the webServer config):

```bash
pnpm dev
```

Run E2E tests:

```bash
pnpm exec playwright test
```

View the HTML report:

```bash
pnpm exec playwright show-report
```

Add scripts to `package.json`:

```json
{
  "scripts": {
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui",
    "test:e2e:debug": "playwright test --debug"
  }
}
```

## Next Steps

- See the `e2e-testing` skill for advanced patterns: multi-tab testing, file uploads, API mocking.
- Read [tdd-workflow.md](./tdd-workflow.md) for integrating E2E tests into the TDD cycle.
