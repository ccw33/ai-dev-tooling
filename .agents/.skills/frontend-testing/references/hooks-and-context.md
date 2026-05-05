---
name: hooks-and-context
description: >
  Testing React hooks, context providers, and forms with Vitest. Covers renderHook
  for both Browser Mode and jsdom, context provider testing with wrapper option,
  multiple providers, and form testing patterns.
  Use when: testing custom hooks, context providers, or form components.
  Triggers: "renderHook", "hook test", "context test", "form test", "provider test".
---

# Hooks, Context, and Forms Testing

> Source: [SKILL.md](../SKILL.md)

> Source: [SKILL.md](../SKILL.md)

## Custom Hooks with renderHook

### Browser Mode

```tsx
import { renderHook, act } from 'vitest-browser-react'

test('toggles boolean value', async () => {
  const { result } = await renderHook(() => useToggle(false))

  expect(result.current.value).toBe(false)

  await act(() => {
    result.current.toggle()
  })

  expect(result.current.value).toBe(true)
})
```

### jsdom Mode

```tsx
import { renderHook, act } from '@testing-library/react'

test('toggles boolean value', () => {
  const { result } = renderHook(() => useToggle(false))

  expect(result.current.value).toBe(false)

  act(() => {
    result.current.toggle()
  })

  expect(result.current.value).toBe(true)
})
```

### Hook with Async Logic

```tsx
// Browser Mode
test('fetches data on mount', async () => {
  const { result } = await renderHook(() => useUser(1))

  // Wait for loading to finish
  await waitFor(() => {
    expect(result.current.user?.name).toBe('Alice')
  })

  expect(result.current.isLoading).toBe(false)
  expect(result.current.error).toBeNull()
})
```

## Context Providers

### Direct Wrapping in Test

For simple cases, wrap the component directly.

```tsx
// Browser Mode
test('shows user menu when authenticated', async () => {
  const screen = await render(
    <AuthProvider initialUser={{ name: 'Alice', role: 'admin' }}>
      <Dashboard />
    </AuthProvider>
  )

  await expect.element(screen.getByRole('button', { name: /user menu/i })).toBeVisible()
})
```

### Using wrapper Option (jsdom)

For repeated context wrapping across multiple tests, use the `wrapper` option.

```tsx
function createWrapper(user?: User) {
  return function Wrapper({ children }: { children: React.ReactNode }) {
    return (
      <AuthProvider initialUser={user}>
        <ThemeProvider>
          {children}
        </ThemeProvider>
      </AuthProvider>
    )
  }
}

test('renders dashboard for admin', () => {
  render(<Dashboard />, { wrapper: createWrapper({ name: 'Alice', role: 'admin' }) })
  expect(screen.getByText('Admin Panel')).toBeInTheDocument()
})

test('shows restricted message for viewer', () => {
  render(<Dashboard />, { wrapper: createWrapper({ name: 'Bob', role: 'viewer' }) })
  expect(screen.getByText('Access Restricted')).toBeInTheDocument()
})
```

### Multiple Providers Pattern

Stack providers that components depend on.

```tsx
function AllProviders({ children }: { children: React.ReactNode }) {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider initialUser={mockUser}>
        <RouterProvider router={router}>
          {children}
        </RouterProvider>
      </AuthProvider>
    </QueryClientProvider>
  )
}

// Use as wrapper
render(<MyComponent />, { wrapper: AllProviders })
```

## Form Testing

### Controlled Inputs (Browser Mode)

```tsx
test('validates email format on blur', async () => {
  const screen = await render(<RegistrationForm />)

  const emailInput = screen.getByLabelText(/email/i)
  await emailInput.fill('invalid-email')
  await emailInput.blur()

  await expect.element(screen.getByText(/valid email/i)).toBeVisible()
})
```

### Form Submission (jsdom)

```tsx
test('submits form with valid data', async () => {
  const onSubmit = vi.fn()
  const user = userEvent.setup()
  render(<ContactForm onSubmit={onSubmit} />)

  await user.type(screen.getByLabelText(/name/i), 'Alice')
  await user.type(screen.getByLabelText(/email/i), 'alice@example.com')
  await user.type(screen.getByLabelText(/message/i), 'Hello world')
  await user.click(screen.getByRole('button', { name: /send/i }))

  expect(onSubmit).toHaveBeenCalledWith({
    name: 'Alice',
    email: 'alice@example.com',
    message: 'Hello world',
  })
})
```

### Validation Errors

```tsx
test('shows validation errors for required fields', async () => {
  const user = userEvent.setup()
  render(<RegistrationForm />)

  // Submit empty form
  await user.click(screen.getByRole('button', { name: /register/i }))

  expect(screen.getByText(/name is required/i)).toBeInTheDocument()
  expect(screen.getByText(/email is required/i)).toBeInTheDocument()
  expect(screen.getByText(/password is required/i)).toBeInTheDocument()
})
```

### Disabled State During Submission

```tsx
test('disables submit button while submitting', async () => {
  const user = userEvent.setup()
  render(<ContactForm onSubmit={() => new Promise(() => {})} />)

  await user.type(screen.getByLabelText(/name/i), 'Alice')
  await user.type(screen.getByLabelText(/email/i), 'a@b.com')
  await user.click(screen.getByRole('button', { name: /send/i }))

  expect(screen.getByRole('button', { name: /sending/i })).toBeDisabled()
})
```
