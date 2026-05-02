#!/bin/bash
# session-doc-check.sh — Session-end doc consistency check
# Triggered by OpenCode experimental.hook.session_completed
# Does: scan→fix (deterministic) + impact detection (warns if docs need AI update)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SCAN_RESULT="$PROJECT_ROOT/scan-result.json"

if [[ ! -f "$PROJECT_ROOT/AGENTS.md" ]]; then
  exit 0
fi

# Phase 1: Deterministic scan + auto-fix
python3 "$SKILL_DIR/scripts/scan.py" --project-root "$PROJECT_ROOT" --output "$SCAN_RESULT" 2>/dev/null || true

FIXED=0
if [[ -f "$SCAN_RESULT" ]]; then
  FIXED=$(python3 "$SKILL_DIR/scripts/fix_refs.py" --project-root "$PROJECT_ROOT" --scan-result "$SCAN_RESULT" --apply 2>&1 | grep -c "FIXED" || true)
  FIXED=${FIXED:-0}
  if [[ "$FIXED" -gt 0 ]]; then
    echo "📝 doc-garden: auto-fixed $FIXED reference(s)"
  fi
  rm -f "$SCAN_RESULT"
fi

# Phase 2: Detect session changes that may need doc updates
# Get files changed in this session (unstaged + staged vs HEAD)
CHANGED_CODE=$(git diff --name-only HEAD 2>/dev/null | grep -E '\.(py|ts|js|go|rs|java)$' || true)
if [[ -z "$CHANGED_CODE" ]]; then
  exit 0
fi

CHANGED_DOCS=$(git diff --name-only HEAD 2>/dev/null | grep -E '(README\.md|AGENTS\.md|docs/|KNOWN_DEBTS\.md)' || true)
CODE_COUNT=$(echo "$CHANGED_CODE" | wc -l | tr -d ' ')

DOC_IMPACT=false

# Check: code changed but no docs touched?
if [[ -n "$CHANGED_CODE" && -z "$CHANGED_DOCS" ]]; then
  DOC_IMPACT=true
fi

# Check: did CLI commands change? (cli.py, build_parser, argparse)
CLI_CHANGED=$(echo "$CHANGED_CODE" | grep -E '(cli\.py|main\.py|commands/|cmd/)' || true)
if [[ -n "$CLI_CHANGED" ]]; then
  DOC_IMPACT=true
fi

# Check: did config/strategy files change?
CONFIG_CHANGED=$(echo "$CHANGED_CODE" | grep -E '(config|strategy|const|setting)' || true)
if [[ -n "$CONFIG_CHANGED" ]]; then
  DOC_IMPACT=true
fi

if [[ "$DOC_IMPACT" == "true" ]]; then
  echo ""
  echo "📋 Session changed $CODE_COUNT code file(s) but no docs were updated."
  echo "   Consider running /timely-doc-garden to check:"
  echo "   - README.md: CLI commands, strategy table, config docs"
  echo "   - AGENTS.md: structure, commands, code map"
  echo "   - docs/: architecture, development guide"
  echo ""
fi
