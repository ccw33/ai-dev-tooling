---
name: harness-gate
description: >
  Set up quality gates for an existing project — automated checks that enforce
  architecture rules, code style, type safety, and test coverage.
  Implements the freeze-ratchet strategy for brownfield projects.
  Use when: setting up CI/lint/test gates after harness-scan (Harness Init step 3).
  Triggers: "harness gate", "set up gates", "quality gates", "设卡", "质量门禁",
  "质量闸门", "set up quality checks".
  Runs: once per project (re-run to update gates).
---

# Harness Gate: Quality Gate Setup

You are setting up quality gates for an existing project (Harness Init step 3: 设卡).
The goal: turn project rules into automated checks so that AI agents and humans
can't accidentally violate them.

**Core principle**: Don't rely on anyone remembering rules — make violations
automatically detectable and blockable.

## Prerequisites

Confirm BEFORE proceeding:
1. Project has `AGENTS.md` at root (from `/harness-scan`)
2. `git` is available
3. Project has a CI system (GitHub Actions, GitLab CI, etc.) or is willing to add one

If AGENTS.md is missing, run `/harness-scan` first.

## Workflow Overview

```
Phase 1: Inventory Existing Checks (what's already there?)
    ↓
Phase 2: Identify Gaps (what's missing?)
    ↓
Phase 3: Design Gates (what to add, with user confirmation)
    ↓
Phase 4: Implement (install, configure, test)
    ↓
Phase 5: Update AGENTS.md (document the gates)
```

