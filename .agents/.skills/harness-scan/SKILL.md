---
name: harness-scan
description: >
  Deep project inventory + layered documentation for brownfield projects.
  Combines init-deep (structure scan + hierarchical AGENTS.md generation) with
  AI-powered supplementary scanning (credential detection, implicit knowledge mining,
  multi-repo drift detection), OpenSpec baseline spec generation, and a human
  confirmation questionnaire.
  Use when: onboarding an existing project for AI-assisted development (Harness Init steps 1-2).
  Triggers: "harness scan", "project inventory", "scan project", "项目盘点", "项目扫描",
  "harness init", "存量项目入场".
  Runs: once per project (re-run with --create-new to regenerate from scratch).
---

# Harness Scan: Deep Project Inventory + Layered Documentation

You are performing Harness Init steps 1-2 (盘点 + 分层) for an existing project.
The goal: produce hierarchical AGENTS.md + docs/ so that future AI sessions
understand the project without repeated exploration.

**This skill extends `/init-deep` with AI supplementary scanning and a
human confirmation questionnaire — replacing manual checklist work with
AI-driven discovery + lightweight human review.**

## Prerequisites

Confirm BEFORE proceeding:
1. `opencode` is available in PATH
2. LSP is available for the project's primary language (optional but preferred)
3. `git` is available (needed for supplementary scanning)

If any prerequisite fails, report what's missing but continue if possible.

## Usage

```
/harness-scan                  # Update mode: modify existing + create new
/harness-scan --create-new     # Read existing → remove all → regenerate from scratch
/harness-scan --max-depth=2    # Limit directory depth (default: 3)
```

---

## Workflow Overview

```
Phase 1: Init-Deep Scan (structure + hierarchical AGENTS.md)
    ↓
Phase 2: AI Supplementary Scan (credentials, implicit knowledge, drift)
    ↓
Phase 3: Human Confirmation Questionnaire (judgment calls only)
    ↓
Phase 4: Finalize (apply questionnaire answers, validate)
```

<critical>
**TodoWrite ALL phases. Mark in_progress → completed in real-time.**
```
TodoWrite([
  { content: "Phase 1: Init-Deep Scan (structure + AGENTS.md + baseline specs)", status: "pending", priority: "high" },
  { content: "Phase 2: AI Supplementary Scan (credentials + implicit knowledge + drift)", status: "pending", priority: "high" },
  { content: "Phase 3: Human Confirmation Questionnaire", status: "pending", priority: "high" },
  { content: "Phase 4: Finalize (apply answers + validate)", status: "pending", priority: "medium" }
])
```
</critical>

---

## Phase 1: Init-Deep Scan

**Mark Phase 1 as in_progress.**

Execute the standard init-deep workflow. This is the 70% that `/init-deep` already does well.

### Step 1.1: Fire Background Explore Agents

Fire all at once, collect later:

```
task(subagent_type="explore", load_skills=[], description="Explore project structure", run_in_background=true,
  prompt="Project structure: PREDICT standard patterns for detected language → REPORT deviations only")
task(subagent_type="explore", load_skills=[], description="Find entry points", run_in_background=true,
  prompt="Entry points: FIND main files → REPORT non-standard organization")
task(subagent_type="explore", load_skills=[], description="Find conventions", run_in_background=true,
  prompt="Conventions: FIND config files (.eslintrc, pyproject.toml, .editorconfig) → REPORT project-specific rules")
task(subagent_type="explore", load_skills=[], description="Find anti-patterns", run_in_background=true,
  prompt="Anti-patterns: FIND 'DO NOT', 'NEVER', 'ALWAYS', 'DEPRECATED' comments → LIST forbidden patterns")
task(subagent_type="explore", load_skills=[], description="Explore build/CI", run_in_background=true,
  prompt="Build/CI: FIND .github/workflows, Makefile → REPORT non-standard patterns")
task(subagent_type="explore", load_skills=[], description="Find test patterns", run_in_background=true,
  prompt="Test patterns: FIND test configs, test structure → REPORT unique conventions")
```

