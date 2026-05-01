# OmO + OpenSpec + TDD + Harness Init：四层 AI 编程体系

> 最后更新：2026-05-01
> 适用环境：macOS + OpenCode + Oh-My-OpenAgent
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

**第零层（Harness Init）解决前三层都管不了的问题**：AI Agent 在存量项目里反复失败——看到已有代码就提前交卷、环境跑不通但不自知、每次新对话重新摸索项目。Harness Init 做一次，前三层才能跑起来。

它们的协作关系：

```
                    ┌─── Harness Init（一次性入场）───┐
                    │ 盘点 → 分层 → 设卡 → 维护        │
                    │ ↓ 产出: AGENTS.md + docs/ + 闸门  │
                    └──────────────┬───────────────────┘
                                   │
                                   ▼
OpenSpec 定义需求 ─────→ TDD 把需求变成测试 ─────→ OmO 编排 Agent 写代码通过测试
       ↑                        │                            │
       │                        │                            │
       └── archive 合并学习 ←─── verify 验证覆盖 ←─── apply 实现并验证
```

**核心理念**：Harness Init 建地基，OpenSpec 的 Scenario（GIVEN/WHEN/THEN）就是测试用例的草稿，TDD 把草稿变成可执行的红灯，OmO 带团队把红灯变绿灯。

---

## 二、系统架构

### 2.1 四层分工

```
┌─────────────────────────────────────────────────────────────────┐
│  第零层：Harness Init — 存量项目入场（"项目长什么样"）            │
│                                                                  │
│  一次性动作，做一次，后续维护。                                    │
│                                                                  │
│  盘点（项目知识文档化）                                           │
│    → AGENTS.md（根，≤100 行：构建命令、架构红线、安全红线、索引） │
│    → 子目录 AGENTS.md（只写与根文件的差异）                       │
│  分层（根文件 vs docs/）                                          │
│    → docs/architecture.md, development-guide.md, api-contracts.md│
│    → docs/adr/（架构决策记录，每份 ≤40 行）                      │
│  设卡（规则 → 自动化检查）                                        │
│    → 架构分层检查、Linter、类型检查、覆盖率阈值                    │
│    → CI + pre-commit hooks                                       │
│  维护（文档 gardening）                                           │
│    → 每周 doc-gardening · 每两周规则回顾 · 每月根文件瘦身         │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│  第一层：OpenSpec — 规范驱动（"做什么"）                         │
│                                                                  │
│  openspec/                                                       │
│  ├── specs/            ← 系统当前行为的真实来源                   │
│  ├── changes/                                                   │
│  │   └── <feature>/                                             │
│  │       ├── proposal.md   ← 为什么做、范围                      │
│  │       ├── specs/        ← Delta Specs (ADDED/MODIFIED/REMOVED)│
│  │       ├── design.md     ← 技术方案 + Test Strategy            │
│  │       ├── tests.md      ← Scenario → 测试代码映射（RED）       │
│  │       └── tasks.md      ← Verify RED → 实现 → REFACTOR       │
│  └── config.yaml         ← schema: tdd-driven                   │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│  第二层：OmO — Agent 编排（"谁来做"）                             │
│                                                                  │
│  .sisyphus/                                                      │
│  ├── plans/             ← 从 tasks.md 生成的执行计划              │
│  ├── notepads/          ← Agent 间的学习积累                      │
│  └── drafts/            ← Prometheus 面谈草稿                    │
│                                                                  │
│  Sisyphus (编排) → Prometheus (规划) → Atlas (执行)               │
│       ↕                ↕                  ↕                      │
│  Oracle (架构)     Metis (查漏)      Momus (审核)                 │
│       ↕                ↕                  ↕                      │
│  Explore (搜索)   Librarian (文档)  Sisyphus-Junior (干活)        │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│  第三层：TDD — 质量闸门（"怎么验证"）                             │
│                                                                  │
│  自定义 Schema: tdd-driven                                       │
│  流程: RED (测试失败) → GREEN (最少代码通过) → REFACTOR (清理)    │
│  闸门: tasks.md 首组必须先 Verify RED，末组必须 REFACTOR          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Harness Init 与前三层的关系

| Harness 四步 | 对应的架构层 | 产出 | 执行工具 |
|---|---|---|---|
| **盘点 + 分层** | OmO 的 `AGENTS.md` 系统 | 根文件 ≤100 行 + `docs/` + 子目录 `AGENTS.md` | `/harness-scan` |
| **设卡**（自动化检查） | TDD 的质量闸门 + CI | lint / type-check / test gates | `/harness-gate` |
| **维护**（文档 gardening） | `harness-doc-garden` 安装 + `timely-doc-garden` 运行 | 定期 doc-gardening + 规则回顾 | `/harness-doc-garden`（安装）+ `timely-doc-garden`（运行） |

### 2.3 不冲突的原因

| 潜在重叠点 | 为什么不冲突 |
|-----------|-------------|
| **Harness Init 盘点 vs OpenSpec specs/** | Harness Init 盘的是**存量项目现状**（构建命令、架构约束、安全红线），OpenSpec specs 是**功能需求**，维度完全不同 |
| **Harness Init 设卡 vs TDD 闸门** | Harness Init 设的是**存量项目的基线检查**（已有代码不能退步），TDD 闸门是**新功能的开发纪律**（RED→GREEN→REFACTOR），一个守存量一个管增量 |
| 规划阶段（OpenSpec propose vs OmO Prometheus） | OpenSpec 定义 **需求规格**，Prometheus 定义 **执行分派**，输入输出互补 |
| 验证阶段（OpenSpec verify vs OmO 验证） | OmO 验代码质量（类型/编译/测试通过），OpenSpec 验需求覆盖（Scenario 覆盖率） |
| 任务管理（tasks.md vs .sisyphus/plans/） | tasks.md 是线性的需求分解，Atlas 在其基础上做依赖分析和并行分组 |
| Agent 权限（规划阶段 vs 执行阶段） | 阶段分离：规划阶段由 Sisyphus 限制为只读代码 + 只写 spec 文件，执行阶段全权限 |

---

## 三、环境配置

### 3.1 安装清单

```bash
# 1. OpenCode（OmO 的运行基础）
# 已安装，跳过

# 2. OmO（Agent 编排框架）
bunx oh-my-opencode doctor   # 检查是否已安装

# 3. OpenSpec（SDD 框架）
npm install -g @fission-ai/openspec@latest
openspec --version            # 确认 1.3.1+

