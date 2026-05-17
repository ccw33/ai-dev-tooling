---
description: >
  Evidence-before-completion discipline. Agents MUST provide verifiable evidence before claiming any task done.
  Extracted from obra/superpowers verification-before-completion skill.
  "Should be fine" is not evidence. Command output is evidence.
globs:
alwaysApply: true
---

# Evidence Before Completion

No task is complete without evidence. "I checked, it should be fine" is a claim, not evidence.

## Minimum Evidence Standards

| Task Type | Required Evidence |
|-----------|-------------------|
| File edit (any) | `lsp_diagnostics` shows no new errors on changed files |
| Code implementation | Tests pass (GREEN) — with actual test runner output |
| Bug fix | Reproduction test transitions from RED → GREEN |
| Refactoring | Full test suite still GREEN + no new diagnostics |
| Documentation update | All `[text](path)` links resolve to existing files |
| Config change | Relevant build/start command succeeds |
| Test writing | Tests compile AND fail (RED) — not just compile |

## Anti-Rationalization Table

| Excuse | Reality |
|--------|---------|
| "I checked, it should be fine" | "Should" is not evidence. Run it. |
| "Tests are too slow" | Test runtime < debugging time. Always. |
| "This change can't affect other places" | You don't know that. Tests do. |
| "Build passes, that's enough" | Build pass ≠ correct behavior. Where are the tests? |
| "Type checking takes too long" | 30 seconds of waiting beats 30 minutes of debugging. |
| "It works on my machine" | Run it in the project's actual test environment. |
| "The error was pre-existing" | Prove it: show the error exists on the base branch too. |

## Red Flags — STOP Before These

- About to say "completed" without pasting any command output → **STOP**
- About to say "should be fine" → **STOP** ("should" = unsure = not verified)
- About to mark a todo `completed` without seeing test output → **STOP**
- About to say "the test was already failing before my change" → **STOP** (prove it: checkout base, run test)

## The Evidence Gate

Before marking ANY task as complete, answer these:

1. **Did I run verification?** (lsp_diagnostics / test runner / build)
2. **Do I have output to prove it?** (Not "it passed" — actual output)
3. **Is the output clean?** (No new errors, no new warnings, tests GREEN)

If any answer is NO → the task is NOT complete.

## Relationship to Existing Rules

| Rule | What It Guards |
|------|---------------|
| **tdd-iron-law** | Don't skip test-first discipline |
| **two-stage-review** | Don't skip code review |
| **This rule** | Don't claim done without proof |

These three rules form a chain: write tests first (Iron Law) → review code (Two-Stage) → prove it works (Evidence). Each rule catches what the others miss.

Source: Extracted from [obra/superpowers](https://github.com/obra/superpowers) `verification-before-completion` skill.
