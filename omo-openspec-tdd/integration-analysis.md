---
name: integration-analysis
description: >
  Feasibility analysis of integrating Harness Init + OpenSpec + OmO + TDD + Behavioral Discipline Rules
  as a five-layer AI programming system. Covers tool positioning, complementary relationships, boundary analysis,
  data flow, and agent switching strategy.
  Use when: technology selection, explaining architecture to team, understanding why these tools work together.
  Triggers: "integration", "feasibility", "可行性", "集成分析", "为什么这五个".
---

# 五工具集成可行性分析

> 读者：技术负责人、架构师、新加入的团队成员
> 目的：回答"这五个工具为什么能搭在一起、边界在哪、数据怎么流转"
> 来源：[omo-openspec-tdd.md](../omo-openspec-tdd.md) §2.2 + §2.3 + §4.2 + §七

## 1. 五工具定位

| 工具 | 一句话定位 | 核心问题 | 触发时机 |
|------|-----------|---------|---------|
| Harness Init | 地基工程师 | 项目长什么样？ | 存量项目首次接入 |
| OpenSpec | 产品经理 + QA | 做什么？怎么验证？ | 每个新功能 |
| OmO | 技术总监 + 开发团队 | 谁来做？怎么编排？ | 每个新功能 |
| TDD | 质量闸门 | 代码对不对？ | 贯穿全过程 |
| 行为纪律 Rules | 纪律教官 | 怎么守规矩？别偷懒？ | 横切贯穿执行全过程 |

## 2. 为什么能搭在一起

核心论点：四个工具各回答一个不同的问题（正交互补），行为纪律 Rules 是横切层（不新增维度，但强化所有维度）。

每个工具的数据产物恰好是下一个工具的输入：

| 工具 | 输入 | 输出 | 下游消费者 |
|------|------|------|-----------|
| Harness Init | 存量项目源码 | AGENTS.md + docs/ + 质量闸门 | OpenSpec（项目上下文）、OmO（Agent 约束） |
| OpenSpec | 功能需求 | proposal → specs → design → tests → tasks | TDD（测试蓝图）、OmO（执行清单） |
| TDD | tests.md 中的测试蓝图 | RED（失败的测试） → GREEN（通过的实现） → REFACTOR | OmO（验证闸门） |
| OmO | tasks.md + AGENTS.md | 执行计划 → 代码变更 → 验证结果 | OpenSpec（verify）、Harness（文档更新触发） |
| 行为纪律 Rules | 无（横切注入） | 行为约束（Iron Law + 审查 + 证据） | TDD + OmO 执行全过程 |

**关键互补关系**：

- Harness Init 盘的是**存量项目现状**，OpenSpec specs 是**功能需求**，维度完全不同
- Harness Init 设的是**存量基线检查**，TDD 闸门是**新功能开发纪律**，一个守存量一个管增量
- OpenSpec 定义**需求规格**，Prometheus 定义**执行分派**，输入输出互补
- OmO 验代码质量（类型/编译/测试通过），OpenSpec 验需求覆盖（Scenario 覆盖率），验证轴正交
- **TDD Schema 保证结构（tasks.md 有 RED→GREEN→REFACTOR），行为纪律 Rules 保证行为（Agent 不跳步、不走捷径）**——一个管骨架一个管灵魂

