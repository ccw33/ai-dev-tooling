---
name: dev-tooling-feedback
description: >
  Report issues found while using dev-tooling skills in other projects, and fix
  the source skills/documentation in the dev-tooling repo. Reads dev-tooling path
  from config.yaml. Follows doc-for-ai rules when modifying documentation.
  Use when: finding bugs in harness-scan/harness-gate/harness-doc-garden/timely-doc-garden/doc-for-ai
  skills, discovering missing features, finding inaccurate documentation.
  Triggers: "dev tooling feedback", "fix skill", "report skill issue", "skill bug",
  "修改skill", "反馈", "skill问题", "dev-tooling反馈".
---

# Dev-Tooling Feedback: Cross-Project Feedback Loop

You are processing feedback from using dev-tooling skills in another project.
Your job: locate the exact source file in dev-tooling, understand the issue,
and fix it — following doc-for-ai rules.

## Configuration

Read `config.yaml` in this skill's directory to find the dev-tooling repo path:

```yaml
dev_tooling_path: /Users/chenchaowen/Desktop/Project/dev-tooling
```

If `config.yaml` is missing or path is invalid, stop and ask the user to provide the path.

## Skill → Source File Mapping

When the user mentions a skill name, map it to the source files:

| Skill Name | SKILL.md | Child Docs |
|------------|----------|------------|
| `harness-scan` | `{path}/.agents/.skills/harness-scan/SKILL.md` | — |
| `harness-gate` | `{path}/.agents/.skills/harness-gate/SKILL.md` | — |
| `harness-doc-garden` | `{path}/.agents/.skills/harness-doc-garden/SKILL.md` | — |
| `timely-doc-garden` | `{path}/.agents/.skills/timely-doc-garden/SKILL.md` | — |
| `doc-for-ai` | `{path}/.agents/.skills/doc-for-ai/SKILL.md` | — |
| documentation (general) | `{path}/omo-openspec-tdd.md` (root) | `{path}/omo-openspec-tdd/*.md` (children) |
| harness-init-guide | `{path}/omo-openspec-tdd/harness-init-guide.md` | — |
| hook-config | `{path}/omo-openspec-tdd/hook-config.md` | — |
| integration-analysis | `{path}/omo-openspec-tdd/integration-analysis.md` | — |
| tdd-mapping | `{path}/omo-openspec-tdd/tdd-mapping.md` | — |
| workflow-example | `{path}/omo-openspec-tdd/workflow-example.md` | — |

If the user mentions a topic but not a specific file, search the mapping table for the best match.

## Execution Flow

### Phase 1: Understand the Issue

1. Parse the user's description to identify:
   - **Which skill/doc** has the issue
   - **What behavior** was expected vs what happened
   - **In which project** the issue was found (current working directory)
2. If any of these are unclear, ask the user BEFORE proceeding.

### Phase 2: Locate and Read Source

1. Read `config.yaml` to get `dev_tooling_path`.
2. Map the skill/doc name to the source file path(s).
3. Read the relevant source file(s).
4. Pinpoint the exact section that needs changing.

### Phase 3: Fix

1. **Load doc-for-ai skill** if modifying documentation (root or child docs).
2. Apply the fix following these rules:

   **If fixing a SKILL.md:**
   - Keep the YAML frontmatter unchanged unless the description itself is wrong.
   - Modify only the relevant section.
   - If adding a new step/rule, fit it into the existing structure.

   **If fixing documentation:**
   - Follow doc-for-ai modification protocol:
     - If changing a child doc → check if parent summary needs updating.
     - If changing the root → check if child docs need updating.
     - Verify root doc stays ≤ 200 lines after changes.
   - Verify all internal links still resolve after changes.

3. After the fix, re-read the modified file to verify correctness.

### Phase 4: Confirm

Report to the user:
1. **What was changed** (file path + section)
2. **Why** (the root cause)
3. **Impact** (which projects/skills benefit from this fix)
4. **Suggest committing** if the fix looks correct.

## Hard Rules

1. **Only modify files under `dev_tooling_path`.** Never touch files in the current project (unless explicitly asked).
2. **Always read before editing.** Never guess at file contents.
3. **Follow doc-for-ai rules** when editing documentation (progressive loading, reference hierarchy, ≤200 line root).
4. **One issue per invocation.** If the user reports multiple issues, handle them one at a time, confirming each fix before moving to the next.
5. **Preserve the skill's purpose.** Don't change what a skill does — fix how it does it.

## Example Usage

```
User: /dev-tooling-feedback
      harness-scan 的 Phase 2 凭证扫描没有覆盖 .env.local 文件

Agent:
  1. 读取 config.yaml → dev_tooling_path = /Users/chenchaowen/Desktop/Project/dev-tooling
  2. 定位 → .agents/.skills/harness-scan/SKILL.md
  3. 读取 → 找到 Phase 2 凭证扫描的文件匹配模式
  4. 修改 → 添加 .env.local 到扫描模式列表
  5. 报告 → "已在 harness-scan/SKILL.md 的 Phase 2 凭证扫描中添加 .env.local。
            影响范围：所有项目下次运行 /harness-scan 时都会扫描 .env.local。"
```