# 4. TDD Schema（自定义）
# 见 3.2 节
```

### 3.2 TDD Schema 配置

参考 [openspec-tdd-setup.md](./openspec-tdd-setup.md)，关键文件：

```
~/.local/share/openspec/schemas/tdd-driven/
├── schema.yaml              # DAG 定义：proposal → specs → design → tests → tasks → apply
└── templates/
    ├── proposal.md           # 含 Test Strategy
    ├── spec.md               # 强制 GIVEN/WHEN/THEN
    ├── design.md             # 含 Test Strategy 章节
    ├── tests.md              # Scenario → 测试代码映射
    └── tasks.md              # 首组 Verify RED，末组 REFACTOR
```

补丁脚本 `~/.local/bin/openspec-tdd`（别名 `oinit`）：
- 在 `openspec init` 后运行
- 覆写 `config.yaml` 为 `schema: tdd-driven`
- 运行 `openspec update` 重新生成 AI skills

### 3.3 OmO 配置适配

确保 `opencode.json`（或 `.opencode/opencode.json`）中包含 OmO 配置即可。

---

## 四、第零层：Harness Init — 存量项目入场

> 核心问题：AI Agent 在存量项目中反复失败——看到已有代码就提前交卷、环境跑不通但不自知、单测过了端到端不通、每次新对话重新摸索项目。
>
> 一句话解法：别指望 Agent 记住规则——把规则变成自动化检查，Agent 根据报错改到通过为止。

### 4.1 四步法概览

```
盘点 → 分层 → 设卡 → 维护
 │       │       │       │
 │       │       │       └→ 持续：doc-gardening + 规则回顾
 │       │       └── 关键一步：规则 → 自动化检查
 │       └── 根文件 ≤100 行，详细内容下沉 docs/
 └── 盘五件事：构建命令 / 架构约束 / 编码规范 / 安全红线 / 隐性知识
```

每步做完向用户汇报，确认后再进下一步。

### 4.2 执行工具选择

| 四步 | 推荐工具 | 原因 |
|------|---------|------|
| **盘点 + 分层** | `/harness-scan` Skill | init-deep 主扫描 + AI 补充扫描 + 人工确认问卷，一步到位 |
| **设卡** | `/harness-gate` Skill | 盘点已有检查 → 识别缺口 → freeze-ratchet 策略 → 安装配置 |
| **维护** | `/harness-doc-garden` 安装 + `timely-doc-garden` 运行 | 实时校验 + Git 保底 + 定时全量扫描（详见 4.5 节） |

**为什么不用 OpenSpec 自定义 Schema 来做 Harness Init？** 因为 Harness Init 是"一次性入场动作"而非"反复做的功能开发流程"。OpenSpec 的 propose→apply→archive 循环适合迭代性的功能开发，硬套到入场流程上会让简单事情变复杂。

### 4.3 Day 1：盘点 + 分层（`/harness-scan`）

```
/harness-scan
```

四阶段自动执行：

| 阶段 | 内容 | 自动化程度 |
|------|------|-----------|
| **Phase 1: Init-Deep 扫描** | 项目结构 + 目录评分 + hierarchical AGENTS.md + docs/ | 🟢 全自动 |
| **Phase 2: AI 补充扫描** | 凭证扫描、隐性知识挖掘（git log/TODO/HACK）、多仓库漂移检测 | 🟢 全自动 |
| **Phase 3: 人工确认问卷** | 安全发现确认、AI 推断规则审核、口头知识补充、secret 管理策略选择 | 🟡 AI 生成问卷，人工做判断题 |
| **Phase 4: 最终确定** | 应用问卷答案到 AGENTS.md，验证引用完整性 | 🟢 全自动 |

**Phase 1 细节**（init-deep 核心能力）：
1. 扫描项目结构（构建文件、CI 配置、源码目录树）
2. 对每个目录**评分**（8 维矩阵：文件数×3、子目录数×2、代码比例×2、符号密度×2、导出数×2、引用中心度×3、模块边界×2、独特约定×1），分数 >15 的目录才生成独立 AGENTS.md，<8 分的由父文件覆盖
3. 根据项目规模**动态调整**探索深度（每 100 文件 +1 agent、每 1 万行 +1 agent、monorepo 每个 package +1 agent）
4. 利用 LSP（Document Symbols、Workspace Symbols、Find References）生成 CODE MAP 和引用中心度分析
5. 生成 hierarchical AGENTS.md（根 50-150 行，子目录 30-80 行，子目录永不重复父目录内容）

**Phase 2 细节**（AI 补充扫描，覆盖 init-deep 做不到的 15%）：

| 维度 | init-deep 自动盘 | AI 补充扫描 | 需要人工确认 |
|------|-----------------|------------|-------------|
| 构建命令 | ✅ 从 `package.json` / `Makefile` / `Cargo.toml` 提取 | — | 环境变量、特殊部署流程 |
| 架构约束 | ✅ 从目录结构 + LSP 引用关系推断 | — | 跨层依赖禁令、代码生成规则 |
| 编码规范 | ✅ 从 linter config + 代码模式提取 | — | 团队口头约定 |
| 安全红线 | ⚠️ 只查文件名和位置 | ✅ gitleaks 模式扫硬编码凭证 | 凭证管理策略（选哪个方案） |
| 隐性知识 | ❌ 无法自动发现 | 🟡 挖 git log / PR comments / TODO/HACK/FIXME 推断隐性规则 | 纯口头约定（无数字痕迹的知识） |
| 多仓库漂移 | ❌ 单项目扫描 | ✅ 多仓库 AGENTS.md + config diff 自动检测 | 差异是否为预期 |

**Phase 3：人工确认问卷**（AI 自动生成，人工只做判断题）：

- **安全确认**：确认 AI 发现的凭证位置是否完整？有无遗漏？
- **推断确认**：AI 从代码推断的隐性规则是否正确？标注 [✓ 正确] / [✗ 不是] / [? 不确定]
- **口头补充**：有无 AI 未发现的口头约定？请口述，AI 记录
- **漂移确认**：多仓库差异中哪些是预期的，哪些需要修复？
- **策略决策**：secret 管理策略选哪个方案？

**Phase 4 自动应用**：问卷答案自动写入 AGENTS.md，无需手动编辑。

**产出**：

```
project/
├── AGENTS.md                ← 根文件（≤100 行）
│   包含：构建命令、架构红线、安全红线、docs/ 索引表
│
├── src/
│   ├── AGENTS.md            ← src 层：与根文件的差异
│   └── components/
│       └── AGENTS.md        ← 组件层：组件特定约定
│
└── docs/                    ← 按需查阅层
    ├── architecture.md      ← 分层结构（ASCII 目录树）、基础设施集成
    ├── development-guide.md ← 环境搭建、本地开发、测试、部署
    ├── api-contracts.md     ← API 规范索引
    └── adr/                 ← 架构决策记录（每份 ≤40 行，必须有源码引用）
        ├── 001-use-vitest.md
        └── 002-monorepo-structure.md
