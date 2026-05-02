---
name: hook-config
description: >
  Three-layer hook system for doc-code consistency: OpenCode hooks, Git hooks, and scheduled scans.
  Covers harness-doc-garden installation, projects.yaml registration, cron/launchd setup, and maintenance calendar.
  Use when: installing doc maintenance infrastructure, configuring hooks, setting up scheduled scans.
  Triggers: "hook config", "doc garden setup", "三层hook", "文档维护配置".
---

# Harness 维护：三层 Hook 体系 + 文档 Gardening

> 来源：[omo-openspec-tdd.md](../omo-openspec-tdd.md) §4.5

## 自动化方案

`harness-doc-garden`（一次性安装）+ `timely-doc-garden`（定时运行）— 安装三层 Hook，定时扫描所有注册项目，自动检测并修复文档过时问题。

让文档活着。过期的记忆比没有记忆更危险——Agent 读到错误的文档，产出的就是幻觉。

## 安装

Skill 位置：`/Users/chenchaowen/Desktop/Project/dev-tooling/.agents/.skills/timely-doc-garden/`

该 skill 位于项目本地 `.agents/.skills/` 目录下，`opencode` 会自动发现项目级 skill，无需额外配置。

**安装方式**：使用 `harness-doc-garden` skill 一键安装三层 Hook：

```
opencode run --command harness-doc-garden
```

或手动安装（见下方"三层 Hook 体系"章节）。

## 注册项目

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

## 定时执行

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

## 三级修复策略

| 级别 | 执行者 | 修复内容 | 人工介入 |
|------|--------|---------|---------|
| **L1 脚本修复** | `scan.py` + `fix_refs.py` | 行号偏移、路径重命名 | 无 |
| **L2 AI 修复** | Agent 直接 Edit .md | 语义过时（库换了、命令变了、模块增删） | 无 |
| **L3 仅报告** | 标记 `[REVIEW: reason]` | 需要团队决策的（架构规则是否仍适用） | 需要 |

**目标：L3 尽量为零。** 绝大多数过时都是事实性的（代码改了文档没跟上），AI 直接修。

## 执行流程

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

## 与 OpenSpec archive 的协同

| 维护维度 | timely-doc-garden（自动化） | OpenSpec archive（功能开发时） |
|---------|---------------------|-------------------------------|
| 项目基础设施知识 | ✅ 构建、架构、安全、技术栈 | ❌ |
| 业务功能知识 | ❌ | ✅ 需求、设计、测试场景 |
| 触发方式 | 定时（每周） | 功能完成归档时 |
| 性质 | 预防性（防止知识过期） | 积累性（新知识合入） |

两者并行运行，互不干扰，都在做"复合学习"。

## 实时 Hook 体系：三层叠加确保文档最新

定时扫描是兜底，但 Agent 编辑代码后文档引用可能立即断裂——等到下周才发现已经太晚。三层 Hook 在不同时机拦截：

```
┌─────────────────────────────────────────────────────────────────┐
│ 第一层：OpenCode Hook（实时，Agent 编辑时触发）                     │
│                                                                  │
│   experimental.hook.file_edited  →  文件编辑后校验引用（含 README.md） │
│   experimental.hook.session_completed  →  Session 结束后轻量扫描   │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│ 第二层：Git Hook（离线保底，人工编辑时触发）                         │
│                                                                  │
│   pre-commit: validate-refs.sh  →  校验引用存在性（含 README.md）    │
│   pre-push: pytest  →  跑测试，失败阻断推送                          │
│   pre-push: check-doc-staleness.sh  →  scan→fix→warn（能修则修）     │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│ 第三层：定时扫描（已有，兜底）                                      │
│                                                                  │
│   每周 timely-doc-garden cron  →  全量扫描 + AI 修复                  │
│   前两层拦截绝大部分过期，这一层兜底                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 第一层：OpenCode 原生 Hook

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

### 第二层：Git Hook（离线保底）

OpenCode 不在运行时（人工编辑、CI 合并），由 git hooks 保底。

**pre-commit：校验文档引用存在性（AGENTS.md + README.md）**

复用 `validate-refs.sh`（已存在于 `.agents/.skills/timely-doc-garden/scripts/`）：

```bash
#!/bin/bash
# 在项目根目录的 pre-commit hook 中调用
bash .agents/.skills/timely-doc-garden/scripts/validate-refs.sh
```

**pre-push：scan → auto-fix → warn（能修则修）**

脚本位置：`.agents/.skills/timely-doc-garden/scripts/check-doc-staleness.sh`

```bash
#!/bin/bash
# scan → fix → warn 三阶段管道（能修则修，修不了的才告警）
# pre-push 触发，不阻断推送
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SCAN_RESULT="$PROJECT_ROOT/scan-result.json"

if command -v python3 &>/dev/null; then
  python3 "$SKILL_DIR/scripts/scan.py" --project-root "$PROJECT_ROOT" --output "$SCAN_RESULT" 2>/dev/null || true
  if [ -f "$SCAN_RESULT" ]; then
    FIXED=$(python3 "$SKILL_DIR/scripts/fix_refs.py" --project-root "$PROJECT_ROOT" --scan-result "$SCAN_RESULT" --apply 2>&1 | grep -c "FIXED" || true)
    if [ "${FIXED:-0}" -gt 0 ]; then
      echo "📝 doc-garden: auto-fixed $FIXED reference(s)"
    fi
    rm -f "$SCAN_RESULT"
  fi
fi

bash "$SKILL_DIR/scripts/validate-refs.sh" 2>/dev/null | grep -E "^(✗|⚠)" || true

exit 0
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

### 现成工具参考

| 工具 | 策略 | AI-Agent 感知 | AGENTS.md 支持 |
|------|------|--------------|----------------|
| **[cortex-tms](https://github.com/cortex-tms/cortex-tms)** | 时间戳 + commit 计数 | ✅ 专为 AI Agent 设计 | ✅ CLAUDE.md / PATTERNS.md |
| **[Wegent AI push gate](https://github.com/wecode-ai/Wegent)** | 代码变更 → 文件映射 + `AI_VERIFIED` 闸门 | ✅ | ✅ 显式检查 AGENTS.md |
| **[docrot](https://github.com/andimrob/docrot)** | `code_changes` 策略：watch 源文件变动 | ❌ | ✅ 作为被监控文档 |

需要更完整的方案时可以直接集成这些工具，上述脚本适用于快速启动。

## 维护日历

| 频率 | 动作 | 执行方式 |
|------|------|---------|
| **实时** | 文件编辑后校验引用 | OpenCode `experimental.hook.file_edited` |
| **每次 Session 结束** | 轻量 timely-doc-garden 扫描 | OpenCode `experimental.hook.session_completed` |
| **每次提交** | AGENTS.md + README.md 引用存在性校验 | git pre-commit → `validate-refs.sh` |
| **每次推送** | pytest 跑测试（阻断）+ scan→fix→warn | git pre-push → pytest + `check-doc-staleness.sh` |
| 每周 | timely-doc-garden 全量扫描 + 修复 | cron/launchd → `run-scheduled.sh` |
| 每两周 | 规则回顾（棘轮收紧） | 人工：看 timely-doc-garden 报告中的违规趋势 |
| 每月 | 根文件瘦身（AGENTS.md ≤100 行） | 人工：参考报告中的大小提示 |