> 📖 行为纪律 Rules 提取自 [obra/superpowers](https://github.com/obra/superpowers)，以 OmO Rules（`alwaysApply: true`）注入，不与现有体系冲突。详见 → [../rules/tdd-iron-law.md](../rules/tdd-iron-law.md)

## 3. 边界划分

### 3.1 潜在重叠点分析

| 潜在重叠点 | 为什么不冲突 |
|-----------|-------------|
| Harness Init 盘点 vs OpenSpec specs/ | Harness Init 盘的是**存量项目现状**，OpenSpec specs 是**功能需求**，维度完全不同 |
| Harness Init 设卡 vs TDD 闸门 | Harness Init 设的是**存量项目的基线检查**，TDD 闸门是**新功能的开发纪律**，一个守存量一个管增量 |
| 规划阶段（OpenSpec propose vs OmO Prometheus） | OpenSpec 定义**需求规格**，Prometheus 定义**执行分派**，输入输出互补 |
| 验证阶段（OpenSpec verify vs OmO 验证） | OmO 验代码质量（类型/编译/测试通过），OpenSpec 验需求覆盖（Scenario 覆盖率） |
| 任务管理（tasks.md vs .sisyphus/plans/） | tasks.md 是线性的需求分解，Atlas 在其基础上做依赖分析和并行分组 |
| Agent 权限（规划阶段 vs 执行阶段） | 阶段分离：规划阶段由 Sisyphus 限制为只读代码 + 只写 spec 文件，执行阶段全权限 |
| **行为纪律 Rules vs TDD Schema** | TDD Schema 保证**结构**（tasks.md 有正确的 RED→GREEN 顺序），Rules 保证**行为**（Agent 真的先写测试、不跳步） |
| **行为纪律 Rules vs OmO Hooks** | Hooks 是**技术拦截**（工具级权限控制），Rules 是**行为塑造**（说服 + 反合理化 + 铁律） |
| **行为纪律 Rules vs delegation-guardrails** | delegation-guardrails 管**分派策略**（谁来干），行为纪律管**执行纪律**（怎么干、干到什么标准） |

### 3.2 不能搭的地方

**Harness Init 不适合用 OpenSpec Schema 来做**。因为 Harness Init 是"一次性入场动作"而非"反复做的功能开发流程"。OpenSpec 的 propose→apply→archive 循环适合迭代性的功能开发，硬套到入场流程上会让简单事情变复杂。

## 4. 数据流

### 4.1 主流程（新功能开发）

```
Harness Init (一次性入场)
    ↓ 产出: AGENTS.md + docs/ + 质量闸门
    ↓
OpenSpec propose (每个功能)
    ↓ 产出: proposal → specs → design → tests → tasks
    ↓
TDD RED (tests.md → 测试代码，确认红灯)    ← tdd-iron-law Rule: 不许跳步
    ↓ 产出: 失败的测试
    ↓
OmO apply (Atlas 读 tasks.md，分派 Agent)
    ↓ 产出: 实现代码 → GREEN → 两阶段审查 → REFACTOR
    │        ↑ two-stage-review Rule: 合规审查 + 质量审查
    │        ↑ evidence-before-completion Rule: 声称完成必须有证据
    ↓
OpenSpec verify (需求覆盖验证)
    ↓ 产出: 三维验证结果（完整性/正确性/一致性）
    ↓
OpenSpec archive (Delta Spec → 主 Spec)
    ↓ 产出: 更新后的主 Spec（复合学习）
```

### 4.2 并行维护流

```
timely-doc-garden (定时)    ←→    OpenSpec archive (功能完成时)
    预防性（防止过期）                  积累性（新知识合入）
    维护基础设施知识                    维护业务功能知识
```

两者并行运行，互不干扰，都在做"复合学习"。

## 5. Agent 切换策略

不同阶段使用不同权限，防止"规划着规划着就开始写代码"的 AI 通病：

| 阶段 | Agent | 权限 | 原因 |
|------|-------|------|------|
| **入场**（Harness Init） | Sisyphus + Prometheus | 全权限 | 需要扫描项目、写 AGENTS.md、配检查 |
| **规划**（propose） | Sisyphus（限制只写 spec） | 读代码，只写 spec 文件 | 靠自律 + 规范约束，规划阶段不写实现代码 |
| **执行**（apply） | Sisyphus | 全权限 | 需要写代码、跑测试、改文件 |
| **验证**（verify） | Sisyphus | 读权限为主 | 偏审查性质 |
| **归档**（archive） | Sisyphus | 需要移动文件 | 涉及文件系统操作 |

## 6. Skill ≠ 执行策略（关键设计决策）

### 问题

`opsx-apply` 等 skill 的指令是"逐个 task 执行"——Sisyphus 加载 skill 后会严格遵守这个顺序，放弃了自己的多 agent 分派能力。结果：一个拥有 8 种 subagent 的编排器变成了单线程打字员。

### 根因

Skill 被当作**执行策略覆盖**（execution strategy override），而不是**领域知识注入**（domain knowledge injection）。Sisyphus 把 skill 里的顺序步骤当成必须遵守的执行计划。

### 解决方案

通过全局 user-level rule `~/.sisyphus/rules/delegation-guardrails.md` 注入两条规则（OMO 的 Rules Injector 机制，`alwaysApply: true`，每个 session 自动加载，无需手动 `load_skills`）：

1. **Skill Hierarchy Rule**: Skill 提供领域知识（文件路径、格式、命令），不覆盖编排行为（谁来做、做几个、什么顺序）
2. **Post-Skill-Load Orchestration Gate**: 加载任何多步骤 skill 后，必须重新做依赖分析 + 分派判断

优先级：**Sisyphus 编排规则** > **Skill 领域知识** > **Skill 执行建议（仅默认值）**

```
Skill says: "For each pending task: make code changes, continue to next"
  ↓
Sisyphus 判断: 5 个独立 tasks → 并行分派 5 个 deep agent
  ↓
每个 agent 收到: Skill 的领域知识（文件路径、格式）+ 具体任务描述
```

### 为什么不修改 skill 本身

- Skill 是通用的，可能在单 agent 场景下使用
- 分派是编排器的核心能力，不应该被任何 skill 覆盖
- **为什么用 rule 而不是 skill**: Skill 需要主动 `load_skills=["xxx"]` 才生效，不会自动注入。而 OMO 的 Rules Injector (`~/.sisyphus/rules/`) 带 `alwaysApply: true` 会自动注入每个 session，零配置生效。

## 7. 结论

五个工具、四个维度 + 一个横切层。四个工具有明确的边界，行为纪律 Rules 横切贯穿 TDD 和 OmO 执行全过程。数据流自上而下（需求 → 测试 → 代码 → 验证），知识积累自下而上（archive → 主 Spec → 未来 proposal 受益）。行为纪律保证这条链路上每一步都不偷懒。

系统成立的原因：关注点分离由工具边界强制执行，行为纪律由 Rules 自动注入。AI Agent 不需要"记住"所有规则——规则变成了自动化检查，Agent 根据报错改到通过为止。
