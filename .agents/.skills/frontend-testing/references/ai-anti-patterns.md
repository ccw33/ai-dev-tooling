---
name: ai-anti-patterns
description: >
  Five AI-specific testing anti-patterns with wrong/correct examples. Covers tautological
  tests, over-mocking, weak assertions, happy-path-only suites, and assertion degradation.
  Use when: reviewing AI-generated tests, catching common AI testing mistakes.
  Triggers: "AI anti-pattern", "test review", "test quality", "tautological test",
  "weak assertion", "over mocking".
---

# AI Testing Anti-Patterns

> Source: [SKILL.md](../SKILL.md)

AI-generated tests often fall into these five traps. Check every generated test suite
against this list before shipping.

## 1. Tautological Tests

AI mirrors the implementation logic in the assertion, so the test proves nothing.

```typescript
// BAD: Asserts the same logic the component uses internally
test('formatPrice works', () => {
  const price = 29.99
  const formatted = `$${price.toFixed(2)}` // mirrors implementation
  expect(formatPrice(price)).toBe(formatted)
})
```

```typescript
// GOOD: Assert against known expected values
test('formatPrice works', () => {
  expect(formatPrice(29.99)).toBe('$29.99')
  expect(formatPrice(0)).toBe('$0.00')
  expect(formatPrice(1000)).toBe('$1,000.00')
})
```

Why it matters: Tautological tests pass even when the implementation is wrong, because
the test re-implements the same buggy logic. Hardcode expected outputs instead.

## 2. Over-Mocking

AI mocks everything so the test passes trivially, but nothing real is being tested.

```typescript
// BAD: Every dependency is mocked, testing only that mocks return what we told them
vi.mock('./api')
vi.mock('./auth')
vi.mock('./db')
vi.mock('./validator')

test('user flow works', async () => {
  vi.mocked(fetchUser).mockResolvedValue({ name: 'Alice' }) // we set this
  vi.mocked(isValid).mockReturnValue(true)                   // we set this
  const result = await processUser(1)
  expect(result.name).toBe('Alice') // obviously passes
})
```

```typescript
// GOOD: Mock only the network boundary, test real logic through it
const server = setupServer(
  http.get('/api/users/1', () => HttpResponse.json({ name: 'Alice' }))
)

test('user flow works', async () => {
  render(<UserProfile userId="1" />)
  // Tests real auth, real state updates, real rendering
  expect(await screen.findByText('Alice')).toBeInTheDocument()
})
```

Why it matters: Over-mocked tests are green even when the real system is broken. Mock
at boundaries (network, storage), not at every internal layer.

## 3. Weak Assertions

AI uses `toBeDefined()`, `toBeTruthy()`, or `toBeGreaterThan(0)` everywhere instead
of asserting specific values.

```typescript
// BAD: These pass with almost any value
expect(result).toBeDefined()
expect(items.length).toBeTruthy()
expect(count).toBeGreaterThan(0)
expect(response).not.toBeNull()
```

```typescript
// GOOD: Assert exact expected values
expect(result).toEqual({ id: 1, name: 'Alice', role: 'admin' })
expect(items).toHaveLength(3)
expect(count).toBe(42)
expect(response.status).toBe(200)
```

Why it matters: Weak assertions catch syntax errors but miss logic errors. A test that
passes when the answer is wrong is worse than no test at all, because it gives false
confidence.

## 4. Happy-Path-Only Suites

AI writes tests only for the success case, missing errors, empty states, boundaries,
and edge cases.

```typescript
// BAD: Only the success path
describe('searchUsers', () => {
  test('returns users matching query', async () => {
    const results = await searchUsers('alice')
    expect(results).toHaveLength(2)
  })
})
```

```typescript
// GOOD: Cover error, empty, boundary, and edge cases
describe('searchUsers', () => {
  test('returns users matching query', async () => {
    const results = await searchUsers('alice')
    expect(results).toHaveLength(2)
  })

  test('returns empty array for no matches', async () => {
    const results = await searchUsers('zzz-nonexistent')
    expect(results).toEqual([])
  })

  test('throws on network error', async () => {
    server.use(http.get('/api/users', () => HttpResponse.error()))
    await expect(searchUsers('alice')).rejects.toThrow('Network error')
  })

  test('handles empty query string', async () => {
    const results = await searchUsers('')
    expect(results).toEqual([])
  })

  test('handles special characters in query', async () => {
    const results = await searchUsers('<script>alert(1)</script>')
    expect(results).toEqual([])
  })
})
```

Why it matters: Users hit edge cases more than happy paths. A suite with only passing
tests is a sign the tests are incomplete, not that the code is correct.

## 5. Assertion Degradation

AI silently weakens assertions to make tests pass, especially after implementation
changes. `toEqual` becomes `toContain`, `toBe` becomes `toBeTruthy`.

```typescript
// BAD: Assertion was weakened from toEqual to toContain to make it pass
expect(result.tags).toContain('featured') // passes even with extra wrong tags
expect(result.count).toBeGreaterThanOrEqual(1) // was originally toBe(1)
```

```typescript
// GOOD: Keep precise assertions, fix the code if the test fails
expect(result.tags).toEqual(['featured', 'new', 'sale'])
expect(result.count).toBe(1)
```

Why it matters: When a test fails, the correct response is to investigate and fix the
code or fix the test assertion to match the correct spec. Weakening the assertion hides
bugs.

## Pre-Ship Checklist

Before accepting AI-generated tests, verify:

- [ ] No tautological assertions (implementation mirrored in test)
- [ ] Mocks are at boundaries only (network, storage), not internal layers
- [ ] Every assertion checks a specific expected value, not just existence
- [ ] Error, empty, boundary, and edge cases are covered
- [ ] No assertion was weakened from its original precise form
