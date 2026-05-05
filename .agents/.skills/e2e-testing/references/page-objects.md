---
name: page-objects
description: >
  Page Object Model patterns for Playwright E2E tests. Covers BasePage abstract class,
  concrete page implementation, locator conventions, action methods, and the three-layer
  test architecture. Use when: writing page objects, structuring test code, implementing POM.
  Triggers: "page object", "POM", "base page", "page class", "test architecture".
---

> Source: [SKILL.md](../SKILL.md)

# Page Object Model

## BasePage Abstract Class

Every page object extends this. It provides shared navigation and utility methods.

```typescript
import { Page, Locator } from '@playwright/test';

export abstract class BasePage {
  readonly page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  async navigate(path: string): Promise<void> {
    await this.page.goto(path);
  }

  async waitForPageLoad(): Promise<void> {
    await this.page.waitForLoadState('networkidle');
  }

  async getTitle(): Promise<string> {
    return this.page.title();
  }

  async takeScreenshot(name: string): Promise<void> {
    await this.page.screenshot({ path: `screenshots/${name}.png` });
  }
}
```

## Concrete Page Class Pattern

LoginPage shows the standard pattern: typed Locators as readonly properties, initialized in the constructor.

```typescript
import { Page, Locator } from '@playwright/test';
import { BasePage } from './base.page';
import { DashboardPage } from './dashboard.page';

export class LoginPage extends BasePage {
  // Locators: typed, readonly, defined in constructor
  readonly emailInput: Locator;
  readonly passwordInput: Locator;
  readonly submitButton: Locator;
  readonly errorMessage: Locator;
  readonly forgotPasswordLink: Locator;

  constructor(page: Page) {
    super(page);
    this.emailInput = page.getByLabel('Email');
    this.passwordInput = page.getByLabel('Password');
    this.submitButton = page.getByRole('button', { name: 'Sign in' });
    this.errorMessage = page.getByRole('alert');
    this.forgotPasswordLink = page.getByRole('link', { name: 'Forgot password' });
  }

  // Navigation returns the page itself
  async goto(): Promise<LoginPage> {
    await this.navigate('/login');
    return this;
  }

  // Actions are public methods. Each does one thing.
  async fillCredentials(email: string, password: string): Promise<void> {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
  }

  async submit(): Promise<void> {
    await this.submitButton.click();
  }

  // Navigation that changes page returns the destination page object
  async loginAs(email: string, password: string): Promise<DashboardPage> {
    await this.fillCredentials(email, password);
    await this.submit();
    return new DashboardPage(this.page);
  }

  async clickForgotPassword(): Promise<void> {
    await this.forgotPasswordLink.click();
  }
}
```

## Key Rules

1. **All locators in the constructor.** Never call `page.locator()` inside action methods. Define them once as `readonly` properties.

2. **Actions are public methods.** Each method performs a single user action: `fillCredentials`, `submit`, `clickForgotPassword`.

3. **Assertions NEVER go in page objects.** Page objects return values or page objects. Assertions live in tests.

4. **Navigation returns the destination page object.** When `loginAs()` succeeds, it returns a `DashboardPage`. This enables fluent chaining and type safety.

5. **No business logic.** Page objects know about the DOM, not about business rules. That belongs in modules.

## Three-Layer Architecture

```
Pages (locators + single actions)
  |
  v
Modules (business flows, compose page actions)
  |
  v
Tests (scenarios + assertions only)
```

### Pages

Pages own locators and atomic actions. They are thin wrappers over the DOM.

```typescript
// pages/cart.page.ts
export class CartPage extends BasePage {
  readonly items: Locator;
  readonly checkoutButton: Locator;
  readonly emptyCartMessage: Locator;

  constructor(page: Page) {
    super(page);
    this.items = page.getByTestId('cart-item');
    this.checkoutButton = page.getByRole('button', { name: 'Checkout' });
    this.emptyCartMessage = page.getByText('Your cart is empty');
  }

  async goto(): Promise<CartPage> {
    await this.navigate('/cart');
    return this;
  }

  async getItemCount(): Promise<number> {
    return this.items.count();
  }

  async removeItem(index: number): Promise<void> {
    await this.items.nth(index).getByRole('button', { name: 'Remove' }).click();
  }

  async checkout(): Promise<CheckoutPage> {
    await this.checkoutButton.click();
    return new CheckoutPage(this.page);
  }
}
```

### Modules

Modules compose page actions into business flows. They orchestrate multiple pages but contain zero assertions.

```typescript
// modules/shopping.module.ts
import { Page } from '@playwright/test';
import { ProductsPage } from '../pages/products.page';
import { CartPage } from '../pages/cart.page';
import { CheckoutPage } from '../pages/checkout.page';

export class ShoppingModule {
  readonly productsPage: ProductsPage;
  readonly cartPage: CartPage;

  constructor(private page: Page) {
    this.productsPage = new ProductsPage(page);
    this.cartPage = new CartPage(page);
  }

  async addItemsToCart(itemNames: string[]): Promise<CartPage> {
    for (const name of itemNames) {
      await this.productsPage.addItemByName(name);
    }
    return this.cartPage.goto();
  }

  async completePurchase(itemNames: string[]): Promise<CheckoutPage> {
    const cartPage = await this.addItemsToCart(itemNames);
    return cartPage.checkout();
  }
}
```

### Tests

Tests use modules and pages. Tests are the only place with assertions.

```typescript
// tests/e2e/cart/cart.spec.ts
import { test, expect } from '../../fixtures/auth.fixture';
import { ShoppingModule } from '../../modules/shopping.module';

test('user can add items and see them in cart', async ({ authenticatedPage }) => {
  const shopping = new ShoppingModule(authenticatedPage);

  const cartPage = await shopping.addItemsToCart(['Widget', 'Gadget']);

  await expect(cartPage.items).toHaveCount(2);
  await expect(cartPage.checkoutButton).toBeVisible();
});

test('removing all items shows empty cart', async ({ authenticatedPage }) => {
  const shopping = new ShoppingModule(authenticatedPage);

  const cartPage = await shopping.addItemsToCart(['Widget']);

  await cartPage.removeItem(0);

  await expect(cartPage.emptyCartMessage).toBeVisible();
  await expect(cartPage.items).toHaveCount(0);
});
```

## File Organization

```
tests/
  e2e/
    pages/
      base.page.ts
      login.page.ts
      cart.page.ts
      checkout.page.ts
    modules/
      shopping.module.ts
      auth.module.ts
    fixtures/
      auth.fixture.ts
    auth/
      login.spec.ts
    cart/
      cart.spec.ts
    checkout/
      checkout.spec.ts
```
