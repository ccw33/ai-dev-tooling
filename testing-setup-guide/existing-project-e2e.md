---
name: existing-project-e2e
description: >
  Guide for adding Playwright E2E testing to an existing project.
  Covers detection, gradual adoption, smoke tests, and Cypress migration guidance.
  Use when: adding E2E tests to a brownfield project.
  Triggers: "add e2e to existing project", "brownfield e2e", "migrate cypress", "add playwright".
---

# Existing Project: Adding E2E Testing (Playwright)

> Source: [testing-setup-guide.md](../testing-setup-guide.md)

Adding E2E tests to an existing project means starting with the highest-value tests and building out from there.

## Step 1: Detect Existing E2E Setup

Check what already exists:

```bash
# Check for existing E2E frameworks
ls playwright.config.ts cypress.config.* cypress/ nightwatch.conf.* wdio.conf.* 2>/dev/null

# Check package.json
cat package.json | grep -E '"@playwright|cypress|nightwatch|webdriverio"'

# Check for existing test directories
ls -d e2e/ cypress/ tests/e2e/ test/ 2>/dev/null
```

**What you might find:**

| Found | Action |
|-------|--------|
| Cypress already installed | See "Migration from Cypress" below |
| No E2E framework | Follow this guide from Step 2 |
| Playwright installed but unused | Extend existing config |
| Partial test directory | Adopt the structure in this guide |

## Step 2: Install Playwright

**No existing E2E framework:**

```bash
pnpm add -D @playwright/test
pnpm exec playwright install
```

**Playwright already installed but incomplete:**

```bash
pnpm exec playwright install
```

Create the config. See [new-project-e2e.md](./new-project-e2e.md) Step 2 for the full `playwright.config.ts`. Adjust the `baseURL` and `webServer` to match your existing project's dev server.

Create the directory structure:

```bash
mkdir -p e2e/pages e2e/fixtures e2e/tests
```

## Step 3: Start with Smoke Tests

Write 3-5 tests that cover the most critical user paths. Don't try to test everything.

**Smoke test template** (`e2e/tests/smoke.spec.ts`):

```typescript
import { test, expect } from '@playwright/test';

test.describe('Smoke Tests', () => {
  test('home page loads', async ({ page }) => {
    await page.goto('/');
    await expect(page.getByRole('main')).toBeVisible();
  });

  test('navigation works', async ({ page }) => {
    await page.goto('/');
    // Replace with actual nav links in your project
    await page.getByRole('link', { name: 'About' }).click();
    await expect(page).toHaveURL(/about/);
  });

  test('login page loads', async ({ page }) => {
    await page.goto('/login');
    await expect(page.getByLabel('Email')).toBeVisible();
    await expect(page.getByLabel('Password')).toBeVisible();
  });

  test('API health check', async ({ request }) => {
    const response = await request.get('/api/health');
    expect(response.ok()).toBeTruthy();
  });

  test('no console errors on home page', async ({ page }) => {
    const errors: string[] = [];
    page.on('console', (msg) => {
      if (msg.type() === 'error') errors.push(msg.text());
    });
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    expect(errors).toHaveLength(0);
  });
});
```

Run them:

```bash
pnpm exec playwright test e2e/tests/smoke.spec.ts
```

## Step 4: Gradually Add Page Objects and Fixtures

Once smoke tests pass, start building the page object layer for pages you test most.

**Create a base page and page objects** following the pattern in [new-project-e2e.md](./new-project-e2e.md) Step 4.

**Create an auth fixture** for logged-in tests (`e2e/fixtures/auth.fixture.ts`):

```typescript
import { test as base, expect } from '@playwright/test';

type AuthFixtures = {
  authenticatedPage: import('@playwright/test').Page;
};

export const test = base.extend<AuthFixtures>({
  authenticatedPage: async ({ page }, use) => {
    // Replace with your app's login flow
    await page.goto('/login');
    await page.getByLabel('Email').fill('test@example.com');
    await page.getByLabel('Password').fill('test-password');
    await page.getByRole('button', { name: 'Log in' }).click();
    await page.waitForURL('/dashboard');

    await use(page);
  },
});

export { expect };
```

**Use the fixture in tests:**

```typescript
import { test, expect } from '../fixtures/auth.fixture';

test('dashboard shows user name', async ({ authenticatedPage }) => {
  await expect(authenticatedPage.getByText('Test User')).toBeVisible();
});
```

## Migration from Cypress

If the project uses Cypress, you can migrate gradually:

**Phase 1: Run both in parallel**

```json
{
  "scripts": {
    "test:e2e": "playwright test",
    "test:e2e:cypress": "cypress run",
    "test:e2e:all": "playwright test && cypress run"
  }
}
```

**Phase 2: Migrate tests one at a time**

Cypress and Playwright concepts map roughly:

| Cypress | Playwright |
|---------|-----------|
| `cy.visit('/')` | `await page.goto('/')` |
| `cy.get('.btn')` | `page.locator('.btn')` or `page.getByRole('button')` |
| `cy.contains('text')` | `page.getByText('text')` |
| `.should('be.visible')` | `await expect(locator).toBeVisible()` |
| `.type('hello')` | `await locator.fill('hello')` |
| `.click()` | `await locator.click()` |
| `cy.intercept()` | `await page.route()` |
| `cypress/fixtures/` | `e2e/fixtures/` (different concept, use Playwright fixtures) |

**Phase 3: Remove Cypress**

Once all tests are migrated:

```bash
pnpm remove cypress
rm -rf cypress/ cypress.config.*
```

## Common Pitfalls

| Problem | Fix |
|---------|-----|
| Tests fail because dev server isn't running | Configure `webServer` in playwright.config.ts |
| Flaky tests due to timing | Use `waitFor` assertions, not `setTimeout` |
| Tests pass locally but fail in CI | Add `retries: 2` for CI, check `baseURL` is correct |
| Can't find elements | Use `getByRole` and `getByText` over CSS selectors |
| Auth tests keep failing | Use storageState to persist auth between tests |

## Next Steps

- See the `e2e-testing` skill for advanced Playwright patterns.
- Read [tdd-workflow.md](./tdd-workflow.md) for the TDD cycle with E2E tests.
