---
name: harness-doc-garden
description: >
  One-time installation of the doc-code consistency maintenance infrastructure
  for a project. Sets up three-layer hooks (OpenCode hooks, git hooks, cron/launchd),
  registers the project for scheduled scanning, and runs a validation pass.
  Use when: setting up doc-garden for a NEW project that already has AGENTS.md from
  Harness Init (step 4 of Harness: 维护). NOT for repeated use — run once per project.
  Triggers: "setup doc garden", "install doc garden", "harness doc garden",
  "配置文档维护", "安装文档维护", "初始化文档维护".
---

# Harness Doc Garden: Install Maintenance Infrastructure

You are installing the doc-code consistency maintenance layer for a project.
This is a one-time setup. After this, `timely-doc-garden` runs automatically via hooks and scheduled scans.

## Prerequisites

Confirm BEFORE proceeding:
1. Project has `AGENTS.md` at root (from Harness Init `/init-deep`)
2. `opencode` is available in PATH
3. `python3` is available in PATH
4. The `timely-doc-garden` skill exists (check `.agents/.skills/timely-doc-garden/SKILL.md`)

If any prerequisite fails, stop and report what's missing.

## Installation Steps

Execute all steps in order. Report progress after each step.

### Step 1: Register Project

Append the current project to `projects.yaml`:

```yaml
# In .agents/.skills/timely-doc-garden/projects.yaml
  - path: <current-project-absolute-path>
    schedule: weekly
    enabled: true
```

Use the project's absolute path. Detect it with `git rev-parse --show-toplevel` or `pwd`.
Do NOT overwrite existing entries — only append if not already registered.

### Step 2: OpenCode Hooks (Layer 1)

Read the current `opencode.json` (project-level `.opencode/opencode.json` if exists, otherwise `~/.config/opencode/opencode.json`).

Add `experimental.hook` configuration:

```jsonc
{
  "experimental": {
    "hook": {
      "file_edited": {
        "Write|Edit|MultiEdit": [
          {
            "command": [
              "bash",
              "<SKILL_DIR>/scripts/validate-refs.sh"
            ],
            "environment": { "TRIGGER": "file_edited" }
          }
        ]
      },
      "session_completed": [
        {
          "command": [
            "bash",
            "<SKILL_DIR>/scripts/session-doc-check.sh"
          ],
          "environment": { "TRIGGER": "session_completed" }
        }
      ]
    }
  }
}
```

Replace `<SKILL_DIR>` with the absolute path to `.agents/.skills/timely-doc-garden/`.
Merge into existing config — do NOT overwrite other settings.
If `experimental.hook` already exists, skip this step and report.

### Step 3: Git Hooks (Layer 2)

Create `.githooks/` directory in the project root and set up hooks:

```bash
mkdir -p .githooks

# pre-commit
cat > .githooks/pre-commit << 'EOF'
#!/bin/bash
bash <SKILL_DIR>/scripts/validate-refs.sh
EOF

# pre-push
cat > .githooks/pre-push << 'EOF'
#!/bin/bash
# Doc Garden: scan → auto-fix → warn remaining (能修则修, non-blocking)
SKILL_DIR="<SKILL_DIR>"
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SCAN_RESULT="$PROJECT_ROOT/scan-result.json"

# Phase 1: Scan for broken/shifted refs
python3 "$SKILL_DIR/scripts/scan.py" --project-root "$PROJECT_ROOT" --output "$SCAN_RESULT" 2>/dev/null || true

# Phase 2: Auto-fix safe corrections (path renames, line shifts)
if [ -f "$SCAN_RESULT" ]; then
  FIXED=$(python3 "$SKILL_DIR/scripts/fix_refs.py" --project-root "$PROJECT_ROOT" --scan-result "$SCAN_RESULT" --apply 2>&1 | grep -c "FIXED" || true)
  if [ "${FIXED:-0}" -gt 0 ]; then
    echo "📝 doc-garden: auto-fixed $FIXED reference(s)"
  fi
  rm -f "$SCAN_RESULT"
fi

# Phase 3: Warn about remaining issues needing AI/human review
bash "$SKILL_DIR/scripts/validate-refs.sh" 2>/dev/null | grep -E "^(✗|⚠)" || true

exit 0  # Non-blocking: never block push
EOF

chmod +x .githooks/pre-commit .githooks/pre-push
git config core.hooksPath .githooks
```

Replace `<SKILL_DIR>` with the actual absolute path.

If the project already uses Husky (`.husky/` exists), use Husky instead:
```bash
npx husky add .husky/pre-commit "bash <SKILL_DIR>/scripts/validate-refs.sh"
```

### Step 4: Scheduled Scan (Layer 3, macOS)

Create launchd plist for weekly scheduled scan:

```bash
PLIST=~/Library/LaunchAgents/com.opencode.timely-doc-garden-<project-name>.plist

cat > "$PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.opencode.timely-doc-garden-<project-name></string>

    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string><SKILL_DIR>/scripts/run-scheduled.sh</string>
    </array>

    <key>WorkingDirectory</key>
    <string><SKILL_DIR></string>

    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key>
        <integer>1</integer>
        <key>Hour</key>
        <integer>9</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>

    <key>StandardOutPath</key>
    <string>/tmp/timely-doc-garden-stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/timely-doc-garden-stderr.log</string>

    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin</string>
    </dict>
</dict>
</plist>
EOF

launchctl load "$PLIST"
```

Replace `<project-name>` with the directory name of the project.
Replace `<SKILL_DIR>` with the absolute path.

### Step 5: Validation Run

Run a single doc-garden scan to verify everything works:

```bash
bash <SKILL_DIR>/scripts/run-scheduled.sh --project <project-path>
```

Check that:
- No errors in output
- `.sisyphus/doc-garden-report.md` was generated

## Summary Report

After all steps, print:

```
✅ harness-doc-garden setup complete for <project-name>

Installed:
  - Layer 1: OpenCode hooks (file_edited + session_completed)
  - Layer 2: Git hooks (pre-commit + pre-push)
  - Layer 3: launchd weekly scan (Monday 09:00)

Project registered in: .agents/.skills/timely-doc-garden/projects.yaml
Report location: .sisyphus/doc-garden-report.md

Doc-garden will also keep KNOWN_DEBTS.md (from /harness-gate) fresh:
  - Weekly scans check debt references for stale file:line
  - Pre-push auto-fixes path renames and line shifts in KNOWN_DEBTS.md

Scanning scope: AGENTS.md, README.md, docs/**/*.md, .sisyphus/rules/*.md, KNOWN_DEBTS.md
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `opencode.json` already has `experimental.hook` | Merge manually — don't overwrite |
| Husky already installed | Use Husky instead of `.githooks` |
| launchctl load fails | Check plist syntax with `plutil -lint` |
| Validation run fails | Check logs in `/tmp/timely-doc-garden-stderr.log` |
