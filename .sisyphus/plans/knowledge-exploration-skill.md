# Plan: knowledge-exploration skill

## TL;DR

> **Quick Summary**: Create a reusable skill documenting the 8-step knowledge exploration methodology, derived from the frontend-testing + e2e-testing creation process.
> 
> **Deliverables**:
> - `.agents/.skills/knowledge-exploration/SKILL.md` — Main skill file (~120 lines)
> - `.agents/.skills/knowledge-exploration/references/work-phases.md` — Detailed 8-step process with real examples (~200 lines)
> - `AGENTS.md` — Updated skill table
> - Global symlink at `~/.agents/skills/knowledge-exploration`

## TODOs

- [x] 1. Create SKILL.md

  **What to do**:
  - Create `.agents/.skills/knowledge-exploration/SKILL.md`
  - YAML frontmatter with name `knowledge-exploration` and description
  - 8-step methodology overview: Explore → Decide → Implement → Comply → Find Gaps → Integrate → Critique → Audit
  - Quick reference section with one-line per step
  - Checklist template
  - Reference index pointing to `references/work-phases.md`
  - Triggers: "explore knowledge", "new skill", "research domain", "知识探索", "新知识", "调研"
  - Follow doc-for-ai conventions (this is a skill, so no 200-line limit on SKILL.md, but keep it concise)

  **Recommended Agent Profile**:
  - **Category**: `writing`
  - **Skills**: [`doc-for-ai`]

- [x] 2. Create references/work-phases.md

  **What to do**:
  - Create `.agents/.skills/knowledge-exploration/references/work-phases.md`
  - Detailed description of each of the 8 phases
  - Real examples from the frontend-testing + e2e-testing exploration (what we actually did at each step)
  - Key lessons learned section
  - YAML frontmatter, back-link to parent SKILL.md

  **Recommended Agent Profile**:
  - **Category**: `writing`
  - **Skills**: [`doc-for-ai`]

- [x] 3. Update AGENTS.md + create symlink

  **What to do**:
  - Add `knowledge-exploration` to the skills table in `AGENTS.md`
  - Create symlink: `~/.agents/skills/knowledge-exploration` → `.agents/.skills/knowledge-exploration`

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []
