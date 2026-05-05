---
name: testing-setup-guide
description: >
  How to set up testing frameworks (Vitest + RTL, Playwright) for new and existing projects,
  with TDD integration. Covers frontend unit testing, E2E testing, and the RED-GREEN-REFACTOR workflow.
  Use when: setting up test infrastructure, adding tests to a project, integrating TDD with AI agents.
  Triggers: "testing setup", "vitest setup", "playwright setup", "add tests", "TDD workflow", "mutation testing".
---

# Testing Setup Guide

> Last updated: 2026-05-04 | TypeScript throughout | Works with the frontend-testing and e2e-testing skills

This guide covers two testing layers and two project states. Pick the combination that fits your situation.

**Testing layers:**
- **Frontend unit/component tests** with Vitest + React Testing Library
- **E2E tests** with Playwright

**Project states:**
- **New project** (greenfield, no existing test infrastructure)
- **Existing project** (brownfield, may have partial or no test setup)

## Quick Start

| Scenario | Read this |
|----------|-----------|
| New project, frontend tests | [new-project-frontend.md](./testing-setup-guide/new-project-frontend.md) |
| Existing project, add frontend tests | [existing-project-frontend.md](./testing-setup-guide/existing-project-frontend.md) |
| New project, E2E tests | [new-project-e2e.md](./testing-setup-guide/new-project-e2e.md) |
| Existing project, add E2E tests | [existing-project-e2e.md](./testing-setup-guide/existing-project-e2e.md) |
| TDD workflow with AI agents | [tdd-workflow.md](./testing-setup-guide/tdd-workflow.md) |

## Architecture

```
Project
├── src/                        ← Application code
│   └── __tests__/              ← Collocated unit tests (Vitest + RTL)
├── e2e/                        ← E2E tests (Playwright)
│   ├── pages/                  ← Page Object Models
│   ├── fixtures/               ← Shared test fixtures
│   └── tests/                  ← Test specs
├── vitest.config.ts            ← Vitest configuration
├── vitest.setup.ts             ← Test setup (RTL cleanup, mocks)
└── playwright.config.ts        ← Playwright configuration
```

## TDD Cycle (Summary)

The TDD cycle runs RED -> GREEN -> REFACTOR. Tests are written before implementation code.

1. **RED**: Write a failing test. The test describes what you want.
2. **GREEN**: Write the minimum code to make the test pass.
3. **REFACTOR**: Clean up the code while keeping all tests green.

With AI agents, the division of labor is: **human defines WHAT, AI implements HOW, human reviews WHETHER**.

> Full TDD workflow with AI prompts and the OpenSpec GIVEN/WHEN/THEN mapping -> [tdd-workflow.md](./testing-setup-guide/tdd-workflow.md)

## Related Skills

| Skill | Purpose |
|-------|---------|
| `frontend-testing` | Vitest + RTL patterns, component testing recipes, mocking strategies |
| `e2e-testing` | Playwright patterns, page objects, fixture management |
| `webapp-testing` | Lightweight browser exploration (not structured testing) |

The skills provide pattern libraries and recipes. This guide provides setup instructions.

## Related TDD Documentation

| Document | Content |
|----------|---------|
| [omo-openspec-tdd.md](./omo-openspec-tdd.md) | Four-layer AI programming system overview |
| [tdd-mapping.md](./omo-openspec-tdd/tdd-mapping.md) | GIVEN/WHEN/THEN to Arrange/Act/Assert mapping |
| [openspec-tdd-setup.md](./openspec-tdd-setup.md) | TDD Schema installation for OpenSpec |

## Mutation Testing (StrykerJS)

StrykerJS mutates your code to verify test quality. If a mutant survives, your tests have a gap.

Brief setup (details in [tdd-workflow.md](./testing-setup-guide/tdd-workflow.md)):

```bash
pnpm add -D @stryker-mutator/core @stryker-mutator/vitest-runner
```

Use it as a quality gate: run mutation testing after the REFACTOR phase to confirm tests actually catch bugs, not just pass.

## Document Index

| Document | Content | When to read |
|----------|---------|-------------|
| [new-project-frontend.md](./testing-setup-guide/new-project-frontend.md) | Vitest + RTL from scratch | Starting a new project with tests |
| [existing-project-frontend.md](./testing-setup-guide/existing-project-frontend.md) | Adding Vitest + RTL to existing code | Brownfield frontend testing |
| [new-project-e2e.md](./testing-setup-guide/new-project-e2e.md) | Playwright from scratch | New project E2E setup |
| [existing-project-e2e.md](./testing-setup-guide/existing-project-e2e.md) | Adding Playwright to existing code | Brownfield E2E testing |
| [tdd-workflow.md](./testing-setup-guide/tdd-workflow.md) | TDD cycle with AI, prompts, mutation testing | Working with AI agents on tested code |
