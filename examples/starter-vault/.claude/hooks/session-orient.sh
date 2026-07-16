#!/bin/bash
# session-orient.sh — Vault OS v4 (D1: continuity is computed, not curated)
# vault-os-hook-version: 4.1.0
# Fires at SessionStart (blank matcher: startup, resume, clear, compact)
#
# Two sections, by trust tier:
#   DERIVED  — computed live from git + disk every session. No stored copy exists to go stale.
#   DECLARED — from compass.md (Focus/Questions/Flags): things git cannot tell you. Shown behind
#              a staleness banner if the compass Updated stamp is >30 days old.
# Plus a PRE-V4 check that offers migration when a vault predates the v4 context contract.
# Everything fails loudly (D6): a check that cannot run says so; it never defaults to "fine".

STALE_DAYS=30

# ── Selftest: verify this hook's own dependencies, loudly ─────────────────────
if [ "${1:-}" = "--selftest" ]; then
  SELFTEST_FAIL=0

  if EPOCH=$(date -d "2026-01-01" +%s 2>/dev/null) && [ -n "$EPOCH" ]; then
    echo "PASS: date -d parses ISO dates (2026-01-01 -> ${EPOCH})"
  else
    echo "FAIL: date -d \"2026-01-01\" +%s did not parse — GNU date required for compass staleness banner"
    SELFTEST_FAIL=1
  fi

  if printf 'WARNING: sample\n' | grep -qE '^(WARNING|ERROR)'; then
    echo "PASS: grep -E works on a sample string"
  else
    echo "FAIL: grep -E did not match expected sample — extended regex unavailable"
    SELFTEST_FAIL=1
  fi

  # The corrected DEC_COUNT char class must not raise "Invalid range end" on this grep.
  if printf 'x\n' | grep -c '^[^[:space:]#-]' >/dev/null 2>&1; then
    echo "PASS: decisions-count char class '^[^[:space:]#-]' compiles (no Invalid range end)"
  else
    echo "FAIL: decisions-count char class raised an error — grep regex engine incompatible"
    SELFTEST_FAIL=1
  fi

  if command -v git >/dev/null 2>&1; then
    echo "PASS: git is on PATH ($(git --version 2>/dev/null)) — DERIVED git signals available"
  else
    echo "FAIL: git not on PATH — DERIVED section cannot compute branch/commits/push status"
    SELFTEST_FAIL=1
  fi

  if ST=$(stat -c %Y "$0" 2>/dev/null) && [ -n "$ST" ]; then
    echo "PASS: stat -c %Y works (mtime ${ST}) — recently-modified-files ranking available"
  else
    echo "FAIL: stat -c %Y did not work — cannot rank recently modified files"
    SELFTEST_FAIL=1
  fi

  SELFTEST_VAULT="${CLAUDE_PROJECT_DIR:-$PWD}"
  if [ -d "$SELFTEST_VAULT" ]; then
    echo "PASS: CLAUDE_PROJECT_DIR (or PWD fallback) resolves to a directory ($SELFTEST_VAULT)"
  else
    echo "FAIL: CLAUDE_PROJECT_DIR/fallback '$SELFTEST_VAULT' is not a directory"
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
[[ -f "$VAULT/CLAUDE.md" ]] || { echo "ERROR: VAULT root invalid at $VAULT (no CLAUDE.md)"; exit 1; }

VAULT_NAME=$(basename "$VAULT")
MANIFEST="$VAULT/ops/vault-manifest.md"

echo "╔══════════════════════════════════════════════════════════╗"
printf "║  %-56s║\n" "${VAULT_NAME} ORIENTATION"
echo "╚══════════════════════════════════════════════════════════╝"
echo "Date: $(date +%Y-%m-%d)   hooks v4.1.0"
echo ""

# ── Operator profile (personal cross-project surface; organic-write-backed) ───
if [ -f "$HOME/.claude/operator.md" ]; then
  echo "--- OPERATOR PROFILE ---"
  cat "$HOME/.claude/operator.md"
  echo ""
fi

# ══════════════════════════════════════════════════════════════════════════════
# DERIVED — computed live. Nothing here is stored; nothing here can go stale.
# ══════════════════════════════════════════════════════════════════════════════
echo "--- DERIVED (computed live — git + disk) ---"

if ! command -v git >/dev/null 2>&1; then
  echo "⚠ git is not on PATH — cannot compute branch, commits, or push status this session."
elif ! git -C "$VAULT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "⚠ NOT A GIT REPOSITORY — no version-control history to derive from."
  echo "  Session continuity is degraded: run 'git init' + first commit to enable DERIVED signals."
else
  BRANCH=$(git -C "$VAULT" rev-parse --abbrev-ref HEAD 2>/dev/null)
  echo "Branch: ${BRANCH:-<unknown>}"

  echo "Last 5 commits:"
  if git -C "$VAULT" rev-parse HEAD >/dev/null 2>&1; then
    git -C "$VAULT" log -5 --oneline 2>/dev/null | sed 's/^/  /'
  else
    echo "  (no commits yet)"
  fi

  UNCOMMITTED=$(git -C "$VAULT" status --porcelain 2>/dev/null | grep -c .)
  echo "Uncommitted changes: ${UNCOMMITTED} file(s)"

  UPSTREAM=$(git -C "$VAULT" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)
  if [ -n "$UPSTREAM" ]; then
    UNPUSHED=$(git -C "$VAULT" rev-list --count "${UPSTREAM}..HEAD" 2>/dev/null)
    echo "Unpushed commits: ${UNPUSHED:-?} (ahead of ${UPSTREAM})"
  else
    echo "Unpushed commits: ⚠ no upstream tracking branch — push status unknown (set with: git push -u)"
  fi

  echo "Recently modified (non-ignored, top 5):"
  RECENT=$(git -C "$VAULT" ls-files --cached --others --exclude-standard -z 2>/dev/null \
    | while IFS= read -r -d '' f; do
        [ -f "$VAULT/$f" ] || continue
        m=$(stat -c %Y "$VAULT/$f" 2>/dev/null) || continue
        printf '%s\t%s\n' "$m" "$f"
      done | sort -rn | head -5 | cut -f2-)
  if [ -n "$RECENT" ]; then
    echo "$RECENT" | sed 's/^/  /'
  else
    echo "  (none tracked or all ignored)"
  fi
