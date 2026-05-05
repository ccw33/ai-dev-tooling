---
name: project-discovery
description: >
  Guide for discovering user flows, UI structure, auth mechanisms, and API surfaces
  in an existing project before writing E2E tests. Covers a seven-phase pipeline
  from application reconnaissance through seed test generation. Use when: onboarding
  an existing project for E2E testing, planning test coverage, deciding fixture
  strategy. Triggers: "discover project", "map user flows", "E2E planning",
  "test strategy", "page inventory", "auth discovery".
---

> Source: [SKILL.md](../SKILL.md)

# Project Discovery for E2E Testing

Before writing a single test, you need to understand the application. This document describes a repeatable discovery pipeline that maps user flows, page structure, auth mechanics, and API contracts. The output is a test strategy document and a seed test that anchors all future work.

Skipping discovery leads to flaky tests, wrong fixture strategies, and gaps in coverage. Invest the time upfront.

## Phase 1: Application Reconnaissance

Goal: get a high-level picture of the application's shape.

1. Start the dev server. If one is already running, note the port.

```typescript
// Basic connectivity check
import { test, expect } from '@playwright/test';

test('app loads', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveTitle(/./); // any non-empty title
});
```

2. Use Playwright MCP tools or `browser-use` to walk the app:
   - `browser_navigate` to the root URL
   - `browser_snapshot` to capture the accessibility tree (reveals structure without screenshots)
   - `browser_take_screenshot` for visual reference on key pages

3. Map all reachable routes. Sources:
   - Navigation links in the header, sidebar, and footer
   - Router config file (e.g., `app/router.ts`, `next.config.js`, `nuxt.config.ts`)
   - Sitemap or `robots.txt`
   - `page.goto` each route and verify it renders (no 404, no blank page)

4. Identify the tech stack from HTML and network responses:
   - Framework signatures in the DOM (`__NEXT_DATA__`, `__NUXT__`, `ng-version`)
   - Meta tags (`generator`, `framework`)
   - Script sources and bundle paths

Record the route map as a simple list:

```
/                   - Landing page (public)
/login              - Login form (public)
/dashboard          - User dashboard (auth required)
/settings           - User settings (auth required)
/admin              - Admin panel (admin role)
/products           - Product listing (public)
/products/:id       - Product detail (public)
/cart               - Shopping cart (auth required)
/checkout           - Checkout flow (auth required)
```

## Phase 2: User Flow Discovery

Goal: identify the primary journeys users take through the application.

### Common Flow Patterns

| Flow Type | Typical Steps | Entry Point |
|-----------|--------------|-------------|
| Auth | Login, dashboard, logout | `/login` |
| CRUD | List, create, edit, delete | List page |
| Search | Query, filter, results, detail | Search bar or filter page |
| Checkout | Cart, shipping, payment, confirmation | `/cart` |
| Settings | View profile, edit, save | `/settings` |

### Documenting a Flow

For each flow, capture these details:

```yaml
flow: "User login"
entry: "/login"
steps:
  - page: "/login"
    action: "fill email field with 'user@example.com'"
    target: "getByLabel('Email')"
  - page: "/login"
    action: "fill password field"
    target: "getByLabel('Password')"
  - page: "/login"
    action: "click submit button"
    target: "getByRole('button', { name: 'Sign in' })"
  - page: "/dashboard"
    action: "verify dashboard loaded"
    target: "getByRole('heading', { name: 'Dashboard' })"
success_criteria: "URL changes to /dashboard, heading visible"
failure_paths:
  - "Wrong credentials: error toast with 'Invalid email or password'"
  - "Empty fields: inline validation messages"
```

### How to Discover Flows

1. Start from each public route and follow every link and button.
2. For auth-gated routes, log in first, then repeat.
3. Pay attention to forms. Every form is a flow.
4. Look for navigation that changes state (adding to cart, toggling settings).

## Phase 3: Page Structure Analysis

Goal: inventory every interactive element on each page.

For each page in the user flows:

1. **Identify interactive elements.** Use the accessibility tree, not the DOM.

```typescript
// Capture the accessibility tree for analysis
test('map page structure', async ({ page }) => {
  await page.goto('/products');

  // Print the accessibility tree to understand structure
  const tree = await page.accessibility.snapshot();
  console.log(JSON.stringify(tree, null, 2));

  // Count interactive elements by role
  const buttons = await page.getByRole('button').count();
  const links = await page.getByRole('link').count();
  const inputs = await page.getByRole('textbox').count();

  console.log(`Buttons: ${buttons}, Links: ${links}, Inputs: ${inputs}`);
});
```

2. **Map form fields and validation rules.** Submit empty forms to trigger validation.

```typescript
test('discover form validation', async ({ page }) => {
  await page.goto('/login');

  // Submit empty form to discover validation messages
  await page.getByRole('button', { name: 'Sign in' }).click();

  // Collect visible error messages
  const errors = await page.getByRole('alert').allTextContents();
  console.log('Validation errors:', errors);
});
```

3. **Detect dynamic content.** Watch for data tables, infinite scroll, modals, and tabs.

