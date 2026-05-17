---
name: omo-openspec-tdd
description: >
  OmO + OpenSpec + TDD + Harness Init + 行为纪律 Rules 五层AI编程体系。
  Quick-start, TDD mapping, troubleshooting. Triggers: "omo", "openspec", "tdd", "harness", "superpowers".
---

# OmO + OpenSpec + TDD + Harness Init + 行为纪律：五层 AI 编程体系

> 最后更新：2026-05-17 | 适用：macOS + OpenCode + Oh-My-OpenAgent | OpenSpec 1.3.1 | OmO 4.1.x

## 一、为什么是这五个？

四个工具各管一层，行为纪律横切贯穿：

| 工具 | 角色 | 回答的问题 | 适用时机 |
|------|------|-----------|---------|
| **Harness Init** | 地基工程师 | 项目长什么样？边界在哪？ | 存量项目首次接入 AI |
| **OpenSpec** | 产品经理 + QA | 做什么？怎么验证对不对？ | 每个新功能的规划 |
| **OmO** | 技术总监 + 开发团队 | 谁来做？怎么编排？ | 每个新功能的执行 |
| **TDD** | 质量闸门 | 代码是不是按要求写的？ | 贯穿实现全过程 |
| **行为纪律 Rules** | 纪律教官 | 怎么守规矩？别偷懒？ | 横切贯穿 TDD + OmO 执行全过程 |

**协作关系**：

```
Harness Init（一次性入场）→ AGENTS.md + docs/ + 闸门
            ↓
OpenSpec 定义需求（brainstorm 聊清 → propose 写定）→ TDD 变成测试 → OmO 编排 Agent 通过测试
     ↑                 ↑ 行为纪律 Rules              │
     └── archive ← verify ←─── apply（Iron Law + 审查 + 证据先行）
```

> 📖 深入理解：为什么这五个能搭在一起？→ [integration-analysis.md](./omo-openspec-tdd/integration-analysis.md)

---

## 二、环境配置

### 2.1 安装

```bash
bunx oh-my-openagent doctor        # 检查 OmO
npm install -g @fission-ai/openspec@latest && openspec --version  # OpenSpec ≥1.3.1
bash ~/Desktop/Project/dev-tooling/rules/install-rules.sh  # 行为纪律 Rules（改为你本机的 dev-tooling 路径）
```

### 2.2 TDD Schema

详见 [openspec-tdd-setup.md](./openspec-tdd-setup.md)。关键文件：`~/.local/share/openspec/schemas/tdd-driven/`。补丁脚本 `~/.local/bin/openspec-tdd`（别名 `oinit`）在 `openspec init` 后运行，切换为 `schema: tdd-driven`。

---

## 三、快速上手

### 3.1 存量项目首次接入（一次性）

```bash
/harness-scan          # 盘点 + 分层 + AI 补充扫描 + 人工确认问卷
/harness-gate          # 设卡（freeze-ratchet 策略，不直接开 strict）
/harness-doc-garden    # 安装三层 Hook（OpenCode + Git + 定时扫描）
```

> 📖 每步做什么、为什么、产出是什么 → [harness-init-guide.md](./omo-openspec-tdd/harness-init-guide.md)
> 📖 三层 Hook 详细配置 → [hook-config.md](./omo-openspec-tdd/hook-config.md)

### 3.2 存量项目补测试基线（Harness Init 之后、OpenSpec 之前）

1. `/frontend-testing` 或 `/e2e-testing` → `project-discovery` 逆向分析测试目标
2. **人工审核测试计划** → 按计划写测试：Smoke → Critical Path → Edge Case
3. `npx stryker run` → **人工审核 mutation report**

"人工"步骤不可跳过：AI 不知道哪些流程是收入关键。

> 📖 测试框架搭建指南 → [testing-setup-guide.md](./testing-setup-guide.md)

### 3.3 启动新功能

```bash
openspec init . --tools opencode && oinit   # 初始化
/opsx-baseline-specs                         # 存量项目：根据 AGENTS.md 生成 baseline specs（一次性，新项目跳过）
/opsx-explore                                # 探索现有代码
/opsx-brainstorm <feature-name>              # 苏格拉底式 Q&A 聊清需求 + 选方案（每 propsoe 前必做）
/opsx-propose <feature-name>                 # 生成 proposal/specs/design/tests/tasks
```

规划阶段**只读代码、只写 spec 文件**，不写实现代码。`/opsx-brainstorm` 是 propose 前的**必经环节**——一次问答省数小时返工。

> 📖 完整工作流示例（2FA）→ [workflow-example.md](./omo-openspec-tdd/workflow-example.md)

### 3.4 开始实现

```bash
/opsx-apply     # Atlas 读 tasks.md，根据测试类型自动加载 frontend-testing 或 e2e-testing skill
openspec validate <change-name>  # 规范验证（完整性 + 正确性 + 一致性）
/opsx-archive   # Delta Spec 合并到主 Spec（复合学习）
```

`opsx-apply` TDD 周期中，Agent 按 [tdd-mapping.md](./omo-openspec-tdd/tdd-mapping.md) §6.4 加载对应 skill：组件/hook → `/frontend-testing`，跨页流程 → `/e2e-testing`。

### 3.5 日常维护

`/harness-doc-garden` 安装完成后，三层 Hook 自动运行，无需手动操作：

| 时机 | 自动触发 | 机制 |
|------|---------|------|
| Agent 编辑文件后 | 实时校验引用 | OpenCode hook |
| Agent 回复完毕后 | AI 检查文档一致性（git worktree 隔离） | Plugin session.idle → worktree → opencode run |
| git commit 时 | lint + format + architecture + pytest（阻断）+ 引用校验 | git pre-commit |
| git push 时 | scan→fix→warn 修不了的 | git pre-push |
| 每周（定时） | 全量扫描 + AI 修复 | cron/launchd |

