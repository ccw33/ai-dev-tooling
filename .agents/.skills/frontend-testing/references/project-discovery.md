---
name: project-discovery
description: >
  Guides AI agents through systematic project analysis before writing any frontend tests.
  Covers directory scanning, framework detection, component inventory, complexity-based
  priority ordering, test scenario generation from code analysis, mock strategy, and
  incremental adoption planning.
  Use when: approaching a new or existing project that lacks tests, planning a test suite
  from scratch, figuring out what to test first.
  Triggers: "discover project", "analyze project for tests", "test plan", "what to test",
  "component inventory", "test priority", "项目分析", "测试计划".
---

> Source: [SKILL.md](../SKILL.md)

# Project Discovery for Frontend Testing

Before writing a single test, you need to understand the project. This document
walks through a six-phase discovery pipeline that produces a concrete, ordered
test plan from raw source code.

Skipping this step is the most common cause of wasted effort in test suites.
You end up testing the wrong things first, mocking the wrong boundaries, and
missing the components that actually need coverage.

---

## Phase 1: Project Structure Scan

Goal: map the project's architecture in under two minutes.

### Directory scan

```
src/
  components/    -- UI components
  hooks/         -- custom hooks
  utils/         -- pure functions
  pages/         -- route-level components
  api/           -- network layer
  store/         -- state management
  context/       -- React context providers
```

Not every project follows this layout. Read the top-level `src/` directory,
then one level deeper, to identify the actual conventions.

### Framework detection

Read `package.json` dependencies:

| Dependency present | Framework |
|---|---|
| `next` | Next.js (App Router or Pages Router) |
| `@remix-run/react` | Remix |
| `react-scripts` or `vite` + `react` | CRA or Vite SPA |
| `@tanstack/react-router` | TanStack Router |

Check `next.config.*` to distinguish App Router (`app/` directory) from Pages
Router (`pages/` directory).

### State management detection

Scan `package.json` for:

- `@reduxjs/toolkit` or `redux` -- Redux
- `zustand` -- Zustand
- `jotai` -- Jotai
- None of the above + `createContext` usage in codebase -- React Context

### Routing detection

- `next/navigation` imports -- Next.js App Router
- `next/router` imports -- Next.js Pages Router
- `react-router-dom` -- React Router
- `@tanstack/react-router` -- TanStack Router

### API layer detection

Scan imports for:

- `fetch` (global) or `axios` -- raw HTTP
- `@trpc/react-query` or `@trpc/server` -- tRPC
- `@tanstack/react-query` -- React Query (likely wrapping fetch/axios)
- SWR, Apollo Client, urql -- other data layers

Record the API layer. It determines your mocking strategy later.

---

## Phase 2: Component Inventory

Goal: list every testable unit and categorize by complexity.

### Finding components

Search for files matching `*.tsx` that contain JSX return patterns:

```
grep -rl "return (" --include="*.tsx" src/
grep -rl "=>" --include="*.tsx" src/components/
```

AST-based search is more reliable:

```typescript
// ast-grep pattern for function components
ast_grep_search: "function $NAME($$$) { return $JSX }"
```

### Extracting component metadata

For each component, read the file and extract:

**Props interface:**
```typescript
// Look for interface/type ending with "Props"
interface ButtonProps {
  variant: 'primary' | 'secondary' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  disabled?: boolean;
  onClick?: () => void;
}
```

**Internal state:**
```typescript
// grep for useState, useReducer
const [isOpen, setIsOpen] = useState(false);
const [data, dispatch] = useReducer(reducer, initialState);
```

**Side effects:**
```typescript
// grep for useEffect, useLayoutEffect
useEffect(() => {
  fetchData();
}, [id]);
```

**Event handlers:**
```typescript
// grep for on[A-Z] props and inline handlers
onClick={handleSubmit}
onChange={(e) => setSearch(e.target.value)}
```

**External dependencies:**
```typescript
// scan imports at top of file
import { useAuth } from '@/hooks/useAuth';
import { api } from '@/api/client';
import { useRouter } from 'next/navigation';
```

### Complexity categories

