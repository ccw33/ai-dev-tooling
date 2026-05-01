#!/bin/bash
# 对比代码 commit 时间 vs 文档修改时间，超过阈值 + N 次 commit 则警告
# 增强：先 scan → fix 自动修复，再告警修不了的 (能修则修)
# pre-push 触发，只警告不阻断
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SCAN_RESULT="$PROJECT_ROOT/scan-result.json"

# Phase 1: Scan for broken/shifted refs
if command -v python3 &>/dev/null; then
  python3 "$SKILL_DIR/scripts/scan.py" --project-root "$PROJECT_ROOT" --output "$SCAN_RESULT" 2>/dev/null || true

  # Phase 2: Auto-fix safe corrections (path renames, line shifts)
  if [ -f "$SCAN_RESULT" ]; then
    FIXED=$(python3 "$SKILL_DIR/scripts/fix_refs.py" --project-root "$PROJECT_ROOT" --scan-result "$SCAN_RESULT" --apply 2>&1 | grep -c "FIXED" || true)
    if [ "${FIXED:-0}" -gt 0 ]; then
      echo "📝 doc-garden: auto-fixed $FIXED reference(s)"
    fi
    rm -f "$SCAN_RESULT"
  fi
fi

# Phase 3: Warn about remaining issues (needs AI or human review)
bash "$SKILL_DIR/scripts/validate-refs.sh" 2>/dev/null | grep -E "^(✗|⚠)" || true

exit 0  # 只警告，不阻断
