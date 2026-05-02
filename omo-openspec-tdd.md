---
name: omo-openspec-tdd
description: >
  OmO + OpenSpec + TDD + Harness Init 四层AI编程体系。
  Core reference for AI-assisted development: architecture, quick-start, TDD mapping, troubleshooting.
  Use when: onboarding an existing project for AI, starting new features, understanding the 4-layer system.
  Triggers: "omo", "openspec", "tdd", "harness", "四层体系", "AI编程体系".
---

# OmO + OpenSpec + TDD + Harness Init：四层 AI 编程体系

> 最后更新：2026-05-01 | 适用：macOS + OpenCode + Oh-My-OpenAgent
> OpenSpec 版本：1.3.1 | OmO 版本：3.17.x

---

## 一、为什么是这四个？

四个工具各管一层，正交互补，不重叠：

| 工具 | 角色 | 回答的问题 | 适用时机 |
|------|------|-----------|---------|
| **Harness Init** | 地基工程师 | 项目长什么样？边界在哪？ | 存量项目首次接入 AI |
| **OpenSpec** | 产品经理 + QA | 做什么？怎么验证对不对？ | 每个新功能的规划 |
| **OmO** | 技术总监 + 开发团队 | 谁来做？怎么编排？ | 每个新功能的执行 |
| **TDD** | 质量闸门 | 代码是不是按要求写的？ | 贯穿实现全过程 |

**核心理念**：Harness Init 建地基，OpenSpec 的 Scenario（GIVEN/WHEN/THEN）就是测试用例的草稿，TDD 把草稿变成可执行的红灯，OmO 带团队把红灯变绿灯。

**协作关系**：

```
                    ┌─── Harness Init（一次性入场）───┐
                    │ 盘点 → 分层 → 设卡 → 维护        │
                    │ ↓ 产出: AGENTS.md + docs/ + 闸门  │
                    └──────────────┬───────────────────┘
                                   │
                                   ▼
OpenSpec 定义需求 ─────→ TDD 把需求变成测试 ─────→ OmO 编排 Agent 写代码通过测试
       ↑                        │                            │
       └── archive 合并学习 ←─── verify 验证覆盖 ←─── apply 实现并验证
```

> 📖 **深入理解**：为什么这四个能搭在一起？边界在哪？→ [integration-analysis.md](./omo-openspec-tdd/integration-analysis.md)

---

## 二、系统架构

| 层 | 工具 | 角色 |
|----|------|------|
| 0 | Harness Init | 盘点→分层→设卡→维护（一次性）→ [harness-init-guide.md](./omo-openspec-tdd/harness-init-guide.md) |
| 1 | OpenSpec | 规范驱动：`openspec/specs/` + `changes/<feature>/` |
| 2 | OmO | Agent 编排：Sisyphus→Prometheus→Atlas + Oracle/Metis/Momus |
| 3 | TDD | 质量闸门：RED→GREEN→REFACTOR |

---

## 三、环境配置

### 3.1 安装

```bash
bunx oh-my-openagent doctor        # 检查 OmO
npm install -g @fission-ai/openspec@latest && openspec --version  # OpenSpec ≥1.3.1
mkdir -p ~/.sisyphus/rules && cp rules/delegation-guardrails.md ~/.sisyphus/rules/  # 解锁多 agent 并行分派
```

### 3.2 TDD Schema

详见 [openspec-tdd-setup.md](./openspec-tdd-setup.md)。关键文件：`~/.local/share/openspec/schemas/tdd-driven/`。补丁脚本 `~/.local/bin/openspec-tdd`（别名 `oinit`）在 `openspec init` 后运行，切换为 `schema: tdd-driven`。

---

## 四、快速上手

### 4.1 存量项目首次接入（一次性）

```bash
/harness-scan          # 盘点 + 分层 + AI 补充扫描 + 人工确认问卷
/harness-gate          # 设卡（freeze-ratchet 策略，不直接开 strict）
/harness-doc-garden    # 安装三层 Hook（OpenCode + Git + 定时扫描）
```

> 📖 每步做什么、为什么、产出是什么 → [harness-init-guide.md](./omo-openspec-tdd/harness-init-guide.md)
> 📖 三层 Hook 详细配置 → [hook-config.md](./omo-openspec-tdd/hook-config.md)

### 4.2 启动新功能

```bash
openspec init . --tools opencode && oinit   # 初始化（新项目）
/opsx-explore                                # 探索现有代码
/opsx-propose <feature-name>                 # 生成 proposal/specs/design/tests/tasks
```

规划阶段**只读代码、只写 spec 文件**，不写实现代码。

> 📖 完整工作流示例（2FA）→ [workflow-example.md](./omo-openspec-tdd/workflow-example.md)

### 4.3 开始实现