```

**质量要求**：
- 每个事实性声明必须有 `文件名:行号` 锚点指向实际源码
- 不确定的信息标注 `[TODO: confirm with team]`，不猜
- 根文件 ≤100 行 / <32KB（太大会被截断或浪费 Token）
- 子目录 AGENTS.md 只写与根文件的差异，不重复

**多仓库额外动作**：对比各仓库的扫描结果，把不一致的地方（框架版本、包前缀、lint 配置等）明确标出来作为漂移警告。Agent 最致命的错误就是把 A 仓库的约定照搬到 B 仓库。

### 4.4 Day 2-3：设卡（`/harness-gate`）

```
/harness-gate
```

五阶段自动执行：

| 阶段 | 内容 | 自动化程度 |
|------|------|-----------|
| **Phase 1: 盘点已有检查** | 扫描 CI/lint/test/hooks/type-check 配置 | 🟢 全自动（5 个并行 explore agents） |
| **Phase 2: 识别缺口** | 架构分层分析 + 高频违规检测 | 🟢 全自动 |
| **Phase 3: 设计 + 用户确认** | 展示缺口清单 + 推荐方案 + 用户选择要装哪些 | 🟡 AI 提案，人工确认 |
| **Phase 4: 实施** | 安装配置（pre-commit hooks / coverage threshold / architecture check / strict mode） | 🟢 全自动（freeze-ratchet 策略） |
| **Phase 5: 更新 AGENTS.md** | 写入质量门禁节 | 🟢 全自动 |

**设卡五步走**：

1. **盘点已有检查** — 不重复建设
2. **识别高频违规** — 从 Code Review 反复出现的评论中提取
3. **新增自动化检查**（按低摩擦优先）：
   - 架构分层检查（禁止跨层依赖）
   - 代码风格 / Linter
   - 类型检查（渐进式启用）
   - 覆盖率阈值（设略低于当前实际值）
4. **挂到 CI** — 每 PR / merge 跑检查
5. **挂到本地** — pre-commit hook + AI 工具本地配置

**棕地项目棘轮策略**（核心）：

存量项目不能一步到位。正确做法是**冻结-棘轮**：
1. 首次运行，记录（冻结）存量违规
2. 只有**新增**违规才阻断构建
3. 随着团队修复存量问题，基线自动收紧

绝不直接开严格模式——几百个存量错误会炸掉构建，团队会放弃整个方案。

**更新 AGENTS.md**：在根文件中加一节"质量门禁"，写明检查命令。Agent 每次改代码后跑这组命令，不过就不提交。

### 4.5 持续：维护（harness-doc-garden 安装 + timely-doc-garden 运行）

让文档活着。过期的记忆比没有记忆更危险——Agent 读到错误的文档，产出的就是幻觉。

**自动化方案**：`harness-doc-garden`（一次性安装）+ `timely-doc-garden`（定时运行）— 安装三层 Hook，定时扫描所有注册项目，自动检测并修复文档过时问题。

#### 安装

Skill 位置：`/Users/chenchaowen/Desktop/Project/dev-tooling/.agents/.skills/timely-doc-garden/`

该 skill 位于项目本地 `.agents/.skills/` 目录下，`opencode` 会自动发现项目级 skill，无需额外配置。

**安装方式**：使用 `harness-doc-garden` skill 一键安装三层 Hook：

```
opencode run --command harness-doc-garden
```

或手动安装（见下方"三层 Hook 体系"章节）。

#### 注册项目

编辑 `projects.yaml`，添加需要定时扫描的项目：

```yaml
projects:
  - path: /Users/chenchaowen/Desktop/Project/quant-invest2
    schedule: weekly
    notify: wechat
    enabled: true

  - path: /Users/chenchaowen/Desktop/Project/my-api
    schedule: weekly
    enabled: true
```

#### 定时执行

**方式 A：cron（简单）**：
```bash
# 每周一 9:00 执行
crontab -e
# 添加：
0 9 * * 1 /bin/bash /Users/chenchaowen/Desktop/Project/dev-tooling/.agents/.skills/timely-doc-garden/scripts/run-scheduled.sh >> /tmp/doc-garden-cron.log 2>&1
```

**方式 B：launchd（推荐，macOS 原生）**：
```bash
# 创建 plist（参考 run-scheduled.sh 内的 launchd 示例）
launchctl load ~/Library/LaunchAgents/com.opencode.timely-doc-garden.plist
```

**方式 C：手动触发**：
```bash
# 扫描所有注册项目
bash /Users/chenchaowen/Desktop/Project/dev-tooling/.agents/.skills/timely-doc-garden/scripts/run-scheduled.sh

# 扫描单个项目
bash /Users/chenchaowen/Desktop/Project/dev-tooling/.agents/.skills/timely-doc-garden/scripts/run-scheduled.sh --project /path/to/project

# 在项目内直接调用 opencode
opencode run --command timely-doc-garden "Run timely-doc-garden check"
```

#### 三级修复策略

| 级别 | 执行者 | 修复内容 | 人工介入 |
|------|--------|---------|---------|
| **L1 脚本修复** | `scan.py` + `fix_refs.py` | 行号偏移、路径重命名 | 无 |
| **L2 AI 修复** | Agent 直接 Edit .md | 语义过时（库换了、命令变了、模块增删） | 无 |
| **L3 仅报告** | 标记 `[REVIEW: reason]` | 需要团队决策的（架构规则是否仍适用） | 需要 |

**目标：L3 尽量为零。** 绝大多数过时都是事实性的（代码改了文档没跟上），AI 直接修。

#### 执行流程

```
定时触发（cron/launchd）
    ↓
run-scheduled.sh → 读取 projects.yaml → 逐项目执行
    ↓
opencode run --command timely-doc-garden
    ↓
