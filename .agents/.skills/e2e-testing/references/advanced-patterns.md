---
name: advanced-patterns
description: >
  Advanced Playwright patterns including network interception, file upload, dialog handling,
  iframe handling, dropdown/select elements, and multi-step navigation. Use when: mocking
  API responses, handling file uploads, working with iframes, intercepting network requests.
  Triggers: "network interception", "mock API", "file upload", "iframe", "dialog", "route",
  "waitForResponse", "setInputFiles", "frameLocator".
---

> Source: [SKILL.md](../SKILL.md)

# Advanced Patterns

## Network Interception

### Mock API Responses

Use `page.route()` to intercept requests and return controlled data. This removes backend dependencies from your tests.

```typescript
import { test, expect } from '@playwright/test';

test('shows product details from API', async ({ page }) => {
  // Intercept the API call and return mock data
  await page.route('**/api/products/42', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({
        id: 42,
        name: 'Test Widget',
        price: 19.99,
        inStock: true,
      }),
    });
  });

  await page.goto('/products/42');

  await expect(page.getByText('Test Widget')).toBeVisible();
  await expect(page.getByText('$19.99')).toBeVisible();
});

test('handles API error gracefully', async ({ page }) => {
  await page.route('**/api/products/42', async (route) => {
    await route.fulfill({
      status: 500,
      contentType: 'application/json',
      body: JSON.stringify({ error: 'Internal Server Error' }),
    });
  });

  await page.goto('/products/42');

  await expect(page.getByText('Something went wrong')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Retry' })).toBeVisible();
});
```

### Assert Network Requests

Use `waitForResponse()` to verify that the correct API call was made with the right payload.

```typescript
test('submits form and calls API', async ({ page }) => {
  await page.goto('/contact');

  // Set up the response listener before the action
  const responsePromise = page.waitForResponse(
    (resp) => resp.url().includes('/api/contact') && resp.status() === 201
  );

  await page.getByLabel('Name').fill('Jane Doe');
  await page.getByLabel('Message').fill('Hello');
  await page.getByRole('button', { name: 'Send' }).click();

  const response = await responsePromise;
  const body = await response.json();

  expect(body.status).toBe('sent');
});

test('verifies request payload', async ({ page }) => {
  await page.goto('/settings');

  const requestPromise = page.waitForRequest(
    (req) => req.url().includes('/api/settings') && req.method() === 'PUT'
  );

  await page.getByLabel('Display name').fill('New Name');
  await page.getByRole('button', { name: 'Save' }).click();

  const request = await requestPromise;
  const payload = request.postDataJSON();

  expect(payload.displayName).toBe('New Name');
});
```

### Modify Responses

```typescript
test('shows discounted price', async ({ page }) => {
  await page.route('**/api/products/*', async (route) => {
    const response = await route.fetch();
    const body = await response.json();
    body.price = body.price * 0.8;  // Apply 20% discount
    await route.fulfill({
      response,
      body: JSON.stringify(body),
    });
  });

  await page.goto('/products/1');
  await expect(page.getByTestId('discount-badge')).toBeVisible();
});
```

## File Upload

### setInputFiles

```typescript
test('uploads a single file', async ({ page }) => {
  await page.goto('/upload');

  await page.setInputFiles('input[type="file"]', 'testdata/document.pdf');
  await page.getByRole('button', { name: 'Upload' }).click();

  await expect(page.getByText('Upload complete')).toBeVisible();
});

test('uploads multiple files', async ({ page }) => {
  await page.goto('/upload');

  await page.setInputFiles('input[type="file"]', [
    'testdata/file1.pdf',
    'testdata/file2.pdf',
    'testdata/file3.pdf',
  ]);
  await page.getByRole('button', { name: 'Upload' }).click();

  await expect(page.getByText('3 files uploaded')).toBeVisible();
});

test('removes uploaded file', async ({ page }) => {
  await page.goto('/upload');

  await page.setInputFiles('input[type="file"]', 'testdata/document.pdf');
  await page.setInputFiles('input[type="file"]', []);  // Clear the input

  await expect(page.getByRole('button', { name: 'Upload' })).toBeDisabled();
});
```

### Upload with File Chooser

For custom upload buttons that don't use a standard file input.

```typescript
test('uploads via custom button', async ({ page }) => {
  await page.goto('/upload');

  const fileChooserPromise = page.waitForEvent('filechooser');
  await page.getByRole('button', { name: 'Choose file' }).click();
  const fileChooser = await fileChooserPromise;
  await fileChooser.setFiles('testdata/document.pdf');

  await expect(page.getByText('document.pdf')).toBeVisible();
});
```

## Dialog Handling

```typescript
test('accepts confirm dialog', async ({ page }) => {
  await page.goto('/items/1');

  page.on('dialog', async (dialog) => {
    expect(dialog.type()).toBe('confirm');
    expect(dialog.message()).toBe('Are you sure you want to delete this item?');
    await dialog.accept();
  });

  await page.getByRole('button', { name: 'Delete' }).click();

  await expect(page.getByText('Item deleted')).toBeVisible();
});

test('dismisses confirm dialog', async ({ page }) => {
  await page.goto('/items/1');

  page.on('dialog', async (dialog) => {
    await dialog.dismiss();
  });

  await page.getByRole('button', { name: 'Delete' }).click();

  // Item should still exist
  await expect(page.getByText('Item Name')).toBeVisible();
});

test('fills prompt dialog', async ({ page }) => {
  page.on('dialog', async (dialog) => {
    await dialog.accept('My reason');
  });

  await page.getByRole('button', { name: 'Report' }).click();
  await expect(page.getByText('Report submitted')).toBeVisible();
});
```

