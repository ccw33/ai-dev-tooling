---
description: >
  Two-stage code review: spec compliance first, code quality second.
  Extracted from obra/superpowers subagent-driven-development skill (spec-reviewer + code-quality-reviewer).
  Ensures each completed task is reviewed by a DIFFERENT agent than the implementer.
globs:
alwaysApply: true
---

# Two-Stage Code Review

Mandatory review pattern for each implementation task after code passes tests (GREEN). Single-stage review misses: checking "does it work?" misses "does it match spec?", checking "is code clean?" misses "is the requirement fully implemented?".

## When to Apply

After each implementation task group in tasks.md reaches GREEN (tests passing), BEFORE moving to the next task group. Does NOT replace OpenSpec `verify` (which is holistic, at the end of all tasks).

## Stage 1: Spec Compliance Review

**Reviewer**: Oracle or Momus (read-only agent, NOT the implementer)
**Focus**: Does the code match what the spec says?

1. Does implementation cover ALL scenarios under the relevant Requirement in `specs/*.md`?
2. Does code behavior match WHEN/THEN descriptions in each Scenario?
3. Are edge cases from the spec handled?
4. Are there implemented behaviors NOT in the spec? (Scope creep signal)

**Does NOT check**: Code quality, naming, patterns, architecture.

**Result**: PASS or FAIL with specific deviations cited by spec line.

## Stage 2: Code Quality Review

**Reviewer**: Oracle or Momus (read-only agent, DIFFERENT from Stage 1 reviewer)
**Focus**: Is the code well-written?

1. Does code follow project patterns documented in AGENTS.md?
2. Naming clarity, function structure, cyclomatic complexity?
3. Error handling completeness?
4. No type safety violations (`as any`, `@ts-ignore`, `@ts-expect-error`)?
5. No AI slop patterns (unnecessary comments, verbose error messages, decorative code)?

**Does NOT check**: Requirement coverage (Stage 1 already confirmed).

**Result**: PASS or FAIL with specific improvement suggestions.

## Execution Flow

```
Implementer finishes task → tests GREEN
    ↓
Stage 1: Spec compliance review (different agent)
    ↓ FAIL → Implementer fixes → re-run Stage 1
    ↓ PASS
Stage 2: Code quality review (different agent, also different from Stage 1)
    ↓ FAIL → Implementer fixes → re-run Stage 2 only
    ↓ PASS
Task complete → move to next task
```

## Integration with opsx-apply

In the `opsx-apply` TDD cycle, this review happens between "run tests, confirm GREEN" and moving to the next task group. Atlas (conductor) dispatches both review stages as read-only subagent tasks.

## When to Skip

- **Verify RED tasks**: No implementation to review.
- **REFACTOR tasks**: Only Stage 2 applies (no spec changes, but quality matters).
- **Single-line changes** (typos, config): Use judgment — review overhead should match change size.

Source: Extracted from [obra/superpowers](https://github.com/obra/superpowers) `subagent-driven-development` skill and companion prompts (`spec-reviewer-prompt.md`, `code-quality-reviewer-prompt.md`).
