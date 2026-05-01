# Common Documentation Drift Patterns

Patterns to watch for during Phase 2 semantic scanning. AI should recognize these and fix them.

## Pattern 1: Library Swap

**Signal**: AGENTS.md mentions a library, package.json has a different one.
**Example**: Doc says "uses Moment.js for dates", code now uses `date-fns`.
**Fix**: Update the library name and any version info.

## Pattern 2: Command Evolution

**Signal**: AGENTS.md records a build/test command, but the script has changed.
**Example**: Doc says `npm run test`, package.json now has `vitest run`.
**Fix**: Update the command. Check if flags changed too.

## Pattern 3: Module Birth/Death

**Signal**: docs/architecture.md lists modules, actual src/ has different set.
**Example**: Doc lists 3 modules (auth, api, core), code has 5 (auth, api, core, workers, scheduler).
**Fix**: Add new modules with brief description. Remove dead modules.

## Pattern 4: Layer Violation Normalized

**Signal**: AGENTS.md says "X must not import Y", but grep finds systematic violations.
**Example**: Rule says "data layer must not import api types", but 20+ files do it.
**Fix**: The codebase evolved. Update the rule to reflect reality, or add nuance (e.g., "data layer must not import API handlers, but may import shared type definitions").

## Pattern 5: Environment Variable Drift

**Signal**: AGENTS.md lists required env vars, .env.example or config has different set.
**Example**: Doc says `DATABASE_URL` is required, code now uses `DB_HOST` + `DB_PORT` + `DB_NAME`.
**Fix**: Update the env var list. NEVER include actual values.

## Pattern 6: Stale ADR

**Signal**: ADR says "we chose X because Y", but code has already migrated to Z.
**Example**: ADR 003 says "use REST API", code now uses GraphQL.
**Fix**: Append `## Superseded` section to the ADR explaining when and why the decision changed. Do NOT delete the ADR — it's a historical record.

## Pattern 7: API Endpoint Drift

**Signal**: docs/api-contracts.md references endpoints, actual routes differ.
**Example**: Doc says `POST /api/users`, routes now use `POST /api/v2/users`.
**Fix**: Update endpoint paths. If versioned, note the version change.

## Pattern 8: Dependency Version Mismatch

**Signal**: AGENTS.md says "React 18", package.json has "react": "^19.0.0".
**Fix**: Update major version references. Minor/patch versions usually not worth tracking.

## Pattern 9: File Reference Shift

**Signal**: `filename:line` reference points to wrong content (line shifted).
**Fix**: Find the correct line with matching content, update the line number.

## Pattern 10: Dead Documentation

**Signal**: A doc section describes a feature/module that no longer exists anywhere in code.
**Fix**: Remove the section entirely. Add a brief note if the removal might surprise someone.
