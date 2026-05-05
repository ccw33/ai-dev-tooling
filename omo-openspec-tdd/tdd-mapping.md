---
name: tdd-mapping
description: >
  TDD Spec-to-Test mapping rules. Defines how GIVEN/WHEN/THEN scenarios translate to Arrange/Act/Assert test code.
  Includes mapping table, code examples, and tasks.md gate rules.
  Use when: writing tests from OpenSpec scenarios, understanding RED/GREEN/REFACTOR mapping.
  Triggers: "tdd mapping", "spec to test", "given when then", "TDD映射", "测试映射".
---

# TDD 的 Spec → Test 映射规则

> 来源：[omo-openspec-tdd.md](../omo-openspec-tdd.md) §四

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

### 6.4 测试类型分流

OpenSpec 的 scenario 不都是同一种测试。根据 scenario 描述的对象和交互范围，分流到不同的测试类型和 skill：

| Scenario 特征 | 测试类型 | 加载 Skill | 测试工具 |
|---------------|---------|-----------|---------|
| 单组件渲染、props 变化、状态转换 | Unit Test | `/frontend-testing` | Vitest + RTL |
| 自定义 hook 逻辑、工具函数 | Unit Test | `/frontend-testing` | Vitest + `renderHook` |
| 多组件交互、表单提交流程 | Integration Test | `/frontend-testing` | Vitest + RTL + MSW |
| 用户跨页面的完整操作流程 | E2E Test | `/e2e-testing` | Playwright |
| 涉及网络请求、数据库、认证的端到端验证 | E2E Test | `/e2e-testing` | Playwright + fixtures |
| API 端点的请求/响应行为 | API Test | (无专用 skill) | Vitest + supertest |

**分流决策树**：

```
Scenario 提到页面跳转或路由变化？
  YES → E2E Test (e2e-testing)
  NO → Scenario 提到多个组件协作？
    YES → Scenario 涉及真实网络请求？
      YES → E2E Test (e2e-testing)
      NO → Integration Test (frontend-testing)
    NO → Unit Test (frontend-testing)
```

**Rule**: 每个 Requirement 至少有一个 Unit Test。E2E Test 只覆盖关键用户流程（Smoke + Critical Path），不重复 Unit Test 已覆盖的逻辑。

### 6.5 Frontend Unit Test 映射示例

**Spec**：
```markdown
### Requirement: Login Form Validation
#### Scenario: shows error when email is invalid
- **GIVEN** the login form is displayed
- **WHEN** the user types an invalid email and clicks submit
- **THEN** an error message "Invalid email" is shown
```

**Test** (使用 frontend-testing skill 模式)：
```typescript
// 遵循 frontend-testing/references/component-testing.md 模式
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, test, expect } from 'vitest';
import { LoginForm } from './LoginForm';

describe('Login Form Validation', () => {
  test('shows error when email is invalid', async () => {
    // GIVEN (Arrange)
    const user = userEvent.setup();
    render(<LoginForm onSubmit={vi.fn()} />);

    // WHEN (Act)
    await user.type(screen.getByLabelText(/email/i), 'invalid-email');
    await user.click(screen.getByRole('button', { name: /submit/i }));

    // THEN (Assert) — 使用 getByRole 优先，不用 test-id
    expect(screen.getByRole('alert')).toHaveTextContent('Invalid email');
  });
});
```

**Browser Mode 版本**（新项目推荐）：

```typescript
// Browser Mode: 真实浏览器渲染，import 来自 vitest-browser-react
import { render } from 'vitest-browser-react';
import { page } from '@vitest/browser/context';
import { describe, test, expect } from 'vitest';
import { LoginForm } from './LoginForm';

describe('Login Form Validation', () => {
  test('shows error when email is invalid', async () => {
    // GIVEN (Arrange)
    render(<LoginForm onSubmit={vi.fn()} />);

    // WHEN (Act) — Browser Mode 使用 page 对象交互
    await page.getByLabelText(/email/i).fill('invalid-email');
    await page.getByRole('button', { name: /submit/i }).click();

    // THEN (Assert) — Browser Mode 使用 expect.element()
    const alert = page.getByRole('alert');
    await expect.element(alert).toHaveTextContent('Invalid email');
  });
});
```

### 6.6 E2E Test 映射示例

**Spec**：
```markdown
### Requirement: User Login
#### Scenario: successful login redirects to dashboard
- **GIVEN** the user is on the login page
- **WHEN** the user enters valid credentials and submits
- **THEN** the user is redirected to the dashboard
- **AND** the dashboard shows the user's name
```

**Test** (使用 e2e-testing skill 模式)：
```typescript
// 遵循 e2e-testing/references/page-objects.md + fixtures.md 模式
import { test, expect } from '@playwright/test';
import { LoginPage } from '../pages/login.page';

test.describe('User Login', () => {
  test('successful login redirects to dashboard', async ({ page }) => {
    // GIVEN (Arrange) — 使用 Page Object 封装
    const loginPage = new LoginPage(page);
    await loginPage.goto();

    // WHEN (Act)
    await loginPage.fillCredentials('user@example.com', 'password123');
    await loginPage.submit();

    // THEN (Assert) — 使用 getByRole，不用 CSS 选择器
    await expect(page).toHaveURL('/dashboard');
    await expect(page.getByRole('heading', { name: /dashboard/i })).toBeVisible();

    // AND (Additional Assert)
    await expect(page.getByText('John Doe')).toBeVisible();
  });
});
```

### 6.7 Skill 加载规则

在 `opsx-apply` 的 TDD 周期中，Agent 写测试时必须加载对应的 testing skill：

```
opsx-apply 读 tasks.md
  │
  ├── 任务涉及写 Unit/Integration Test?
  │   → 加载 /frontend-testing
  │   → 参考 references/ 按需加载:
  │     - component-testing.md (组件测试模式)
  │     - hooks-and-context.md (hook/context 测试)
  │     - mocking.md (mock 策略)
  │     - ai-anti-patterns.md (避免 AI 常见测试反模式)
  │
  ├── 任务涉及写 E2E Test?
  │   → 加载 /e2e-testing
  │   → 参考 references/ 按需加载:
  │     - page-objects.md (POM 封装)
  │     - selectors-and-waits.md (选择器 + 等待策略)
  │     - fixtures.md (认证 + 数据 fixtures)
  │
  └── 任务是 Verify RED / REFACTOR?
      → 无需额外 skill，执行 vitest/run 或 npx playwright test
```

**关键约束**：
- RED 阶段写的测试必须能编译通过（语法正确），但断言必须失败
- 写测试时必须遵循对应 skill 的模式（选择器策略、mock 边界、断言风格）
- 不要在 E2E 测试中重复 Unit Test 已覆盖的逻辑验证
