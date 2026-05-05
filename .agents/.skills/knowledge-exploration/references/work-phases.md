---
name: work-phases
description: >
  Detailed breakdown of the 8-step knowledge exploration process, including goals,
  execution instructions, real examples from testing skills creation, and common
  pitfalls. Companion to knowledge-exploration SKILL.md.
  Use when: executing a specific step of the knowledge exploration workflow,
  understanding what each step should produce, debugging a stuck exploration.
  Triggers: "explore step", "explore phase", "explore detail", "探索步骤".
---

> Source: [SKILL.md](../SKILL.md)

# Work Phases: Detailed 8-Step Process

## Step 1: Explore (Breadth-First)

**Goal**: Gather maximum surface area of the domain before making any judgments.

**How to execute**:
- Fire 3-5 parallel background agents (librarian for docs, explore for code patterns)
- Each agent gets a distinct search angle: official docs, OSS implementations, engineering blogs, existing repo overlap
- Collect findings into drafts. Do NOT evaluate or rank yet
- Time-box: 10 minutes of parallel research, then converge

**Real example**: We fired 4 parallel agents for testing skills creation: 3 librarian (official Vitest docs, OSS testing skills, AI testing tools survey) + 1 explore (existing dev-tooling repo patterns). Found 4 existing skills: antfu/vitest, citypaul/react-testing, QASkills/playwright, dify/frontend-testing. Scored each against our requirements.

**Common pitfalls**:
- Judging too early kills promising directions
- Skipping the "existing repo overlap" agent means reinventing wheels
- Only reading official docs misses real-world patterns and gotchas

**Output**: A findings document with raw notes from each agent, organized by source.

## Step 2: Decide (Converge)

**Goal**: Make explicit, documented decisions from the exploration data.

**How to execute**:
- Build a decision table: Option A vs Option B, chosen option, why
- Every technology choice, architecture decision, and scope boundary gets a row
- Record rationale even (especially) when the choice seems obvious

**Real example**: Vitest over Jest (native TS, Vite integration), Playwright over Cypress (accessibility-tree-first, MCP support), self-build frontend-testing skill (no single existing skill covered browser mode + jsdom + MSW patterns), adopt QASkills for E2E reference (92/100 quality score).

**Common pitfalls**:
- Implicit decisions become tech debt. If you can't write down why, you haven't decided
- Skipping the "why NOT" column. Recording rejected options prevents re-litigation
- Scope creep. The decision table should also record what is OUT of scope

**Output**: A decision table with at least 3-5 rows, each with chosen option and rationale.

## Step 3: Implement

**Goal**: Create all deliverable files following project conventions.

**How to execute**:
- Create skill files under `.agents/.skills/<name>/`
- Create guide docs following doc-for-ai conventions (frontmatter, line limits, child docs)
- Update AGENTS.md with new skill table entries
- Create symlinks if the project uses global skill registration

**Real example**: Created 21 files across 3 skills (frontend-testing, e2e-testing, testing-setup-guide) + 1 guide doc. Updated AGENTS.md with skill table entries. Created global symlinks in `~/.agents/skills/`.

**Common pitfalls**:
- Writing before checking conventions. Always read existing skills first for style
- Forgetting to update the index (AGENTS.md, README, etc.)
- Creating files in the wrong directory. Match the project's existing structure

**Output**: All files created, AGENTS.md updated, symlinks in place.

## Step 4: Comply

**Goal**: Verify every file meets doc-for-ai standards.

**How to execute**:
- Check every `.md` for YAML frontmatter with `name` and `description`
- Verify root docs stay under 200 lines
- Confirm each child doc has a back-link to its parent in the first 5 lines
- Test every `[text](path)` link resolves to an existing file
- Verify new files appear in parent index tables

**Real example**: Checked 19+ files for frontmatter, line counts, back-links, and link integrity. Found 5 missing back-links in frontend-testing reference docs that were added during implementation.

**Common pitfalls**:
- Back-links are the most commonly forgotten requirement
- Link checking is tedious but critical. One broken link breaks the progressive loading chain
- Line count creep. "Just one more section" pushes root docs past 200

