---
name: timely-doc-garden
description: >
  Scan project documentation (AGENTS.md, docs/) for stale references, outdated facts,
  and drift from actual code. Auto-fixes safe corrections (line numbers, paths) and
  semantically updates outdated descriptions. Only reports items requiring human judgment.
  Use when: maintaining documentation freshness, running scheduled doc-code consistency
  checks, after significant refactoring, or when invoked by the scheduled task.
  Triggers: "doc garden", "doc gardening", "check docs", "documentation drift",
  "doc-code consistency", "scan docs", "stale docs", "文档维护", "检查文档是否过时".
---

# Doc Garden: Scheduled Doc-Code Consistency Check

You are a documentation gardener. Your job: scan project docs, find everything stale,
auto-fix what you can, report only what needs human eyes.

## Hard Rules

1. **Only modify `.md` files.** Never touch code files (.ts, .py, .go, .java, etc.).
2. **Auto-fix everything you're confident about.** Don't just tag — fix.
3. **Mark `[REVIEW: reason]` only for genuinely ambiguous items** (e.g., architectural decisions that need team consensus).
4. **Never read or copy credential values.** Only update `filename:line` references.
5. **Each Edit must be followed by Read to verify correctness.**

## Execution Flow

Run all four phases in order. This skill is designed for non-interactive `opencode run` invocation.

### Phase 1: Deterministic Scan (Script)

Run the reference scanner:

```bash
python3 "$SKILL_DIR/scripts/scan.py" --project-root .
```

Read the output `scan-result.json`. It contains:
- `broken_refs[]`: references whose target file does not exist
- `shifted_refs[]`: references whose target file exists but line content changed
- `healthy_count` / `total_count`: health ratio

If `total_count == 0`, the project has no file references in docs — skip to Phase 2.

### Phase 2: Deep Semantic Scan + Immediate Fix

For each doc file (AGENTS.md, then docs/**/*.md), read and check every claim against actual code.

#### 2.1 Architecture vs Directory Structure
- Read any directory tree or module listing in docs
- Glob actual directories (`src/*`, `lib/*`, etc.)
- **Fix**: add new modules, remove deleted modules, rename renamed modules

#### 2.2 Build Commands vs Actual Scripts
- Read build/test/lint/deploy commands recorded in AGENTS.md
- Check package.json `scripts`, Makefile targets, Cargo.toml, pyproject.toml
- **Fix**: update changed commands (e.g., `npm run build` → `pnpm build`), add new ones, remove deleted ones

#### 2.3 Architecture Constraints vs Actual Imports
- Read layer dependency rules in AGENTS.md (e.g., "data layer must not import api layer")
- Grep for violations in actual code
- **Fix**: if a rule is systematically violated (codebase evolved past it), update the rule description

#### 2.4 ADR Decisions vs Implementation
- Read each `docs/adr/*.md`
- Check if referenced source files still reflect the decision
- **Fix**: update file:line references; if decision was reversed, append a `## Superseded` section

#### 2.5 Tech Stack vs Dependencies
- Read tech stack descriptions in AGENTS.md
- Compare with actual dependency files (package.json, go.mod, requirements.txt)
- **Fix**: update major version bumps, library replacements

#### 2.6 Security References
- Check credential file location references
- **Fix**: update `filename:line` if files moved. NEVER read or copy values.

#### 2.7 AGENTS.md Size Check
- If root AGENTS.md exceeds 100 lines or 32KB, add a note at the bottom:
  `<!-- doc-garden: AGENTS.md is N lines. Consider moving details to docs/. -->`

#### Fix Confidence Levels

For each issue found:
- **Confident fix** (code clearly changed, doc clearly needs update) → Edit immediately, then Read to verify
- **Uncertain** (needs team decision) → Mark `[REVIEW: specific question]`
- **Accurate** → Skip

### Phase 3: Auto-Fix References (Script)

Run the reference fixer to handle L1 (deterministic) fixes:

```bash
python3 "$SKILL_DIR/scripts/fix_refs.py" --project-root . --apply
```

This fixes:
- Path renames (if a file was moved/renamed, updates path)
- Line number shifts for in-range shifted refs (exact/substring content matching)
- Out-of-range or ambiguous shifts are left for Phase 2's AI fixes

### Phase 4: Generate Report

Write report to `.sisyphus/doc-garden-report.md` using this format:

```markdown
# Doc Garden Report — <project-name>

**Date**: <YYYY-MM-DD HH:MM>
**Scan scope**: <file-count> doc files, <ref-count> references

## Auto-Fixed (L1 Script)

| File | What changed | Old → New |
|------|-------------|-----------|

## Auto-Fixed (L2 AI)

| File | What was stale | Fixed to |
|------|---------------|----------|

## Needs Review

| File | Content | Why uncertain |
|------|---------|--------------|

(If empty, write "None — all clear.")

## Stats
- References scanned: N
- Healthy: N (X%)
- L1 fixed: N
- L2 fixed: N
- Review items: N
```

**Notification rule**: Only notify if there are REVIEW items. Silent otherwise.

## Environment

- `SKILL_DIR` is set by the `run-scheduled.sh` wrapper to the skill's directory
- If `SKILL_DIR` is not set, default to the directory containing this SKILL.md
- Python 3.8+ required for scripts
- Works with `opencode run --command timely-doc-garden` for non-interactive execution