Phase 1: scan.py（确定性扫描，< 5 秒）
  → 提取所有文件:行号引用，验证存在性和行内容
  → 输出 scan-result.json
    ↓
Phase 2: AI 深度扫描 + 即时修复（2-5 分钟）
  → 架构描述 vs 实际目录 → 自动更新
  → 构建命令 vs 实际 scripts → 自动更新
  → 架构约束 vs 实际 import → 自动更新
  → ADR 决策 vs 实现 → 自动更新引用
  → 技术栈 vs 依赖文件 → 自动更新
  → 不确定的 → 标记 [REVIEW]
    ↓
Phase 3: fix_refs.py（L1 自动修复，< 5 秒）
  → 修复路径重命名
  → 修复行号偏移（精确/子串匹配）
  → 无法确定的退回 Phase 2 AI 处理
    ↓
Phase 4: 报告
  → 保存到 .sisyphus/doc-garden-report.md
  → 有 REVIEW 项？→ 推送微信通知
  → 无 REVIEW 项？→ 静默完成，不打扰
```

#### 与 OpenSpec archive 的协同

| 维护维度 | timely-doc-garden（自动化） | OpenSpec archive（功能开发时） |
|---------|---------------------|-------------------------------|
| 项目基础设施知识 | ✅ 构建、架构、安全、技术栈 | ❌ |
| 业务功能知识 | ❌ | ✅ 需求、设计、测试场景 |
| 触发方式 | 定时（每周） | 功能完成归档时 |
| 性质 | 预防性（防止知识过期） | 积累性（新知识合入） |

两者并行运行，互不干扰，都在做"复合学习"。

#### 实时 Hook 体系：三层叠加确保文档最新

定时扫描是兜底，但 Agent 编辑代码后文档引用可能立即断裂——等到下周才发现已经太晚。三层 Hook 在不同时机拦截：

```
┌─────────────────────────────────────────────────────────────────┐
│ 第一层：OpenCode Hook（实时，Agent 编辑时触发）                     │
│                                                                  │
│   experimental.hook.file_edited  →  文件编辑后校验引用              │
│   experimental.hook.session_completed  →  Session 结束后轻量扫描   │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│ 第二层：Git Hook（离线保底，人工编辑时触发）                         │
│                                                                  │
│   pre-commit: validate-refs.sh  →  校验引用存在性，阻断提交          │
│   pre-push: check-doc-staleness.sh  →  检查过期，警告不阻断        │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│ 第三层：定时扫描（已有，兜底）                                      │
│                                                                  │
│   每周 timely-doc-garden cron  →  全量扫描 + AI 修复                  │
│   前两层拦截绝大部分过期，这一层兜底                                 │
└─────────────────────────────────────────────────────────────────┘
```

##### 第一层：OpenCode 原生 Hook

OpenCode 的 `experimental.hook` 配置（写在 `opencode.json` 中）可以在文件编辑和 Session 结束时自动运行 shell 命令，**零代码，配置即用**。

**配置方式**：

```jsonc
// opencode.json
{
  "experimental": {
    "hook": {
      // 文件编辑后触发 — key 匹配工具名（Write|Edit|MultiEdit）
      "file_edited": {
        "Write|Edit|MultiEdit": [
          {
            "command": [
              "bash",
              "/Users/chenchaowen/Desktop/Project/dev-tooling/.agents/.skills/timely-doc-garden/scripts/validate-refs.sh"
            ],
            "environment": { "TRIGGER": "file_edited" }
          }
        ]
      },
      // Session 结束后触发 — 轻量 timely-doc-garden 扫描
      "session_completed": [
        {
          "command": [
            "bash",
            "/Users/chenchaowen/Desktop/Project/dev-tooling/.agents/.skills/timely-doc-garden/scripts/run-scheduled.sh",
            "--project", "."
          ],
          "environment": { "TRIGGER": "session_completed" }
        }
      ]
    }
  }
}
```

| Hook 点 | 触发时机 | 用途 |
|---------|---------|------|
| `file_edited` | Agent 每次 Write/Edit/MultiEdit 后 | 校验被改文件的文档引用是否断裂 |
| `session_completed` | 整个对话结束时 | 全量 timely-doc-garden 扫描（只检查本次变更涉及的文档） |

**进阶：Plugin 级 Hook**（需要写插件代码）：

`@opencode-ai/plugin` 的 `Hooks` 接口提供 17 个 hook 点，文档新鲜度最相关的：

| Hook | 触发时机 | 能做什么 |
|------|---------|---------|
| `tool.execute.after` | 每次工具执行后 | 检测 `tool === "write"\|"edit"` → 检查 `args.file_path` → 在 output 中追加文档校验警告 |
| `event` | 任何系统事件 | 监听 `file.edited`、`session.idle`、`session.diff` |
| `tool` | 自定义工具注册 | 注册 `validate.docs` 工具，让 Agent 随时手动调用 |

OmO 内置了 **Claude Code 兼容层**，将 Claude Code 的 hook 映射到 OpenCode Plugin 事件：

| Claude Code Hook | → OpenCode Plugin | 说明 |
|---|---|---|
| `PostToolUse` | `tool.execute.after` | 工具执行后 |
| `PreToolUse` | `tool.execute.before` | 工具执行前（可阻断） |
| `Stop` | `event` (session.idle) | Agent 停止时 |

> **实施优先级**：先启用 `experimental.hook`（配置即用），需要更精细控制时再写 Plugin。

##### 第二层：Git Hook（离线保底）

OpenCode 不在运行时（人工编辑、CI 合并），由 git hooks 保底。

**pre-commit：校验 AGENTS.md 引用存在性**

复用 `validate-refs.sh`（已存在于 `.agents/.skills/timely-doc-garden/scripts/`）：

```bash
#!/bin/bash
# 在项目根目录的 pre-commit hook 中调用
bash .agents/.skills/timely-doc-garden/scripts/validate-refs.sh
```

**pre-push：检查文档过期**

脚本位置：`scripts/hooks/check-doc-staleness.sh`（需在项目中创建）

```bash
#!/bin/bash
# 对比代码 commit 时间 vs 文档修改时间，超过阈值 + N 次 commit 则警告
# pre-push 触发，只警告不阻断
set -euo pipefail

DOCS=("AGENTS.md" "CLAUDE.md")
WATCH_DIRS=("src/" "lib/")
THRESHOLD_DAYS=30
MIN_COMMITS=5