**Dynamic agent spawning** — after bash analysis, spawn additional agents based on project scale:

| Factor | Threshold | Additional Agents |
|--------|-----------|-------------------|
| Total files | >100 | +1 per 100 files |
| Total lines | >10k | +1 per 10k lines |
| Directory depth | ≥4 | +2 for deep exploration |
| Large files (>500 lines) | >10 | +1 for complexity hotspots |
| Monorepo | detected | +1 per package/workspace |
| Multiple languages | >1 | +1 per language |

```bash
# Measure project scale
total_files=$(find . -type f -not -path '*/node_modules/*' -not -path '*/.git/*' | wc -l)
total_lines=$(find . -type f \( -name "*.ts" -o -name "*.py" -o -name "*.go" \) -not -path '*/node_modules/*' -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}')
```

### Step 1.2: Main Session Concurrent Analysis

While background agents run:

**Bash structural analysis:**
```bash
# Directory depth + file counts
find . -type d -not -path '*/.*' -not -path '*/node_modules/*' -not -path '*/venv/*' -not -path '*/dist/*' | awk -F/ '{print NF-1}' | sort -n | uniq -c

# Files per directory (top 30)
find . -type f -not -path '*/.*' -not -path '*/node_modules/*' | sed 's|/[^/]*$||' | sort | uniq -c | sort -rn | head -30
```

**Read existing AGENTS.md** (if present). If `--create-new`: read all first → delete → regenerate.

**LSP Codemap** (if available):
```
LspDocumentSymbols for entry points
LspWorkspaceSymbols for key symbols
LspFindReferences for top exports (centrality analysis)
```

### Step 1.3: Collect Background Results + Score Directories

Collect all background task results.

**Scoring matrix** (8 dimensions):

| Factor | Weight | High Threshold | Source |
|--------|--------|----------------|--------|
| File count | 3x | >20 | bash |
| Subdir count | 2x | >5 | bash |
| Code ratio | 2x | >70% | bash |
| Unique patterns | 1x | Has own config | explore |
| Module boundary | 2x | Has index.ts/__init__.py | bash |
| Symbol density | 2x | >30 symbols | LSP |
| Export count | 2x | >10 exports | LSP |
| Reference centrality | 3x | >20 refs | LSP |

**Decision rules:**

| Score | Action |
|-------|--------|
| Root (.) | ALWAYS create |
| >15 | Create AGENTS.md |
| 8-15 | Create if distinct domain |
| <8 | Skip (parent covers) |

### Step 1.4: Generate AGENTS.md Files

<critical>
**File Writing Rule**: If AGENTS.md exists → use Edit. If NOT → use Write.
NEVER use Write to overwrite an existing file.
</critical>

**Root AGENTS.md** (50-200 lines):
```markdown
# PROJECT KNOWLEDGE BASE

**Generated:** {TIMESTAMP}
**Commit:** {SHORT_SHA}

## OVERVIEW
{1-2 sentences: what + core stack}

## STRUCTURE
{ASCII tree — non-obvious purpose only}

## WHERE TO LOOK
| Task | Location | Notes |

## CODE MAP
{From LSP — skip if project <10 files}

## CONVENTIONS
{ONLY deviations from standard}

## ANTI-PATTERNS (THIS PROJECT)
{Explicitly forbidden here}

## COMMANDS
{dev/test/build}

## NOTES
{Gotchas}
```

**Subdirectory AGENTS.md** (parallel, 30-80 lines each):
- NEVER repeat parent content
- Sections: OVERVIEW (1 line), STRUCTURE, WHERE TO LOOK, CONVENTIONS (if different), ANTI-PATTERNS

### Step 1.5: Generate docs/ Structure

Create (if not existing):
- `docs/architecture.md` — layer structure, infrastructure integration
- `docs/development-guide.md` — environment setup, local dev, testing, deployment
- `docs/api-contracts.md` — API spec index
- `docs/adr/` — architecture decision records (each ≤40 lines, must have source code references)

