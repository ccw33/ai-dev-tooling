---
name: tdd-workflow
description: >
  TDD workflow integration with AI agents. Covers RED-GREEN-REFACTOR cycle, AI prompt templates,
  StrykerJS mutation testing as quality gate, and OpenSpec GIVEN/WHEN/THEN mapping.
  Use when: working with AI agents on tested code, setting up TDD workflows, adding mutation testing.
  Triggers: "tdd workflow", "ai tdd", "mutation testing", "stryker", "red green refactor".
---

# TDD Workflow with AI Agents

> Source: [testing-setup-guide.md](../testing-setup-guide.md)

The TDD cycle with AI agents splits responsibilities: **human defines WHAT, AI implements HOW, human reviews WHETHER**. This document shows how to use the `frontend-testing` and `e2e-testing` skills within this cycle.

## The TDD Cycle

### RED Phase: Write Tests First

The human (or human + AI together) writes the test that describes the desired behavior. The test must fail.

**AI prompt for RED phase:**

```
I need a component that [describe behavior].
Write a failing test for it using Vitest + React Testing Library.
Do NOT write the implementation. Only the test.
The test should cover:
- [scenario 1]
- [scenario 2]
```

**Example test (from OpenSpec scenario):**

Given an OpenSpec scenario:
```
### Requirement: User Login
#### Scenario: successful login
- GIVEN a user with valid credentials on the login page
- WHEN the user submits the form
- THEN the user is redirected to the dashboard
- AND a welcome message is displayed
```

The test maps directly:

```typescript
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, test, expect, vi } from 'vitest';
import { LoginPage } from './LoginPage';
import { AuthProvider } from '../providers/AuthProvider';

// vi.mock MUST be at module scope — Vitest hoists it automatically
vi.mock('../api/auth', () => ({
  login: vi.fn().mockResolvedValue({ token: 'fake-token' }),
}));

vi.mock('react-router-dom', () => ({
  ...vi.importActual('react-router-dom'),
  useNavigate: () => vi.fn(),
}));

// GIVEN: Arrange helper
function renderLoginPage() {
  return render(
    <AuthProvider>
      <LoginPage />
    </AuthProvider>
  );
}

describe('User Login', () => {
  test('successful login', async () => {
    // GIVEN (Arrange)
    const user = userEvent.setup();
    renderLoginPage();

    // WHEN (Act)
    await user.type(screen.getByLabelText('Email'), 'user@example.com');
    await user.type(screen.getByLabelText('Password'), 'valid-password');
    await user.click(screen.getByRole('button', { name: /log in/i }));

    // THEN (Assert) — check navigation via mocked router
    const navigate = vi.mocked(require('react-router-dom').useNavigate)();
    await waitFor(() => {
      expect(navigate).toHaveBeenCalledWith('/dashboard');
    });

    // AND (Additional Assert)
    expect(screen.getByText(/welcome/i)).toBeInTheDocument();
  });
});
```

Run the test. It must fail (RED):

```bash
npx vitest run src/components/LoginPage/__tests__/LoginPage.test.tsx
```

### GREEN Phase: Minimum Implementation

The AI writes the minimum code to make the test pass. No more, no less.

**AI prompt for GREEN phase:**

```
This test is failing:
[paste the test]

Write the minimum implementation to make it pass.
Do not add features beyond what the test requires.
Do not refactor. Just make it green.
```

Run the test again. It must pass (GREEN):

```bash
npx vitest run src/components/LoginPage/__tests__/LoginPage.test.tsx
```

### REFACTOR Phase: Clean Up

Both human and AI review the code. The AI can refactor, but tests must stay green.

**AI prompt for REFACTOR phase:**

```
The tests are green. Now refactor the implementation for:
- Readability
- DRY (Don't Repeat Yourself)
- Proper error handling
- Type safety

Run tests after each refactor step to confirm they stay green.
```

## OpenSpec GIVEN/WHEN/THEN Mapping

The TDD cycle integrates with OpenSpec. The mapping is:

