#!/bin/bash
# session-orient.sh — Vault OS v2 compliant
# Fires at SessionStart (blank matcher: startup, resume, compact)

VAULT="${CLAUDE_PROJECT_DIR:?ERROR: CLAUDE_PROJECT_DIR not set — hook must be invoked by Claude Code}"
[[ -f "$VAULT/CLAUDE.md" ]] || { echo "ERROR: VAULT root invalid at $VAULT"; exit 1; }

# --- Set your vault name here ---
VAULT_NAME=$(basename "$VAULT")
RUNTIME_DIR="$HOME/.claude/vault-runtime/$VAULT_NAME"
mkdir -p "$RUNTIME_DIR"

echo "╔══════════════════════════════════════════╗"
echo "║       ${VAULT_NAME} ORIENTATION           ║"
echo "╚══════════════════════════════════════════╝"
echo "Date: $(date +%Y-%m-%d)"
echo ""

# --- Operator profile ---
if [ -f "$HOME/.claude/operator.md" ]; then
  echo "--- OPERATOR PROFILE ---"
  cat "$HOME/.claude/operator.md"
  echo ""
fi

# --- Last session ---
if [ -f "$VAULT/ops/sessions/last-active.md" ]; then
  echo "--- LAST SESSION ---"
  cat "$VAULT/ops/sessions/last-active.md"
  echo ""
fi

# --- Decisions ---
if [ -f "$VAULT/ops/decisions.md" ]; then
  echo "--- DECISIONS ---"
  cat "$VAULT/ops/decisions.md"
  echo ""
fi

# --- Knowledge Core ---
if [ -f "$VAULT/ops/knowledge.md" ]; then
  CORE=$(awk '/^## Core/{found=1; next} /^## /{if(found) exit} found{print}' "$VAULT/ops/knowledge.md")
  if echo "$CORE" | grep -qv '^[[:space:]]*$'; then
    echo "--- KNOWLEDGE ---"
    echo "$CORE"
    CORE_LINES=$(echo "$CORE" | grep -c .)
    EXT_COUNT=$(awk '/^## Extended/{found=1} found && /^[^#[:space:]]/{count++} END{print count+0}' "$VAULT/ops/knowledge.md")
    DEC_COUNT=$(grep -c '^[^[:space:]-#]' "$VAULT/ops/decisions.md" 2>/dev/null || echo 0)
    echo "KNOWLEDGE: Core ${CORE_LINES} lines | Extended ${EXT_COUNT} entries | decisions.md ${DEC_COUNT} entries"
    if [ "${EXT_COUNT:-0}" -gt 20 ] || [ "${DEC_COUNT:-0}" -gt 30 ]; then
      echo "/maintain recommended"
    fi
    echo ""
  else
    echo "WARNING: knowledge.md has no Core/Extended structure — run /maintain to migrate."
    echo ""
  fi
fi

# --- Quest context (quest-link declared in manifest) ---
MANIFEST="$VAULT/ops/vault-manifest.md"
if [ -f "$MANIFEST" ]; then
  QUEST_LINK=$(grep 'quest-link:' "$MANIFEST" | sed 's/.*quest-link:[[:space:]]*//' | tr -d '"' | xargs 2>/dev/null)
  if [ -n "$QUEST_LINK" ]; then
    if [ -f "$VAULT/$QUEST_LINK" ]; then
      echo "--- QUEST CONTEXT ---"
      head -30 "$VAULT/$QUEST_LINK"
      if ! head -5 "$VAULT/$QUEST_LINK" | grep -qE '^(---|[*#])'; then
        echo "WARNING: no front-matter detected in first 5 lines of $QUEST_LINK. Quest file should open with a summary block." >&2
      fi
      echo ""
    else
      echo "WARNING: quest file not found at $VAULT/$QUEST_LINK"
      echo "To fix: update quest-link in ops/vault-manifest.md or create the missing file."
      echo ""
    fi
  fi
fi

# --- Manifest drift check ---
if [ -f "$MANIFEST" ]; then
  LAST_VERIFIED=$(grep 'last-verified:' "$MANIFEST" | sed 's/.*last-verified:[[:space:]]*//' | xargs 2>/dev/null)
  SUPPRESS="$RUNTIME_DIR/.last-manifest-warning"
  TODAY=$(date +%Y-%m-%d)
  LAST_WARNED=$(cat "$SUPPRESS" 2>/dev/null || echo "1970-01-01")

  if [ -z "$LAST_VERIFIED" ]; then
    echo "--- MANIFEST DRIFT CHECK ---"
    echo "WARNING: ops/vault-manifest.md missing last-verified field."
    echo ""
  elif [ "$LAST_WARNED" != "$TODAY" ]; then
    DAYS_OLD=$(python -c "from datetime import date; print((date.today() - date.fromisoformat('$LAST_VERIFIED')).days)" 2>/dev/null || echo 0)
    if [ "${DAYS_OLD:-0}" -gt 7 ]; then
      echo "--- MANIFEST DRIFT CHECK ---"
      echo "WARNING: ops/vault-manifest.md last-verified $LAST_VERIFIED ($DAYS_OLD days ago). Review and stamp last-verified."
      echo "$TODAY" > "$SUPPRESS"
      echo ""
    fi
  fi
fi

# --- Operational state ---
echo "--- OPERATIONAL STATE ---"
cat "$VAULT/ops/compass.md" 2>/dev/null || echo "(compass not found)"
echo ""

# --- Vault structure (live-generated) ---
echo "--- VAULT STRUCTURE ---"
echo "${VAULT##*/}/"
for entry in "$VAULT"/*/; do
  [ -d "$entry" ] || continue
  name="${entry%/}"; name="${name##*/}"
  echo "├── $name/"
done
for entry in "$VAULT"/*.md; do
  [ -f "$entry" ] || continue
  echo "├── ${entry##*/}"
done
KEY_DIRS=("ops" "quests" ".claude/hooks" ".claude/commands")
for kd in "${KEY_DIRS[@]}"; do
  target="$VAULT/$kd"
  [ -d "$target" ] || { echo "│   (not found: $kd/)"; continue; }
  for item in "$target"/*; do
    [ -e "$item" ] || continue
    name="${item##*/}"
    if [ -d "$item" ]; then
      echo "│   ├── $name/"
    else
      echo "│   ├── $name"
    fi
  done
done
echo "(generated $(date +%Y-%m-%d))"
echo ""

echo "╔══════════════════════════════════════════╗"
echo "║  Run /capture before closing this tab.   ║"
echo "╚══════════════════════════════════════════╝"