| Category | Criteria | Test approach |
|---|---|---|
| Simple | Presentational, no state, no effects, no external deps | Smoke test: renders without crashing |
| Medium | Has useState or useEffect, no API calls | Test state transitions and effects |
| Complex | API calls, routing, context, or store access | Integration test with mocks |

---

## Phase 3: Complexity-Based Priority

Order your testing effort from easiest to hardest return on investment:

1. **Utility functions** -- pure, no mocks needed, highest confidence per line
2. **Custom hooks** -- isolated logic, test with `renderHook`
3. **Simple components** -- smoke tests, fast to write
4. **Medium components** -- state transitions, event handling
5. **Complex components** -- API mocking, router mocking, context setup
6. **Integration tests** -- multi-component flows, user journeys

**Rule: Process ONE file at a time.** Write the test, run it, see it pass, then
move to the next file. Never batch-write tests across multiple files.

### Priority quick-sort

```
for each file in src/:
  if file has no imports from React/framework:
    priority = 1 (utility)
  else if file exports a function starting with "use":
    priority = 2 (hook)
  else if file is Simple component:
    priority = 3
  else if file is Medium component:
    priority = 4
  else:
    priority = 5 (complex)

sort all files by priority
```

---

## Phase 4: Test Scenario Generation from Code Analysis

Each code pattern in a component maps to specific test scenarios. Extract them
mechanically.

### From TypeScript props interface

```typescript
interface ButtonProps {
  variant: 'primary' | 'secondary' | 'danger';
  disabled?: boolean;
}
```

Generates:
- renders with variant="primary"
- renders with variant="secondary"
- renders with variant="danger"
- renders disabled state when disabled=true
- renders default state when disabled is undefined

### From useState

```typescript
const [isOpen, setIsOpen] = useState(false);
```

Generates:
- starts closed (isOpen = false)
- opens when trigger is clicked
- closes when dismiss action fires

### From useEffect with fetch

```typescript
useEffect(() => {
  fetchUser(id).then(setUser);
}, [id]);
```

Generates:
- shows loading state while fetching
- renders data on successful fetch
- shows error state on failed fetch
- re-fetches when id changes

### From event handlers

```typescript
const handleSubmit = (e: FormEvent) => {
  e.preventDefault();
  onSubmit(formData);
};
```

Generates:
- calls onSubmit with form data when form is submitted
- prevents default form behavior

### From conditional rendering

```typescript
{isLoading && <Spinner />}
{error && <ErrorMessage error={error} />}
{data && <DataDisplay data={data} />}
```

Generates:
- shows spinner when loading
- shows error message when error exists
- shows data when loaded
- shows nothing when loading is done and no data

### From optional props

```typescript
interface ListProps {
  items?: Item[];
  emptyMessage?: string;
}
```

Generates:
- renders list when items provided
- renders empty state when items is undefined
- renders custom empty message when provided
- renders default empty state when no emptyMessage

---

## Phase 5: Mock Strategy from Dependencies

Read the imports of each component to determine what needs mocking.

### Mock decision matrix

| Import pattern | Mock strategy |
|---|---|
| `import { api } from '@/api'` | MSW (network-level) or `vi.mock('@/api')` |
| `import { useAuth } from '@/hooks'` | `vi.mock('@/hooks/useAuth')` with return value |
| `import { useRouter } from 'next/navigation'` | `vi.mock('next/navigation')` with push/replace |
| `import { useStore } from '@/store'` | Real store with `store.setState()` for test data |
| `import { useQuery } from '@tanstack/react-query'` | Wrap in `QueryClientProvider` with real client |
| `import { format } from 'date-fns'` | No mock needed (pure function) |
| `import { motion } from 'framer-motion'` | `vi.mock('framer-motion')` to skip animations |

### Boundary rule

Mock at the edges of your system: network requests, browser APIs, external
services. Do not mock internal utility functions or pure logic. If you find
yourself mocking a function that has no side effects, test it directly instead.

### Common mock templates

