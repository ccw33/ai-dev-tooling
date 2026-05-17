#!/usr/bin/env bash
# install-rules.sh — Install behavioral discipline rules for omo-openspec-tdd
#
# Usage (run from ANY directory):
#   bash /path/to/dev-tooling/rules/install-rules.sh

set -euo pipefail

RULES_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$HOME/.sisyphus/rules"

if [[ ! -f "$RULES_DIR/delegation-guardrails.md" ]]; then
  echo "❌ Cannot find rules in: $RULES_DIR"
  echo ""
  echo "Run with the full path to dev-tooling:"
  echo "  bash /path/to/dev-tooling/rules/install-rules.sh"
  exit 1
fi

RULES="delegation-guardrails.md
tdd-iron-law.md
two-stage-review.md
evidence-before-completion.md"

mkdir -p "$TARGET_DIR"

installed=0
updated=0
skipped=0

for rule in $RULES; do
  src="$RULES_DIR/$rule"
  dst="$TARGET_DIR/$rule"

  if [[ ! -f "$src" ]]; then
    echo "⚠️  Source not found: $rule (skipping)"
    skipped=$((skipped + 1))
    continue
  fi

  if [[ -f "$dst" ]]; then
    if diff -q "$src" "$dst" > /dev/null 2>&1; then
      echo "✅ Already up-to-date: $rule"
      skipped=$((skipped + 1))
    else
      cp "$src" "$dst"
      echo "🔄 Updated: $rule"
      updated=$((updated + 1))
    fi
  else
    cp "$src" "$dst"
    echo "✨ Installed: $rule"
    installed=$((installed + 1))
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Target: $TARGET_DIR"
echo "Installed: $installed | Updated: $updated | Unchanged: $skipped"
echo ""

if [[ -f "$TARGET_DIR/delegation-guardrails.md" ]]; then
  echo "✅ All rules in place. Restart OmO session to activate."
else
  echo "⚠️  Something went wrong — delegation-guardrails.md missing from $TARGET_DIR"
  exit 1
fi
