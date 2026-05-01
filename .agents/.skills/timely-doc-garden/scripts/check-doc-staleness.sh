#!/bin/bash
# 对比代码 commit 时间 vs 文档修改时间，超过阈值 + N 次 commit 则警告
# pre-push 触发，只警告不阻断
set -euo pipefail

DOCS=("AGENTS.md" "CLAUDE.md")
WATCH_DIRS=("src/" "lib/")
THRESHOLD_DAYS=30
MIN_COMMITS=5

for doc in "${DOCS[@]}"; do
  [ -f "$doc" ] || continue

  doc_date=$(git log -1 --format="%ct" -- "$doc" 2>/dev/null || echo 0)
  code_date=$(git log -1 --format="%ct" -- "${WATCH_DIRS[@]}" 2>/dev/null || echo 0)

  if [ "$code_date" -gt "$doc_date" ]; then
    days_stale=$(( (code_date - doc_date) / 86400 ))
    commits_since=$(git log --format="%H" -- "${WATCH_DIRS[@]}" \
        --since="@${doc_date}" 2>/dev/null | wc -l | tr -d ' ')

    if [ "$days_stale" -gt "$THRESHOLD_DAYS" ] && [ "$commits_since" -gt "$MIN_COMMITS" ]; then
      echo "⚠️  $doc 可能已过期（$days_stale 天未更新，$commits_since 次代码提交）"
    fi
  fi
done

exit 0  # 只警告，不阻断
