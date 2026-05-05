---
name: existing-project-frontend
description: >
  Guide for adding Vitest + React Testing Library to an existing project.
  Covers detection of existing test infrastructure, migration, and gradual adoption strategy.
  Use when: adding frontend tests to a brownfield project.
  Triggers: "add tests to existing project", "brownfield testing", "migrate to vitest", "gradual testing".
---

# Existing Project: Adding Frontend Testing (Vitest + RTL)

> Source: [testing-setup-guide.md](../testing-setup-guide.md)

Adding tests to an existing project is different from starting fresh. You need to detect what's already there, avoid breaking existing tooling, and adopt tests gradually.

## Step 1: Detect Existing Test Infrastructure

Before installing anything, check what exists:

```bash
# Check for existing test configs
ls vitest.config.ts jest.config.* vitest.setup.ts setupTests.ts 2>/dev/null

# Check package.json for test-related dependencies
cat package.json | grep -E '"vitest|jest|@testing-library|mocha|ava"'

# Check for existing test files
find src -name "*.test.*" -o -name "*.spec.*" | head -20

# Check the existing bundler
cat package.json | grep -E '"vite|webpack|next|@remix-run"'
```

**What you might find:**

| Found | Action |
|-------|--------|
| Jest config, no Vitest | Vitest can coexist. Install separately. |
| Vitest config, incomplete | Extend existing config (Step 3). |
| No test infrastructure | Follow the new project guide. |
| React Testing Library already installed | Skip RTL installation, focus on config. |
| Vite config exists | Vitest extends it. No separate config needed if simple. |

## Step 2: Install Dependencies

**If no test framework exists:**

```bash
pnpm add -D vitest @testing-library/react @testing-library/jest-dom @testing-library/user-event jsdom
```

**If Jest exists and you want to keep it temporarily:**

```bash
pnpm add -D vitest @testing-library/react @testing-library/jest-dom @testing-library/user-event jsdom
# Jest and Vitest coexist. Don't remove Jest yet.
```

**If Vitest exists but is incomplete:**

```bash
pnpm add -D @testing-library/react @testing-library/jest-dom @testing-library/user-event jsdom
```

## Step 3: Configure Vitest

**If a `vitest.config.ts` already exists**, add the missing pieces:

```typescript
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./vitest.setup.ts'],
    css: true,
    include: ['src/**/*.{test,spec}.{ts,tsx}'],
    // Keep existing coverage config if present
  },
});
```

**If only a `vite.config.ts` exists**, add the `test` block to it:

```typescript
import { defineConfig } from 'vitest/config';

export default defineConfig({
  // ... existing vite config ...
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./vitest.setup.ts'],
    css: true,
    include: ['src/**/*.{test,spec}.{ts,tsx}'],
  },
});
```

Create `vitest.setup.ts` as described in [new-project-frontend.md](./new-project-frontend.md) Step 3.

## Step 4: Write First Test for an Existing Component

Pick a simple, self-contained component. A button or a display component works best.

```typescript
// src/components/Button/__tests__/Button.test.tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import { Button } from '../Button';

describe('Button', () => {
  it('renders with text', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByRole('button', { name: /click me/i })).toBeInTheDocument();
  });

  it('calls onClick when clicked', async () => {
    const onClick = vi.fn();
    render(<Button onClick={onClick}>Click me</Button>);

    const user = userEvent.setup();
    await user.click(screen.getByRole('button'));

    expect(onClick).toHaveBeenCalledOnce();
  });
});
```

Run it:

```bash
pnpm vitest run src/components/Button/__tests__/Button.test.tsx
```

## Step 5: Gradual Adoption Strategy

Don't try to test everything at once. Follow this sequence:

**Phase 1: Smoke tests (Day 1)**
- Test that key components render without crashing
- Test routing works (each route loads)
- Goal: catch import errors, missing props, broken renders

**Phase 2: Critical paths (Week 1)**
- Test user flows: login, form submission, data display
- Focus on components with business logic
- Goal: prevent regressions in core functionality

**Phase 3: Edge cases (Ongoing)**
- Error states, loading states, empty states
- Accessibility checks
- Goal: improve confidence in edge cases

**Phase 4: Refactor with confidence**
- Now that tests exist, refactor existing code
- Tests catch regressions during refactoring

## Common Pitfalls

| Problem | Cause | Fix |
|---------|-------|-----|
| Tests fail with "window is not defined" | Missing jsdom environment | Set `environment: 'jsdom'` in config |
| CSS imports cause errors | Vitest doesn't process CSS by default | Set `css: true` in config |
| Path aliases don't resolve | Alias not configured in vitest config | Add `resolve.alias` matching your tsconfig |
| Component uses context/router | Missing provider wrapper | Create a test wrapper with required providers |
| Tests pass but shouldn't | `getBy*` vs `queryBy*` mismatch | `getBy*` throws if not found (good), `queryBy*` returns null |
| Existing Jest tests break | Config conflict | Keep separate configs until migration is complete |

## Coexistence with Jest

If the project uses Jest, both can run side by side:

```json
{
  "scripts": {
    "test": "vitest run",
    "test:jest": "jest",
    "test:all": "vitest run && jest"
  }
}
```

Migrate tests one file at a time. Jest and Vitest APIs are similar enough that most tests need minimal changes.

## Next Steps

- See the `frontend-testing` skill for patterns on testing complex components.
- Read [tdd-workflow.md](./tdd-workflow.md) for integrating TDD into your existing workflow.
