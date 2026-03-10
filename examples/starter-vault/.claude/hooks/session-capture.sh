#!/bin/bash
# session-capture.sh — Vault OS v2 compliant
# Fires at SessionEnd (clean exits only — does NOT fire on VS Code tab close)
# Primary capture path is /capture command. This hook is a fallback.

VAULT="${CLAUDE_PROJECT_DIR:?ERROR: CLAUDE_PROJECT_DIR not set — hook must be invoked by Claude Code}"
mkdir -p "$VAULT/ops/sessions"

DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)

# Skip overwrite if /capture already wrote a real summary this session
if grep -q "## What was worked on" "$VAULT/ops/sessions/last-active.md" 2>/dev/null; then
  exit 0
fi

cat > "$VAULT/ops/sessions/last-active.md" << EOF
Date: $DATE $TIME
Source: SessionEnd hook (fallback — /capture not run this session)

Session summary not recorded. Run /capture at session end to write a paragraph-level summary: what was worked on, what was decided, what is in progress, what is blocked. One-line entries cause amnesia in the next session.
EOF