**Output**: A compliance report listing all checks and any fixes applied.

## Step 5: Find Gaps (User Perspective)

**Goal**: Identify what a first-time user would be missing.

**How to execute**:
- Adopt the persona of someone encountering this topic for the first time
- Ask: "What's my first step? What do I need before I start? What decision am I making?"
- Look for: missing 0-to-1 onboarding, absent decision trees, hidden prerequisites
- The "teaches HOW but not WHAT" pattern is the most common gap

**Real example**: User asked "How should existing projects add tests?" This single question revealed that both testing skills taught testing mechanics (HOW) but had no guidance on test discovery or prioritization (WHAT to test). We added `project-discovery.md` to both frontend-testing and e2e-testing skills.

**Common pitfalls**:
- Expert blind spot. You know the domain, so you skip the basics
- Assuming the user reads everything. They won't. Each doc must stand on its own
- Not asking "what happens before this step?" Missing prerequisites strand users

**Output**: List of identified gaps, with new files or sections created to fill each.

## Step 6: Integrate (System Wiring)

**Goal**: Connect new content into the existing system without breaking it.

**How to execute**:
- Update parent system docs to reference new content
- Add entries to tables, flow diagrams, navigation indexes
- Check that adding content doesn't push any root doc past 200 lines
- Trim or restructure if line limits are exceeded

**Real example**: User asked about omo-openspec-tdd topic ordering. This triggered analysis of the Harness to Testing to OpenSpec pipeline. Added section 3.2 to the root doc, updated the flow diagram, added reference tables. Had to trim 20 lines from the existing root to stay under 200.

**Common pitfalls**:
- Adding without trimming. Every addition to a root doc risks exceeding limits
- Updating the parent but forgetting sibling cross-references
- Flow diagrams that don't reflect the new content. Outdated diagrams are worse than no diagrams

**Output**: Updated parent docs, diagrams, and tables. Line counts verified.

## Step 7: Critique (Human Checkpoints)

**Goal**: Identify every point where AI should NOT proceed without human input.

**How to execute**:
- Walk through each automated step and ask: "Can AI do this alone? Should it?"
- Mark human-required checkpoints explicitly in the documentation
- If every answer is "yes, AI can do this alone", you haven't looked hard enough
- Common checkpoint areas: destructive operations, security-sensitive configs, architectural decisions

**Real example**: User asked "Is the test baseline entirely AI-executed?" This exposed zero human checkpoints in the project-discovery docs. We added 3 explicit checkpoints to frontend-testing and 4 to e2e-testing, covering baseline approval, flaky test policy, and coverage target negotiation.

**Common pitfalls**:
- Over-automation. Some decisions need human judgment, and that's fine
- Vague checkpoints. "Review this" is not actionable. Specify WHAT to review and WHY
- Forgetting that checkpoints should be in the workflow, not just documented as notes

**Output**: Explicit human-checkpoint markers in every relevant file.

## Step 8: Audit (Cross-File Consistency)

**Goal**: Verify that all files tell a coherent, consistent story.

**How to execute**:
- Check API usage is consistent across all files (same function names, same signatures)
- Verify command syntax is uniform (same package manager, same flag conventions)
- Run every code example mentally. Does it actually work?
- Check mapping tables and cross-references are consistent
- Hunt for orphaned references (mentions of things that no longer exist)

**Real example**: Cross-file review found 7 issues: `vi.mock` used inside a function (should be module scope), `window.location.pathname` doesn't work in jsdom, `/load` command doesn't exist, `it()` vs `test()` inconsistency, `pnpm` vs `npx` mismatch, missing Browser Mode example, StrykerJS E2E gap undocumented.

**Common pitfalls**:
- Skipping this step because "it should be fine." It won't be.
- Only checking syntax, not semantics. Commands can be syntactically correct but contextually wrong
- Forgetting to check the inverse: things mentioned in one file but never defined anywhere

**Output**: A bug list with fixes applied, and a consistency report confirming zero remaining issues.