**Quality gates**:
- Every factual claim must have a `filename:line` anchor pointing to actual source code
- Uncertain items marked `[TODO: confirm with team]`, never guess
- Root ≤200 lines / <32KB
- Subdirectory AGENTS.md only shows differences from parent

### Step 1.6: Generate Baseline Specs (if OpenSpec initialized)

If the project has `openspec/` directory (i.e., `openspec init` has been run), generate
baseline specs that describe the **current state** of each module — not just incremental changes.

**Why**: OpenSpec delta specs only describe what CHANGED in a feature. For a brownfield project,
you need baseline specs that describe what the system already does, so future changes have
accurate context to diff against.

**Identify capabilities** from the WHERE TO LOOK table in AGENTS.md:

```
For each row in WHERE TO LOOK:
  - If the "Location" maps to a distinct module directory → that's a capability
  - Capability name = kebab-case of the module purpose (e.g., data-pipeline, backtest-engine)
  - Skip if openspec/specs/<capability>/spec.md already exists (user may have written it)
```

**Spawn parallel agents** — one per capability, all at once:

```
For each identified capability:
  task(
    category="deep",
    load_skills=[],
    description="Write baseline spec: <capability>",
    run_in_background=true,
    prompt="""
    ## TASK
    Write a baseline spec for the `<capability>` capability of this project.

    ## EXPECTED OUTCOME
    A file at `openspec/specs/<capability>/spec.md` (under 200 lines) describing
    the module's current behavior, interfaces, constraints, and dependencies.

    ## REQUIRED TOOLS
    Read, Write, Grep, Glob

    ## MUST DO
    1. Read these files (agent fills in specific paths from AGENTS.md WHERE TO LOOK):
       - AGENTS.md (project overview)
       - <module source files>
       - <CLI handlers for this module>
       - <config files for this module>

    2. The spec MUST cover:
       - **Overview**: What this module does (1-2 paragraphs)
       - **Core Interfaces**: Key classes, functions, ABCs with signatures
       - **Data Flow**: Input → processing → output
       - **CLI Interface**: Related subcommands and flags
       - **Internal API**: Key classes/functions with signatures
       - **Constraints**: Assumptions, limitations, domain-specific rules
       - **Dependencies**: Upstream and downstream module relationships

    3. Write in English, technical documentation style.
    4. Include actual file paths and function names as references.
    5. Keep under 200 lines.

    ## MUST NOT DO
    - Do NOT modify any source code
    - Do NOT run any tests or commands
    - Do NOT reference line numbers (they drift)
    """
  )
```

**After all agents complete**:
1. Verify each `openspec/specs/<capability>/spec.md` exists and is under 200 lines.
2. List generated specs in the final report (Step 4.4).

**Skip conditions**:
- No `openspec/` directory → skip entirely (not using OpenSpec)
- `openspec/specs/` already populated → only fill gaps, don't overwrite

**Mark Phase 1 as completed.**

---

## Phase 2: AI Supplementary Scan

**Mark Phase 2 as in_progress.**

This is the 15% that init-deep misses — AI-powered discovery of security, implicit knowledge, and cross-repo drift.

### Step 2.1: Credential Scanning

Scan for hardcoded secrets and credential patterns:

```bash
# Pattern-based scan (no external tools needed)
grep -rn --include="*.ts" --include="*.py" --include="*.go" --include="*.js" --include="*.yaml" --include="*.yml" --include="*.json" --include="*.env" --include="*.toml" \
  -E '(password|secret|api_key|apikey|access_key|token|credential|private_key)\s*[:=]\s*["\x27]?[A-Za-z0-9+/=_-]{8,}' \
  . 2>/dev/null || true

# Check for .env files with actual values (not just placeholders)
find . -name ".env*" -not -name ".env.example" -not -name ".env.template" -not -path "*/node_modules/*" 2>/dev/null

# Check for common secret file patterns
find . -type f \( -name "*secret*" -o -name "*credential*" -o -name "*key*.pem" -o -name "*.p12" -o -name "*.jks" \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null
```