fi

# Last session record + its age
LAST="$VAULT/ops/sessions/last-active.md"
echo ""
if [ -f "$LAST" ]; then
  MT=$(stat -c %Y "$LAST" 2>/dev/null)
  if [ -n "$MT" ]; then
    AGE_DAYS=$(( ( $(date +%s) - MT ) / 86400 ))
    echo "Last session record (ops/sessions/last-active.md, ${AGE_DAYS}d old):"
  else
    echo "Last session record (ops/sessions/last-active.md):"
  fi
  sed 's/^/  /' "$LAST"
else
  echo "Last session record: none (no ops/sessions/last-active.md yet)."
fi
echo ""

# ══════════════════════════════════════════════════════════════════════════════
# DECLARED — from compass.md. Things git cannot tell you. Historical if stale.
# ══════════════════════════════════════════════════════════════════════════════
# Resolve compass path from the manifest's exports.compass, then fall back.
EXPORT_COMPASS=""
if [ -f "$MANIFEST" ]; then
  EXPORT_COMPASS=$(awk '
    /^exports:/{inx=1; next}
    inx && /^[^[:space:]#]/{inx=0}
    inx && /compass:/{sub(/.*compass:[[:space:]]*/,""); gsub(/"/,""); print; exit}
  ' "$MANIFEST" | xargs 2>/dev/null)
fi
COMPASS=""
for cand in "$EXPORT_COMPASS" "compass.md" "ops/compass.md"; do
  [ -n "$cand" ] && [ -f "$VAULT/$cand" ] && { COMPASS="$VAULT/$cand"; break; }
done

echo "--- DECLARED (compass intent — Focus / Questions / Flags) ---"
if [ -z "$COMPASS" ]; then
  echo "⚠ No compass found (looked for exports.compass, compass.md, ops/compass.md)."
  echo "  Declared intent is unavailable — create a compass so orientation has intent to show."
else
  UPDATED=$(grep -oE '\*Updated:[[:space:]]*[0-9]{4}-[0-9]{2}-[0-9]{2}\*' "$COMPASS" 2>/dev/null \
    | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
  if [ -n "$UPDATED" ] && U_EPOCH=$(date -d "$UPDATED" +%s 2>/dev/null); then
    C_AGE=$(( ( $(date +%s) - U_EPOCH ) / 86400 ))
    if [ "$C_AGE" -gt "$STALE_DAYS" ]; then
      echo "╔══════════════════════════════════════════════════════════╗"
      echo "║  ⚠ intent last declared ${C_AGE} days ago — treat as HISTORICAL"
      echo "║  The compass below reflects intent as of ${UPDATED}, not now."
      echo "║  Trust the DERIVED section above for current state.       ║"
      echo "╚══════════════════════════════════════════════════════════╝"
    fi
  elif [ -z "$UPDATED" ]; then
    echo "⚠ compass has no '*Updated: YYYY-MM-DD*' stamp — cannot judge staleness. Add one."
  else
    echo "⚠ could not parse compass Updated date '$UPDATED' — staleness unknown."
  fi
  cat "$COMPASS"
fi
echo ""

# Decisions log (human-authored calls; injected verbatim — D2 keeps it unchanged)
DECISIONS="$VAULT/ops/decisions.md"
if [ -f "$DECISIONS" ]; then
  echo "--- DECISIONS ---"
  cat "$DECISIONS"
  # Volume signal. Corrected char class (was '^[^[:space:]-#]' which raises Invalid range end;
  # '-' must be last in a bracket expression). Counts non-blank, non-comment, non-bullet lines.
  DEC_COUNT=$(grep -c '^[^[:space:]#-]' "$DECISIONS" 2>/dev/null)
  DEC_COUNT=${DEC_COUNT:-0}
  echo ""
  echo "decisions.md: ${DEC_COUNT} content line(s)"
  echo ""
fi

# ══════════════════════════════════════════════════════════════════════════════
# PRE-V4 CHECK (D8) — offer migration when this vault predates the context contract.
# ══════════════════════════════════════════════════════════════════════════════
if [ -f "$MANIFEST" ] && ! grep -q '^exports:' "$MANIFEST" 2>/dev/null; then
  echo "--- MIGRATION ---"
  echo "⚠ PRE-V4 VAULT: ops/vault-manifest.md has no 'exports:' contract. This vault predates"
  echo "  Vault OS v4. Offer to migrate it (slim compass, context-contract manifest, native"
  echo "  permissions, v4 hooks) — see spec/vault-os-v4.md in the vault-os repo."
  echo ""
fi

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Continuity is computed. /capture only adds narrative.    ║"
echo "╚══════════════════════════════════════════════════════════╝"