<critical>
**TodoWrite ALL phases. Mark in_progress → completed in real-time.**
```
TodoWrite([
  { content: "Phase 1: Inventory existing checks (CI, lint, test, hooks)", status: "pending", priority: "high" },
  { content: "Phase 2: Identify gaps and high-frequency violations", status: "pending", priority: "high" },
  { content: "Phase 3: Design gates + user confirmation", status: "pending", priority: "high" },
  { content: "Phase 4: Implement gates (install, configure, test)", status: "pending", priority: "high" },
  { content: "Phase 5: Update AGENTS.md with quality gates section", status: "pending", priority: "medium" }
])
</critical>

---

## Phase 1: Inventory Existing Checks

**Mark Phase 1 as in_progress.**

Scan what's already in place. Don't duplicate effort.

### Step 1.1: Fire Background Explore Agents

```
task(subagent_type="explore", load_skills=[], description="Scan CI configuration", run_in_background=true,
  prompt="Find ALL CI/CD configuration: .github/workflows/, .gitlab-ci.yml, Jenkinsfile, Makefile, docker-compose*.yml.
  For each: what checks run? what's the trigger? any quality gates?
  Return: file paths + summary of each pipeline's checks.")

task(subagent_type="explore", load_skills=[], description="Scan lint/format config", run_in_background=true,
  prompt="Find ALL lint and format configuration: .eslintrc*, .prettierrc*, pyproject.toml [lint], .flake8, .golangci.yml, rubocop, etc.
  For each: what rules are enabled? what's the severity? any disabled rules?
  Return: file paths + active rules summary.")

task(subagent_type="explore", load_skills=[], description="Scan test config", run_in_background=true,
  prompt="Find ALL test configuration: vitest.config, jest.config, pytest.ini, Cargo.toml [test], go test flags.
  For each: what framework? coverage enabled? coverage threshold? test file patterns?
  Return: file paths + test setup summary.")

task(subagent_type="explore", load_skills=[], description="Scan pre-commit hooks", run_in_background=true,
  prompt="Find ALL pre-commit hook configs: .husky/, .pre-commit-config.yaml, .githooks/, lefthook.yml.
  For each: what hooks exist? what do they check?
  Return: file paths + hook summary.")

task(subagent_type="explore", load_skills=[], description="Scan type check config", run_in_background=true,
  prompt="Find type checking configuration: tsconfig.json (strict mode?), pyproject.toml (mypy?), mypy.ini.
  For each: strict mode enabled? any suppressed errors? ignore patterns?
  Return: file paths + type check strictness level.")
```

### Step 1.2: Direct Scanning (while agents run)

```bash
# CI files
find . -path "*/node_modules" -prune -o -type f \( -name "*.yml" -o -name "*.yaml" \) -path "*/.github/workflows/*" -print 2>/dev/null
find . -name ".gitlab-ci.yml" -o -name "Jenkinsfile" -o -name "Makefile" 2>/dev/null

# Lint configs
find . -name ".eslintrc*" -o -name ".prettierrc*" -o -name ".flake8" -o -name ".golangci*" -o -name "pyproject.toml" 2>/dev/null

# Test configs
find . -name "vitest.config*" -o -name "jest.config*" -o -name "pytest.ini" -o -name "conftest.py" 2>/dev/null

# Hooks
find . -path "./.husky/*" -o -name ".pre-commit-config.yaml" -o -path "./.githooks/*" 2>/dev/null

# Type check
find . -name "tsconfig*.json" -o -name "mypy.ini" 2>/dev/null

# Current test status (baseline)
# Adjust command for the project's language
npm test 2>&1 | tail -5 || pytest --tb=no -q 2>&1 | tail -5 || go test ./... 2>&1 | tail -5 || echo "No test command found"
```

### Step 1.3: Compile Inventory

After collecting all results, compile into a structured inventory:

```
## Existing Checks Inventory

### CI Pipeline
- [GitHub Actions] lint + test + build on PR
- Missing: no deploy gate, no coverage threshold

### Linting
- [ESLint] active, extends recommended
- Disabled rules: no-console, any-type
- Missing: no architecture layer checks

### Type Checking
- [TypeScript] strict: partial (no strictNullChecks)
- Missing: full strict mode

### Testing
- [Vitest] unit tests only, no coverage threshold
- Coverage: ~60% (estimated)
- Missing: integration tests, coverage gate

### Pre-commit Hooks
- None
```

**Mark Phase 1 as completed.**

---

## Phase 2: Identify Gaps

**Mark Phase 2 as in_progress.**

### Step 2.1: Architecture Layer Analysis

Read AGENTS.md for architecture rules, then check if they're enforced:

```bash
# Extract architecture rules from AGENTS.md
grep -A5 "architecture\|layer\|dependency\|import.*must not\|forbidden" AGENTS.md 2>/dev/null || true

# Check for actual violations of documented rules
# Example: if AGENTS.md says "data layer must not import api layer"
grep -rn "from.*api" src/data/ 2>/dev/null || true
```

### Step 2.2: High-Frequency Violation Detection

Scan git history for recurring code review patterns:

```bash
# Recent commit messages indicating recurring issues
git log --oneline -30 | grep -iE "(fix.*lint|fix.*type|fix.*import|refactor.*layer|cleanup)" || true

# Common violation patterns in code
grep -rn --include="*.ts" --include="*.tsx" "as any\|@ts-ignore\|@ts-expect-error\|eslint-disable" . 2>/dev/null | wc -l || true
```

### Step 2.3: Gap Assessment

Categorize gaps by friction level (low friction = easy to add, high value):

| Gap Category | Friction | Value | Example |
|---|---|---|---|
| Architecture layer check | Medium | High | `src/data` must not import `src/api` |
| Linter rules | Low | Medium | Enable missing ESLint rules |
| Type strictness | Medium | High | Enable strictNullChecks |
| Coverage threshold | Low | High | Fail if coverage < current baseline |
| Pre-commit hooks | Low | Medium | Run lint + type check before commit |
| Import restrictions | Medium | High | Ban cross-layer imports |

**Mark Phase 2 as completed.**

---

## Phase 3: Design Gates + User Confirmation

**Mark Phase 3 as in_progress.**

### Step 3.1: Present Proposal to User

```
╔══════════════════════════════════════════════════════════════╗
║              HARNESS GATE — Gate Proposal                   ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  Existing checks found:                                      ║
║    ✅ ESLint (JavaScript)                                    ║
║    ✅ Vitest (unit tests)                                    ║
║                                                              ║
║  Gaps detected:                                              ║
║    ❌ No architecture layer enforcement                       ║
║    ❌ TypeScript strict mode partially off                    ║
║    ❌ No coverage threshold                                  ║
║    ❌ No pre-commit hooks                                    ║
║                                                              ║
║  Proposed gates (low friction first):                        ║
║                                                              ║
║  [1] Pre-commit: lint + type check (LOW friction)           ║
║  [2] Coverage threshold: freeze at current ~60% (LOW)       ║
║  [3] Architecture check: layer import rules (MEDIUM)        ║
║  [4] TypeScript strict mode: gradual enable (MEDIUM)        ║
║                                                              ║
║  Strategy: freeze-ratchet for brownfield project             ║
║  (Only NEW violations are blocked, existing are tracked)     ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

Which gates do you want to install? [all / 1,2,3 / none / custom]

Also: What are the most common mistakes AI agents make in this project?
These will become the first gates.
```

### Step 3.2: Await User Response

Wait for user to confirm which gates to install and provide common violation patterns.

**Mark Phase 3 as completed after user confirms.**

---

## Phase 4: Implement Gates

**Mark Phase 4 as in_progress.**

Implement each confirmed gate. For brownfield projects, use the **freeze-ratchet** strategy.

### Step 4.1: Freeze-Ratchet Strategy (CRITICAL for brownfield)

For each gate, the first run establishes a **baseline**:

1. **Freeze**: Run the check, record current violations (the "baseline")
2. **Ratchet**: Only NEW violations (not in baseline) block the build
3. **Tighten**: As team fixes old violations, baseline auto-shrinks

**NEVER enable strict mode on day one** — hundreds of existing errors will break
the build, and the team will abandon the whole system.

Implementation pattern:

```bash
# Example: ESLint freeze-ratchet
# Step 1: Run ESLint, capture current violations as baseline
npx eslint . --format json > .gate-baselines/eslint-baseline.json 2>/dev/null || true

# Step 2: CI script only fails on NEW violations
# (Compare current violations against baseline, fail only on new ones)
```

### Step 4.2: Install Gates by Type

#### Pre-commit Hooks (if confirmed)

```bash
# Option A: Husky (if already in project)
npx husky add .husky/pre-commit "npx eslint . --max-warnings 0 && npx tsc --noEmit"

# Option B: Simple .githooks
mkdir -p .githooks
cat > .githooks/pre-commit << 'EOF'
#!/bin/bash
set -euo pipefail
# Harness Gate: Pre-commit checks
echo "Running quality gates..."
# Adjust for project's language
npx eslint . --max-warnings 0 2>/dev/null || true
npx tsc --noEmit 2>/dev/null || true
echo "✅ Pre-commit checks passed"
EOF
chmod +x .githooks/pre-commit
git config core.hooksPath .githooks
```

#### Coverage Threshold (if confirmed)

```bash
# Step 1: Measure current coverage (baseline)
# Vitest example:
npx vitest run --coverage 2>/dev/null
# Read the coverage summary, extract line coverage %

# Step 2: Set threshold slightly below current (ratchet)
# In vitest.config.ts:
# coverage: { thresholds: { lines: <current - 2>%, branches: <current - 2>% } }
```

#### Architecture Layer Check (if confirmed)

```bash
# Create a custom check script
mkdir -p scripts

cat > scripts/check-architecture.sh << 'ARCH_EOF'
#!/bin/bash
# Architecture layer enforcement
# Reads layer rules from AGENTS.md or hardcoded below
set -euo pipefail

VIOLATIONS=0

# Example: data layer must not import api layer
if grep -rn "from.*\.\./api\|from.*\/api" src/data/ 2>/dev/null; then
  echo "❌ Architecture violation: src/data/ imports from src/api/"
  VIOLATIONS=$((VIOLATIONS + 1))
fi

# Add more rules as needed based on AGENTS.md

if [ "$VIOLATIONS" -gt 0 ]; then
  echo "Found $VIOLATIONS architecture violations"
  exit 1
fi

echo "✅ Architecture check passed"
ARCH_EOF

chmod +x scripts/check-architecture.sh
```

#### Type Check Strictness (if confirmed, gradual)

```bash
# Step 1: Check current strict settings
cat tsconfig.json | grep -A10 "compilerOptions" || true

# Step 2: Add incremental strict flags (not all at once)
# In tsconfig.json, add ONE flag at a time:
# "strictNullChecks": true
# Run: npx tsc --noEmit
# Fix errors. Repeat with next flag.
```

### Step 4.3: Validate All Gates

Run all installed gates to confirm they work:

```bash
# Run each gate individually
echo "Testing pre-commit hook..."
bash .githooks/pre-commit || bash .husky/pre-commit

echo "Testing architecture check..."
bash scripts/check-architecture.sh 2>/dev/null || echo "No architecture script"

echo "Testing lint..."
npx eslint . --max-warnings 0 2>/dev/null || echo "Lint has violations (expected for brownfield)"

echo "Testing type check..."
npx tsc --noEmit 2>/dev/null || echo "Type errors exist (expected for brownfield)"
```

**Mark Phase 4 as completed.**

---

## Phase 5: Update AGENTS.md

**Mark Phase 5 as in_progress.**

Add a "Quality Gates" section to the root AGENTS.md:

```markdown
## QUALITY GATES

Run these after every code change. All must pass before commit.

```bash
# Lint
npx eslint . --max-warnings 0

# Type check
npx tsc --noEmit

# Tests
npx vitest run

# Architecture
bash scripts/check-architecture.sh
```

### Strategy
- Mode: freeze-ratchet (new violations only are blocked)
- Baseline: .gate-baselines/ (auto-updated)
- Coverage floor: X% (from current baseline)
```

### Step 5.1: Validate AGENTS.md

```bash
wc -l AGENTS.md  # Should still be ≤200 lines
```

If adding quality gates pushes it over 200 lines, move detailed gate documentation
to `docs/development-guide.md` and keep only the commands in AGENTS.md.

### Step 5.2: Generate or Append KNOWN_DEBTS.md

After gates are installed, generate (if not exists) or append to the unified debt tracking file. This is where
all discovered issues (lint debt, architecture warnings, TODOs, security findings)
are cataloged with priority, fix instructions, and status.

> **Important**: harness-scan creates KNOWN_DEBTS.md during initial inventory. This step should APPEND any gate-discovered issues to the existing file, not overwrite it.

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

### D-001: <issue title>
- **Location**: <file or area>
- **Risk**: <what could go wrong>
- **Fix**: <specific command or step>
- **Status**: open / fixing / done

---

## 🟡 MEDIUM
(group by category: lint debt, architecture warnings, missing features)

---

## 🟢 LOW

---

## Quick Fix Commands
(concrete one-liners for bulk fixes)
```

**Data sources to populate KNOWN_DEBTS.md**:
- Lint errors: `ruff check . --quiet 2>&1 | wc -l` / `eslint . --format compact 2>&1 | wc -l`
- Architecture warnings: `bash scripts/check-architecture.sh 2>&1`
- TODOs/FIXMEs: `grep -rn "TODO\|FIXME\|HACK" src/ 2>/dev/null`
- Security findings from harness-scan Phase 2
- Coverage gaps vs baseline

**Update AGENTS.md NOTES** to reference:
```markdown
## NOTES
- Complete debt list: [KNOWN_DEBTS.md](KNOWN_DEBTS.md) (prioritized + fix instructions)
```

### Step 5.3: Final Report

```
=== harness-gate Complete ===

Existing Checks:
  ✅ ESLint — already configured
  ✅ Vitest — already configured

New Gates Installed:
  ✅ Pre-commit hook — lint + type check
  ✅ Coverage threshold — X% (freeze-ratchet)
  ✅ Architecture check — layer import rules
  ✅ TypeScript strict — strictNullChecks enabled

Debt Tracking:
  ✅ KNOWN_DEBTS.md — N items cataloged (🔴 H / 🟡 M / 🟢 L)
  ✅ AGENTS.md — NOTES section references KNOWN_DEBTS.md

Strategy: freeze-ratchet
  Baseline: .gate-baselines/ (N existing violations frozen)
  New violations: BLOCKED
  Existing violations: TRACKED in KNOWN_DEBTS.md (not blocked)

Next Step: Run /harness-doc-garden to set up ongoing maintenance.
```

**Mark Phase 5 as completed.**

---

## Anti-Patterns

- **Enabling strict mode on day one**: Hundreds of errors → team abandons the system. ALWAYS use freeze-ratchet.
- **Gates without CI**: Local hooks can be bypassed with `--no-verify`. Mirror gates in CI.
- **Too many gates at once**: Start with 2-3 low-friction gates, add more over time.
- **Gate drift**: Gates not updated when codebase evolves. Schedule quarterly gate review.
- **Manual-only gates**: If a gate can be automated, automate it. Don't rely on humans remembering.
- **Over-blocking**: Gates should block on NEW violations, not punish the team for historical debt.
