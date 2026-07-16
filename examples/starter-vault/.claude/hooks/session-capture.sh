#!/bin/bash
# session-capture.sh — Vault OS v2 compliant
# vault-os-hook-version: 4.0.0
# Fires at SessionEnd (clean exits only — does NOT fire on VS Code tab close)
# Primary capture path is /capture command. This hook is a fallback.

# --- Selftest mode: verify this hook's own dependencies, loudly ---
if [ "${1:-}" = "--selftest" ]; then
  SELFTEST_FAIL=0

  if TODAY_CHECK=$(date +%Y-%m-%d 2>/dev/null) && [ -n "$TODAY_CHECK" ] && TIME_CHECK=$(date +%H:%M 2>/dev/null) && [ -n "$TIME_CHECK" ]; then
    echo "PASS: date +%Y-%m-%d / +%H:%M format (${TODAY_CHECK} ${TIME_CHECK})"
  else
    echo "FAIL: date +%Y-%m-%d or +%H:%M produced no output — cannot stamp session record"
    SELFTEST_FAIL=1
  fi

  if printf '## What was worked on\n' | grep -q "## What was worked on"; then
    echo "PASS: grep -q works on a sample string"
  else
    echo "FAIL: grep -q did not match expected sample — skip-overwrite check unavailable"
    SELFTEST_FAIL=1
  fi

  SELFTEST_VAULT="${CLAUDE_PROJECT_DIR:-$PWD}"
  if [ -d "$SELFTEST_VAULT" ]; then
    echo "PASS: CLAUDE_PROJECT_DIR (or PWD fallback) resolves to a directory ($SELFTEST_VAULT)"
  else
    echo "FAIL: CLAUDE_PROJECT_DIR/fallback '$SELFTEST_VAULT' is not a directory"
    SELFTEST_FAIL=1
  fi

  if [ -d "$SELFTEST_VAULT" ] && { [ -d "$SELFTEST_VAULT/ops" ] || [ -w "$SELFTEST_VAULT" ]; }; then
    echo "PASS: $SELFTEST_VAULT/ops/sessions write target has a reachable parent"
  else
    echo "FAIL: $SELFTEST_VAULT is not reachable/writable — cannot mkdir -p ops/sessions or write last-active.md"
    SELFTEST_FAIL=1
  fi

  if [ "$SELFTEST_FAIL" -eq 0 ]; then
    echo "SELFTEST: all checks passed"
    exit 0
  else
    echo "SELFTEST: one or more checks failed"
    exit 1
  fi
fi

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