**Actions**:
- If credentials found: record locations (file:line only, NEVER values)
- Add to AGENTS.md security section: `⚠️ Credential found at <file>:<line> — confirm handling`
- If `.env` files exist with real values: flag for `.gitignore` check

### Step 2.2: Implicit Knowledge Mining

Mine knowledge that "everyone knows but nobody wrote down":

```bash
# 1. TODO/FIXME/HACK/XXX comments — indicate tech debt and implicit rules
grep -rn --include="*.ts" --include="*.py" --include="*.go" --include="*.js" \
  -E '(TODO|FIXME|HACK|XXX|WORKAROUND|DEPRECATED|TEMP|NO_COMMIT)' \
  . 2>/dev/null | head -50 || true

# 2. Git log patterns — recent pain points and decisions
git log --oneline --grep="fix\|hotfix\|urgent\|broken\|security\|hack\|workaround\|legacy\|deprecated" -20 2>/dev/null || true

# 3. PR/commit messages with implicit rules
git log --format="%s" -50 2>/dev/null | grep -iE "(never|always|must|don't|avoid|ensure|make sure)" || true

# 4. Code review comments (if GitHub CLI available)
gh pr list --state all --limit 20 --json title,comments --jq '.[] | select(.comments > 3) | .title' 2>/dev/null || true

# 5. Recently changed files — active development areas
git log --format="" --name-only -20 2>/dev/null | sort | uniq -c | sort -rn | head -20 || true
```

**Infer rules from patterns**:
- Cluster of HACK/FIXME in a module → "This module has known issues, new code should avoid extending it"
- `DEPRECATED` comments → "This API is deprecated, use X instead"
- Frequent hotfixes in an area → "This area is fragile, changes need extra review"
- Commit messages with "never"/"always" → extract as conventions

**Actions**:
- Add inferred rules to AGENTS.md under CONVENTIONS or NOTES
- Mark each as `[AI-inferred: <evidence>]` for human confirmation

### Step 2.3: Multi-Repo Drift Detection

If the user has multiple registered projects (check `timely-doc-garden/projects.yaml`):

```bash
# Find other registered projects
cat /Users/chenchaowen/Desktop/Project/dev-tooling/.agents/.skills/timely-doc-garden/projects.yaml 2>/dev/null || echo "No projects registered"

# For each pair of projects, compare:
# - Framework versions (package.json / requirements.txt / go.mod)
# - Lint configs (.eslintrc / pyproject.toml / .golangci.yml)
# - Package prefixes / naming conventions
# - AGENTS.md conventions
```

**Actions**:
- If drift detected: add warning to AGENTS.md `⚠️ Drift: <project-A> uses X, <project-B> uses Y`
- Mark as `[REVIEW: intentional or needs alignment?]`

### Step 2.4: Compile Supplementary Findings + Create KNOWN_DEBTS.md

Collect all findings into a structured supplement:

```
## Supplementary Scan Results

### Security
- [FOUND] N credential patterns detected
- [FOUND] N .env files with potential real values
- [OK] No credential patterns found

### Implicit Knowledge
- [INFERRED] N rules inferred from code patterns
- [INFERRED] N tech debt areas identified
- [INFERRED] N deprecated patterns found

### Multi-Repo Drift
- [DRIFT] N inconsistencies across M projects
- [OK] Single project, no drift check needed
```

**Create KNOWN_DEBTS.md** at project root. This is the initial debt tracking file
that captures all issues found during scan. harness-gate (Step 3) will append
additional items (lint debt, coverage baseline, architecture violations).

Populate with findings from Phase 2 (security, TODO/FIXME, deprecated patterns):

