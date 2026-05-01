---
name: harness-init-guide
description: >
  Harness Engineering guide for brownfield project initialization.
  Four-step method: inventory → layer → gate → maintain.
  Use when: onboarding existing projects for AI-assisted development, understanding Harness Init in depth.
  Triggers: "harness init", "存量项目", "项目初始化", "harness guide".
---

# Harness Engineering — 存量项目初始化

> 适用于任何语言、任何 AI 编码工具。思路通用，脚本绑定 macOS + OpenCode + Oh-My-OpenAgent。
>
> 相关文档：
> - [omo-openspec-tdd.md](../omo-openspec-tdd.md) — 四层体系总览
> - [integration-analysis.md](./integration-analysis.md) — 四工具集成可行性分析
> - [hook-config.md](./hook-config.md) — 三层 Hook 体系详细配置

---

## 核心问题

AI Agent 在存量项目中反复失败：看到已有代码就提前交卷、环境跑不通但不自知、每次新对话重新摸索项目。

**一句话解法**：别指望 Agent 记住规则——把规则变成自动化检查，Agent 根据报错改到通过为止。

---

## 四步法概览

```
盘点 → 分层 → 设卡 → 维护
 │       │       │       │
 │       │       │       └→ 持续：doc-gardening + 规则回顾
 │       │       └── 关键一步：规则 → 自动化检查
 │       └── 根文件 ≤100 行，详细内容下沉 docs/
 └── 盘五件事：构建命令 / 架构约束 / 编码规范 / 安全红线 / 隐性知识
```

每步做完向用户汇报，确认后再进下一步。

---

## 执行方式

| 步骤 | 命令 | 说明 |
|------|------|------|
| **Step 1-2：盘点 + 分层** | `/harness-scan` | init-deep 扫描 + AI 补充扫描（凭证/隐性知识/漂移）+ 人工确认问卷 |
| **Step 3：设卡** | `/harness-gate` | 盘点已有检查 → 识别缺口 → freeze-ratchet → 安装配置 |
| **Step 4：维护** | `/harness-doc-garden` → `timely-doc-garden` | 三层 Hook（OpenCode + Git + 定时扫描）一步到位 |

> **三个 skill 各自的详细指令**：见 `.agents/.skills/harness-scan/SKILL.md`、`harness-gate/SKILL.md`、`harness-doc-garden/SKILL.md`。

---

## Step 1：盘点

**目的**：把 Agent 需要知道的东西写下来，放到它能读到的地方。

**盘五件事**：

| 维度 | 问什么 |
|------|--------|
| 构建命令 | 怎么装依赖、跑测试、跑 lint、部署？需要什么环境变量？ |
| 架构约束 | 哪些层不能互相依赖？模块边界在哪？有没有代码生成？ |
| 编码规范 | 命名风格、错误处理、日志格式、Response 结构 |
| 安全红线 | 哪些文件不能碰？凭证在哪（只标位置不复制值）？ |
| 隐性知识 | 团队口头约定、历史坑、"大家都知道但没写下来"的事 |

`/harness-scan` 自动盘前 85%（从构建文件、CI 配置、源码、git log 提取），剩下 15%（纯口头约定、策略决策）通过确认问卷补全。

---

## Step 2：分层

**目的**：Agent 不需要一次加载所有知识。把"每次必须知道的"和"按需查阅的"分开。

| 层级 | 放什么 | 加载时机 |
|------|--------|----------|
| 根文件 | 构建命令、架构红线、安全红线、文档索引 | 每次对话自动加载 |
| docs/ 目录 | 架构细节、开发指南、API 索引、架构决策记录(ADR) | Agent 需要时按需读取 |

**docs/ 建议包含**：
- **architecture.md** — 分层结构（ASCII 目录树）、基础设施集成、外部依赖、特殊模式
- **development-guide.md** — 环境搭建、本地开发、测试、迁移、部署
- **api-contracts.md** — API 规范索引（只做索引，不复制规范内容）
- **adr/** — 架构决策记录，每份 ≤ 40 行，必须有源码引用

**约束**：根文件 ≤ 100 行 / < 32KB。子目录只写与根文件的差异。凭证只标 `文件名:行号`。

---

## Step 3：设卡

**目的**：把文档里写的规则变成可执行的自动化检查。这是最关键的一步。

> Agent 不需要"记住"任何规则。它只需要跑检查命令，然后根据报错改到通过。

**五步走**（`/harness-gate` 自动执行）：

1. **盘点已有检查** — 项目已经有哪些 lint / test / CI 检查？
2. **识别高频违规** — Agent（和人）最容易犯什么错？
3. **新增自动化检查** — 架构分层检查、Linter、类型检查、覆盖率阈值
4. **挂到 CI** — 每 PR / merge 跑检查
5. **挂到本地** — pre-commit hook + AI 工具本地配置

**棕地项目棘轮策略**（核心）：绝不直接开严格模式。正确做法是**冻结-棘轮**：首次冻结存量违规，只阻断新增违规，随团队修复自动收紧。

---

## Step 4：维护

**目的**：让文档活着。过期的记忆比没有记忆更危险。

| 机制 | 做什么 | 频率 |
|------|--------|------|
| Doc-gardening | 扫描引用是否正确，事实性声明是否与代码一致 | 每周 |
| 规则回顾 | 违规率趋势、棘轮收紧、无效规则清理 | 每两周 |
| 根文件瘦身 | 膨胀超过 100 行时下沉到 docs/ | 每月 |

详细配置见 [hook-config.md](./hook-config.md)。

---

## 常见误区

| 误区 | 正确做法 |
|------|----------|
| 5000 行的根配置文件 | ≤ 100 行索引，详细内容放 docs/ |
| 只写文档不设自动检查 | 关键规则必须变成可执行 lint / test |
| Agent 自己验证自己的产出 | 生成与评估必须分离（Agent 写 → Linter 验） |
| 一次性写好不维护 | 文档是活的，需要持续 gardening |
| 棕地项目直接全量 strict | 冻结-棘轮法：先宽松启动，逐步收紧 |
| 子仓库复制根文件内容 | 只写差异 |
| 文档里写凭证值 | 只写 `文件名:行号` + 字段名 |

---

## 时间线参考

```
Day 1：  /harness-scan       — 盘点 + 分层（含 AI 补充扫描 + 人工确认问卷）
Day 2-3：/harness-gate       — 设卡（盘点已有检查 → 识别缺口 → freeze-ratchet → 安装）
Day 3+： /harness-doc-garden — 安装三层 Hook（OpenCode + Git + 定时扫描）
持续：   timely-doc-garden   — 每周 gardening · 每两周规则回顾 · 每月根文件瘦身
```

---

> 来源: 张乐《AI 时代研发效能提升落地实战》、OpenAI Codex 团队实践、Anthropic Harness Engineering 工程文章。
