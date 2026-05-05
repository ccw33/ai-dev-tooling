---
name: new-project-frontend
description: >
  Step-by-step guide to set up Vitest + React Testing Library for a brand new project.
  Includes copy-paste ready configs for both jsdom and Browser Mode approaches.
  Use when: starting a new project and need frontend test infrastructure from scratch.
  Triggers: "new project testing", "vitest setup", "frontend testing setup", "RTL setup".
---

# New Project: Frontend Testing (Vitest + RTL)

> Source: [testing-setup-guide.md](../testing-setup-guide.md)

This guide sets up Vitest with React Testing Library for a new project. Two approaches are covered: **jsdom** (fast, default) and **Browser Mode** (real browser, for components with browser APIs).

Choose jsdom unless you specifically need real browser behavior. You can switch later.

## Step 1: Install Dependencies

**jsdom approach:**

```bash
pnpm add -D vitest @testing-library/react @testing-library/jest-dom @testing-library/user-event jsdom
```

**Browser Mode approach (includes jsdom dependencies):**

```bash
pnpm add -D vitest @testing-library/react @testing-library/jest-dom @testing-library/user-event jsdom @vitest/browser playwright
pnpm add -D vitest-browser-react
```

## Step 2: Create vitest.config.ts

**jsdom approach:**

```typescript
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./vitest.setup.ts'],
    css: true,
    include: ['src/**/*.{test,spec}.{ts,tsx}'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      include: ['src/**/*.{ts,tsx}'],
      exclude: ['src/**/*.{test,spec}.{ts,tsx}', 'src/types/**'],
    },
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
});
```

**Browser Mode approach** (replace the `test` block):

```typescript
  test: {
    globals: true,
    browser: {
      enabled: true,
      instances: [{ browser: 'chromium' }],
    },
    setupFiles: ['./vitest.setup.ts'],
    css: true,
    include: ['src/**/*.{test,spec}.{ts,tsx}'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      include: ['src/**/*.{ts,tsx}'],
      exclude: ['src/**/*.{test,spec}.{ts,tsx}', 'src/types/**'],
    },
  },
```

## Step 3: Create Test Setup File

Create `vitest.setup.ts` at project root:

```typescript
import '@testing-library/jest-dom/vitest';
import { cleanup } from '@testing-library/react';
import { afterEach, vi } from 'vitest';

afterEach(() => {
  cleanup();
});

// Mock window.matchMedia if needed (jsdom doesn't implement it)
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation((query: string) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  })),
});
```

## Step 4: Create First Test

Create `src/__tests__/App.test.tsx`:

```typescript
import { render, screen } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import App from '../App';

describe('App', () => {
  it('renders the heading', () => {
    render(<App />);
    expect(screen.getByRole('heading', { level: 1 })).toBeInTheDocument();
  });
});
```

For Browser Mode, the test looks identical. Vitest handles the environment difference.

## Step 5: Add npm Scripts

Add to `package.json`:

```json
{
  "scripts": {
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage",
    "test:browser": "vitest --browser"
  }
}
```

Use `test:browser` only if you installed the Browser Mode dependencies in Step 1.

## Step 6: Verify It Works

```bash
pnpm test
```

Expected output: 1 test passes. If you see errors about missing modules, check that all dependencies from Step 1 are installed.

Run with coverage to confirm the coverage reporter works:

```bash
pnpm test:coverage
```

## Next Steps

- See the `frontend-testing` skill for component testing patterns, mocking strategies, and recipes.
- Read [tdd-workflow.md](./tdd-workflow.md) for the RED-GREEN-REFACTOR cycle with AI agents.
