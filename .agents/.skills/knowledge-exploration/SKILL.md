---
name: knowledge-exploration
description: >
  8-step methodology for exploring new domain knowledge, creating skills/docs, and
  integrating into existing systems. Use when: researching new technology/domain for
  AI-assisted development, building new skills, creating documentation for unfamiliar
  topics, onboarding new knowledge into existing systems.
  Triggers: "explore knowledge", "new skill", "research domain", "知识探索",
  "新建skill", "新知识", "调研", "方法论".
---

# Knowledge Exploration & Implementation Workflow

You are exploring a new domain and need to produce production-quality skills,
documentation, and system integration. This skill provides an 8-step methodology
tested on real-world knowledge exploration.

## When to Use This Skill

- User asks to research a new technology/domain for AI-assisted development
- Building a new skill from scratch or adapting existing ones
- Creating documentation for unfamiliar topics
- Onboarding new knowledge into existing systems

## Quick Reference

```
Step 1: Explore    →  Parallel research (3-5 agents)
Step 2: Decide     →  Converge, record rationale
Step 3: Implement  →  Create files following project conventions
Step 4: Comply     →  Check doc-for-ai rules, register in indexes
Step 5: Find Gaps  →  "How would someone USE this for the first time?"
Step 6: Integrate  →  Wire into existing system (index files, flow diagrams)
Step 7: Critique   →  Mark human-required checkpoints
Step 8: Audit      →  Cross-file consistency review
```

## The 8-Step Process

### Step 1: Explore (Breadth-First)

Fire 3-5 parallel librarian/explore agents. Agent 1 = official docs,
Agent 2 = OSS implementations, Agent 3 = engineering blogs,
Agent 4 = existing repo overlap. Do NOT judge yet. Record findings in drafts.

### Step 2: Decide (Converge)

Build an explicit decision table: Option A vs B, chosen, why. Record every
decision with rationale. No decision should be implicit.

### Step 3: Implement

Create deliverables. Skills under `.agents/.skills/<name>/`, guides following
doc-for-ai conventions. Update AGENTS.md with new entries.

### Step 4: Comply

Run the doc-for-ai checklist: frontmatter on every .md, root files under 200
lines, child doc back-links present, all links resolve, registered in index tables.

### Step 5: Find Gaps (User Perspective)

Ask: "Someone who just got this, what's their first step?" Common gaps include
0-to-1 onboarding paths, decision trees, hidden prerequisites, and "teaches HOW
but not WHAT" syndrome.

### Step 6: Integrate (System Wiring)

Update parent system docs, add to tables, update flow diagrams. Trim existing
content to stay within line limits if necessary.

### Step 7: Critique (Human Checkpoints)

For every automated step, ask "Can AI do this alone?" Mark human-required nodes
explicitly. If the answer is always yes, you're not looking hard enough.

### Step 8: Audit (Cross-File Consistency)

Check: API usage consistency, command syntax uniformity, examples actually work,
mapping rules consistent, no orphaned references. This is the last defense.

## Key Lessons

- Exploration should be broad, decisions should be narrow. Record rationale.
- User questions are the best gap detector. Steps 5, 6, 7 were all triggered by user questions in practice.
- Implementation is only 1/3 of the work. 8 steps, only Step 3 is "writing code".
- Cross-file consistency is the last defense. Step 8 found 7 bugs in real testing skills.
- Line limits force re-evaluation of knowledge structure.

## Checklist Template

Copy this at the start of any knowledge exploration:

```markdown
## Knowledge Exploration: [TOPIC]

- [ ] Step 1: Explore — agents fired, findings recorded
- [ ] Step 2: Decide — decision table built, rationale documented
- [ ] Step 3: Implement — files created, AGENTS.md updated
- [ ] Step 4: Comply — frontmatter, line counts, links, indexes
- [ ] Step 5: Find Gaps — first-time user perspective checked
- [ ] Step 6: Integrate — wired into parent docs, diagrams updated
- [ ] Step 7: Critique — human checkpoints marked
- [ ] Step 8: Audit — cross-file consistency verified
```

## Reference

| Document | Content | When to read |
|----------|---------|-------------|
| [work-phases.md](./references/work-phases.md) | Detailed goals, actions, real examples, and pitfalls for each step | Before starting Step 1, or when stuck on any step |
