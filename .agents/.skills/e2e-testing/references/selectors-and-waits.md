---
name: selectors-and-waits
description: >
  Selector priority order, code examples for each type, web-first assertions,
  auto-wait mechanism, and anti-patterns. Use when: writing locators, choosing selectors,
  debugging waits, writing assertions. Triggers: "selector", "locator", "waitFor", "assertion",
  "getByRole", "getByTestId", "auto-wait".
---

> Source: [SKILL.md](../SKILL.md)

# Selectors and Waits

## Selector Priority Order

Use the highest-priority selector that works for your element.

| Priority | Selector | When to Use |
|----------|----------|-------------|
| 1 | `getByRole` | Buttons, links, checkboxes, any element with ARIA role |
| 2 | `getByLabel` | Form inputs with associated labels |
| 3 | `getByPlaceholder` | Inputs without visible labels |
| 4 | `getByText` | Headings, paragraphs, spans, non-interactive content |
| 5 | `getByTestId` | Dynamic lists, elements without semantic identifiers |
| 6 | CSS / XPath | Last resort. Fragile, breaks on redesign |

## Selector Examples

### getByRole (Preferred)

Queries the accessibility tree. The most resilient selector.

```typescript
await page.getByRole('button', { name: 'Submit' }).click();
await page.getByRole('link', { name: 'Dashboard' }).click();
await page.getByRole('checkbox', { name: 'Accept terms' }).check();
await page.getByRole('textbox', { name: 'Email' }).fill('user@example.com');
await page.getByRole('heading', { name: 'Welcome' });
await page.getByRole('alert');
await page.getByRole('dialog');
await page.getByRole('tab', { name: 'Settings' }).click();
await page.getByRole('option', { name: 'United States' }).click();
```

### getByLabel

For form inputs that have an associated `<label>` element.

```typescript
await page.getByLabel('First name').fill('Jane');
await page.getByLabel('Password').fill('secret123');
await page.getByLabel('Remember me').check();
await page.getByLabel('Country').selectOption('US');
```

### getByPlaceholder

For inputs without visible labels, only placeholder text.

```typescript
await page.getByPlaceholder('Search products...').fill('widget');
await page.getByPlaceholder('Enter your email').fill('a@b.com');
```

### getByText

For non-interactive elements: headings, paragraphs, status messages.

```typescript
await expect(page.getByText('Order confirmed')).toBeVisible();
page.getByText('Add to cart');          // partial match
page.getByText('Add to cart', { exact: true });  // exact match
```

### getByTestId

For dynamic content where semantic selectors are not feasible. Requires `data-testid` attributes in markup.

```typescript
// HTML: <div data-testid="cart-item">Widget</div>
page.getByTestId('cart-item');
page.getByTestId('product-card').nth(2);
```

### CSS and XPath (Last Resort)

Fragile. Only use when no other option works.

```typescript
page.locator('.submit-button');        // CSS class
page.locator('#login-form');           // CSS id
page.locator('xpath=//button[@type="submit"]');  // XPath
```

## Web-First Assertions

Playwright assertions auto-retry until the condition passes or the timeout expires.

### Common Assertions

```typescript
import { expect } from '@playwright/test';

// Visibility
await expect(page.getByRole('heading', { name: 'Welcome' })).toBeVisible();
await expect(page.getByText('Loading...')).toBeHidden();

// Text content
await expect(page.getByRole('status')).toHaveText('Saved successfully');
await expect(page.getByTestId('price')).toContainText('$');

// Form values
await expect(page.getByLabel('Email')).toHaveValue('user@example.com');
await expect(page.getByLabel('Country')).toHaveValue('US');

// URL and title
await expect(page).toHaveURL('/dashboard');
await expect(page).toHaveTitle('Dashboard - MyApp');

// Count
await expect(page.getByTestId('cart-item')).toHaveCount(3);

// CSS classes and properties
await expect(page.getByRole('button', { name: 'Submit' })).toBeEnabled();
await expect(page.getByRole('checkbox', { name: 'Agree' })).toBeChecked();

// Screenshots (pixel-level comparison)
await expect(page).toHaveScreenshot('homepage.png');
```

### Negated Assertions

```typescript
await expect(page.getByText('Error')).not.toBeVisible();
await expect(page.getByRole('button', { name: 'Delete' })).not.toBeEnabled();
```

### Soft Assertions

Soft assertions don't stop the test. Use for non-critical checks.

```typescript
await expect.soft(page.getByTestId('footer')).toBeVisible();
await expect.soft(page.getByText('Version 2.0')).toBeVisible();
```

## Auto-Wait Mechanism

Playwright auto-waits before every action. You don't need manual waits for:

- Elements to become visible before clicking
- Elements to become stable (not animating) before interacting
- Network idle after navigation
- Elements to become enabled before acting

```typescript
// All of these auto-wait. No explicit waits needed.
await page.getByRole('button', { name: 'Submit' }).click();  // waits for visible + enabled
await page.getByLabel('Email').fill('a@b.com');              // waits for visible + editable
await page.getByTestId('dropdown').selectOption('US');       // waits for visible + enabled
```

### What Triggers a Wait

Every action (click, fill, check, selectOption, etc.) performs these checks before acting:

1. Element is attached to the DOM
2. Element is visible
3. Element is stable (not animating)
4. Element is enabled (not disabled)
5. Element receives events (not covered by overlay)

If any check fails, Playwright retries until the timeout (default 5s).

## Anti-Pattern: waitForTimeout

Never use `waitForTimeout`. It is a code smell that indicates flaky, time-dependent tests.

```typescript
// WRONG: arbitrary wait, slow and flaky
await page.waitForTimeout(3000);
await expect(page.getByText('Success')).toBeVisible();

// RIGHT: assertion auto-waits until condition is met or timeout
await expect(page.getByText('Success')).toBeVisible();

// WRONG: sleeping after an action
await page.getByRole('button', { name: 'Save' }).click();
await page.waitForTimeout(1000);

// RIGHT: assert the outcome of the action
await page.getByRole('button', { name: 'Save' }).click();
await expect(page.getByText('Changes saved')).toBeVisible();
```

## When Manual Waits Are Appropriate

Only a few legitimate cases exist:

```typescript
// Waiting for a navigation to complete
await page.waitForURL('/dashboard');

// Waiting for a specific network response
await page.waitForResponse(resp => resp.url().includes('/api/users') && resp.status() === 200);

// Waiting for a download to start
const downloadPromise = page.waitForEvent('download');
await page.getByRole('button', { name: 'Download' }).click();
const download = await downloadPromise;
```

## Custom Timeout

Override the default 5-second timeout per assertion:

```typescript
await expect(page.getByText('Processing complete')).toBeVisible({ timeout: 30_000 });
```
