#!/bin/bash
# validate-refs.sh — 校验 AGENTS.md 中 file:line 引用是否还存在
# 用途：OpenCode experimental.hook.file_edited 触发，或 git pre-commit 触发
# 退出码：0 = 全部通过，1 = 有断裂引用
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# 允许通过环境变量覆盖扫描范围
SCAN_DIR="${SCAN_DIR:-$PROJECT_ROOT}"
ERRORS=0
WARNINGS=0

# 颜色输出（CI 环境下禁用）
if [ -t 1 ] && [ "${NO_COLOR:-}" != "1" ]; then
  RED='\033[0;31m'
  YELLOW='\033[0;33m'
  GREEN='\033[0;32m'
  NC='\033[0m'
else
  RED=''
  YELLOW=''
  GREEN=''
  NC=''
fi

# 查找所有文档文件（AGENTS.md + README.md，排除 node_modules 等）
DOC_FILES=$(find "$SCAN_DIR" \
  \( -name "AGENTS.md" -o -name "README.md" \) \
  -not -path "*/node_modules/*" \
  -not -path "*/.git/*" \
  -not -path "*/vendor/*" \
  2>/dev/null || true)

if [ -z "$DOC_FILES" ]; then
  exit 0
fi

for doc_file in $DOC_FILES; do
  refs=$(grep -oE '[a-zA-Z0-9_./-]+\.[a-zA-Z0-9]+:[0-9]+' "$doc_file" 2>/dev/null || true)

  if [ -z "$refs" ]; then
    continue
  fi

  doc_dir="$(dirname "$doc_file")"

  while IFS= read -r ref; do
    file_part=$(echo "$ref" | rev | cut -d: -f2- | rev)
    line_part=$(echo "$ref" | rev | cut -d: -1 | rev)

    resolved_file="$doc_dir/$file_part"

    if [ ! -f "$resolved_file" ]; then
      resolved_file="$SCAN_DIR/$file_part"
    fi

    if [ ! -f "$resolved_file" ]; then
      echo -e "${RED}✗ $doc_file: 引用文件不存在 — $ref${NC}"
      ERRORS=$((ERRORS + 1))
      continue
    fi

    # 检查行号是否越界
    total_lines=$(wc -l < "$resolved_file" | tr -d ' ')
    if [ "$line_part" -gt "$total_lines" ]; then
      echo -e "${YELLOW}⚠ $doc_file: 行号越界 — $ref（文件只有 $total_lines 行）${NC}"
      WARNINGS=$((WARNINGS + 1))
      continue
    fi

  done <<< "$refs"
done

# 汇总报告
if [ "$ERRORS" -gt 0 ] || [ "$WARNINGS" -gt 0 ]; then
  echo ""
  echo -e "${RED}引用校验结果: ${ERRORS} 个错误, ${WARNINGS} 个警告${NC}"
  if [ "$ERRORS" -gt 0 ]; then
    exit 1
  fi
else
  # 静默成功（不污染 hook 输出）
  exit 0
fi