## Iframe Handling

Use `frameLocator()` to interact with content inside iframes.

```typescript
test('interacts with iframe content', async ({ page }) => {
  await page.goto('/page-with-iframe');

  const iframe = page.frameLocator('iframe[title="Payment form"]');

  await iframe.getByLabel('Card number').fill('4242424242424242');
  await iframe.getByLabel('Expiry').fill('12/28');
  await iframe.getByLabel('CVC').fill('123');
  await iframe.getByRole('button', { name: 'Pay' }).click();

  await expect(page.getByText('Payment successful')).toBeVisible();
});

test('nested iframes', async ({ page }) => {
  await page.goto('/page-with-nested-iframes');

  const outerFrame = page.frameLocator('#outer-frame');
  const innerFrame = outerFrame.frameLocator('#inner-frame');

  await innerFrame.getByRole('button', { name: 'Submit' }).click();
});
```

## Dropdown and Select Elements

### Native Select

```typescript
test('selects option by value', async ({ page }) => {
  await page.goto('/settings');

  await page.getByLabel('Country').selectOption('US');
  await page.getByLabel('Language').selectOption({ label: 'English' });

  await expect(page.getByLabel('Country')).toHaveValue('US');
});

test('selects multiple options', async ({ page }) => {
  await page.goto('/settings');

  await page.getByLabel('Interests').selectOption(['tech', 'sports', 'music']);

  await expect(page.getByTestId('selected-count')).toHaveText('3 selected');
});
```

### Custom Dropdown (non-native)

```typescript
test('selects from custom dropdown', async ({ page }) => {
  await page.goto('/search');

  // Open the dropdown
  await page.getByRole('combobox', { name: 'Category' }).click();

  // Select from the dropdown list
  await page.getByRole('option', { name: 'Electronics' }).click();

  // Verify selection
  await expect(page.getByRole('combobox', { name: 'Category' })).toHaveText('Electronics');
});

test('searches in custom dropdown', async ({ page }) => {
  await page.goto('/search');

  await page.getByRole('combobox', { name: 'Category' }).click();
  await page.getByRole('combobox', { name: 'Category' }).fill('elec');

  // Filtered options appear
  await page.getByRole('option', { name: 'Electronics' }).click();
});
```

## Multi-Step Navigation Patterns

### Wizard/Multi-Step Form

```typescript
test('completes multi-step registration', async ({ page }) => {
  await page.goto('/register');

  // Step 1: Account info
  await page.getByLabel('Email').fill('user@example.com');
  await page.getByLabel('Password').fill('SecurePass123!');
  await page.getByRole('button', { name: 'Next' }).click();

  // Step 2: Profile
  await page.getByLabel('First name').fill('Jane');
  await page.getByLabel('Last name').fill('Doe');
  await page.getByRole('button', { name: 'Next' }).click();

  // Step 3: Confirm
  await page.getByRole('checkbox', { name: 'I agree to the terms' }).check();
  await page.getByRole('button', { name: 'Create account' }).click();

  // Verify completion
  await expect(page).toHaveURL('/welcome');
  await expect(page.getByText('Account created')).toBeVisible();
});
```

### Page Object for Multi-Step Flow

```typescript
// pages/registration.page.ts
import { BasePage } from './base.page';
import { Page, Locator } from '@playwright/test';

export class RegistrationPage extends BasePage {
  readonly step1Email: Locator;
  readonly step1Password: Locator;
  readonly step2FirstName: Locator;
  readonly step2LastName: Locator;
  readonly step3AgreeCheckbox: Locator;
  readonly nextButton: Locator;
  readonly submitButton: Locator;
  readonly stepIndicator: Locator;

  constructor(page: Page) {
    super(page);
    this.step1Email = page.getByLabel('Email');
    this.step1Password = page.getByLabel('Password');
    this.step2FirstName = page.getByLabel('First name');
    this.step2LastName = page.getByLabel('Last name');
    this.step3AgreeCheckbox = page.getByRole('checkbox', { name: 'I agree to the terms' });
    this.nextButton = page.getByRole('button', { name: 'Next' });
    this.submitButton = page.getByRole('button', { name: 'Create account' });
    this.stepIndicator = page.getByTestId('step-indicator');
  }

  async goto(): Promise<RegistrationPage> {
    await this.navigate('/register');
    return this;
  }

  async fillAccountInfo(email: string, password: string): Promise<void> {
    await this.step1Email.fill(email);
    await this.step1Password.fill(password);
    await this.nextButton.click();
  }

  async fillProfile(firstName: string, lastName: string): Promise<void> {
    await this.step2FirstName.fill(firstName);
    await this.step2LastName.fill(lastName);
    await this.nextButton.click();
  }

  async agreeAndSubmit(): Promise<void> {
    await this.step3AgreeCheckbox.check();
    await this.submitButton.click();
  }

  async getCurrentStep(): Promise<string> {
    return this.stepIndicator.innerText();
  }
}
```
