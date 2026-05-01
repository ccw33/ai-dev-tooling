# 四工具集成可行性分析

> 读者：技术负责人、架构师、新加入的团队成员
> 目的：回答"这四个工具为什么能搭在一起、边界在哪、数据怎么流转"
> 来源：[omo-openspec-tdd.md](../omo-openspec-tdd.md) §2.2 + §2.3 + §4.2 + §七

## 1. 四工具定位

| 工具 | 一句话定位 | 核心问题 | 触发时机 |
|------|-----------|---------|---------|
| Harness Init | 地基工程师 | 项目长什么样？ | 存量项目首次接入 |
| OpenSpec | 产品经理 + QA | 做什么？怎么验证？ | 每个新功能 |
| OmO | 技术总监 + 开发团队 | 谁来做？怎么编排？ | 每个新功能 |
| TDD | 质量闸门 | 代码对不对？ | 贯穿全过程 |

## 2. 为什么能搭在一起

核心论点：四个工具各回答一个不同的问题，正交互补，不重叠。

每个工具的数据产物恰好是下一个工具的输入：

| 工具 | 输入 | 输出 | 下游消费者 |
|------|------|------|-----------|
| Harness Init | 存量项目源码 | AGENTS.md + docs/ + 质量闸门 | OpenSpec（项目上下文）、OmO（Agent 约束） |
| OpenSpec | 功能需求 | proposal → specs → design → tests → tasks | TDD（测试蓝图）、OmO（执行清单） |
| TDD | tests.md 中的测试蓝图 | RED（失败的测试） → GREEN（通过的实现） → REFACTOR | OmO（验证闸门） |
| OmO | tasks.md + AGENTS.md | 执行计划 → 代码变更 → 验证结果 | OpenSpec（verify）、Harness（文档更新触发） |

**关键互补关系**：

- Harness Init 盘的是**存量项目现状**（构建命令、架构约束、安全红线），OpenSpec specs 是**功能需求**，维度完全不同
- Harness Init 设的是**存量项目的基线检查**（已有代码不能退步），TDD 闸门是**新功能的开发纪律**（RED→GREEN→REFACTOR），一个守存量一个管增量
- OpenSpec 定义**需求规格**，Prometheus 定义**执行分派**，输入输出互补
- OmO 验代码质量（类型/编译/测试通过），OpenSpec 验需求覆盖（Scenario 覆盖率），验证轴正交

## 3. 边界划分

### 3.1 潜在重叠点分析

| 潜在重叠点 | 为什么不冲突 |
|-----------|-------------|
| Harness Init 盘点 vs OpenSpec specs/ | Harness Init 盘的是**存量项目现状**（构建命令、架构约束、安全红线），OpenSpec specs 是**功能需求**，维度完全不同 |
| Harness Init 设卡 vs TDD 闸门 | Harness Init 设的是**存量项目的基线检查**（已有代码不能退步），TDD 闸门是**新功能的开发纪律**（RED→GREEN→REFACTOR），一个守存量一个管增量 |
| 规划阶段（OpenSpec propose vs OmO Prometheus） | OpenSpec 定义**需求规格**，Prometheus 定义**执行分派**，输入输出互补 |
| 验证阶段（OpenSpec verify vs OmO 验证） | OmO 验代码质量（类型/编译/测试通过），OpenSpec 验需求覆盖（Scenario 覆盖率） |
| 任务管理（tasks.md vs .sisyphus/plans/） | tasks.md 是线性的需求分解，Atlas 在其基础上做依赖分析和并行分组 |
| Agent 权限（规划阶段 vs 执行阶段） | 阶段分离：规划阶段由 Sisyphus 限制为只读代码 + 只写 spec 文件，执行阶段全权限 |

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
TDD RED (tests.md → 测试代码，确认红灯)
    ↓ 产出: 失败的测试
    ↓
OmO apply (Atlas 读 tasks.md，分派 Agent)
    ↓ 产出: 实现代码 → GREEN → REFACTOR
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

## 6. 结论

四个工具、四个问题、四层架构。每个工具有明确的边界，数据流自上而下（需求 → 测试 → 代码 → 验证），知识积累自下而上（archive → 主 Spec → 未来 proposal 受益）。

系统成立的原因：关注点分离由工具边界强制执行，而非依赖约定。AI Agent 不需要"记住"所有规则——规则变成了自动化检查，Agent 根据报错改到通过为止。