for doc in "${DOCS[@]}"; do
  [ -f "$doc" ] || continue

  doc_date=$(git log -1 --format="%ct" -- "$doc" 2>/dev/null || echo 0)
  code_date=$(git log -1 --format="%ct" -- "${WATCH_DIRS[@]}" 2>/dev/null || echo 0)

  if [ "$code_date" -gt "$doc_date" ]; then
    days_stale=$(( (code_date - doc_date) / 86400 ))
    commits_since=$(git log --format="%H" -- "${WATCH_DIRS[@]}" \
        --since="@${doc_date}" 2>/dev/null | wc -l | tr -d ' ')

    if [ "$days_stale" -gt "$THRESHOLD_DAYS" ] && [ "$commits_since" -gt "$MIN_COMMITS" ]; then
      echo "⚠️  $doc 可能已过期（$days_stale 天未更新，$commits_since 次代码提交）"
    fi
  fi
done

exit 0  # 只警告，不阻断
```

**安装 hook**（两种方式任选）：

```bash
# 方式 A：Husky（如果项目已有）
npx husky add .husky/pre-commit "bash .agents/.skills/timely-doc-garden/scripts/validate-refs.sh"
npx husky add .husky/pre-push "bash .agents/.skills/timely-doc-garden/scripts/check-doc-staleness.sh"

# 方式 B：直接写 .githooks（无依赖）
mkdir -p .githooks
echo '#!/bin/bash' > .githooks/pre-commit
echo 'bash .agents/.skills/timely-doc-garden/scripts/validate-refs.sh' >> .githooks/pre-commit
echo '#!/bin/bash' > .githooks/pre-push
echo 'bash .agents/.skills/timely-doc-garden/scripts/check-doc-staleness.sh' >> .githooks/pre-push
chmod +x .githooks/pre-commit .githooks/pre-push
git config core.hooksPath .githooks
```

##### 现成工具参考

| 工具 | 策略 | AI-Agent 感知 | AGENTS.md 支持 |
|------|------|--------------|----------------|
| **[cortex-tms](https://github.com/cortex-tms/cortex-tms)** | 时间戳 + commit 计数 | ✅ 专为 AI Agent 设计 | ✅ CLAUDE.md / PATTERNS.md |
| **[Wegent AI push gate](https://github.com/wecode-ai/Wegent)** | 代码变更 → 文件映射 + `AI_VERIFIED` 闸门 | ✅ | ✅ 显式检查 AGENTS.md |
| **[docrot](https://github.com/andimrob/docrot)** | `code_changes` 策略：watch 源文件变动 | ❌ | ✅ 作为被监控文档 |

需要更完整的方案时可以直接集成这些工具，上述脚本适用于快速启动。

#### 维护日历

| 频率 | 动作 | 执行方式 |
|------|------|---------|
| **实时** | 文件编辑后校验引用 | OpenCode `experimental.hook.file_edited` |
| **每次 Session 结束** | 轻量 timely-doc-garden 扫描 | OpenCode `experimental.hook.session_completed` |
| **每次提交** | AGENTS.md 引用存在性校验 | git pre-commit → `validate-refs.sh` |
| **每次推送** | 文档过期检测 | git pre-push → `check-doc-staleness.sh`（只警告） |
| 每周 | timely-doc-garden 全量扫描 + 修复 | cron/launchd → `run-scheduled.sh` |
| 每两周 | 规则回顾（棘轮收紧） | 人工：看 timely-doc-garden 报告中的违规趋势 |
| 每月 | 根文件瘦身（AGENTS.md ≤100 行） | 人工：参考报告中的大小提示 |

### 4.6 Harness Init 常见误区

| 误区 | 正确做法 |
|------|---------|
| 5000 行的根配置文件 | ≤100 行索引，详细内容放 docs/ |
| 只写文档不设自动检查 | 关键规则必须变成可执行 lint / test |
| Agent 自己验证自己的产出 | 生成与评估必须分离（Agent 写 → Linter 验） |
| 一次性写好不维护 | 文档是活的，需要持续 gardening |
| 棕地项目直接全量 strict | 冻结-棘轮法：先宽松启动，逐步收紧 |
| 子仓库复制根文件内容 | 只写差异 |
| 文档里写凭证值 | 只写 `文件名:行号` + 字段名 |

---

## 五、完整工作流：新功能开发

以给电商系统添加"两步验证（2FA）"为例。

> **前提**：已完成 Harness Init（第零层），项目已有 `AGENTS.md` + `docs/` + 质量闸门。如果是全新项目，先跑一遍 `/harness-scan` → `/harness-gate` → `/harness-doc-garden`，然后 `oinit`。

### 5.1 Phase 1：初始化功能

```bash
# 新项目（首次接入）
/harness-scan                      # Harness Init: 盘点+分层+AI补充扫描+确认问卷
/harness-gate                      # Harness Init: 设卡
/harness-doc-garden                # Harness Init: 安装文档维护
openspec init . --tools opencode  # 初始化 OpenSpec 目录
oinit                              # 覆写 config.yaml → openspec update（重新生成 AI skills）

# 已有项目（已做过 Harness Init，直接开新功能）
openspec init . --tools opencode  # 如果还没初始化过 OpenSpec
oinit                              # 如果还没切换过 tdd-driven
```

### 5.2 Phase 2：规划（Sisyphus + OpenSpec）

在 OmO 中使用 Sisyphus Agent 进行规划，规划阶段应**只读代码、只写 spec 文件**，不写实现代码。

#### Step 1：探索

```
/opsx:explore
```

Agent 调查现有认证系统、数据库结构、TOTP 库选型。此阶段不产出文件。

#### Step 2：提案

```
/opsx:propose add-2fa
```

DAG 引擎按依赖顺序生成制品：

**proposal.md** — 为什么做：
```markdown
## Why
密码认证不足以防止账户被盗。

## What Changes
- 新增：TOTP 两步验证注册/启用/禁用
- 修改：登录流程增加验证码步骤
- 修改：用户表增加 totp_secret 字段
```

**specs/auth.md** — 做什么（Delta Spec）：
```markdown
## ADDED Requirements
### Requirement: Two-Factor Authentication
系统 SHALL 支持 TOTP 两步验证。

#### Scenario: 2FA 注册
- **GIVEN** 一个已登录用户
- **WHEN** 用户在设置页点击"启用两步验证"
- **THEN** 显示 QR 码和手动输入密钥
- **AND** 用户输入验证码确认后 2FA 生效

