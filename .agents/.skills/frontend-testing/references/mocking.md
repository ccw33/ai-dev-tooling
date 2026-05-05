---
name: mocking
description: >
  Mocking patterns for Vitest frontend tests. Covers vi.fn/vi.mock/vi.spyOn,
  MSW (Mock Service Worker) for API mocking, module mocking (next/navigation, external
  packages), timer mocking, and Zustand store testing.
  Use when: mocking functions, APIs, modules, or state in tests.
  Triggers: "vi.fn", "vi.mock", "MSW", "mock service worker", "spy", "module mock",
  "zustand test", "timer mock".
---

# Mocking Patterns

> Source: [SKILL.md](../SKILL.md)


> Source: [SKILL.md](../SKILL.md)

Always use `vi.*` APIs. Never use `jest.*`.

## vi.fn() -- Function Mocks

```typescript
test('calls onClick when button clicked', async () => {
  const onClick = vi.fn()
  const screen = await render(<Button onClick={onClick}>Click me</Button>)

  await screen.getByRole('button').click()

  expect(onClick).toHaveBeenCalledOnce()
  expect(onClick).toHaveBeenCalledWith(expect.any(MouseEvent))
})
```

### Return Values and Implementations

```typescript
const mockFn = vi.fn().mockReturnValue(42)
const mockFn2 = vi.fn().mockImplementation((x: number) => x * 2)
const mockFn3 = vi.fn().mockResolvedValue({ data: 'ok' })
const mockFn4 = vi.fn().mockRejectedValue(new Error('fail'))
```

## vi.mock() -- Module Mocking

### Auto-Hoisted Module Mock

```typescript
vi.mock('next/navigation', () => ({
  useRouter: () => ({
    push: vi.fn(),
    replace: vi.fn(),
    back: vi.fn(),
  }),
  useSearchParams: () => new URLSearchParams('foo=bar'),
  useParams: () => ({ id: '123' }),
}))
```

### Mocking External Packages

```typescript
vi.mock('lodash/debounce', () => ({
  default: vi.fn((fn: Function) => fn),
}))

vi.mock('date-fns', async () => {
  const actual = await vi.importActual('date-fns')
  return {
    ...actual,
    format: vi.fn(() => '2025-01-01'),
  }
})
```

### Partial Mock with importActual

```typescript
vi.mock('./api', async () => {
  const actual = await vi.importActual('./api')
  return {
    ...actual,
    fetchUser: vi.fn().mockResolvedValue({ id: 1, name: 'Mock User' }),
  }
})
```

## vi.spyOn() -- Method Spies

```typescript
test('logs error when fetch fails', async () => {
  const consoleError = vi.spyOn(console, 'error').mockImplementation(() => {})

  render(<ErrorReportingComponent />)
  await userEvent.click(screen.getByRole('button', { name: /trigger error/i }))

  expect(consoleError).toHaveBeenCalledWith('Fetch failed:', expect.any(Error))
  consoleError.mockRestore()
})
```

## MSW -- API Mocking

Mock Service Worker intercepts network requests at the browser level. Prefer this
for API mocking over mocking fetch/axios directly.

### Setup

```typescript
import { http, HttpResponse } from 'msw'
import { setupServer } from 'msw/node'

const handlers = [
  http.get('/api/users/:id', ({ params }) => {
    return HttpResponse.json({ id: params.id, name: 'Alice' })
  }),

  http.post('/api/users', async ({ request }) => {
    const body = await request.json()
    return HttpResponse.json({ id: 1, ...body }, { status: 201 })
  }),
]

const server = setupServer(...handlers)

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())
```

### Overriding Per Test

```typescript
test('shows error when API returns 500', async () => {
  server.use(
    http.get('/api/users/1', () => {
      return HttpResponse.json(
        { error: 'Internal Server Error' },
        { status: 500 }
      )
    })
  )

  render(<UserProfile userId="1" />)
  expect(await screen.findByText(/error loading user/i)).toBeInTheDocument()
})
```

### Simulating Network Delay

```typescript
test('shows loading state during slow API', async () => {
  server.use(
    http.get('/api/data', async () => {
      await delay(2000)
      return HttpResponse.json({ items: [] })
    })
  )

  render(<DataList />)
  expect(screen.getByRole('status')).toBeInTheDocument()
})
```

## Timer Mocking

```typescript
test('auto-refreshes data every 30 seconds', () => {
  vi.useFakeTimers()
  const refreshData = vi.fn()
  render(<AutoRefresh interval={30000} onRefresh={refreshData} />)

  vi.advanceTimersByTime(30000)
  expect(refreshData).toHaveBeenCalledTimes(1)

  vi.advanceTimersByTime(30000)
  expect(refreshData).toHaveBeenCalledTimes(2)

  vi.useRealTimers()
})
```

## Zustand Store Testing

Do NOT mock Zustand stores. Use `setState` to set up test state and test real behavior.

```typescript
import { useStore } from './store'

test('adds item to cart', () => {
  // Set up initial state
  useStore.setState({ cart: [] })

  render(<AddToCartButton productId="abc" />)

  fireEvent.click(screen.getByRole('button', { name: /add to cart/i }))

  const state = useStore.getState()
  expect(state.cart).toContainEqual({ productId: 'abc', quantity: 1 })
})

test('shows empty cart message', () => {
  useStore.setState({ cart: [] })
  render(<CartSummary />)

  expect(screen.getByText(/your cart is empty/i)).toBeInTheDocument()
})
```

## Mocking Decision Tree

```
Need to isolate something?
  |
  +-- A function passed as prop?
  |     -> vi.fn()
  |
  +-- An entire module?
  |     -> vi.mock('module-name')
  |
  +-- A specific method on an object?
  |     -> vi.spyOn(object, 'method')
  |
  +-- An API endpoint?
  |     -> MSW (setupServer for jsdom, setupWorker for browser)
  |
  +-- A Zustand store?
        -> DO NOT mock. Use store.setState() instead.
```
