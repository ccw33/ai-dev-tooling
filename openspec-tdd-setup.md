---
name: openspec-tdd-setup
description: >
  OpenSpec + TDD global configuration guide.
  Covers TDD Schema installation, patch script setup, and oinit alias configuration.
  Use when: setting up OpenSpec environment, installing tdd-driven schema, configuring openspec-tdd patch.
  Triggers: "openspec setup", "tdd schema", "oinit", "tdd配置", "openspec安装".
---

# OpenSpec + TDD 全局配置指南

> 配置日期：2026-04-30
> 适用环境：本机 macOS (chenchaowen)
> OpenSpec 版本：1.3.1

---

## 一、背景

[OpenSpec](https://github.com/Fission-AI/OpenSpec) 是 Fission-AI 开发的 Spec-Driven Development (SDD) 框架，专为 AI 编程助手设计。其核心流程是先定义行为规范（Spec），再写代码。

TDD（测试驱动开发）的核心理念是先写测试（RED），再写实现（GREEN），最后重构（REFACTOR）。

两者的天然契合点：**OpenSpec 的 Scenario（GIVEN/WHEN/THEN）本质上就是测试用例的草稿**，可以直接转化为自动化测试（Arrange/Act/Assert）。

---

## 二、配置内容

### 2.1 全局自定义 Schema：`tdd-driven`

**位置**：`~/.local/share/openspec/schemas/tdd-driven/`

**与默认 `spec-driven` 的区别**：

```
spec-driven（原版）：
  proposal → specs → design → tasks → apply

tdd-driven（TDD 版）：
  proposal → specs → design → tests → tasks → apply
                                    ↑
                              新增 tests artifact
                              测试必须在任务之前创建
```

**关键改动**：

| 改动点 | 说明 |
|--------|------|
| 新增 `tests` artifact | 位于 specs/design 之后、tasks 之前 |
| `tasks` 依赖 `tests` | 不写完测试就不能创建任务清单 |
| Spec 场景强制 GIVEN/WHEN/THEN | 直接映射为测试的 Arrange/Act/Assert |
| Design 新增 Test Strategy 章节 | 明确测试框架、命名规范、组织方式 |
| Tasks 模板首组为 "Verify RED" | 确保先确认所有测试失败再实现 |
| Apply 指令强制 TDD 流程 | RED → GREEN → REFACTOR |

**文件结构**：

```
~/.local/share/openspec/schemas/tdd-driven/
├── schema.yaml              # Schema 定义（依赖链、指令）
└── templates/
    ├── proposal.md           # 提案模板
    ├── spec.md               # 规范模板（GIVEN/WHEN/THEN）
    ├── design.md             # 设计模板（含 Test Strategy）
    ├── tests.md              # 测试模板（新增）
    └── tasks.md              # 任务模板（含 Verify RED）
```

### 2.2 TDD 补丁脚本：`openspec-tdd`

**位置**：`~/.local/bin/openspec-tdd`

在 `openspec init` 之后运行，切换为 TDD schema。

1. 若 `openspec/config.yaml` 不存在（non-interactive 模式会跳过），自动创建
2. 覆写 `openspec/config.yaml` 为 TDD 版本
3. 运行 `openspec update`（重新生成 AI skills）

**别名**：`oinit`（已写入 `~/.zshrc`）

### 2.3 项目 config.yaml 模板

每个项目初始化后自动获得以下配置：

```yaml
schema: tdd-driven

context: |
  TDD: Strict RED-GREEN-REFACTOR cycle
  Every spec scenario must have a corresponding test
  Tests are written BEFORE implementation

rules:
  proposal:
    - Include test strategy in proposal
  specs:
    - Use GIVEN/WHEN/THEN format for all scenarios
    - Every scenario must be directly convertible to a test
    - Cover happy path AND edge cases
  design:
    - Include Test Strategy section
    - Specify testing framework and conventions
  tests:
    - Every spec scenario MUST have a corresponding test
    - Tests MUST be written BEFORE implementation
    - Use GIVEN/WHEN/THEN naming in test structure
    - Run tests to verify RED before implementing
  tasks:
    - First task group MUST be "Verify RED"
    - Each implementation task group ends with "Run tests"
    - Last task group is "REFACTOR"
```

---

## 三、使用方法

### 3.1 新项目

```bash
# 第一步：用原生命令初始化（处理目录创建和 AI 工具配置）
openspec init . --tools opencode

# 第二步：切换为 TDD schema
openspec-tdd

# 或使用别名
oinit

# 然后在 AI 编程助手中使用
/opsx:propose add-dark-mode
```

### 3.2 已有项目

编辑 `openspec/config.yaml`，将第一行改为：

```yaml
schema: tdd-driven
```

然后添加 TDD context 和 rules（见 2.3 模板），最后运行：

```bash
openspec update
```

### 3.3 完整 TDD 工作流

```
/opsx:propose add-feature
       │
       ▼
  proposal.md    ──── 为什么做、做什么
       │
       ▼
  specs/          ──── GIVEN/WHEN/THEN 场景（测试蓝图）
       │
       ▼
  design.md       ──── 技术方案 + Test Strategy
       │
       ▼
  tests/          ──── 场景 → 测试代码（RED 阶段）
       │
       ▼
  tasks.md        ──── Verify RED → 实现 → REFACTOR
       │
       ▼
/opsx:apply       ──── GREEN: 最少代码通过测试
                      REFACTOR: 清理，保持 GREEN
       │
       ▼
/opsx:verify      ──── 检查 Spec-Test-Code 一致性
       │
       ▼
/opsx:archive     ──── 归档，Delta Specs 合入主 Spec
```

### 3.4 Spec Scenario → Test 映射示例

**Spec**：
```markdown
#### Scenario: Valid credentials
- **GIVEN** a user with valid credentials
- **WHEN** the user submits login form
- **THEN** a JWT token is returned
```

**Test**：
```python
def test_valid_credentials():
    # GIVEN (Arrange)
    user = create_test_user(credentials="valid")

    # WHEN (Act)
    result = login(user)

    # THEN (Assert)
    assert result.status_code == 200
    assert "jwt_token" in result.json()
```

### 3.5 临时切换回原版 Schema

如某个项目不想用 TDD，编辑 `openspec/config.yaml`：

```yaml
schema: spec-driven    # 改回原版
```

运行 `openspec update` 即可。

---

## 四、验证命令

```bash
# 查看所有可用 schema
openspec schemas

# 验证 tdd-driven schema
openspec schema validate tdd-driven

# 查看 tdd-driven 解析来源
openspec schema which tdd-driven

# 查看项目当前配置
cat openspec/config.yaml
```

---

## 五、Schema 解析优先级

OpenSpec 的 schema 查找顺序：

1. **项目本地**：`<project>/openspec/schemas/<name>/schema.yaml`
2. **用户全局**：`~/.local/share/openspec/schemas/<name>/schema.yaml` ← 我们的 tdd-driven 在这里
3. **包内置**：`<npm-package>/schemas/<name>/schema.yaml`

全局 schema 不会在 OpenSpec 升级时被覆盖，但包内置的 `spec-driven` 更新时需要手动同步改动到 `tdd-driven`。

---

## 六、文件清单

| 文件 | 路径 | 用途 |
|------|------|------|
| Schema 定义 | `~/.local/share/openspec/schemas/tdd-driven/schema.yaml` | TDD 工作流依赖链和指令 |
| Proposal 模板 | `~/.local/share/openspec/schemas/tdd-driven/templates/proposal.md` | 提案文档模板 |
| Spec 模板 | `~/.local/share/openspec/schemas/tdd-driven/templates/spec.md` | GIVEN/WHEN/THEN 场景模板 |
| Design 模板 | `~/.local/share/openspec/schemas/tdd-driven/templates/design.md` | 设计文档模板（含 Test Strategy） |
| Tests 模板 | `~/.local/share/openspec/schemas/tdd-driven/templates/tests.md` | 测试文件模板（新增） |
| Tasks 模板 | `~/.local/share/openspec/schemas/tdd-driven/templates/tasks.md` | 任务清单模板（含 Verify RED） |
| TDD 补丁脚本 | `~/.local/bin/openspec-tdd` | 在 openspec init 之后运行，切换为 TDD schema |
| Shell 别名 | `~/.zshrc` 中的 `oinit` | 快捷方式 |
| Hermes Skill | `~/.hermes/skills/software-development/openspec-tdd/SKILL.md` | AI agent 使用的技能文档 |