#### Scenario: 2FA 登录
- **GIVEN** 一个已启用 2FA 的用户
- **WHEN** 用户输入正确密码
- **THEN** 系统显示验证码输入框
- **AND** 用户输入正确验证码后登录成功

#### Scenario: 错误验证码
- **GIVEN** 一个已启用 2FA 的用户
- **WHEN** 用户输入错误验证码
- **THEN** 系统拒绝登录并提示错误
```

**design.md** — 怎么做 + 测试策略：
```markdown
## Decisions
- 使用 otplib 生成 TOTP
- secret 加密存储在 totp_secret 字段
- QR 码服务端生成

## Test Strategy
- 框架：Vitest + Supertest
- 命名：test_<scenario-name>
- 组织：与 src/ 目录镜像
- 每个 Scenario 对应一个 test case
```

**tests.md** — 测试蓝图（TDD 的 RED 阶段）：
```markdown
## auth/totp.test.ts

### test_2fa_enrollment
// GIVEN: logged-in user without 2FA
const user = await createTestUser();
// WHEN: enables 2FA in settings
const res = await request(app)
  .post('/api/auth/2fa/setup')
  .set('Authorization', `Bearer ${user.token}`);
// THEN: QR code is displayed
expect(res.status).toBe(200);
expect(res.body.qrCode).toBeDefined();

### test_2fa_login
// GIVEN: user with 2FA enabled
const user = await createTestUserWith2FA();
// WHEN: submits correct password
const loginRes = await request(app)
  .post('/api/auth/login')
  .send({ email: user.email, password: 'valid' });
// THEN: verification code input is shown
expect(loginRes.status).toBe(200);
expect(loginRes.body.requires2FA).toBe(true);

### test_invalid_verification_code
// GIVEN: user with 2FA during login
// WHEN: enters wrong code
// THEN: login rejected
```

**tasks.md** — 执行清单：
```markdown
## 1. Verify RED
- [ ] 1.1 创建测试文件 auth/totp.test.ts
- [ ] 1.2 运行测试，确认全部失败（RED）

## 2. 数据层
- [ ] 2.1 User 表添加 totp_secret 和 recovery_codes 字段
- [ ] 2.2 创建迁移脚本
- [ ] 2.3 运行测试，确认无回归

## 3. 服务层
- [ ] 3.1 安装 otplib、qrcode
- [ ] 3.2 实现 TotpService
- [ ] 3.3 运行测试，确认部分通过

## 4. API 层
- [ ] 4.1 POST /api/auth/2fa/setup
- [ ] 4.2 POST /api/auth/2fa/verify-setup
- [ ] 4.3 修改 POST /api/auth/login
- [ ] 4.4 运行测试，确认全部 GREEN

## 5. 前端
- [ ] 5.1 设置页两步验证区域
- [ ] 5.2 登录页验证码输入
- [ ] 5.3 运行测试，确认全部 GREEN