> 📖 三层 Hook 安装配置 → [hook-config.md](./omo-openspec-tdd/hook-config.md)
### 3.6 扩展命令（CLI 直接调用）

```bash
openspec new change <name>    # 建脚手架
openspec validate <name>      # 验证完整性 + 正确性 + 一致性
openspec archive <name>       # Delta Specs 合入主 Spec
openspec show <name>          # 查看 change 详情
openspec list                 # 列出活跃 changes
```

---

## 四、TDD 的 Spec → Test 映射

GIVEN→Arrange, WHEN→Act, THEN→Assert. Scenario→`test_<snake_case>`, Requirement→`describe()`.
测试类型分流：组件/hook → unit test (`/frontend-testing`)，跨页流程 → E2E (`/e2e-testing`)。

> 📖 完整映射规则 + 示例 → [tdd-mapping.md](./omo-openspec-tdd/tdd-mapping.md)

---

## 五、故障排查

| 问题 | 解决 |
|------|------|
| `openspec init` 后 schema 是 `spec-driven` | 运行 `oinit` |
| 存量项目开 strict 后构建全红 | `/harness-gate` 冻结-棘轮法 |
| Agent 忽略 AGENTS.md 规则 | `/harness-gate` 把规则变成 lint/test |
| 测试在 Verify RED 阶段就通过了 | 检查测试是否有具体断言 |

---

## 六、文档索引

### 参考文档（按需加载）

| 文档 | 内容 | 什么时候读 |
|------|------|-----------|
| [harness-init-guide.md](./omo-openspec-tdd/harness-init-guide.md) | Harness 四步法详细指南（面向人） | 首次接入存量项目 |
| [integration-analysis.md](./omo-openspec-tdd/integration-analysis.md) | 四工具集成可行性分析 | 技术选型、理解架构 |
| [workflow-example.md](./omo-openspec-tdd/workflow-example.md) | 2FA 完整工作流示例（~250 行） | 第一次学习工作流 |
| [tdd-mapping.md](./omo-openspec-tdd/tdd-mapping.md) | TDD Spec→Test 映射规则 + 示例 | 每次 propose 功能时 |
| [hook-config.md](./omo-openspec-tdd/hook-config.md) | 三层 Hook 体系详细配置 | 安装维护基础设施 |
| [openspec-tdd-setup.md](./openspec-tdd-setup.md) | TDD Schema 安装配置 | 环境搭建 |
| [testing-setup-guide.md](./testing-setup-guide.md) | 测试框架搭建指南（新/存量项目） | 补测试基线时 |

### AI Skills（自动加载）

| Skill | 路径 | 用途 |
|-------|------|------|
| harness-scan | `.agents/.skills/harness-scan/SKILL.md` | 盘点 + 分层 |
| opsx-baseline-specs | `.agents/.skills/opsx-baseline-specs/SKILL.md` | 存量项目 baseline spec 生成 |
| opsx-brainstorm | `.agents/.skills/opsx-brainstorm/SKILL.md` | propose 前苏格拉底式需求讨论 |
| harness-gate | `.agents/.skills/harness-gate/SKILL.md` | 设卡 |
| harness-doc-garden | `.agents/.skills/harness-doc-garden/SKILL.md` | 安装维护基础设施 |
| timely-doc-garden | `.agents/.skills/timely-doc-garden/SKILL.md` | 文档一致性扫描+修复 |
| frontend-testing | `.agents/.skills/frontend-testing/SKILL.md` | Vitest + RTL 组件/ hooks 测试 |
| e2e-testing | `.agents/.skills/e2e-testing/SKILL.md` | Playwright E2E 测试 |

### 行为纪律 Rules（alwaysApply，无需 load_skills）

| Rule | 路径 | 用途 | 来源 |
|------|------|------|------|
| delegation-guardrails | `rules/delegation-guardrails.md` | 防止 Skill 覆盖编排策略 | OmO 社区 |
| tdd-iron-law | `rules/tdd-iron-law.md` | TDD 行为纪律 + 反合理化 | Superpowers |
| two-stage-review | `rules/two-stage-review.md` | 两阶段代码审查（合规 + 质量） | Superpowers |
| evidence-before-completion | `rules/evidence-before-completion.md` | 声称完成前必须提供证据 | Superpowers |

> 💡 已有项目补装 Rules：`bash rules/install-rules.sh`

### 项目内产出

| 产出 | 路径 | 来源 |
|------|------|------|
| 项目知识 | `AGENTS.md` + `docs/` | Harness Init |
| Baseline Specs | `openspec/specs/<capability>/spec.md` | opsx-baseline-specs（存量项目一次性） |
| 债务清单 | `KNOWN_DEBTS.md` | harness-gate（按优先级分类 + 修复方法） |
| OpenSpec 制品 | `openspec/` | OpenSpec |
| 执行计划 | `.sisyphus/plans/` | OmO |
| 维护报告 | `.sisyphus/doc-garden-report.md` | timely-doc-garden |
| 测试代码 | `src/**/*.test.{ts,tsx}` + `e2e/**/*.spec.ts` | frontend-testing / e2e-testing |

---

## 七、参考链接

- [OpenSpec](https://github.com/Fission-AI/OpenSpec) — SDD 框架 · [OmO](https://github.com/code-yeongyu/oh-my-openagent) — Agent 编排 · [Superpowers](https://github.com/obra/superpowers) — 行为纪律 Rules 来源 · [Open Specification](https://open-specification.org/) — 规范标准
