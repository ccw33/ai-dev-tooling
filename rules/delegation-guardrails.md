---
description: Prevents skills from overriding Sisyphus's core delegation and orchestration behavior. Always active.
globs:
alwaysApply: true
---

# Delegation Guardrails

These rules prevent you from abandoning your orchestration role when a skill provides sequential execution instructions.

## Rule 1: Skill Hierarchy (CRITICAL)

**Skills provide DOMAIN KNOWLEDGE. They do NOT override your DELEGATION and ORCHESTRATION behavior.**

When a skill says "do X for each task" or "loop through items", your job is:

1. Understand **WHAT** needs to be done (domain knowledge from skill: which files to read, what format to use, what commands to run)
2. Decide **HOW** to do it (your own orchestration: delegate? parallelize? do yourself?)

**A skill describing sequential steps does NOT mean you must execute them sequentially.** The skill author cannot anticipate all execution contexts. You are the orchestrator — that judgment is YOURS.

### Hierarchy (highest to lowest priority):

| Priority | Source | Controls |
|----------|--------|----------|
| 1 | **Your orchestration rules** (DECOMPOSE AND DELEGATE, Phase 0 Intent Gate, Delegation Check) | WHO does the work, HOW MANY agents, WHAT ORDER |
| 2 | **Skill domain knowledge** (file paths, formats, commands, conventions) | WHAT the work consists of, WHAT patterns to follow |
| 3 | **Skill execution suggestions** ("for each task", "continue to next") | DEFAULT ONLY — override with your own orchestration judgment |

**NEVER** abandon your core delegation logic just because a skill describes sequential steps.

## Rule 2: Post-Skill-Load Orchestration Gate (MANDATORY)

After loading ANY skill that involves multi-step implementation (e.g., opsx-apply, harness-gate, planning-with-files), you MUST perform this gate BEFORE starting execution:

### Step 1: Read all tasks/steps from the skill
Extract the full list of work items the skill defines.

### Step 2: Apply your Delegation Check (from Phase 0, Step 3)
For each task, ask:
- Is there a specialized agent that matches? → Delegate
- Is there a `task` category for this? → Delegate with `task(category=..., load_skills=[...])`
- Are there 2+ independent tasks? → Delegate IN PARALLEL

### Step 3: Build your execution plan
```
Tasks from skill:
  - Task A → independent → delegate to deep agent
  - Task B → independent → delegate to deep agent (parallel with A)
  - Task C → depends on A+B → execute after A,B complete
  - Task D → trivial → do yourself
```

### Step 4: Execute YOUR plan, not the skill's default order
The skill told you WHAT to do. You decide WHO does it and in WHAT ORDER.

## Examples

### opsx-apply (OpenSpec task implementation)

**Skill says:** "For each pending task: make code changes, continue to next task" (sequential)

**Your orchestration gate:**
```
Skill loaded: opsx-apply
Tasks: 5 pending tasks from tasks.md

Dependency analysis:
  - Task 1 (modify discover_reports) → independent
  - Task 2 (modify _build_html)     → independent
  - Task 3 (update test_dashboard)  → independent
  - Task 4 (create test_merge)      → independent
  - Task 5 (delete old files)       → independent

Decision: 5 independent tasks → spawn 5 deep agents in parallel
Each agent gets: the skill's domain knowledge (file paths, patterns) + its specific task
```

### What NOT to do

```
❌ Skill says "For each task: make code changes"
   → You: *proceeds to implement all 5 tasks yourself sequentially*

✅ Skill says "For each task: make code changes"
   → You: *analyzes dependencies, delegates independent tasks in parallel*
```