4. **Find auth-gated content.** Compare the page logged in vs logged out. Elements that appear or disappear define the auth boundary.

### Page Inventory Format

| Page | Key Elements | Interactions | Auth Required |
|------|-------------|--------------|---------------|
| `/login` | Email input, password input, submit button | Fill form, submit | No |
| `/dashboard` | Welcome heading, stats cards, nav links | View stats, navigate | Yes |
| `/products` | Product grid, search bar, filter dropdowns | Search, filter, click product | No |
| `/products/:id` | Product image, price, add-to-cart button | Add to cart | No |
| `/cart` | Cart items, quantity inputs, checkout button | Update quantity, checkout | Yes |
| `/settings` | Profile form, save button, delete account link | Edit profile, save | Yes |

## Phase 4: Auth Flow Analysis

Goal: understand the auth mechanism so you can choose the right fixture strategy.

### Questions to Answer

1. **How does the user authenticate?** Email/password, OAuth (Google, GitHub), magic link, SSO?
2. **What tokens or cookies are set after login?** Check `localStorage`, `sessionStorage`, cookies.
3. **Where is auth state stored?** This determines how you persist it across tests.
4. **Which routes require auth?** Compare the route map from Phase 1 against access.
5. **What roles exist?** Admin, user, viewer, guest. Each role may need its own fixture.

### How to Inspect Auth

```typescript
test('inspect auth state', async ({ page, context }) => {
  await page.goto('/login');
  await page.getByLabel('Email').fill('user@example.com');
  await page.getByLabel('Password').fill('password123');
  await page.getByRole('button', { name: 'Sign in' }).click();

  // Wait for redirect after login
  await page.waitForURL('/dashboard');

  // Check cookies
  const cookies = await context.cookies();
  console.log('Cookies:', cookies.map(c => ({ name: c.name, domain: c.domain })));

  // Check localStorage
  const storage = await page.evaluate(() => {
    const entries: Record<string, string> = {};
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (key) entries[key] = localStorage.getItem(key) ?? '';
    }
    return entries;
  });
  console.log('localStorage:', Object.keys(storage));
});
```

### Fixture Strategy Decision

| Auth Complexity | Strategy | When to Use |
|----------------|----------|-------------|
| Simple (email/password, single token) | Inline login in fixture | Small apps, few auth tests |
| Medium (JWT in localStorage) | `storageState` with setup script | Most common case |
| Complex (OAuth, multiple roles) | `storageState` per role, setup scripts per role | Apps with role-based access |
| Custom (SSO, magic link) | Custom fixture with API calls | When login cannot be automated via UI |

## Phase 5: API Surface Discovery

Goal: know which APIs the frontend calls so you can decide what to mock and what to test against.

### Monitoring Network Requests

```typescript
test('discover API endpoints', async ({ page }) => {
  const requests: Array<{ method: string; url: string; status: number }> = [];

  page.on('response', async (response) => {
    const url = new URL(response.url());
    // Filter to API calls only (skip static assets)
    if (url.pathname.startsWith('/api/') || url.hostname.includes('api.')) {
      requests.push({
        method: response.request().method(),
        url: url.pathname,
        status: response.status(),
      });
    }
  });

  await page.goto('/products');
  await page.waitForLoadState('networkidle');

  console.table(requests);
});
```

### What to Record

For each endpoint:

| Field | Example |
|-------|---------|
| Method | `GET` |
| URL pattern | `/api/products/:id` |
| Request body | `{ "query": "shoes", "page": 1 }` |
| Response shape | `{ "items": [...], "total": 42 }` |
| Error responses | `401 Unauthorized`, `404 Not Found` |
| Source | Own backend or third-party |

### Mocking Decisions

- **Own backend APIs**: Test against a real staging/dev instance. Mocking your own APIs hides integration bugs.
- **Third-party APIs**: Mock them. Payment processors, email services, analytics. You control the response.
- **Unstable or slow APIs**: Consider mocking if they block CI. Add a separate integration test for the real call.

## Phase 6: Test Strategy and Priority

Goal: produce an ordered test plan that delivers value immediately.

### Priority Tiers

1. **Smoke tests (3-5 tests).** Does the app load? Does login work? Do the main routes render? These catch deploy-breaking issues in minutes.
2. **Critical path tests (5-10 tests).** The core user journeys that generate revenue or deliver primary value. If these break, the business is impacted.
3. **Regression guards (ongoing).** Every bug fix gets a test. The bug description becomes the test name.
4. **Edge cases (later).** Error states, empty states, concurrent actions, mobile viewports. Important but not day-one work.

### Test Plan Format

For each test, specify:

```yaml
test: "User can add product to cart and checkout"
priority: "critical_path"
prerequisites:
  - "Authenticated user fixture"
  - "At least one product exists"
steps:
  - "Navigate to /products"
  - "Click on first product card"
  - "Click 'Add to Cart' button"
  - "Navigate to /cart"
  - "Click 'Checkout' button"
  - "Fill shipping form"
  - "Submit payment"
assertions:
  - "Order confirmation page shows order number"
  - "Cart is empty after checkout"
```

### Coverage Mapping

