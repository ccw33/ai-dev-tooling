---
name: e2e-testing
description: >
  Structured E2E testing with Playwright and TypeScript. Covers Page Object Model,
  resilient selectors, custom fixtures, CI configuration, and advanced patterns like
  network interception and file upload. Use when: writing E2E tests, setting up Playwright
  test suites, creating page objects, configuring CI pipelines for E2E, debugging flaky tests.
  Triggers: "e2e test", "playwright test", "page object", "end-to-end", "spec file",
  "test fixture", "playwright config", "E2E".
---

# E2E Testing with Playwright

Structured, maintainable end-to-end testing using Playwright and TypeScript.
This skill covers the full lifecycle: page objects, selectors, fixtures, CI config, and advanced patterns.

For quick browser exploration and one-off screenshots, use the `webapp-testing` skill instead.
This skill is for building persistent, CI-ready test suites.

## Core Principles

1. **User-centric testing.** Write tests from the user's perspective, not the implementation's.
2. **Resilient selectors.** Prefer `getByRole`, `getByLabel`, `getByTestId` over CSS/XPath.
3. **Auto-wait.** Leverage Playwright's built-in auto-waiting. Never use `waitForTimeout`.
4. **Isolation.** Each test is independent. No shared mutable state.
5. **Tests as documentation.** A well-written test describes expected behavior.

## When to Use This Skill

- Building a new E2E test suite with Playwright
- Discovering user flows and test strategy for an existing project (start with [project-discovery.md](./references/project-discovery.md))
- Writing page objects and fixtures
- Setting up `playwright.config.ts` for CI
- Debugging flaky E2E tests
- Adding network interception or mocking
- Structuring tests with the three-layer architecture (Pages, Modules, Tests)

## Quick Reference

```typescript
// Run tests
npx playwright test                          // all tests
npx playwright test --headed                 // with browser visible
npx playwright test --ui                     // interactive UI mode
npx playwright test --debug                  // step through with inspector
npx playwright test -g "login"               // tests matching "login"
npx playwright test --project=chromium       // single browser
npx playwright show-report                   // view HTML report
npx playwright codegen http://localhost:3000  // record actions as code
```

## Project Structure

```
tests/
  e2e/
    pages/           # Page Object classes (locators + actions)
      base.page.ts
      login.page.ts
    modules/         # Business flow composition (multi-page sequences)
      shopping.module.ts
    fixtures/        # Custom test fixtures (auth, seeded data)
      auth.fixture.ts
    auth/            # Test files organized by feature
      login.spec.ts
    setup/           # Auth setup scripts
      auth.setup.ts
  playwright.config.ts
```

## Reference Index

| Document | Content | When to Read |
|----------|---------|-------------|
| [page-objects.md](./references/page-objects.md) | BasePage, concrete pages, three-layer architecture | Writing page objects, structuring test code |
| [selectors-and-waits.md](./references/selectors-and-waits.md) | Selector priority, web-first assertions, auto-wait | Choosing selectors, writing assertions |
| [fixtures.md](./references/fixtures.md) | Custom fixtures, auth state reuse, page injection | Setting up test fixtures, reusing auth |
| [ci-and-config.md](./references/ci-and-config.md) | playwright.config.ts, CI, sharding, reporters | Configuring CI pipelines, setting up config |
| [advanced-patterns.md](./references/advanced-patterns.md) | Network interception, file upload, iframes, dialogs | Mocking APIs, handling edge cases |
| [project-discovery.md](./references/project-discovery.md) | Seven-phase pipeline: app recon, user flows, page structure, auth, API, test strategy, seed test | Onboarding an existing project for E2E testing |

## Playwright MCP Integration

Playwright offers two modes for AI-driven browser testing.

### CLI + Skills Mode (This Skill)

Best for building persistent, version-controlled test suites.

- Write page objects, fixtures, and spec files that live in your repo
- Run in CI with sharding, reporters, and retries
- Tests survive across sessions and serve as living documentation
- Use `npx playwright codegen` to bootstrap locators

### MCP Mode (`@playwright/mcp`)

Best for ad-hoc browser interaction during development.

- Connect AI agents directly to a browser via the Model Context Protocol
- No test files needed. AI drives the browser in real time
- Useful for quick smoke tests, visual verification, and debugging

```bash
# Install and run the Playwright MCP server
npx @playwright/mcp@latest
```

### Playwright Test Agents

Playwright provides built-in AI agents for test maintenance:

- **Planner**: Generates test plans from natural language descriptions
- **Generator**: Creates test code from user interactions
- **Healer**: Auto-fixes broken locators when the UI changes

See the [Playwright Test Agents documentation](https://playwright.dev/docs/test-ai) for setup and usage.

### Choosing Between Modes

| Scenario | Use CLI+Skills | Use MCP |
|----------|---------------|---------|
| Build regression suite | Yes | No |
| Quick visual check during dev | No | Yes |
| CI pipeline integration | Yes | No |
| Ad-hoc debugging | No | Yes |
| Persistent test artifacts | Yes | No |

## Anti-Patterns

- `waitForTimeout`. Use assertions instead. They auto-retry.
- Shared mutable state between tests. Each test gets a clean context.
- Testing implementation details (CSS classes, DOM structure). Test user-visible behavior.
- Giant test files. One file per feature, tests grouped by `test.describe`.
- Hardcoded URLs. Always use `baseURL` config with relative paths.
- Importing `test`/`expect` from `@playwright/test` directly. Import from your fixture file.
