# 完整工作流示例：给电商系统添加两步验证（2FA）

> 来源：[omo-openspec-tdd.md](../omo-openspec-tdd.md) §五

> **前提**：已完成 Harness Init（第零层），项目已有 `AGENTS.md` + `docs/` + 质量闸门。如果是全新项目，先跑一遍 `/harness-scan` → `/harness-gate` → `/harness-doc-garden`，然后 `oinit`。

## 5.1 Phase 1：初始化功能

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

## 5.2 Phase 2：规划（Sisyphus + OpenSpec）

在 OmO 中使用 Sisyphus Agent 进行规划，规划阶段应**只读代码、只写 spec 文件**，不写实现代码。

### Step 1：探索

```
/opsx:explore
```

Agent 调查现有认证系统、数据库结构、TOTP 库选型。此阶段不产出文件。

### Step 2：提案

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

## 5.3 Phase 3：执行（Sisyphus Agent）

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

### OmO 的关键附加值

1. **模型路由**：数据层 → `deep`（GPT-5.4），前端 → `visual-engineering`（Gemini），REFACTOR → `quick`（Mini）
2. **自动验证**：每个任务完成后自动 `lsp_diagnostics` + `build` + `test`
3. **失败恢复**：3 次失败 → revert → 咨询 Oracle
4. **并行执行**：识别无依赖的任务并行分派

## 5.4 Phase 4：双重验证

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

## 5.5 Phase 5：归档 & 复合学习

```
/opsx:archive
```

Delta Spec 合并到主 Spec：
```
ADDED    "Two-Factor Authentication"  → 追加到 openspec/specs/auth.md
MODIFIED "User Login"                 → 替换旧版本
```

下次做"社交账号登录"时，OpenSpec 已经知道系统有 2FA 了，新的 proposal 会自动考虑 2FA 对社交登录的影响。知识在积累，不是在堆叠。