Cross-reference the user flows from Phase 2 with the test plan:

| User Flow | Smoke | Critical Path | Regression | Edge Case |
|-----------|-------|---------------|------------|-----------|
| Login/Logout | Yes | | | |
| Browse products | Yes | Yes | | |
| Add to cart | | Yes | | |
| Checkout | | Yes | | |
| Search/filter | | Yes | | |
| Profile settings | | | | Later |

Gaps in the table reveal untested flows. Fill them in priority order.

## Phase 7: Seed Test Generation

Goal: create a single test that proves the setup works and serves as a template for all other tests.

### What the Seed Test Does

1. Navigates to the app root
2. Dismisses common blockers (cookie banners, announcement modals)
3. Verifies the app rendered correctly
4. Confirms the test infrastructure is working

### Seed Test Template

```typescript
import { test, expect } from '@playwright/test';

test.describe('Seed: App Loads', () => {
  test('homepage renders and key elements are visible', async ({ page }) => {
    await page.goto('/');

    // Dismiss cookie banner if present
    const cookieBanner = page.getByRole('button', { name: /accept.*cookies/i });
    if (await cookieBanner.isVisible()) {
      await cookieBanner.click();
    }

    // Dismiss announcement modal if present
    const dismissModal = page.getByRole('button', { name: /close|dismiss/i }).first();
    if (await dismissModal.isVisible()) {
      await dismissModal.click();
    }

    // Verify core page structure
    const heading = page.getByRole('heading', { level: 1 }).first();
    await expect(heading).toBeVisible();

    // Verify navigation exists
    const nav = page.getByRole('navigation').first();
    await expect(nav).toBeVisible();

    // Verify no console errors (optional, adjust threshold)
    const consoleErrors: string[] = [];
    page.on('console', (msg) => {
      if (msg.type() === 'error') consoleErrors.push(msg.text());
    });

    // Navigate to a second page to confirm routing works
    const firstNavLink = nav.getByRole('link').first();
    const linkText = await firstNavLink.textContent();
    if (linkText?.trim()) {
      await firstNavLink.click();
      await page.waitForLoadState('domcontentloaded');
      await expect(page).toHaveURL(/./); // URL changed from root
    }

    // Report console errors as test failures
    expect(consoleErrors.filter(e => !e.includes('favicon'))).toHaveLength(0);
  });
});
```

### Using the Seed Test as a Template

Every new test should follow the same structure:

1. Navigate to the starting page
2. Handle any modal/banner blockers
3. Perform user actions
4. Assert the expected outcome
5. Verify no unexpected console errors

Copy the seed test, change the `test.describe` name and the `goto` target, then fill in the user actions. This keeps the test suite consistent and avoids repeated boilerplate for common setup.

---

## Human Checkpoints

E2E tests are expensive to write and maintain. Human judgment is critical at these gates:

### Checkpoint 1: Review User Flow Map (after Phase 2)

AI discovers flows from code and navigation, but cannot know:

- **Which flows generate revenue**: A "browse products" flow might look equal to
  "update profile", but the business values them differently.
- **Non-obvious flows**: Admin panels, invite-only features, multi-step approvals
  that require specific account states AI cannot create.
- **Deprecated flows**: Routes that exist in code but are no longer used.

**Action**: Present the flow map (Phase 2 output) to the human. Let them add,
remove, and reprioritize before test planning begins.

### Checkpoint 2: Review Test Plan (after Phase 6)

The test strategy document needs human confirmation:

- **Priority tiers**: AI ranks by coverage gaps. Humans rank by business impact.
  A smoke test for a revenue-critical checkout flow is more important than
  edge-case tests for a settings page.
- **Auth fixture strategy**: If the app uses OAuth/SSO, the human must provide
  test credentials or approve the fixture approach. AI cannot create these.
- **Third-party mocking decisions**: Which external services to mock vs test
  against. Humans know which integrations are stable vs flaky.

**Action**: Do NOT proceed to write E2E tests until the human confirms the plan.

### Checkpoint 3: Review Test Code (after each priority tier)

E2E tests are particularly prone to AI-generated issues:

- **Brittle selectors**: AI may choose CSS classes or text that change frequently.
  Humans must verify selectors are resilient (prefer `getByRole`, `getByLabel`).
- **Missing wait strategies**: AI may not account for async content, animations,
  or loading states specific to this app.
- **Over-specified assertions**: Asserting exact text content instead of semantic
  meaning makes tests fragile to minor copy changes.

**Action**: After each tier, present the test files to the human. Focus review
on selector resilience and wait strategy correctness.

### Checkpoint 4: Flakiness Review (after CI runs)

After the first CI run with real E2E tests:

- **Failed tests**: Human must triage -- is it a real bug, a flaky test, or an
  environment issue?
- **Execution time**: E2E tests should complete within a reasonable window. Human
  must decide which tests to parallelize, which to move to a nightly run.
- **False positives**: Tests that pass but don't actually validate meaningful
  behavior (e.g., asserting page loaded but not checking correct data).

**Action**: Human must review the first full CI run and accept or flag each
test result before marking the E2E suite as production-ready.