```bash
/opsx-apply     # Atlas 读 tasks.md，分派 Agent，TDD 流程：RED → GREEN → REFACTOR
openspec validate <change-name>  # 规范验证（完整性 + 正确性 + 一致性）
/opsx-archive   # Delta Spec 合并到主 Spec（复合学习）
```

### 4.4 日常维护

`/harness-doc-garden` 安装完成后，三层 Hook 自动运行，无需手动操作：

| 时机 | 自动触发 | 机制 |
|------|---------|------|
| Agent 编辑文件后 | 实时校验引用 | OpenCode hook |
| Agent 回复完毕后 | AI 检查文档一致性（git worktree 隔离） | Plugin session.idle → worktree → opencode run |
| git commit 时 | lint + format + architecture + pytest（阻断）+ 引用校验 | git pre-commit |
| git push 时 | scan→fix→warn 修不了的 | git pre-push |
| 每周（定时） | 全量扫描 + AI 修复 | cron/launchd |

如需手动触发单次扫描：

```bash
/timely-doc-garden              # 手动运行扫描+修复（等同于定时任务的一次执行）
```

> 📖 三层 Hook 安装配置 → [hook-config.md](./omo-openspec-tdd/hook-config.md)

### 4.5 扩展命令（CLI 直接调用）

```bash
openspec new change <name>    # 建脚手架，不自动生成制品
openspec validate <name>      # 验证规范完整性 + 正确性 + 一致性
openspec archive <name>       # 归档完成的 change，Delta Specs 合入主 Spec
openspec show <name>          # 查看 change 详情
openspec list                 # 列出所有活跃 changes
```

---

## 五、TDD 的 Spec → Test 映射

GIVEN→Arrange, WHEN→Act, THEN→Assert. Scenario→`test_<snake_case>`, Requirement→`describe()`.
tasks.md 闸门：首组必须 Verify RED，末组必须 REFACTOR。

> 📖 完整映射规则 + 示例 → [tdd-mapping.md](./omo-openspec-tdd/tdd-mapping.md)

---

## 六、故障排查

| 问题 | 解决 |
|------|------|
| `openspec init` 后 schema 是 `spec-driven` | 运行 `oinit` |
| Agent 在规划阶段写代码 | 规划阶段只允许编辑 `openspec/` |
| 测试在 Verify RED 阶段就通过了 | 检查测试是否有具体断言 |
| Agent 忽略 AGENTS.md 规则 | `/harness-gate` 把规则变成 lint/test |
| 存量项目开 strict 后构建全红 | `/harness-gate` 用冻结-棘轮法 |
| Skill 导致 Agent 串行执行 | 安装 delegation-guardrails rule（§3.1）|

---

## 七、文档索引

### 参考文档（按需加载）

| 文档 | 内容 | 什么时候读 |
|------|------|-----------|
| [harness-init-guide.md](./omo-openspec-tdd/harness-init-guide.md) | Harness 四步法详细指南（面向人） | 首次接入存量项目 |
| [integration-analysis.md](./omo-openspec-tdd/integration-analysis.md) | 四工具集成可行性分析 | 技术选型、理解架构 |
| [workflow-example.md](./omo-openspec-tdd/workflow-example.md) | 2FA 完整工作流示例（~250 行） | 第一次学习工作流 |
| [tdd-mapping.md](./omo-openspec-tdd/tdd-mapping.md) | TDD Spec→Test 映射规则 + 示例 | 每次 propose 功能时 |
| [hook-config.md](./omo-openspec-tdd/hook-config.md) | 三层 Hook 体系详细配置 | 安装维护基础设施 |
| [openspec-tdd-setup.md](./openspec-tdd-setup.md) | TDD Schema 安装配置 | 环境搭建 |

### AI Skills（自动加载）

| Skill | 路径 | 用途 |
|-------|------|------|
| harness-scan | `.agents/.skills/harness-scan/SKILL.md` | 盘点 + 分层 |
| harness-gate | `.agents/.skills/harness-gate/SKILL.md` | 设卡 |
| harness-doc-garden | `.agents/.skills/harness-doc-garden/SKILL.md` | 安装维护基础设施 |
| timely-doc-garden | `.agents/.skills/timely-doc-garden/SKILL.md` | 文档一致性扫描+修复 |

### 项目内产出

| 产出 | 路径 | 来源 |
|------|------|------|
| 项目知识 | `AGENTS.md` + `docs/` | Harness Init |
| 债务清单 | `KNOWN_DEBTS.md` | harness-gate（按优先级分类 + 修复方法） |
| OpenSpec 制品 | `openspec/` | OpenSpec |
| 执行计划 | `.sisyphus/plans/` | OmO |
| 维护报告 | `.sisyphus/doc-garden-report.md` | timely-doc-garden |

---

## 八、参考链接

- [OpenSpec](https://github.com/Fission-AI/OpenSpec) — SDD 框架 · [OmO](https://github.com/code-yeongyu/oh-my-openagent) — Agent 编排 · [Open Specification](https://open-specification.org/) — 规范标准
