---
name: vitest-setup
description: >
  Vitest configuration and setup guide for both Browser Mode (vitest-browser-react)
  and jsdom (@testing-library/react). Includes dependencies, vitest.config.ts, and
  file naming conventions.
  Use when: setting up Vitest for the first time, adding a new test mode, troubleshooting config.
  Triggers: "vitest config", "vitest setup", "browser mode", "jsdom", "test config".
---

# Vitest Setup

> Source: [SKILL.md](../SKILL.md)

> Source: [SKILL.md](../SKILL.md)

Two rendering approaches exist. Pick one per project, don't mix them in the same test file.

## Browser Mode (Preferred)

Tests run in a real Chromium browser via Playwright. Gives production-accurate rendering,
events, and CSS behavior.

### Dependencies

```bash
npm install -D vitest @vitest/browser vitest-browser-react @vitejs/plugin-react playwright
```

### Configuration

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    restoreMocks: true,
    browser: {
      enabled: true,
      headless: true,
      instances: [{ browser: 'chromium' }],
    },
  },
})
```

### Imports

```typescript
import { render } from 'vitest-browser-react'
import { expect, test, vi } from 'vitest'
```

Key points for Browser Mode:
- `render()` is async, always `await` it
- Returns a scoped `screen`, no global `screen` needed
- Use `expect.element()` for auto-retrying assertions
- No `act()` wrapper needed, CDP events handle timing
- Auto-cleanup runs before each test (components stay visible for debugging)

## jsdom Mode (Legacy)

Tests run in a simulated DOM via jsdom. Faster startup but no real browser behavior.

### Dependencies

```bash
npm install -D vitest jsdom @testing-library/react @testing-library/jest-dom @testing-library/user-event
```

### Configuration

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    restoreMocks: true,
    environment: 'jsdom',
    setupFiles: ['./test/setup.ts'],
  },
})
```

### Setup File

```typescript
// test/setup.ts
import '@testing-library/jest-dom/vitest'
```

### Imports

```typescript
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { expect, test, vi } from 'vitest'
```

## Critical Config Options

| Option | Why it matters |
|--------|---------------|
| `globals: true` | Use `test/it/expect/vi` without importing in every file. Reduces boilerplate for AI-generated tests. |
| `restoreMocks: true` | Auto-restores all mocks between tests. Prevents state leakage without manual `afterEach`. |
| `restoreMocks: true` | Essential for AI agents that might forget cleanup. |

## File Naming Conventions

| Pattern | Purpose |
|---------|---------|
| `*.test.ts(x)` | Co-located test files (preferred) |
| `*.spec.ts(x)` | Spec-driven tests (use with OpenSpec TDD) |
| `test/` directory | Standalone test directory for integration tests |
| `__tests__/` | Alternative co-location (common in React projects) |

## Running Tests

```bash
npx vitest                    # Watch mode, reruns on file changes
npx vitest run                # Single run (use in CI)
npx vitest run path/to/test   # Run specific file
npx vitest --browser          # Force browser mode
npx vitest --environment jsdom # Force jsdom mode
```
