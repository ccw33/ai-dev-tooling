---
name: opsx-baseline-specs
description: >
  Generate OpenSpec baseline specs for brownfield projects after `openspec init`.
  Reads AGENTS.md WHERE TO LOOK table, identifies module capabilities, and spawns
  parallel deep agents to write `openspec/specs/<capability>/spec.md` for each module.
  Use when: after `openspec init . --tools opencode && oinit`, before first `/opsx-propose`.
  Triggers: "baseline specs", "generate specs", "初始化 spec", "baseline spec", "生成 spec".
  Runs: once per project (re-run to fill gaps only).
---

# Baseline Specs: Generate OpenSpec Specs from AGENTS.md

Generate baseline specs that describe the **current state** of each module in a
brownfield project — not incremental changes, but comprehensive "what exists now" docs.

**When to use**: After `openspec init . --tools opencode && oinit`, before your first
`/opsx-propose`. This gives future delta specs an accurate baseline to diff against.

**Prerequisites**:
1. Project has `AGENTS.md` (from `/harness-scan`)
2. Project has `openspec/` directory (from `openspec init`)
3. Both conditions met → proceed. If not, run the missing step first.

## Workflow

```
1. Parse AGENTS.md WHERE TO LOOK → identify capabilities
2. For each capability → spawn parallel deep agent
3. Collect results → verify → report
```

### Step 1: Identify Capabilities

Read `AGENTS.md` and extract the WHERE TO LOOK table. Each row that maps to a distinct
module directory is a capability.

**Naming convention**: kebab-case of the module's purpose.

Example mapping:
```
| 任务 | 位置 |
|------|------|
| 添加新策略 | execution/strategies/ | → backtest-engine
| 修改 ML 模型 | research/ml/ | → ml-research
| 修改数据源 | data/downloader_*.py | → data-pipeline
| 修改因子计算 | research/ml/alpha158_computer.py | → (merged with ml-research)
```

**Deduplication rules**:
- If two WHERE TO LOOK rows point to the same directory tree → merge into one capability
- If a row is too small to be a standalone capability (single file) → merge with related capability
- Use judgment: aim for 5-10 capabilities for a medium project

**Skip**: If `openspec/specs/<capability>/spec.md` already exists → skip that capability
(unless `--force` flag is provided).

### Step 2: Create Directories

```bash
# For each identified capability (that doesn't already exist)
mkdir -p openspec/specs/<capability>
```

### Step 3: Spawn Parallel Agents

One agent per capability, all at once. This is the core of the skill — leveraging OmO's
multi-agent orchestration for maximum throughput.

```
For each capability:
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
    1. Read these files to understand the module:
       - AGENTS.md (project overview and conventions)
       - <module source files — list specific paths from WHERE TO LOOK>
       - <CLI handlers for this module — grep cli.py for relevant subcommands>
       - <Config files for this module>

    2. The spec MUST cover these sections:
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
    - Do NOT write tests
    - Do NOT reference line numbers (they drift)
    """
  )
```

**Important**: The orchestrator (you) must fill in `<module source files>` for each agent
based on the WHERE TO LOOK table. Do NOT pass the generic template — each agent gets
specific file paths to read.

### Step 4: Collect and Verify

After all agents complete (wait for system notifications):

1. Check each `openspec/specs/<capability>/spec.md` exists
2. Verify each is under 200 lines: `wc -l openspec/specs/*/spec.md`
3. Spot-check 1-2 specs for accuracy (read first 20 lines)

### Step 5: Report

```
=== Baseline Specs Generated ===

Created:
  [OK] openspec/specs/<capability-1>/spec.md ({N} lines)
  [OK] openspec/specs/<capability-2>/spec.md ({N} lines)
  ...
  Skipped: {N} (already existed)

Total: {N} capabilities documented

Next Step: Run /opsx-explore to explore the codebase, then /opsx-propose to plan your first feature.
```

## Usage

```
/opsx-baseline-specs           # Generate baseline specs (skip existing)
/opsx-baseline-specs --force   # Overwrite existing specs
```

## Anti-Patterns

- **Running before `openspec init`**: Will fail — no `openspec/` directory exists yet
- **Running before `/harness-scan`**: Will fail — no AGENTS.md to parse
- **Running after every feature**: Unnecessary — only run once. Delta specs from `/opsx-archive` handle incremental updates
- **Passing generic prompts to agents**: Each agent MUST get specific file paths, not a template
