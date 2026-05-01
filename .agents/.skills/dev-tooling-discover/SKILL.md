---
name: dev-tooling-discover
description: >
  Discover all available research/guide documents and skills in the dev-tooling knowledge base.
  Recursively scans all .md files, reads YAML frontmatter (name + description),
  and presents a tree-structured catalog grouped by directory hierarchy.
  Use when: exploring what dev-tooling offers, finding relevant docs for a project,
  onboarding to the dev-tooling knowledge base, looking for AI tooling guidance.
  Triggers: "dev tooling discover", "what's available", "show docs", "list skills",
  "发现文档", "查看可用skill", "dev-tooling有什么".
---

# Dev-Tooling Discover: Knowledge Base Catalog

You are presenting the dev-tooling knowledge base catalog to the user.
The goal: help them quickly find relevant documents and skills for their current need.

## Configuration

Read `config.yaml` in this skill's directory (same as `dev-tooling-feedback/config.yaml`):

```yaml
dev_tooling_path: /path/to/dev-tooling
```

If missing or invalid, stop and ask the user.

## Execution

### Step 1: Scan All `.md` Files

Recursively find all `.md` files under `dev_tooling_path`, excluding:
- `.git/`
- `__pycache__/`
- `node_modules/`
- `templates/` (skill internal files, follow skill-creator conventions, not documentation)
- `references/` (skill internal files, follow skill-creator conventions, not documentation)

For each file, read ONLY the YAML frontmatter (lines between `---` markers).
Extract `name` and `description` fields.

If a file has no YAML frontmatter, note it as `[missing frontmatter]` and skip it from the catalog (but report it as a quality issue at the end).

### Step 2: Build Directory Tree

Organize the results as a tree matching the actual directory structure.
Use the relative path from `dev_tooling_path` as the hierarchy.

### Step 3: Present the Catalog

Display in this format:

```
📂 dev-tooling/

📄 omo-openspec-tdd.md
   OmO + OpenSpec + TDD + Harness Init 四层AI编程体系
   适用：存量项目接入AI、新功能开发

📄 openspec-tdd-setup.md
   OpenSpec + TDD 全局配置指南
   适用：环境搭建

📂 omo-openspec-tdd/

   📄 harness-init-guide.md
      Harness Engineering 存量项目初始化指南
      适用：首次接入存量项目

   📄 integration-analysis.md
      四工具集成可行性分析
      适用：技术选型、理解架构

   📄 workflow-example.md
      2FA完整工作流示例
      适用：学习工作流

   📄 tdd-mapping.md
      TDD Spec→Test 映射规则
      适用：编写测试

   📄 hook-config.md
      三层Hook体系详细配置
      适用：安装维护基础设施

📂 .agents/.skills/

   🔧 harness-scan/SKILL.md
      Deep project inventory + layered documentation
      适用：存量项目盘点+分层

   🔧 harness-gate/SKILL.md
      Quality gate setup with freeze-ratchet
      适用：设卡

   🔧 harness-doc-garden/SKILL.md
      One-time install of doc maintenance hooks
      适用：安装文档维护

   🔧 timely-doc-garden/SKILL.md
      Doc-code consistency scan + fix
      适用：定期文档扫描

   🔧 doc-for-ai/SKILL.md
      Progressive documentation architecture rules
      适用：写/改AI文档

   🔧 dev-tooling-feedback/SKILL.md
      Cross-project feedback loop
      适用：在其他项目发现问题后修复源头

   🔧 dev-tooling-discover/SKILL.md
      Knowledge base catalog (this skill)
      适用：发现可用文档和skill
```

### Step 4: Recommend (Optional)

If the user described their current task or problem, highlight the 2-3 most relevant entries:

```
💡 Based on your context, you might want:

1. 📄 omo-openspec-tdd.md — 了解整体四层体系
2. 🔧 harness-scan — 直接开始盘点当前项目
3. 📄 harness-init-guide.md — 详细了解每步做什么
```

## Hard Rules

1. **Read frontmatter only.** Never load the full file content — just the YAML between `---` markers.
2. **Respect directory structure.** Present files in their actual directory hierarchy.
3. **Report quality issues.** If any `.md` file is missing YAML frontmatter, list it at the end as a warning. Exception: files under `templates/` or `references/` subdirectories are internal skill support files and should be silently skipped — no warning needed.
4. **Don't modify anything.** This is a read-only discovery skill.
