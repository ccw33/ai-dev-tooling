---
name: frontend-testing
description: >
  Vitest + React Testing Library best practices for AI-assisted frontend testing.
  Covers Browser Mode (vitest-browser-react) and jsdom (@testing-library/react),
  component patterns, hooks, context, mocking (vi.* + MSW), AI-specific anti-patterns,
  and coverage/CI configuration.
  Use when: writing or reviewing React/Vitest tests, setting up test infrastructure,
  debugging test failures, adding coverage gates.
  Triggers: "frontend test", "react test", "vitest", "testing library", "component test",
  "test coverage", "mutation test", "前端测试", "组件测试", "覆盖率".
---

# Frontend Testing: Vitest + React Testing Library

You are writing or reviewing frontend tests. This skill gives you the patterns,
config, and anti-pattern knowledge to produce reliable, maintainable test suites.

## Tech Stack

| Tool | Purpose |
|------|---------|
| Vitest | Test runner (NOT Jest) |
| vitest-browser-react | Browser Mode rendering (preferred) |
| @testing-library/react | jsdom rendering (legacy fallback) |
| @testing-library/user-event | User interaction simulation (jsdom only) |
| MSW | API mocking via Mock Service Worker |
| StrykerJS | Mutation testing for test quality validation |

All API calls use `vi.*` (never `jest.*`). All examples use TypeScript + TSX.

## Quick Commands

```bash
npx vitest                    # Watch mode (local dev)
npx vitest run                # Single run (CI)
npx vitest run --coverage     # Single run with coverage report
npx vitest --browser          # Force Browser Mode
npx stryker run               # Mutation testing
```

## Testing Workflow

0. **Discover the project.** Scan structure, inventory components, prioritize. See [project-discovery.md](./references/project-discovery.md).
1. **Pick a mode.** Browser Mode for new projects. jsdom for existing suites already using it.
2. **Configure once.** See [vitest-setup.md](./references/vitest-setup.md).
3. **Write the test.** Follow patterns in [component-testing.md](./references/component-testing.md).
4. **Mock external dependencies.** Use [mocking.md](./references/mocking.md) for vi.*, MSW, module mocks.
5. **Check for AI anti-patterns.** Run through [ai-anti-patterns.md](./references/ai-anti-patterns.md) before shipping.
6. **Verify coverage.** Configure thresholds in [coverage-and-ci.md](./references/coverage-and-ci.md).

## Mode Decision

```
Need to test?
  |
  +-- Existing project already uses @testing-library/react?
  |     YES -> Use jsdom mode (consistency)
  |     NO  -> Use Browser Mode (preferred, real browser)
  |
  +-- Testing CSS, layout, or browser-specific behavior?
        YES -> Browser Mode (jsdom has no real DOM)
        NO  -> Either works, prefer Browser Mode
```

## Critical Rules

- `render()` in Browser Mode is async. Always `await` it.
- Use `expect.element()` in Browser Mode, not `expect(...).toBeInTheDocument()`.
- Use factory functions for component setup, not `beforeEach` render.
- Never wrap RTL calls in `act()` manually. RTL handles it.
- Always test rendered output, not internal component state.
- Run `vitest run` (not `vitest`) in CI for a single, deterministic run.

## Reference Index

| Document | Content | When to read |
|----------|---------|-------------|
| [project-discovery.md](./references/project-discovery.md) | Project scanning, component inventory, priority ordering, test scenario generation | Before writing any tests for an existing project |
| [vitest-setup.md](./references/vitest-setup.md) | Config, dependencies, file naming for both modes | Setting up test infrastructure |
| [component-testing.md](./references/component-testing.md) | Rendering, props, callbacks, conditional rendering, factory pattern | Writing component tests |
| [hooks-and-context.md](./references/hooks-and-context.md) | renderHook, context providers, form testing | Testing hooks, context, forms |
| [mocking.md](./references/mocking.md) | vi.fn/mock/spyOn, MSW, module mocking, timers, Zustand | Mocking dependencies |
| [ai-anti-patterns.md](./references/ai-anti-patterns.md) | Tautological tests, over-mocking, weak assertions, happy-path-only, assertion degradation | Reviewing AI-generated tests |
| [coverage-and-ci.md](./references/coverage-and-ci.md) | Coverage config, CI settings, StrykerJS mutation testing | Setting up CI quality gates |

## TDD Integration

This skill pairs with the TDD mapping in `omo-openspec-tdd/tdd-mapping.md`.
Spec `GIVEN/WHEN/THEN` maps directly to test `Arrange/Act/Assert`:

- `GIVEN` becomes test setup (Arrange)
- `WHEN` becomes the action under test (Act)
- `THEN` becomes the assertion (Assert)

When writing tests from OpenSpec scenarios, load the TDD mapping skill for the full mapping rules.
