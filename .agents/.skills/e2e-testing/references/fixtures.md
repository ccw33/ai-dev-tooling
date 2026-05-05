---
name: fixtures
description: >
  Custom Playwright fixtures with TypeScript types, authenticated page fixture using
  storageState, auth setup scripts, and test file usage patterns. Use when: setting up
  test fixtures, reusing auth state, sharing page objects across tests.
  Triggers: "fixture", "authenticated page", "storageState", "auth setup", "test extension".
---

> Source: [SKILL.md](../SKILL.md)

# Fixtures

## Custom Fixture Pattern

Fixtures extend the base `test` object with reusable setup. Define once, import in every test file.

```typescript
// fixtures/auth.fixture.ts
import { test as base, Page, BrowserContext } from '@playwright/test';
import { LoginPage } from '../pages/login.page';

type AuthFixtures = {
  authenticatedPage: Page;
  authContext: BrowserContext;
};

export const test = base.extend<AuthFixtures>({
  authenticatedPage: async ({ browser }, use) => {
    const context = await browser.newContext({
      storageState: 'playwright/.auth/user.json',
    });
    const page = await context.newPage();
    await use(page);
    await context.close();
  },

  authContext: async ({ browser }, use) => {
    const context = await browser.newContext({
      storageState: 'playwright/.auth/admin.json',
    });
    await use(context);
    await context.close();
  },
});

export { expect } from '@playwright/test';
```

## Auth Setup Script

The setup project runs once before all tests. It performs a real login and saves the session to a JSON file. Tests reuse this saved session instead of logging in every time.

```typescript
// tests/e2e/auth.setup.ts
import { test as setup, expect } from '@playwright/test';

const authFile = 'playwright/.auth/user.json';

setup('authenticate', async ({ page }) => {
  await page.goto('/login');

  await page.getByLabel('Email').fill(process.env.E2E_USER_EMAIL!);
  await page.getByLabel('Password').fill(process.env.E2E_USER_PASSWORD!);
  await page.getByRole('button', { name: 'Sign in' }).click();

  // Wait for login to complete by confirming redirect
  await page.waitForURL('/dashboard');
  await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible();

  // Save the authenticated state
  await page.context().storageState({ path: authFile });
});
```

### Multiple Auth Roles

Save separate state files for different user roles.

```typescript
// tests/e2e/auth.setup.ts
import { test as setup, expect } from '@playwright/test';

setup('authenticate as admin', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel('Email').fill(process.env.ADMIN_EMAIL!);
  await page.getByLabel('Password').fill(process.env.ADMIN_PASSWORD!);
  await page.getByRole('button', { name: 'Sign in' }).click();
  await page.waitForURL('/admin');
  await page.context().storageState({ path: 'playwright/.auth/admin.json' });
});

setup('authenticate as regular user', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel('Email').fill(process.env.USER_EMAIL!);
  await page.getByLabel('Password').fill(process.env.USER_PASSWORD!);
  await page.getByRole('button', { name: 'Sign in' }).click();
  await page.waitForURL('/dashboard');
  await page.context().storageState({ path: 'playwright/.auth/user.json' });
});
```

## Test File Using Custom Fixtures

Import `test` and `expect` from your fixture file, not from `@playwright/test`.

```typescript
// tests/e2e/dashboard/dashboard.spec.ts
import { test, expect } from '../../fixtures/auth.fixture';
import { DashboardPage } from '../../pages/dashboard.page';

test.describe('Dashboard', () => {
  test('shows welcome message after login', async ({ authenticatedPage }) => {
    const dashboard = new DashboardPage(authenticatedPage);
    await dashboard.goto();

    await expect(dashboard.welcomeMessage).toBeVisible();
    await expect(dashboard.welcomeMessage).toContainText('Welcome');
  });

  test('displays recent orders', async ({ authenticatedPage }) => {
    const dashboard = new DashboardPage(authenticatedPage);
    await dashboard.goto();

    await expect(dashboard.recentOrders).toHaveCount(await dashboard.getRecentOrderCount());
  });
});
```

## Fixture with Page Object Injection

Inject page objects directly as fixtures for cleaner test code.

```typescript
// fixtures/pages.fixture.ts
import { test as base } from '@playwright/test';
import { DashboardPage } from '../pages/dashboard.page';
import { CartPage } from '../pages/cart.page';

type PageFixtures = {
  dashboardPage: DashboardPage;
  cartPage: CartPage;
};

export const test = base.extend<PageFixtures>({
  dashboardPage: async ({ authenticatedPage }, use) => {
    const dashboard = new DashboardPage(authenticatedPage);
    await dashboard.goto();
    await use(dashboard);
  },

  cartPage: async ({ authenticatedPage }, use) => {
    const cart = new CartPage(authenticatedPage);
    await use(cart);
  },
});

export { expect } from '@playwright/test';
```

```typescript
// tests/e2e/dashboard/dashboard.spec.ts
import { test, expect } from '../../fixtures/pages.fixture';

test('dashboard shows user stats', async ({ dashboardPage }) => {
  // dashboardPage is already navigated and ready
  await expect(dashboardPage.statsPanel).toBeVisible();
});
```

## Common Fixture Patterns

### API-Seeded Data Fixture

```typescript
type DataFixtures = {
  testProduct: { id: string; name: string };
};

export const test = base.extend<DataFixtures>({
  testProduct: async ({ request }, use) => {
    // Create test data via API
    const response = await request.post('/api/products', {
      data: { name: 'Test Widget', price: 9.99 },
    });
    const product = await response.json();

    await use(product);

    // Cleanup after test
    await request.delete(`/api/products/${product.id}`);
  },
});
```

### Combined Fixtures

```typescript
// fixtures/app.fixture.ts
import { test as base, Page } from '@playwright/test';
import { DashboardPage } from '../pages/dashboard.page';

type AppFixtures = {
  authenticatedPage: Page;
  dashboardPage: DashboardPage;
  testProduct: { id: string; name: string };
};

export const test = base.extend<AppFixtures>({
  authenticatedPage: async ({ browser }, use) => {
    const context = await browser.newContext({
      storageState: 'playwright/.auth/user.json',
    });
    const page = await context.newPage();
    await use(page);
    await context.close();
  },

  dashboardPage: async ({ authenticatedPage }, use) => {
    const dashboard = new DashboardPage(authenticatedPage);
    await dashboard.goto();
    await use(dashboard);
  },

  testProduct: async ({ request }, use) => {
    const response = await request.post('/api/products', {
      data: { name: 'Test Widget', price: 9.99 },
    });
    const product = await response.json();
    await use(product);
    await request.delete(`/api/products/${product.id}`);
  },
});

export { expect } from '@playwright/test';
```

## Rules

1. Import `test` and `expect` from your fixture file, never from `@playwright/test` directly.
2. Auth setup scripts run in the `setup` project, which all other projects depend on.
3. Storage state files go in `playwright/.auth/` and should be gitignored.
4. Each fixture cleans up after itself (close contexts, delete test data).
5. Never share mutable state between fixtures. Each test gets fresh instances.
