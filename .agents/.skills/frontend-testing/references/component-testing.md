---
name: component-testing
description: >
  React component testing patterns for Vitest. Covers Browser Mode (vitest-browser-react)
  and jsdom (@testing-library/react). Includes rendering, props, callbacks, conditional
  rendering, loading states, error boundaries, and the factory function pattern.
  Use when: writing tests for React components.
  Triggers: "component test", "render test", "props test", "callback test", "conditional rendering".
---

# Component Testing

> Source: [SKILL.md](../SKILL.md)

> Source: [SKILL.md](../SKILL.md)

## The Factory Function Pattern (Required)

Do NOT use `beforeEach` to render components. Use a factory function that each test calls
with its specific props. This makes tests self-contained and explicit.

```typescript
// Browser Mode factory
function renderLoginForm(props: Partial<LoginFormProps> = {}) {
  const defaultProps = { onSubmit: vi.fn(), isLoading: false }
  return render(<LoginForm {...defaultProps} {...props} />)
}

// jsdom factory
function setup(props: Partial<LoginFormProps> = {}) {
  const defaultProps = { onSubmit: vi.fn(), isLoading: false }
  return {
    screen: render(<LoginForm {...defaultProps} {...props} />),
    onSubmit: defaultProps.onSubmit,
  }
}
```

## Browser Mode (Preferred)

### Basic Rendering

```tsx
test('displays user profile information', async () => {
  const screen = await render(
    <UserProfile name="Alice" email="alice@example.com" role="admin" />
  )

  await expect.element(screen.getByText('Alice')).toBeVisible()
  await expect.element(screen.getByText('alice@example.com')).toBeVisible()
})
```

### Props and Callbacks

```tsx
test('calls onSubmit with form data', async () => {
  const handleSubmit = vi.fn()
  const screen = await render(<LoginForm onSubmit={handleSubmit} />)

  await screen.getByLabelText(/email/i).fill('test@example.com')
  await screen.getByRole('button', { name: /submit/i }).click()

  expect(handleSubmit).toHaveBeenCalledWith({
    email: 'test@example.com',
  })
})
```

### Conditional Rendering

```tsx
test('shows loading spinner when isLoading is true', async () => {
  const screen = await render(<DataPanel isLoading={true} data={null} />)
  await expect.element(screen.getByRole('status')).toBeVisible()
})

test('shows data when loaded', async () => {
  const screen = await render(
    <DataPanel isLoading={false} data={{ title: 'Hello' }} />
  )
  await expect.element(screen.getByText('Hello')).toBeVisible()
  await expect.element(screen.queryByRole('status')).not.toBeInTheDocument()
})
```

### Error Boundaries

```tsx
test('catches render errors and shows fallback', async () => {
  const consoleError = vi.spyOn(console, 'error').mockImplementation(() => {})

  const screen = await render(
    <ErrorBoundary fallback={<span>Something went wrong</span>}>
      <ThrowingComponent />
    </ErrorBoundary>
  )

  await expect.element(screen.getByText('Something went wrong')).toBeVisible()
  consoleError.mockRestore()
})
```

## jsdom Mode (Legacy)

### Basic Rendering

```tsx
test('displays user profile information', () => {
  render(<UserProfile name="Alice" email="alice@example.com" role="admin" />)

  expect(screen.getByText('Alice')).toBeInTheDocument()
  expect(screen.getByText('alice@example.com')).toBeInTheDocument()
})
```

### Props and Callbacks

```tsx
test('calls onSubmit with form data', async () => {
  const handleSubmit = vi.fn()
  const user = userEvent.setup()
  render(<LoginForm onSubmit={handleSubmit} />)

  await user.type(screen.getByLabelText(/email/i), 'test@example.com')
  await user.click(screen.getByRole('button', { name: /submit/i }))

  expect(handleSubmit).toHaveBeenCalledWith({
    email: 'test@example.com',
  })
})
```

### Conditional Rendering

```tsx
test('shows loading spinner when isLoading is true', () => {
  render(<DataPanel isLoading={true} data={null} />)
  expect(screen.getByRole('status')).toBeInTheDocument()
})

test('shows data when loaded', () => {
  render(<DataPanel isLoading={false} data={{ title: 'Hello' }} />)
  expect(screen.getByText('Hello')).toBeInTheDocument()
  expect(screen.queryByRole('status')).not.toBeInTheDocument()
})
```

### Loading States and Suspense

```tsx
test('shows skeleton while loading', async () => {
  render(
    <Suspense fallback={<div data-testid="skeleton">Loading...</div>}>
      <AsyncData fetcher={() => new Promise(() => {})} />
    </Suspense>
  )

  expect(screen.getByTestId('skeleton')).toBeInTheDocument()
})
```

## Pattern Comparison

| Pattern | Browser Mode | jsdom Mode |
|---------|-------------|------------|
| Render | `await render(<Comp />)` | `render(<Comp />)` |
| Screen | Returned from render | Global `screen` |
| Assertion | `expect.element(el).toBeVisible()` | `expect(el).toBeInTheDocument()` |
| Query failure | Auto-retries | Throws immediately |
| User input | `el.fill()`, `el.click()` | `user.type()`, `user.click()` |
| Cleanup | Before each test (auto) | After each test (auto) |
| act() | Not needed | Handled by RTL automatically |

## Anti-Patterns

1. **beforeEach render** -- Makes tests implicit and coupled. Use factory functions instead.
2. **Testing internal state** -- Test what the user sees, not component state variables.
3. **Manual act() wrapping** -- RTL and Browser Mode handle this automatically.
4. **Manual cleanup() calls** -- Automatic in both modes since RTL 9.
5. **Shallow rendering** -- Always render the full component tree. Shallow rendering misses real integration bugs.
