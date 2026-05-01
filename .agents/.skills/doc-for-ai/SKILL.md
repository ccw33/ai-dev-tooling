---
name: doc-for-ai
description: >
  Progressive documentation architecture for AI agents. Guides writing and modifying
  docs that AI reads efficiently: root file ≤200 lines with index, child docs in same-name
  subdirectory, code/scripts extracted as skills or executable files.
  Use when: creating or restructuring documentation meant for AI agent consumption,
  writing AGENTS.md, designing doc hierarchies, splitting long docs.
  Triggers: "doc for ai", "progressive doc", "ai documentation", "restructure doc",
  "split doc", "文档重构", "渐进式文档", "AI文档", "拆分文档".
---

# Doc-for-AI: Progressive Documentation for AI Agents

You are restructuring or creating documentation optimized for AI agent consumption.
AI agents have context windows — loading 1000+ lines wastes tokens and dilutes focus.
The fix: progressive loading through a layered file structure.

## Hard Rules

1. **Root file ≤ 200 lines.** No exceptions. If it's growing past 200, content belongs in a child doc.
2. **Directory = reference hierarchy.** Child docs live in a subdirectory named after the parent file (without extension).
3. **Code blocks become files.** If a code block is > 10 lines and executable, extract it to a standalone file or skill. The doc only keeps a reference.
4. **Every internal link must resolve.** Verify all `[text](./path)` links point to existing files before finishing.
5. **Never duplicate content.** If the same info exists in a skill or child doc, the parent only keeps a one-line reference + link.

## Structure Pattern

Given a root doc `my-system.md`:

```
my-system.md                    ← Root: concepts + quick-start + index (≤200 lines)
my-system/                      ← Same-name subdirectory for child docs
├── detailed-guide.md           ← Detailed how-to (referenced from root §4)
├── example.md                  ← Full examples (referenced from root §5)
└── config-reference.md         ← Config details (referenced from root §6)
.agents/.skills/                ← Extracted executable scripts/skills
├── setup-script/SKILL.md       ← Was an embedded code block → now a skill
└── ...
```

### Layer Definitions

| Layer | Max Lines | Content | When Loaded |
|-------|-----------|---------|-------------|
| **Root** | ≤200 | Core concepts, quick-start commands, document index | Every AI session |
| **Child docs** | No hard limit | Detailed guides, examples, configuration | On demand (AI follows links) |
| **Skills/Scripts** | N/A | Executable code, automation | When action needed |

### What Goes in Root vs Child

**Root MUST contain:**
- "What is this?" (1-2 paragraphs)
- "How to use" (quick-start commands, max 3-5 steps)
- "Where to find more" (document index table with links)

**Root MUST NOT contain:**
- Full code examples > 10 lines
- Configuration details (JSON/YAML > 5 lines)
- Step-by-step tutorials
- ASCII art diagrams > 15 lines

**Child docs contain everything else.** Each child doc has a clear single purpose.

## Reference Syntax

### Root → Child

```markdown
> 📖 Details → [topic.md](./my-system/topic.md)
```

or in a table:

```markdown
| Document | Content | When to read |
|----------|---------|-------------|
| [topic.md](./my-system/topic.md) | Detailed explanation | When you need depth |
```

### Child → Root

```markdown
> Source: [my-system.md](../my-system.md)
```

Child docs always include a back-link to their parent in the first 5 lines.

### Child → Sibling

```markdown
See also: [related-topic.md](./related-topic.md)
```

## Modification Protocol

### When Modifying a Child Doc

1. **Check if the change affects the parent.** Read the parent's relevant section.
2. **If the parent has a summary of this content** → update the summary too.
3. **If the parent doesn't mention this content** → consider whether it should (add a one-liner + link if so).

### When Modifying the Root Doc

1. **If adding a new section** → check whether it should be a child doc instead.
2. **If removing a section** → check whether child docs that reference it need updating.
3. **If changing a link** → verify the target exists.

### When Adding New Content

1. **≤ 3 lines, directly relevant to root's purpose** → add to root.
2. **> 3 lines or a distinct topic** → create a child doc, add one-liner + link in root.
3. **Executable code > 10 lines** → extract as a skill or standalone script, add reference in the appropriate doc.

### Decision Tree

```
New content to add
    │
    ├── Is it executable code > 10 lines?
    │       → YES: Extract to skill/script. Add reference link in doc.
    │       → NO: ↓
    │
    ├── Is it ≤ 3 lines and core to root's purpose?
    │       → YES: Add to root. Check root stays ≤ 200 lines.
    │       → NO: ↓
    │
    └── Create child doc in parent's subdirectory.
        Add one-liner + link in parent's relevant section or index table.
        Verify link resolves.
```

## Quality Checklist

Before finishing any documentation work, verify ALL of the following:

- [ ] Root file ≤ 200 lines
- [ ] No code block > 10 lines that could be an executable file
- [ ] Every `[text](path)` link resolves to an existing file
- [ ] Each child doc has a back-link to parent in first 5 lines
- [ ] No content duplicated between parent and child (parent only has summaries/references)
- [ ] Directory structure matches reference hierarchy (child docs in same-name subdirectory)
- [ ] New files added to parent's document index table

## Anti-Patterns

| Anti-Pattern | Fix |
|-------------|-----|
| 500-line root doc with everything | Split: keep concepts + index in root, move details to children |
| Code blocks that should be scripts | Extract to `.agents/.skills/` or standalone file, keep reference |
| Flat directory with 10+ docs | Group into subdirectories matching parent file names |
| Child doc with no back-link | Add `> Source: [parent.md](../parent.md)` at top |
| Cross-references that skip levels | Use `../` to go up, `./dir/` to go down — match the directory tree |
| Adding content to root without checking size | Count lines first. If >180, something needs to move out |
| Modifying child without checking parent | Always read parent's relevant section after modifying child |

## Example: Before and After

### Before (monolithic, 1100 lines)

```
project/
└── system-doc.md    ← 1100 lines, AI loads all of it every time
```

### After (progressive, root 180 lines)

```
project/
├── system-doc.md                ← 180 lines: what + how + index
└── system-doc/
    ├── architecture.md          ← Detailed architecture
    ├── getting-started.md       ← Step-by-step setup
    ├── examples.md              ← Full code examples
    └── config-reference.md      ← All configuration options
```

AI loads 180 lines by default, follows links only when needed. Token usage drops ~85%.
