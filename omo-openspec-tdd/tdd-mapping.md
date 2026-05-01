<!--
  参考文档：从 omo-openspec-tdd.md §六 提取的 TDD Spec→Test 映射规则。
  供 AI Agent 和人类在编写测试时查阅，无需翻阅主文档。
  原始来源：omo-openspec-tdd.md (1114 行)
-->

# TDD 的 Spec → Test 映射规则

> 来源：[omo-openspec-tdd.md](../omo-openspec-tdd.md) §六

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
