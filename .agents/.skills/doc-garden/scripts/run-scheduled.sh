#!/usr/bin/env bash
# Doc Garden: Scheduled Runner
#
# Reads projects.yaml, runs doc-garden on each enabled project.
# Designed for cron/launchd invocation.
#
# Usage:
#   bash run-scheduled.sh                    # Run all enabled projects
#   bash run-scheduled.sh --project /path    # Run a single project
#   bash run-scheduled.sh --dry-run          # Preview without executing
#
# Setup cron (weekly, Monday 9:00):
#   0 9 * * 1 /bin/bash /path/to/doc-garden/scripts/run-scheduled.sh >> /tmp/doc-garden-cron.log 2>&1
#
# Or use launchd (see doc-garden-launchd.plist.example)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
PROJECTS_FILE="$SKILL_DIR/projects.yaml"
LOG_DIR="/tmp/doc-garden"

mkdir -p "$LOG_DIR"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
info() { log "${GREEN}INFO${NC} $*"; }
warn() { log "${YELLOW}WARN${NC} $*"; }
error() { log "${RED}ERROR${NC} $*"; }

# Parse arguments
DRY_RUN=false
SINGLE_PROJECT=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run) DRY_RUN=true; shift ;;
    --project) SINGLE_PROJECT="$2"; shift 2 ;;
    --help)
      echo "Usage: $0 [--dry-run] [--project /path/to/project]"
      echo "  --dry-run    Preview without executing"
      echo "  --project    Run for a single project only"
      exit 0
      ;;
    *) error "Unknown argument: $1"; exit 1 ;;
  esac
done

# Check dependencies
if ! command -v opencode &>/dev/null; then
  error "opencode not found in PATH"
  exit 1
fi

if ! command -v python3 &>/dev/null; then
  error "python3 not found in PATH"
  exit 1
fi

# Extract project paths from YAML (simple parser, no dependency needed)
parse_projects() {
  local yaml_file="$1"
  local in_projects=false
  local capturing=false

  while IFS= read -r line; do
    # Skip comments
    [[ "$line" =~ ^[[:space:]]*# ]] && continue

    if [[ "$line" =~ ^projects: ]]; then
      in_projects=true
      continue
    fi

    if $in_projects; then
      # Check for enabled: false
      if [[ "$line" =~ enabled:[[:space:]]*false ]]; then
        capturing=false
        continue
      fi

      # Check for path: line
      if [[ "$line" =~ path:[[:space:]]*(.*) ]]; then
        local path="${BASH_REMATCH[1]}"
        path="${path%\"}"  # Remove trailing quote
        path="${path#\"}"  # Remove leading quote
        path="${path%\'}"  # Remove trailing single quote
        path="${path#\'}"  # Remove leading single quote
        path="${path% }"   # Remove trailing space

        # Only output if not explicitly disabled
        if [[ ! "$line" =~ enabled:[[:space:]]*false ]]; then
          echo "$path"
        fi
      fi
    fi
  done < "$yaml_file"
}

# Collect projects to process
declare -a PROJECTS=()

if [[ -n "$SINGLE_PROJECT" ]]; then
  PROJECTS+=("$SINGLE_PROJECT")
else
  if [[ ! -f "$PROJECTS_FILE" ]]; then
    error "projects.yaml not found at $PROJECTS_FILE"
    exit 1
  fi

  while IFS= read -r proj; do
    [[ -z "$proj" ]] && continue
    PROJECTS+=("$proj")
  done < <(parse_projects "$PROJECTS_FILE")
fi

if [[ ${#PROJECTS[@]} -eq 0 ]]; then
  warn "No projects found in registry. Edit projects.yaml to add projects."
  exit 0
fi

info "Found ${#PROJECTS[@]} project(s) to scan"

# Process each project
TOTAL_FIXED=0
TOTAL_REVIEW=0

for PROJECT_PATH in "${PROJECTS[@]}"; do
  PROJECT_NAME="$(basename "$PROJECT_PATH")"
  LOG_FILE="$LOG_DIR/${PROJECT_NAME}-$(date '+%Y%m%d-%H%M%S').log"

  if [[ ! -d "$PROJECT_PATH" ]]; then
    warn "Project directory not found: $PROJECT_PATH — skipping"
    continue
  fi

  if [[ ! -f "$PROJECT_PATH/AGENTS.md" ]]; then
    warn "No AGENTS.md in $PROJECT_PATH — skipping (not initialized with Harness Init)"
    continue
  fi

  info "Scanning: $PROJECT_NAME ($PROJECT_PATH)"

  if $DRY_RUN; then
    info "  [DRY RUN] Would run: opencode run --command doc-garden in $PROJECT_PATH"
    continue
  fi

  # Run doc-garden via opencode
  info "  Running doc-garden..."
  if opencode run \
    --command doc-garden \
    --project "$PROJECT_PATH" \
    "Run doc-garden: scan all project docs for stale references, auto-fix safe corrections and semantic drift, report only items needing human review. Follow the doc-garden skill instructions exactly. SKILL_DIR=$SKILL_DIR" \
    > "$LOG_FILE" 2>&1; then

    # Check for REVIEW items in report
    REPORT="$PROJECT_PATH/.sisyphus/doc-garden-report.md"
    if [[ -f "$REPORT" ]]; then
      REVIEW_COUNT=$(grep -c "REVIEW" "$REPORT" 2>/dev/null || echo "0")

      if [[ "$REVIEW_COUNT" -gt 0 ]]; then
        warn "  ⚠ $REVIEW_COUNT item(s) need review in $PROJECT_NAME"
        TOTAL_REVIEW=$((TOTAL_REVIEW + REVIEW_COUNT))

        # Optional: push notification via wechat-push
        # Uncomment the lines below to enable WeChat notifications:
        # if command -v opencode &>/dev/null; then
        #   opencode run --command wechat-push \
        #     "doc-garden: $PROJECT_NAME has $REVIEW_COUNT item(s) needing review" \
        #     --project "$PROJECT_PATH"
        # fi
      else
        info "  ✅ All clear for $PROJECT_NAME"
      fi
    fi
  else
    error "  doc-garden failed for $PROJECT_NAME. See log: $LOG_FILE"
  fi
done

# Summary
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "Scan complete. ${#PROJECTS[@]} project(s) processed."
if [[ $TOTAL_REVIEW -gt 0 ]]; then
  warn "⚠ $TOTAL_REVIEW item(s) across all projects need human review."
else
  info "✅ All issues auto-fixed. No notifications needed."
fi