## 6. REFACTOR
- [ ] 6.1 审查代码，消除重复
- [ ] 6.2 提取公共逻辑
- [ ] 6.3 运行测试，确认仍然 GREEN
```

### 5.3 Phase 3：执行（Sisyphus Agent）

切回 Sisyphus Agent，触发 DAG apply 阶段：

```
/opsx:apply
```

OmO 读取 `openspec/changes/add-2fa/tasks.md`，Atlas 做依赖分析和并行分组：

```
Atlas 读取 tasks.md
    │
    ├── [组 1] Verify RED（串行）
    │   task(category="quick", load_skills=[],
    │     prompt="创建测试文件 auth/totp.test.ts，参考
    │            openspec/changes/add-2fa/tests.md 中的测试蓝图。
    │            运行测试确认全部失败（RED）。")
    │
    ├── [组 2] 数据层（等组 1 完成）
    │   task(category="deep", load_skills=["git-master"],
    │     prompt="参考 openspec/changes/add-2fa/design.md 的决策。
    │            2.1 添加 totp_secret 和 recovery_codes 字段
    │            2.2 创建迁移脚本
    │            完成后运行测试确认无回归。")
    │
    ├── [组 3] 服务层（等组 2 完成）
    │   task(category="deep", load_skills=[],
    │     prompt="参考 openspec/changes/add-2fa/specs/auth.md 的需求。
    │            3.1 安装 otplib、qrcode
    │            3.2 实现 TotpService
    │            完成后运行测试。")
    │
    ├── [组 4] API 层（等组 3 完成）
    │   task(category="deep", load_skills=[],
    │     prompt="参考 openspec/changes/add-2fa/specs/auth.md 的 Scenario。
    │            实现 4.1-4.4 API 端点。
    │            完成后运行测试确认 GREEN。")
    │
    ├── [组 5] 前端（等组 4 完成）
    │   task(category="visual-engineering", load_skills=["frontend-ui-ux"],
    │     prompt="参考 specs 中的 Scenario 设计登录页和设置页。
    │            5.1 设置页两步验证区域
    │            5.2 登录页验证码输入
    │            完成后运行测试确认仍然 GREEN。")
    │
    └── [组 6] REFACTOR（等组 5 完成）
        task(category="unspecified-low", load_skills=[],
          prompt="审查所有变更，消除重复，提取公共逻辑。
                 运行测试确认仍然 GREEN。")
```

**OmO 的关键附加值**：
1. **模型路由**：数据层 → `deep`（GPT-5.4），前端 → `visual-engineering`（Gemini），REFACTOR → `quick`（Mini）
2. **自动验证**：每个任务完成后自动 `lsp_diagnostics` + `build` + `test`
3. **失败恢复**：3 次失败 → revert → 咨询 Oracle
4. **并行执行**：识别无依赖的任务并行分派

### 5.4 Phase 4：双重验证

**OmO 自动验证**（每个任务完成后）：
```
lsp_diagnostics  → 类型错误检查
build            → 编译通过
test             → 测试通过
```

**OpenSpec 规范验证**（全部完成后）：
```
/opsx:verify
```

三维验证：
| 维度 | 检查内容 |
|------|---------|
| **完整性** | tasks.md 的 checkbox 全部 `[x]`，每个 Scenario 都有对应实现 |
| **正确性** | 代码行为匹配 Spec 描述，edge case 覆盖 |
| **一致性** | design.md 的决策在代码中体现，测试命名遵循 Test Strategy |

### 5.5 Phase 5：归档 & 复合学习

```
/opsx:archive
```

Delta Spec 合并到主 Spec：
```
ADDED    "Two-Factor Authentication"  → 追加到 openspec/specs/auth.md
MODIFIED "User Login"                 → 替换旧版本
```

下次做"社交账号登录"时，OpenSpec 已经知道系统有 2FA 了，新的 proposal 会自动考虑 2FA 对社交登录的影响。知识在积累，不是在堆叠。

---

## 六、TDD 的 Spec → Test 映射规则

### 6.1 映射关系

| Spec 元素 | 测试元素 |
|-----------|---------|
| `GIVEN` | Arrange（准备测试数据和环境） |
| `WHEN` | Act（调用被测函数/接口） |
| `THEN` | Assert（断言结果） |
| `AND` | 额外的 Assert 或 Arrange |
| `#### Scenario: <name>` | `test_<name_in_snake_case>` |
| `### Requirement: <name>` | `describe('<name>', () => {...})` |

### 6.2 映射示例

**Spec**：
```markdown
### Requirement: Two-Factor Authentication
#### Scenario: 2FA enrollment
- **GIVEN** a logged-in user without 2FA
- **WHEN** the user enables 2FA in settings
- **THEN** a QR code is displayed
- **AND** a TOTP secret is stored for the user
```

**Test**：
```typescript
describe('Two-Factor Authentication', () => {
  test('2FA enrollment', async () => {
    // GIVEN (Arrange)
    const user = await createTestUser({ totpEnabled: false });

    // WHEN (Act)
    const res = await request(app)
      .post('/api/auth/2fa/setup')
      .set('Authorization', `Bearer ${user.token}`);

    // THEN (Assert)
    expect(res.status).toBe(200);
    expect(res.body.qrCode).toBeDefined();

    // AND (Additional Assert)
    const updatedUser = await getUserById(user.id);
    expect(updatedUser.totpSecret).toBeDefined();
  });
});
```

### 6.3 tasks.md 的 TDD 闸门规则

`tdd-driven` schema 的 tasks 模板强制：

```markdown
## 1. Verify RED          ← 必须是第一个任务组
- [ ] 1.1 创建所有测试文件
- [ ] 1.2 运行测试，确认全部失败

## N-1. <实现任务组>       ← 每个实现组末尾有 "运行测试"
- [ ] N-1.x 实现功能
- [ ] N-1.y 运行测试，确认通过

## N. REFACTOR            ← 必须是最后一个任务组
- [ ] N.1 审查代码
- [ ] N.2 运行测试，确认仍然 GREEN
```

---

## 七、Agent 切换策略

不同阶段使用不同 Agent，利用各自的权限优势：

| 阶段 | Agent | 权限 | 原因 |
|------|-------|------|------|
| **入场**（Harness Init） | `Sisyphus` + Prometheus | 全权限 | 需要扫描项目、写 AGENTS.md、配检查 |
| **规划**（propose） | `Sisyphus`（限制只写 spec） | 读代码，只写 spec 文件 | 靠自律 + 规范约束，规划阶段不写实现代码 |
| **执行**（apply） | `Sisyphus` | 全权限 | 需要写代码、跑测试、改文件 |
| **验证**（verify） | `Sisyphus` | 读权限为主 | 偏审查性质 |
| **归档**（archive） | `Sisyphus` | 需要移动文件 | 涉及文件系统操作 |

**关键**：规划阶段严格自律——只写 spec 文件（`openspec/changes/` 下的 proposal/specs/design/tests/tasks），杜绝"规划着规划着就开始写代码"的 AI 通病。

---

## 八、日常工作速查

### 8.1 存量项目首次接入（一次性）

```bash
# Day 1: 盘点 + 分层（含 AI 补充扫描 + 人工确认问卷）
/harness-scan                      # 四阶段：init-deep 扫描 → AI 补充 → 确认问卷 → 最终确定

# Day 2-3: 设卡
/harness-gate                      # 五阶段：盘点已有 → 识别缺口 → 用户确认 → 安装 → 更新 AGENTS.md
# → 棕地项目自动用冻结-棘轮法，不直接开 strict

# Day 3+: 安装文档维护基础设施
/harness-doc-garden                # 三层 Hook（OpenCode + Git + 定时扫描）一步到位
```

### 8.2 启动新功能

```bash
# 1. 初始化（新项目）
openspec init . --tools opencode && oinit

# 2. 使用 Sisyphus Agent 进行规划（只写 spec 文件）
# 3. /opsx:explore          # 探索
# 4. /opsx:propose <name>   # 生成 proposal/specs/design/tests/tasks
```

### 8.3 开始实现

```bash
# 1. 切回 Sisyphus Agent
# 2. "按照 openspec/changes/<name>/tasks.md 执行，遵循 TDD 流程"
```

### 8.4 完成收尾

```bash
# 1. /opsx:verify           # 规范验证
# 2. /opsx:archive          # 归档
```

### 8.5 日常检查

```bash
openspec schemas            # 查看可用 schema
cat openspec/config.yaml    # 查看当前配置
git diff openspec/specs/    # 查看归档后的 spec 变更
```

### 8.6 扩展命令（按需使用）

```
/opsx:new <name>        # 只建 change 脚手架，不自动生成制品
/opsx:continue          # 生成 DAG 中下一个制品（逐个推进）
/opsx:ff                # 快进：一次生成所有规划制品（proposal→specs→design→tests→tasks）
/opsx:sync              # 单独合并 delta specs 到主 specs（不等 archive）
/opsx:bulk-archive      # 批量归档多个 change
/opsx:onboard           # 引导教程：走一遍完整工作流
```

---

## 九、故障排查

| 问题 | 原因 | 解决 |
|------|------|------|
| `openspec init` 后 schema 是 `spec-driven` | 正常，需要手动切换 | 运行 `oinit` |
| OmO 没有识别到 OpenSpec skills | 没有运行 `openspec update` | 项目根目录运行 `openspec update` |
| Agent 在规划阶段写代码 | 规划阶段应只写 spec 文件 | 自律约束：规划阶段只允许编辑 `openspec/` 目录下的文件 |
| 测试在 Verify RED 阶段就通过了 | 测试写得太宽泛或没有实际断言 | 检查 tests.md 中的测试是否有具体断言 |
| `openspec: command not found` | OpenSpec 未全局安装 | `npm install -g @fission-ai/openspec@latest` |
| tdd-driven schema 找不到 | 全局 schema 未安装 | 参考 [openspec-tdd-setup.md](./openspec-tdd-setup.md) 安装 |
| `/harness-scan` 生成的 AGENTS.md 太长 | 存量项目信息量大 | 手动瘦身：不变量留根文件，详细内容下沉 docs/ |
| Agent 忽略 AGENTS.md 中的规则 | 规则只是文字，不可执行 | 运行 `/harness-gate`：把关键规则变成 lint / test |
| 存量项目开 strict 后构建全红 | 一次开太严了 | `/harness-gate` 自动用冻结-棘轮法：先宽松，逐步收紧 |
| timely-doc-garden 扫描不到项目 | 未在 `projects.yaml` 中注册 | 编辑 skill 目录下的 `projects.yaml` 添加项目路径，或运行 `harness-doc-garden` 安装 |

---

## 十、文件清单

### 全局配置

| 文件 | 路径 | 用途 |
|------|------|------|
| TDD Schema | `~/.local/share/openspec/schemas/tdd-driven/` | TDD 工作流 DAG + 模板 |
| TDD 补丁脚本 | `~/.local/bin/openspec-tdd` | 切换为 TDD schema |
| Shell 别名 | `~/.zshrc` 中的 `oinit` | `openspec init` + TDD 补丁快捷方式 |
| OmO 配置 | `~/.config/opencode/opencode.json` | 注册 `oh-my-openagent` 插件 |

### 全局工具 — Harness Init Skills

#### harness-scan（盘点+分层，一次性）

| 文件 | 路径 | 用途 |
|------|------|------|
| 扫描 Skill | `dev-tooling/.agents/.skills/harness-scan/SKILL.md` | 四阶段：init-deep → AI 补充扫描 → 确认问卷 → 最终确定 |

#### harness-gate（设卡，一次性）

| 文件 | 路径 | 用途 |
|------|------|------|
| 设卡 Skill | `dev-tooling/.agents/.skills/harness-gate/SKILL.md` | 五阶段：盘点已有 → 识别缺口 → 用户确认 → 安装 → 更新 AGENTS.md |

#### harness-doc-garden（安装 skill，一次性）

| 文件 | 路径 | 用途 |
|------|------|------|
| 安装 Skill | `dev-tooling/.agents/.skills/harness-doc-garden/SKILL.md` | 一键安装三层 Hook + 注册项目 |

#### timely-doc-garden（运行 skill，反复执行）

| 文件 | 路径 | 用途 |
|------|------|------|
| 运行 Skill | `dev-tooling/.agents/.skills/timely-doc-garden/SKILL.md` | 四阶段扫描+修复指令 |
| 扫描脚本 | `dev-tooling/.agents/.skills/timely-doc-garden/scripts/scan.py` | Phase 1: 确定性引用扫描 |
| 修复脚本 | `dev-tooling/.agents/.skills/timely-doc-garden/scripts/fix_refs.py` | Phase 3: L1 自动修复（路径重命名 + 行号偏移） |
| 引用校验 | `dev-tooling/.agents/.skills/timely-doc-garden/scripts/validate-refs.sh` | 实时/Git hook: 引用存在性校验 |
| 定时执行器 | `dev-tooling/.agents/.skills/timely-doc-garden/scripts/run-scheduled.sh` | 读取 projects.yaml，逐项目执行 |
| 项目注册表 | `dev-tooling/.agents/.skills/timely-doc-garden/projects.yaml` | 用户注册需要定时扫描的项目 |
| 漂移模式 | `dev-tooling/.agents/.skills/timely-doc-garden/references/drift-patterns.md` | 10 种常见文档过时模式 |
| 报告模板 | `dev-tooling/.agents/.skills/timely-doc-garden/templates/report.md` | 输出报告格式 |

### 项目内 — Harness Init 产出（一次性）

| 文件 | 路径 | 用途 |
|------|------|------|
| 根配置文件 | `AGENTS.md` | ≤100 行：构建命令、架构红线、安全红线、索引 |
| 子目录配置 | `src/AGENTS.md` 等 | 与根文件的差异 |
| 架构文档 | `docs/architecture.md` | 分层结构、基础设施集成 |
| 开发指南 | `docs/development-guide.md` | 环境搭建、本地开发、测试、部署 |
| API 索引 | `docs/api-contracts.md` | API 规范索引 |
| 架构决策 | `docs/adr/*.md` | 每份 ≤40 行，有源码引用 |
| Harness 规则 | `.sisyphus/rules/` | doc-gardening + 规则回顾规则 |
| 维护报告 | `.sisyphus/doc-garden-report.md` | 每次 timely-doc-garden 运行的结果报告 |

### 项目内 — OpenSpec 产出（每个功能）

| 文件 | 路径 | 用途 |
|------|------|------|
| 项目配置 | `openspec/config.yaml` | `schema: tdd-driven` + TDD rules |
| AI Skills | `.opencode/skills/openspec-*/SKILL.md` | OpenSpec 生成的 Agent 指令 |
| AI Commands | `.opencode/commands/opsx-*.md` | `/opsx:*` 斜杠命令 |
| Specs | `openspec/specs/` | 系统当前行为的真实来源 |
| 变更 | `openspec/changes/<name>/` | 每个功能的完整制品 |
| 归档 | `openspec/changes/archive/` | 已完成功能的归档 |

### 项目内 — OmO 产出（执行过程）

| 文件 | 路径 | 用途 |
|------|------|------|
| 执行计划 | `.sisyphus/plans/` | Atlas 的执行计划 |
| 学习积累 | `.sisyphus/notepads/` | Agent 间的知识积累 |
| 面谈草稿 | `.sisyphus/drafts/` | Prometheus 面谈过程 |

---

## 十一、参考链接

- [OpenSpec](https://github.com/Fission-AI/OpenSpec) — SDD 框架
- [Open Specification](https://open-specification.org/) — 规范标准
- [Oh-My-OpenAgent](https://github.com/code-yeongyu/oh-my-openagent) — Agent 编排框架
- [openspec-tdd-setup.md](./openspec-tdd-setup.md) — TDD Schema 配置详情
- [harness-init-guide.md](./harness-init-guide.md) — Harness Init 四步法详细指南
- [harness-doc-garden skill](./.agents/.skills/harness-doc-garden/SKILL.md) — 文档维护基础设施安装 Skill
- [timely-doc-garden skill](./.agents/.skills/timely-doc-garden/SKILL.md) — 文档-代码一致性扫描+修复 Skill