```markdown
# Known Debts — <project-name>

> Freeze-ratchet: tracked but not blocking. New code must not add same-category violations.

## Priority

| Level | Meaning | When to fix |
|-------|---------|-------------|
| 🔴 HIGH | Security or correctness risk | ASAP |
| 🟡 MEDIUM | Code quality, maintainability | When convenient |
| 🟢 LOW | Style, non-functional | When bored |

---

## 🔴 HIGH

(group security findings here with D-NNN IDs)

## 🟡 MEDIUM

(group TODO/FIXME clusters, deprecated patterns, tech debt areas)

## 🟢 LOW

(group naming inconsistencies, documentation gaps)

---

## Quick Fix Commands
(concrete one-liners for bulk fixes, if applicable)
```

Later, `/harness-gate` will append lint debt, architecture violations, and coverage baseline.
`/timely-doc-garden` will keep debt references fresh (verify files exist, update counts).

**Mark Phase 2 as completed.**

---

## Phase 3: Human Confirmation Questionnaire

**Mark Phase 3 as in_progress.**

Generate a questionnaire from Phase 1 + Phase 2 findings. The user only needs to
answer judgment calls — everything else has been auto-detected and auto-filled.

### Questionnaire Format

Present the following to the user:

```
╔══════════════════════════════════════════════════════════════╗
║           HARNESS SCAN — Confirmation Questionnaire          ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  Please review the following items.                          ║
║  Answer [Y] confirm / [N] incorrect / [?] unsure             ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

#### Section A: Security (must confirm)

For each credential/secret finding:
```
A1. Credential pattern found at <file>:<line>
    AI assessment: appears to be a hardcoded <type>
    [Y] Real credential, needs removal/rotation
    [N] False positive (placeholder/test value)
    → Action: _______________

A2. .env file found: <file>
    AI assessment: contains N non-placeholder entries
    [Y] Contains real secrets, needs .gitignore + secret manager
    [N] Only placeholders, fine as-is
    → Action: _______________
```

#### Section B: Secret Management Strategy (must decide)

```
B1. How should this project manage secrets?
    [1] Environment variables (.env + .gitignore)
    [2] Secret manager (Vault, AWS Secrets Manager, etc.)
    [3] Platform-native (Vercel/Netlify env, etc.)
    [4] Other: _______________
```

#### Section C: AI-Inferred Rules (confirm or reject)

For each inferred implicit knowledge rule:
```
C1. "This module is likely legacy (N FIXME/HACK comments)"
    Evidence: <file:line references>
    [Y] Correct — mark as legacy in AGENTS.md
    [N] Not legacy, actively maintained
    [?] Unsure — mark [TODO: confirm with team]

C2. "This API is deprecated"
    Evidence: DEPRECATED comment at <file:line>
    [Y] Correct — add to ANTI-PATTERNS
    [N] Still active
    [?] Unsure — mark [TODO: confirm with team]
```

#### Section D: Multi-Repo Drift (if applicable)

```
D1. Project A uses React 18, Project B uses React 19
    [INTENTIONAL] Different migration timelines
    [NEEDS FIX] Should align to version X
```

#### Section E: Oral Knowledge (free-form)

```
E1. Are there any unwritten rules the AI would not find in code?
    Examples: "Always ask Bob before changing payment code",
              "The staging DB resets every Monday",
              "Don't touch the legacy API, it's deprecated but still used by client X"
    → Free-form answer: _______________

E2. Any other context the AI should know about this project?
    → Free-form answer: _______________