```typescript
// Next.js router
vi.mock('next/navigation', () => ({
  useRouter: () => ({
    push: vi.fn(),
    replace: vi.fn(),
    back: vi.fn(),
    pathname: '/test',
  }),
  useSearchParams: () => new URLSearchParams(),
}));

// Auth hook
vi.mock('@/hooks/useAuth', () => ({
  useAuth: () => ({
    user: { id: '1', name: 'Test User' },
    isAuthenticated: true,
    login: vi.fn(),
    logout: vi.fn(),
  }),
}));

// API module
vi.mock('@/api/client', () => ({
  api: {
    get: vi.fn().mockResolvedValue({ data: {} }),
    post: vi.fn().mockResolvedValue({ data: {} }),
  },
}));
```

---

## Phase 6: Incremental Adoption Plan

Combine the priority list from Phase 3 with the scenario list from Phase 4
into a concrete, time-boxed plan.

### Output format

```
## Test Adoption Plan for [project-name]

### Phase 1 -- Smoke tests (Day 1)
Goal: 5 core components render without crashing
- [ ] src/components/Button/Button.test.tsx
- [ ] src/components/Input/Input.test.tsx
- [ ] src/components/Modal/Modal.test.tsx
- [ ] src/components/Card/Card.test.tsx
- [ ] src/components/Layout/Layout.test.tsx

### Phase 2 -- Critical paths (Week 1)
Goal: test the main user flows
- [ ] src/hooks/useAuth.test.ts (auth state transitions)
- [ ] src/pages/Login.test.tsx (form submission, validation)
- [ ] src/pages/Dashboard.test.tsx (data loading, display)
- [ ] src/components/SearchBar.test.tsx (input, debounce, results)

### Phase 3 -- Edge cases (Ongoing)
Goal: cover error states, empty data, boundary values
- [ ] Error boundary behavior
- [ ] Empty list states
- [ ] Network failure handling
- [ ] Concurrent state updates
```

### Plan generation rules

- Each test file name matches the source file with `.test` before the extension.
- Phase 1 files come from the Simple category (priority 3).
- Phase 2 files come from Medium and Complex categories (priority 4-5) plus
  hooks (priority 2) that support critical flows.
- Phase 3 fills gaps found during Phase 2 review.
- Never plan more than 5 test files per phase. Small batches keep momentum.

---

## Human Checkpoints

AI cannot know business context. These gates require human judgment:

### Checkpoint 1: Review Test Plan (after Phase 6)

Present the test adoption plan to the developer for confirmation:

- **Priority ordering**: AI ranks by code complexity, but only humans know which
  components are revenue-critical. Reorder if needed.
- **Missing flows**: AI can only analyze code structure. If the app has business
  rules not visible in code (e.g., "promo codes expire at midnight"), the human
  must add them to the test plan.
- **Scope decision**: Approve the planned phases or trim/skip based on timeline.

**Action**: Do NOT proceed to write tests until the human confirms the plan.

### Checkpoint 2: Review Test Code (after each phase)

AI-generated tests commonly suffer from:

- Tautological assertions (`expect(true).toBe(true)` disguised behind variables)
- Testing implementation details instead of behavior
- Over-mocking that makes tests trivially pass
- Missing edge cases the code hints at but AI didn't catch

**Action**: After each phase of tests is written, present the test file to the
human for review. Highlight any test where the assertion is weak (e.g., `toBeDefined()`
on a value that should have a specific shape).

### Checkpoint 3: Mutation Testing Review (after StrykerJS)

When StrykerJS reports low mutation scores:

- **Low score (< 60)**: Tests are likely not asserting meaningful behavior. Human
  must decide: fix the tests, or is the code genuinely simple enough that no
  assertion would catch the mutation?
- **Survived mutations**: Review each one. Some are false positives (e.g., changing
  a string literal that has no functional impact). Humans must triage.
- **Timeout mutations**: Usually indicate flaky async tests. Human must decide
  whether to fix the test or mark as known limitation.

**Action**: Do NOT declare testing complete until the human has reviewed the
mutation report and accepted the final score.

---

## Discovery Checklist

Before writing the first test, confirm you have:

- [ ] Identified the framework and render mode (Browser Mode vs jsdom)
- [ ] Mapped the directory structure and conventions
- [ ] Listed all components with their complexity category
- [ ] Generated test scenarios from TypeScript types and code patterns
- [ ] Determined mock strategy based on imports
- [ ] Produced a phased test plan ordered by priority
- [ ] **Human confirmed the test plan (Checkpoint 1)**
