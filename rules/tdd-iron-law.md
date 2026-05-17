---
description: >
  TDD behavioral discipline: anti-rationalization, Iron Laws, red flags.
  Extracted from obra/superpowers test-driven-development + verification-before-completion skills.
  Prevents agents from skipping tests, writing implementation before tests, or declaring done without evidence.
globs:
alwaysApply: true
---

# TDD Iron Law

Behavioral discipline for Test-Driven Development. This Rule supplements the **structural** TDD discipline from the `tdd-driven` OpenSpec schema (which ensures tasks.md has Verify RED → Implement → REFACTOR structure). This Rule ensures agents **behave** correctly within that structure.

## Iron Laws

1. **Tests MUST be written before implementation code.** Not a suggestion — a law.
2. **Tests MUST fail first (RED).** If a test passes immediately, the test is wrong — check assertions are specific and testing the right thing.
3. **Bug fixes MUST start with a failing test that reproduces the bug.** No reproduction test = guaranteed regression.
4. **REFACTOR phase MUST run full test suite and confirm still GREEN.** No exceptions.

## Anti-Rationalization Table

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks too. Test takes 30 seconds. |
| "I'll add tests after" | Post-hoc tests prove code runs, not that code is correct. |
| "This is a UI change, untestable" | `/frontend-testing` skill covers component testing patterns. |
| "Test passed immediately without RED" | Test is likely wrong. Check: are assertions specific? Testing the right thing? |
| "I'm fixing a bug, not new feature" | Fixing without a reproduction test = guaranteeing the same bug recurs. |
| "Deadline pressure, skip tests" | Time saved skipping tests is paid back doubled during debugging. |
| "The existing tests cover this" | Existing tests didn't prevent the current change from being needed. |
| "It's just a config change" | Config changes cause outages. Test the config. |

## Red Flags — STOP When You Think These

- "This change is so small it doesn't need a test" → **STOP**
- "Let me get the code working first, tests later" → **STOP**
- "The test passed already, I didn't see RED" → **STOP** (test is probably invalid)
- "I'll skip the RED phase and go straight to implementation" → **STOP**
- "This is just refactoring, tests aren't needed" → **STOP** (REFACTOR must confirm GREEN)

## Relationship to Existing System

| Layer | What It Ensures | How |
|-------|----------------|-----|
| **OpenSpec tdd-driven schema** (structural) | tasks.md has correct structure: Verify RED → Implement → REFACTOR | Schema template enforcement |
| **This Rule** (behavioral) | Agent follows the structure honestly: real RED, real GREEN, no shortcuts | Anti-rationalization + Iron Laws |
| **evidence-before-completion Rule** (verification) | Agent proves completion with command output, not claims | Evidence gate before marking done |

Source: Extracted from [obra/superpowers](https://github.com/obra/superpowers) `test-driven-development` and `verification-before-completion` skills.