| Spec Element | Test Element | TDD Phase |
|-------------|-------------|-----------|
| `GIVEN` | Arrange (setup data/context) | RED |
| `WHEN` | Act (call the function) | RED |
| `THEN` | Assert (check results) | RED |
| `AND` | Additional Assert or Arrange | RED |
| `Scenario: name` | `test('name', ...)` | RED |
| `Requirement: name` | `describe('name', ...)` | RED |

All spec elements produce tests in the RED phase. Implementation happens in GREEN. Cleanup in REFACTOR.

See [tdd-mapping.md](../omo-openspec-tdd/tdd-mapping.md) for the full mapping with examples.

## Skill Integration

### frontend-testing skill

Use it during the RED and REFACTOR phases:

- **RED**: The skill provides patterns for testing components, hooks, and utilities. Load it when writing tests.
- **REFACTOR**: The skill provides mock strategies and testing recipes that help verify refactored code.

**When to load it:**

```
/frontend-testing
```

### e2e-testing skill

Use it when writing E2E tests in the TDD cycle:

- **RED**: Page object patterns, fixture setup, assertion recipes.
- **GREEN**: Writing the minimum page/application code to pass E2E tests.
- **REFACTOR**: Reorganizing page objects, consolidating fixtures.

**When to load it:**

```
/e2e-testing
```

## Mutation Testing with StrykerJS

Mutation testing verifies that your tests actually catch bugs. It mutates your code and checks if tests fail.

### Setup

```bash
npm install -D @stryker-mutator/core @stryker-mutator/vitest-runner
```

Create `stryker.config.json`:

```json
{
  "packageManager": "npm",
  "reporters": ["html", "clear-text", "progress"],
  "testRunner": "vitest",
  "vitest": {
    "configFile": "vitest.config.ts"
  },
  "coverageAnalysis": "perTest",
  "mutate": [
    "src/**/*.ts",
    "src/**/*.tsx",
    "!src/**/*.test.ts",
    "!src/**/*.test.tsx",
    "!src/**/*.spec.ts",
    "!src/**/*.spec.tsx",
    "!src/types/**"
  ],
  "thresholds": {
    "high": 80,
    "low": 60,
    "break": 50
  }
}
```

### Running

```bash
npx stryker run
```

**Note**: The setup above uses `@stryker-mutator/vitest-runner` for unit/integration tests. E2E tests (Playwright) can also be mutation-tested with `@stryker-mutator/playwright-runner`, but this is significantly slower and rarely worth the cost — E2E tests already run against real browser behavior. Focus mutation testing on unit and integration tests where AI-generated assertions are most likely to be weak.

### When to Run It

Run mutation testing as a quality gate after the REFACTOR phase. It tells you:

- **Mutation score**: Percentage of mutants killed by tests.
- **Survived mutants**: Code changes that tests didn't catch. These are test gaps.
- **Killed mutants**: Code changes that tests correctly caught.

Add it to your scripts:

```json
{
  "scripts": {
    "test:mutation": "stryker run"
  }
}
```

### Interpreting Results

| Score | Meaning |
|-------|---------|
| Above 80% | Tests are solid. Ship with confidence. |
| 60-80% | Decent but has gaps. Focus on survived mutants. |
| Below 60% | Tests are weak. Write more targeted assertions. |

## Common AI Testing Anti-Patterns

Watch for these when reviewing AI-generated tests:

| Anti-pattern | What it looks like | Fix |
|-------------|-------------------|-----|
| Testing implementation details | Asserting on internal state, class names | Test user-visible behavior |
| Over-mocking | Mocking everything, test tests nothing | Mock at boundaries (API, external modules) |
| Shallow assertions | `expect(result).toBeDefined()` | Assert specific values |
| Duplicate test logic | Same setup repeated in every test | Extract to factories or fixtures |
| Tests that always pass | No assertions, only side effects | Every test needs at least one assertion |
| Ignoring async | Missing `await`, `waitFor` | Always await user events and async operations |

See the `frontend-testing` and `e2e-testing` skills for detailed pattern libraries.