```

### Awaiting User Response

**This phase requires user interaction.** Present the questionnaire and WAIT for answers.
Do not proceed to Phase 4 until the user responds.

**Mark Phase 3 as completed after receiving answers.**

---

## Phase 4: Finalize

**Mark Phase 4 as in_progress.**

### Step 4.1: Apply Questionnaire Answers

Process user responses:

| Response | Action |
|----------|--------|
| `[Y]` on security finding | Add to AGENTS.md security section + KNOWN_DEBTS.md 🔴 HIGH |
| `[N]` on security finding | Remove from findings, no action |
| `[Y]` on inferred rule | Add to AGENTS.md CONVENTIONS, remove `[AI-inferred]` tag |
| `[Y]` on inferred tech debt | Add to KNOWN_DEBTS.md with appropriate priority |
| `[N]` on inferred rule | Discard |
| `[?]` on any item | Keep `[TODO: confirm with team]` tag |
| Free-form oral knowledge | Add to AGENTS.md NOTES section |
| Secret management strategy | Add to AGENTS.md security section |
| Drift `[INTENTIONAL]` | Add note to AGENTS.md explaining difference |
| Drift `[NEEDS FIX]` | Add to AGENTS.md as action item |

### Step 4.2: Update AGENTS.md

Apply all changes from the questionnaire to the AGENTS.md files generated in Phase 1.

**Security section** (if not present, create it):
```markdown
## SECURITY
- Secret management: <strategy from B1>
- Credential files: <list from A1-A2>
- ⚠️ Never commit: <patterns>
```

**Notes section** (add oral knowledge + debt tracking reference):
```markdown
## NOTES
- Complete debt list: [KNOWN_DEBTS.md](KNOWN_DEBTS.md) (created by /harness-scan, augmented by /harness-gate)
- <oral knowledge from E1>
- <context from E2>
- [TODO: confirm with team] <any uncertain items>
```

### Step 4.3: Validate

Run validation checks:

```bash
# Check AGENTS.md line count
wc -l AGENTS.md
# Must be ≤200 lines

# Check all file:line references are valid
grep -oE '[a-zA-Z0-9_./-]+\.[a-zA-Z]+:[0-9]+' AGENTS.md | while read ref; do
  file=$(echo "$ref" | cut -d: -f1)
  line=$(echo "$ref" | cut -d: -f2)
  [ -f "$file" ] && [ "$line" -le "$(wc -l < "$file")" ] || echo "BROKEN: $ref"
done
```

**README.md freshness check**: After generating AGENTS.md, compare with README.md:

1. Does README.md mention CLI commands that have changed? (e.g., new subcommands, renamed flags)
2. Does README.md reference architecture/structure that has been updated in AGENTS.md?
3. Are there stale URLs, deprecated commands, or removed features still listed?

If README.md is stale, add a note to the final report:
```
⚠️  README.md may need updates: {list of stale items}
    Run /readme-blueprint-generator to regenerate, or update manually.
```

### Step 4.4: Final Report

```
=== harness-scan Complete ===

Files Generated:
  [OK] ./AGENTS.md (root, {N} lines)
  [OK] ./src/{dir}/AGENTS.md ({N} lines)
  [OK] ./docs/architecture.md
  [OK] ./docs/development-guide.md
  [OK] ./KNOWN_DEBTS.md ({N} items: 🔴 H / 🟡 M / 🟢 L)

Baseline Specs (if OpenSpec initialized):
  [OK] openspec/specs/<capability-1>/spec.md ({N} lines)
  [OK] openspec/specs/<capability-2>/spec.md ({N} lines)
  ...

Supplementary Scan:
  Security: {N} findings ({confirmed} confirmed, {false_positives} false positives)
  Implicit Knowledge: {N} rules inferred ({confirmed} confirmed)
  Drift: {N} drift items ({intentional} intentional, {needs_fix} needs fix)

Pending (requires team input):
  - [TODO: confirm with team] {N} items

Hierarchy:
  ./AGENTS.md
  ├── src/hooks/AGENTS.md
  └── src/api/AGENTS.md

Next Step: Run /harness-gate to set up quality gates.
```

**Mark Phase 4 as completed.**

---

## Anti-Patterns

- **Guessing instead of asking**: If uncertain, mark `[TODO: confirm with team]`
- **Copying credential values**: NEVER copy secret values into docs — only `file:line` references
- **Generic advice**: Remove anything that applies to ALL projects (e.g., "use meaningful variable names")
- **Redundant content**: Subdirectory AGENTS.md must NEVER repeat parent content
- **Skipping the questionnaire**: Phase 3 is mandatory — even if AI is confident, human must confirm security findings
- **Over-documenting**: Not every directory needs AGENTS.md (score <8 → skip)
