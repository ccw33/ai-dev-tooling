---
name: agents-md
description: >
  Project-level instruction file for the dev-tooling meta-project.
  Helps AI agents understand repo structure, skill inventory, and working constraints.
  Auto-loaded by OpenCode at session start.
---

# AGENTS.md — dev-tooling

> This repo is a **meta-project**: it stores documentation and reusable skills for AI-assisted development across multiple projects. It has no application code, no build system, no tests.

## What's Here

```
omo-openspec-tdd.md           ← Root doc: 4-layer AI programming system (OmO + OpenSpec + TDD + Harness Init)
omo-openspec-tdd/             ← Child docs (progressive loading, referenced from root)
openspec-tdd-setup.md         ← TDD Schema installation config (standalone topic)
testing-setup-guide.md        ← Testing framework setup guide (new/existing projects + TDD)
testing-setup-guide/          ← Child docs (per-scenario setup instructions)
.agents/.skills/              ← OpenCode skills (auto-discovered)
```

## Skills

| Skill | Purpose |
|-------|---------|
| `harness-scan` | Inventory + layer an existing project (Harness Init step 1-2) |
| `harness-gate` | Set up quality gates + KNOWN_DEBTS.md with freeze-ratchet (step 3) |
| `harness-doc-garden` | One-time install of doc maintenance hooks (step 4) |
| `timely-doc-garden` | Recurring doc-code consistency scan + fix |
| `doc-for-ai` | Progressive documentation architecture rules |
| `frontend-testing` | Vitest + React Testing Library patterns, AI anti-patterns, coverage/CI |
| `e2e-testing` | Playwright E2E testing: POM, fixtures, selectors, CI config |
| `dev-tooling-feedback` | Report issues from other projects → fix source here |
| `knowledge-exploration` | 8-step methodology for researching new domains and creating skills/docs |

All skills are registered globally via symlinks in `~/.agents/skills/`. **Source of truth is this repo**, not the global dir.

## Documentation Rules

**Writing or editing any `.md` file in this repo MUST follow the `doc-for-ai` skill.** Load the skill before creating or modifying documentation.

Key rules (see `doc-for-ai` skill for full detail):

- Root doc ≤ 200 lines. Children go in same-name subdirectory (e.g., `testing-setup-guide/` for `testing-setup-guide.md`).
- Every `.md` file must have YAML frontmatter with `name` and `description`.
- Modifying a child doc → check if parent summary needs updating.
- Modifying the root → check if child docs still accurate.
- Executable code > 10 lines → extract to skill or standalone script, doc only keeps a reference.
- Verify all `[text](path)` links resolve after any change.
- Each child doc must have a back-link to parent in first content lines.

## Paths (hardcoded in configs)

- `dev-tooling-feedback/config.yaml` → `dev_tooling_path` points to this repo
- `timely-doc-garden/projects.yaml` → list of projects registered for scheduled scans
- `timely-doc-garden/scripts/` → shell/python scripts (run-scheduled.sh, scan.py, fix_refs.py, validate-refs.sh, check-doc-staleness.sh)

## When Working in This Repo

- **Don't** run tests or builds — there are none.
- **Don't** add application code — this is docs + skills only.
- **Do** follow `doc-for-ai` skill rules when editing any `.md` file.
- **Do** verify link integrity after moving/renaming files.
- **Do** commit after each logical change (skill creation, doc restructuring, feedback fix).
