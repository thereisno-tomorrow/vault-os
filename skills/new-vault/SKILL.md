---
name: new-vault
description: Scaffold a new vault conforming to vault-os-v4. Invoked when user says "new vault", "create vault", "scaffold vault", or describes a project that needs a vault. Extracts context from chat, asks ≤3 questions, confirms, then writes all files.
---

# new-vault

Scaffold a complete vault conforming to **vault-os-v4** (`spec/vault-os-v4.md`). When invoked, execute phases 0–4 below. All file content is defined inline — no external files consulted at runtime. Everything needed is here.

**v4 baseline (what changed from v2 — do not scaffold the v2 artifacts):**
- **Slim compass** — three sections only (Focus / Questions / Flags) + an `*Updated:*` stamp. No Vault State, Key Files, or Hot Files tables. Continuity is computed by the orient hook, not curated here.
- **Context-contract manifest** — `exports:` / `intake:` / `domains:`, not `export-surfaces:`.
- **Native permissions** — protected files gated by `permissions.ask` in `.claude/settings.json`. No `protect.py`, no `protected-files.txt`.
- **No `knowledge.md`** and **no `guide.md`** — both retired (D9). `/guide` renders CLAUDE.md's Commands table.
- **Two v4 hooks** (`session-orient.sh`, `session-capture.sh`, version 4.1.0, `--selftest`-able).
- `validate-note.py` + `ops/validate-config.yaml` remain **Module A only**.

---

## Module Catalog

The vault manifest (`ops/vault-manifest.md`) is always created — it is a baseline component, not a module.

| ID | Name | Key additions | Requires |
|---|---|---|---|
| A | Knowledge Graph | `notes/` (flat), MOCs, `dedup-index.md`, `validate-note.py`, `ops/validate-config.yaml`, `/reduce` `/reflect` `/connect` `/think` | — |
| B | Inbox Pipeline | `inbox/`, `archive/transcripts/`, `processing-backlog.md`, full `/reduce` pipeline | A |
| C | Synthesis Commands | `/brief`, `/challenge` (+ `/think` shared with A) | A |
| D | Project State | Tech Stack, Architecture, Code Patterns in CLAUDE.md. (Protected files are native `permissions.ask` — baseline, not a module. No Session Handoff narrative, no `protect.py`.) | — |
| E | Context Loading Table | Context Loading Table in CLAUDE.md | — |
| F | Design Workspace | `context/`, `architecture/`, `research/`, Core Insight, Constraints sections | — |
| G | Intelligence Scanning | `sources/`, `/scan`, Epistemic Rules (accepts any HTTPS) | A or E |

**Typical combinations:**

| Vault type | Modules |
|---|---|
| Knowledge vault (YouTube, books, transcripts) | A + B + C |
| Research intelligence | A + B + C + G |
| Engineering project | D |
| Architecture / design workspace | C + E + F |
| Hybrid (code + research) | A + C + D |

---

## Execution

### Phase 0 — Extract from chat

Before asking anything, scan the conversation for:

- **Vault name or project name** — explicit or implied from context
- **Source material type** — YouTube videos → implies A + YouTube URL prefix; code/documents/papers → implies A + general HTTPS
- **Operating mode** — processing sources → implies B; designing a system → implies F; engineering project → implies D
- **Subject domains** — topic areas → candidate MOC names if A selected
- **Target directory** — absolute path (look for path-like strings in the chat)

---

### Phase 1 — Interview (one AskUserQuestion call, ≤3 questions)

Present only what Phase 0 couldn't resolve. Required to resolve before writing: vault name, root path, feature selection.

**Feature menu** — present as a multi-select question with these options:

```
Label: "Knowledge graph"
Description: "Atomic notes, wikilinks, MOCs, schema validation hook. Best for processing sources into a permanent knowledge base."

Label: "Inbox pipeline"
Description: "inbox/, /reduce, archive/. For batches of source files. Requires Knowledge graph."

Label: "Synthesis"
Description: "/brief, /think, /challenge. Reasoning over vault content. Requires Knowledge graph."

Label: "Project state"
Description: "Session handoff, hot files, tech stack, code patterns, protected files. For engineering projects needing continuity across sessions."

Label: "Context loading table"
Description: "Session intent → file mapping. Clean navigation for design/research."

Label: "Design workspace"
Description: "context/, architecture/, research/ directories. Core Insight and Constraints sections."

Label: "Intelligence scanning"
Description: "/scan, sources/, epistemic rules. For live web intelligence with source tracking."
```

If YouTube source was implied in Phase 0, add a question: "URL validation for note schema: YouTube only (`https://www.youtube.com/`) or general HTTPS?"

If vault name unclear, ask. If root path not found in chat, ask.

Use one AskUserQuestion call with all outstanding questions (max 3).

---

### Phase 2 — Confirm before writing

Present a summary block and write nothing until the user explicitly confirms:

```
Vault: [name]
Path: [root]
Features: [A, B, C, ...] (manifest always included)
Creates: [N files across X directories]
Commands: [comma-separated list]
Hooks: session-orient.sh, session-capture.sh[, validate-note.py (Module A)]
Protected files (native permissions.ask): CLAUDE.md, ops/vault-manifest.md
```

---

### Phase 3 — Scaffold

Execute in dependency-first order. Use the substitution conventions defined below.

**Substitution conventions** (substitute these placeholders throughout all templates):

- `{{VAULT_PATH}}` → absolute path to vault root, no trailing slash
- `{{VAULT_NAME}}` → human-readable vault name
- `{{SOURCE_URL_PREFIX}}` → `https://www.youtube.com/` for YouTube vaults; `""` (empty string) for general vaults; `""` if Module G is selected (G accepts any HTTPS)
- `{{SCAFFOLD_DATE}}` → today's date YYYY-MM-DD
- `{{FEATURES_LIST}}` → comma-separated module letters, e.g., `A, B, C`

Note: compass is always `compass.md` at the vault root. No path substitution needed.

**Step 1: Create all directories**

Always: `.claude/hooks/`, `.claude/commands/`, `ops/sessions/`
Module A: `notes/`
Module B: `inbox/`, `archive/transcripts/`
Module D: no extra dirs
Module E: no extra dirs
Module F: `context/`, `architecture/`, `research/`
Module G: `sources/`

**Step 2: Write `.claude/hooks/session-orient.sh`** — see T-ORIENT

**Step 3: Write `.claude/hooks/session-capture.sh`** — see T-CAPTURE

**Step 4 (Module A only): Write `.claude/hooks/validate-note.py`** — see T-VALIDATE. Substitute `{{SOURCE_URL_PREFIX}}` before writing.

**Step 5 (Module A only): Write `ops/validate-config.yaml`** — see T-VALIDATE-CONFIG.

**Step 6:** *(removed in v4 — protected files are native `permissions.ask` rules written in Step 7. No `protect.py`, no `protected-files.txt`.)*

**Step 7: Write `.claude/settings.json`** — see T-SETTINGS. Baseline variant unless Module A is selected (Module A adds the `validate-note.py` PostToolUse hook). The `permissions.ask` block is always written.

**Step 8: Write `CLAUDE.md`** — assemble sections per T-CLAUDE. Omit module-conditional sections when their module is not selected.

**Step 9: Write `compass.md`** — see T-COMPASS. Slim: Focus / Questions / Flags only.

**Step 10:** *(removed in v4 — `ops/knowledge.md` and its Core/Extended machinery are retired.)*

**Step 11: Write `ops/decisions.md`** — see T-DECISIONS. Always.

**Step 12 (Module A): Write `notes/index.md`, `notes/dedup-index.md`, `notes/methods.md`** — see T-INDEX, T-DEDUP, T-METHODS.

**Step 13 (Module A, only if domains identified in Phase 0): Write domain MOC stubs** — see T-MOC-STUB. One file per domain.

**Step 14: Write `ops/vault-manifest.md`** — see T-MANIFEST. Always.

**Step 15 (Module B): Write `ops/processing-backlog.md`** — see T-BACKLOG.

**Step 16: Write `.claude/commands/` files** — write one file per active command:
- Always: `compass.md` (T-CMD-COMPASS) — local override because new vaults place compass at root, not ops/
- Note: `capture.md`, `decide.md`, `guide.md` are global commands in `~/.claude/commands/` — do NOT scaffold them locally. `/guide` renders CLAUDE.md's Commands table; there is no `ops/guide.md`.
- Module A: `reduce.md` (T-CMD-REDUCE), `reflect.md` (T-CMD-REFLECT), `connect.md` (T-CMD-CONNECT), `think.md` (T-CMD-THINK)
- Module C: `brief.md` (T-CMD-BRIEF), `challenge.md` (T-CMD-CHALLENGE). If A already wrote `think.md`, do not write it again.
- Module G: `scan.md` (T-CMD-SCAN)

**Step 17:** *(removed in v4 — no `ops/guide.md`. `/guide` renders the Commands table in CLAUDE.md.)*

---

### Phase 4 — Report

```
Created: N files in X directories

[directory tree of what was created]

Start here: compass.md
First action: [what to do now — e.g., "Add your first source file to inbox/ then run /reduce" or "Set the compass Focus to what this vault is trying to do" or "Add domains to notes/index.md"]
```

---

## File Templates

---

### T-ORIENT: `.claude/hooks/session-orient.sh`

Write this file verbatim (vault-os v4.1.0). It is baseline for every vault — no module conditionals. The DERIVED section computes state from git + disk every session; the DECLARED section prints the compass. Do not add per-module blocks; keep one hook lineage (D6).

```bash
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
```

**Hard constraints:**
- `VAULT` set from `$CLAUDE_PROJECT_DIR` with sentinel check — never hardcode paths.
- Do NOT cat CLAUDE.md, notes, or any file beyond compass / decisions / last-active / operator.md.
- Keep the `--selftest` block and the `vault-os-hook-version: 4.1.0` stamp intact.
- Everything fails loudly (D6): a check that cannot run says so; it never defaults to "fine".

---

### T-CAPTURE: `.claude/hooks/session-capture.sh`

Write this file verbatim (vault-os v4.1.0). Minimal machine record on SessionEnd; `/capture` enriches with narrative when invoked. Fires on clean exits only (NOT VS Code tab close). Must not clobber a richer same-day `/capture` record.

```bash
#!/bin/bash
# session-capture.sh — Vault OS v4 (D2: capture is a hook with a skill on top)
# vault-os-hook-version: 4.1.0
# Fires at SessionEnd (clean exits only — does NOT fire on VS Code tab close).
#
# Reliability tiers (D2):
#   1. THIS hook writes a minimal machine record when it fires.
#   2. /capture enriches with narrative when invoked — optional, never load-bearing.
#   3. DERIVED orientation (session-orient.sh) is the safety net — git is the record of last resort.
# This hook must not clobber a richer /capture record written the same day (same-day marker check).

# ── Selftest: verify this hook's own dependencies, loudly ─────────────────────
if [ "${1:-}" = "--selftest" ]; then
  SELFTEST_FAIL=0

  if TODAY_CHECK=$(date +%Y-%m-%d 2>/dev/null) && [ -n "$TODAY_CHECK" ] \
     && TIME_CHECK=$(date +%H:%M 2>/dev/null) && [ -n "$TIME_CHECK" ]; then
    echo "PASS: date +%Y-%m-%d / +%H:%M format (${TODAY_CHECK} ${TIME_CHECK})"
  else
    echo "FAIL: date +%Y-%m-%d or +%H:%M produced no output — cannot stamp session record"
    SELFTEST_FAIL=1
  fi

  if printf 'Source: auto-generated by session-capture.sh\n' \
       | grep -q 'auto-generated by session-capture.sh'; then
    echo "PASS: grep -q works — same-day/self-stub detection available"
  else
    echo "FAIL: grep -q did not match expected sample — skip-overwrite check unavailable"
    SELFTEST_FAIL=1
  fi

  if command -v git >/dev/null 2>&1; then
    echo "PASS: git is on PATH ($(git --version 2>/dev/null)) — files-touched approximation available"
  else
    echo "WARN: git not on PATH — files-touched list will be empty (record still written)"
  fi

  SELFTEST_VAULT="${CLAUDE_PROJECT_DIR:-$PWD}"
  if [ -d "$SELFTEST_VAULT" ] && { [ -d "$SELFTEST_VAULT/ops" ] || [ -w "$SELFTEST_VAULT" ]; }; then
    echo "PASS: $SELFTEST_VAULT/ops/sessions write target has a reachable parent"
  else
    echo "FAIL: $SELFTEST_VAULT is not reachable/writable — cannot write last-active.md"
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

LAST="$VAULT/ops/sessions/last-active.md"
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)
SELF_MARK="auto-generated by session-capture.sh"

# Same-day marker check: if a record dated today already exists and it is NOT this hook's own
# stub, a richer /capture record was written this session — preserve it, do not clobber.
if [ -f "$LAST" ] \
   && grep -q "^Date: ${DATE}" "$LAST" 2>/dev/null \
   && ! grep -q "$SELF_MARK" "$LAST" 2>/dev/null; then
  exit 0
fi

# Files touched — APPROXIMATION. SessionEnd cannot diff against session start (no start snapshot
# is available to the hook), so we approximate with the current uncommitted working-tree changes
# plus the files in today's most recent commit. This over-counts (pre-existing dirty files) and
# under-counts (changes already committed on an earlier day). /capture gives the accurate story.
BRANCH="(not a git repo)"
FILES=""
if command -v git >/dev/null 2>&1 && git -C "$VAULT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  BRANCH=$(git -C "$VAULT" rev-parse --abbrev-ref HEAD 2>/dev/null)
  DIRTY=$(git -C "$VAULT" status --porcelain 2>/dev/null | awk '{print $NF}')
  TODAY_COMMIT=""
  if git -C "$VAULT" rev-parse HEAD >/dev/null 2>&1; then
    LAST_COMMIT_DATE=$(git -C "$VAULT" log -1 --format=%cd --date=format:%Y-%m-%d 2>/dev/null)
    if [ "$LAST_COMMIT_DATE" = "$DATE" ]; then
      TODAY_COMMIT=$(git -C "$VAULT" show --name-only --format= HEAD 2>/dev/null)
    fi
  fi
  FILES=$(printf '%s\n%s\n' "$DIRTY" "$TODAY_COMMIT" | grep -v '^$' | sort -u)
fi

{
  echo "Date: ${DATE} ${TIME}"
  echo "Branch: ${BRANCH:-<unknown>}"
  echo "Source: ${SELF_MARK} (SessionEnd hook — clean exit only; does NOT fire on VS Code tab close)"
  echo ""
  echo "Files touched (approximation — see note):"
  if [ -n "$FILES" ]; then
    echo "$FILES" | sed 's/^/  - /'
  else
    echo "  (none detected — clean tree, or not a git repo)"
  fi
  echo ""
  echo "Note: SessionEnd cannot diff against session start. The list above is uncommitted"
  echo "working-tree changes plus files in today's most recent commit — an approximation, not"
  echo "a session diff. Run /capture for a narrative summary of what was actually done and why."
} > "$LAST"
```

---

### T-VALIDATE: `.claude/hooks/validate-note.py` (Module A only)

Substitute `{{SOURCE_URL_PREFIX}}` before writing. For YouTube vaults: `"https://www.youtube.com/"`. For general vaults or Module G: `""` (empty string disables the prefix check).

```python
#!/usr/bin/env python3
"""
Vault schema validator — conforms to vault-os-v2.
Fires on PostToolUse Write. Validates any note written to notes/.

Checks (atomic notes):
  1. Frontmatter block present
  2. Required fields present
  3. Description length 50-200 chars
  4. Date format YYYY-MM-DD
  5. source-url prefix (vault-specific; empty string skips check)
  6. source-video wikilink format [[...]]
  7. type vocabulary (loaded from ops/validate-config.yaml — hard error if absent)
  8. Topics: footer present
  9. Contradiction field (soft warning)
  10. Prose wikilinks (not footer-only)
  11. Broken wikilinks
  12. Dedup registration

MOC files (-moc.md): bare-link check only (checks 1-12 skipped).
Infrastructure files (compass, methods, index, dedup-index): fully skipped.
"""

import sys
import json
import os
import re

REQUIRED_FIELDS = {
    "description:":  "description  (~150 chars — adds scope/mechanism beyond the title, not a restatement)",
    "type:":         "type         (controlled vocabulary — see ops/validate-config.yaml)",
    "source-video:": "source-video (wikilink to archived source: [[slug]])",
    "source-url:":   "source-url   (URL of source material)",
    "published:":    "published    (YYYY-MM-DD — date of source)",
    "created:":      "created      (YYYY-MM-DD — date this note was created)",
}

# Infrastructure files — skip all validation
SKIP_NAMES = {"compass.md", "methods.md", "index.md", "dedup-index.md"}

# SOURCE_URL_PREFIX: set at vault build time.
# YouTube vaults: "https://www.youtube.com/"
# General vaults or Module G vaults: "" (empty string disables prefix check)
SOURCE_URL_PREFIX = "{{SOURCE_URL_PREFIX}}"


def load_config(vault_root):
    """Load validate-config.yaml. Returns dict with type_vocabulary set, or None on failure."""
    config_path = os.path.join(vault_root, "ops", "validate-config.yaml")
    try:
        with open(config_path, "r", encoding="utf-8") as f:
            content = f.read()
        match = re.search(r'^type-vocabulary:\s*\n((?:[^\S\n]*-[^\n]+\n?)+)', content, re.MULTILINE)
        if match:
            items = re.findall(r'-\s*(.+)', match.group(1))
            return {"type_vocabulary": set(item.strip() for item in items)}
    except FileNotFoundError:
        pass
    return None


def is_moc_file(basename):
    return basename.endswith("-moc.md")


def find_vault_root(file_path):
    normalised = file_path.replace("\\", "/")
    idx = normalised.find("/notes/")
    if idx >= 0:
        return normalised[:idx]
    return None


def check_description_length(content, violations):
    match = re.search(r'^description:\s*(.+)$', content, re.MULTILINE)
    if not match:
        return
    desc = match.group(1).strip().strip('"').strip("'")
    length = len(desc)
    if length < 50:
        violations.append(
            f"Description too short ({length} chars, aim for ~150). "
            "A vague description fails progressive disclosure."
        )
    elif length > 200:
        violations.append(
            f"Description too long ({length} chars, cap ~200). "
            "Trim to a single sharp claim that adds scope or mechanism beyond the title."
        )


def check_date_field(content, field_name, violations):
    match = re.search(rf'^{re.escape(field_name)}:\s*(.+)$', content, re.MULTILINE)
    if not match:
        return
    date_val = match.group(1).strip()
    if not re.match(r'^\d{4}-\d{2}-\d{2}$', date_val):
        violations.append(
            f"{field_name} format invalid ('{date_val}'). Must be YYYY-MM-DD."
        )


def check_source_url(content, violations):
    if not SOURCE_URL_PREFIX:
        return
    match = re.search(r'^source-url:\s*(.+)$', content, re.MULTILINE)
    if not match:
        return
    url = match.group(1).strip()
    if not url.startswith(SOURCE_URL_PREFIX):
        violations.append(
            f"source-url must start with '{SOURCE_URL_PREFIX}' (got: '{url}'). "
            "Every note must trace to a specific source."
        )


def check_source_video_format(content, violations):
    match = re.search(r'^source-video:\s*(.+)$', content, re.MULTILINE)
    if not match:
        return
    val = match.group(1).strip().strip('"').strip("'")
    if not (val.startswith("[[") and val.endswith("]]")):
        violations.append(
            f"source-video must be a wikilink (e.g. [[source-slug]]), got: '{val}'. "
            "This creates the graph edge back to the source."
        )


def check_type_field(content, config, violations):
    match = re.search(r'^type:\s*(.+)$', content, re.MULTILINE)
    if not match:
        return
    type_val = match.group(1).strip()
    if config is None:
        violations.append(
            "MISSING CONFIG: ops/validate-config.yaml required for Module A. "
            "Check 7 (type vocabulary) cannot run."
        )
        return
    valid_types = config.get("type_vocabulary", set())
    if type_val not in valid_types:
        violations.append(
            f"type '{type_val}' is not in controlled vocabulary. "
            f"Valid values: {', '.join(sorted(valid_types))}. "
            "See ops/validate-config.yaml."
        )


def check_topics_footer(content, violations):
    body = content
    fm_match = re.match(r'^---\n.*?\n---\n', content, re.DOTALL)
    if fm_match:
        body = content[fm_match.end():]
    if not re.search(r'^Topics:', body, re.MULTILINE):
        violations.append(
            "Missing Topics: footer section. Every note must declare MOC membership:\n"
            "   ---\n"
            "   Topics:\n"
            "   - [[domain-moc]]\n"
            "   This is body content (not YAML) and makes the graph traversable."
        )


def check_contradiction_field(content, violations):
    if re.search(r'^type:\s*contradiction', content, re.MULTILINE):
        if not re.search(r'^contradicts:', content, re.MULTILINE):
            violations.append(
                "type: contradiction set but no contradicts: field found. "
                "Add: contradicts: '[[note-slug]]' to create an explicit contradiction link."
            )


def check_broken_wikilinks(content, vault_root, violations):
    if not vault_root:
        return
    links = re.findall(r'\[\[([^\]|]+)', content)
    if not links:
        return
    known_files = set()
    for root, dirs, files in os.walk(vault_root):
        dirs[:] = [d for d in dirs if not d.startswith('.')]
        for fname in files:
            if fname.endswith('.md'):
                known_files.add(fname[:-3])
    broken = []
    seen = set()
    for link in links:
        target = link.strip()
        if target in seen:
            continue
        seen.add(target)
        if target not in known_files:
            broken.append(target)
    if broken:
        violations.append("Broken wikilinks (no matching .md file in vault):")
        for b in broken[:5]:
            violations.append(f"   • [[{b}]]")
        if len(broken) > 5:
            violations.append(f"   • ... and {len(broken) - 5} more")
        violations.append(
            "   Create the target note or correct the link name. "
            "Broken links corrupt graph traversal."
        )


def check_dedup_registration(file_path, vault_root, violations):
    if not vault_root:
        return
    basename = os.path.basename(file_path)
    slug = basename[:-3]
    dedup_path = os.path.join(vault_root, "notes", "dedup-index.md")
    try:
        with open(dedup_path, "r", encoding="utf-8") as f:
            dedup_content = f.read()
        if slug not in dedup_content:
            violations.append(
                f"[[{slug}]] not registered in dedup-index.md — "
                "did you consult it before writing?"
            )
    except FileNotFoundError:
        pass


def check_moc_bare_links(content, violations):
    """MOC-only check: warn on bare [[link]] lines in Core Ideas section."""
    core_match = re.search(
        r'(?:^|\n)## Core Ideas\n(.*?)(?=\n## |\Z)', content, re.DOTALL
    )
    if not core_match:
        return
    core_body = core_match.group(1)
    bare_pattern = re.compile(r'^- \[\[([^\]]+)\]\]\s*$', re.MULTILINE)
    for m in bare_pattern.finditer(core_body):
        link_target = m.group(1).strip()
        violations.append(
            f"[[{link_target}]] is a bare link — add context phrase explaining why it matters."
        )


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    file_path = data.get("tool_input", {}).get("file_path", "")
    if not file_path:
        sys.exit(0)

    normalised = file_path.replace("\\", "/")
    if "/notes/" not in normalised or not normalised.endswith(".md"):
        sys.exit(0)

    basename = os.path.basename(file_path)

    if basename in SKIP_NAMES:
        sys.exit(0)

    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception:
        sys.exit(0)

    # MOC files: bare-link check only
    if is_moc_file(basename):
        violations = []
        check_moc_bare_links(content, violations)
        if violations:
            print(f"\n⚠️  VAULT VIOLATION — {basename}")
            for v in violations:
                print(f"   {v}" if not v.startswith("   ") else v)
            print("\n   Fix before moving on.")
        sys.exit(0)

    # Atomic notes: full check sequence
    vault_root = find_vault_root(file_path)
    config = load_config(vault_root) if vault_root else None

    # Check 1: Frontmatter block
    if not content.startswith("---"):
        print(f"\n⚠️  VAULT VIOLATION — {basename}")
        print("   No frontmatter block found. Notes require YAML frontmatter.")
        print("\n   Fix before moving on.")
        sys.exit(0)

    violations = []

    # Check 2: Required fields
    missing = []
    for field, label in REQUIRED_FIELDS.items():
        if not re.search(f"^{re.escape(field)}", content, re.MULTILINE):
            missing.append(f"   • {label}")
    if missing:
        violations.append("Missing required frontmatter fields:")
        violations.extend(missing)

    # Check 3: Description length
    check_description_length(content, violations)

    # Check 4: Date formats
    check_date_field(content, "published", violations)
    check_date_field(content, "created", violations)

    # Check 5: source-url prefix
    check_source_url(content, violations)

    # Check 6: source-video wikilink format
    check_source_video_format(content, violations)

    # Check 7: type vocabulary (from validate-config.yaml)
    check_type_field(content, config, violations)

    # Check 8: Topics: footer
    check_topics_footer(content, violations)

    # Check 9: Contradiction soft warning
    check_contradiction_field(content, violations)

    # Check 10: Prose wikilinks (not footer-only)
    body = content
    fm_match = re.match(r'^---\n.*?\n---\n', content, re.DOTALL)
    if fm_match:
        body = content[fm_match.end():]
    topics_split = re.split(r'^---\s*\nTopics:', body, flags=re.MULTILINE)
    pre_topics = topics_split[0] if topics_split else body
    all_links = re.findall(r'\[\[[^\]]+\]\]', body)
    prose_links = re.findall(r'\[\[[^\]]+\]\]', pre_topics)
    if all_links and not prose_links:
        violations.append("Wikilinks are footer-only (all in Topics: section).")
        violations.append(
            "   Embed at least one [[link]] in body prose explaining why you'd follow it."
        )
        violations.append(
            "   Prose links implement spreading activation. Footer links are addresses."
        )

    # Check 11: Broken wikilinks
    check_broken_wikilinks(content, vault_root, violations)

    # Check 12: Dedup registration
    check_dedup_registration(file_path, vault_root, violations)

    if violations:
        print(f"\n⚠️  VAULT VIOLATION — {basename}")
        for v in violations:
            print(f"   {v}" if v and not v.startswith("   ") else v)
        print("\n   Fix before moving on.")


if __name__ == "__main__":
    main()
```

---

### T-VALIDATE-CONFIG: `ops/validate-config.yaml` (Module A only)

```yaml
# Controlled vocabulary for note type field.
# validate-note.py reads this file on every validation run.
# Add or remove values to match this vault's note taxonomy.
# Absence of this file causes a hard error on check 7.

type-vocabulary:
  - insight
  - framework
  - tactic
  - distinction
  - contradiction
```

---

### T-SETTINGS: `.claude/settings.json`

Event keys: `"SessionStart"` and `"SessionEnd"` exactly — not `"Start"` / `"Stop"` / `"SessionStop"`.
`SessionStart` with blank matcher (`""`) matches all sources: startup, resume, clear, compact.
Commands use `bash "$CLAUDE_PROJECT_DIR"/...` for robust path resolution regardless of cwd.

The `permissions.ask` block is **always written** — it gates protected files with native, pre-write
prompts (D5). Rule syntax verified against the official Claude Code permissions docs: `Edit(/path)`
and `Write(/path)` use gitignore-spec patterns; a leading `/path` anchors at the project root (the
settings source); a Read/Edit rule does NOT cover Write, so each protected file needs BOTH an
`Edit(...)` and a `Write(...)` rule. No `protect.py`, no `protected-files.txt`.

**Baseline (Module A not selected):**

```json
{
  "permissions": {
    "ask": [
      "Edit(/CLAUDE.md)",
      "Write(/CLAUDE.md)",
      "Edit(/ops/vault-manifest.md)",
      "Write(/ops/vault-manifest.md)"
    ]
  },
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [{"type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/session-orient.sh"}]
      }
    ],
    "SessionEnd": [
      {
        "matcher": "",
        "hooks": [{"type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/session-capture.sh"}]
      }
    ]
  }
}
```

**Module A selected (adds the `validate-note.py` PostToolUse Write hook):**

```json
{
  "permissions": {
    "ask": [
      "Edit(/CLAUDE.md)",
      "Write(/CLAUDE.md)",
      "Edit(/ops/vault-manifest.md)",
      "Write(/ops/vault-manifest.md)"
    ]
  },
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [{"type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/session-orient.sh"}]
      }
    ],
    "SessionEnd": [
      {
        "matcher": "",
        "hooks": [{"type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/session-capture.sh"}]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [{"type": "command", "command": "python \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/validate-note.py"}]
      }
    ]
  }
}
```

---

### T-CLAUDE: `CLAUDE.md` Assembly

Assemble sections in canonical order 1–20. Sections marked **Always** appear in every vault. Module-conditional sections are omitted when their module is not selected. Do not reorder.

**Global layer fallback:** If `~/.claude/CLAUDE.md` is present and complete, sections 19 (Anti-Patterns) and 20 (Operating Style) may be omitted from the vault CLAUDE.md — one source of truth per rule. If the global layer is absent or incomplete, include them verbatim.

---

**§1 — Header (Always)**

```
# {{VAULT_NAME}}

[One-sentence description of what this vault is for.]

**Start here:** [[compass]][ → [[index]]]
```

Include `→ [[index]]` only if Module A selected. Max 3 lines total.

---

**§2 — Operating Frame (Always)**

For A+B vaults (processing sources into a knowledge base):

```
**Operating frame:**
- **EXTRACT** — process raw sources into atomic notes (`/reduce`)
- **SYNTHESIZE** — traverse the graph to generate insight (`/think`, `/connect`)
- **APPLY** — produce briefs, analyses, memos (`/brief`, `/challenge`)
```

For engineering vaults (D, no A):

```
**Operating frame:**
- **LOCATE** — read compass and hot files to establish current position
- **BUILD** — implement against the architecture; follow code patterns
- **INTEGRATE** — update session handoff, verify, close loop
```

For design/architecture vaults (F, no A):

```
**Operating frame:**
- **ORIENT** — read compass and context/ to understand the problem space
- **DESIGN** — iterate in architecture/; constraints are fixed, form is open
- **VALIDATE** — check against Core Insight and Constraints before shipping
```

Adapt verbs to the vault's actual cognitive mode. Three bold verbs always. Always includes: "State session intent in one sentence before loading any context."

---

**§3 — Commands Table (Always)**

Include only commands from selected modules. Always include the four baseline commands. Precede the table with: "This table IS the command reference. `/guide` renders it — there is no separate guide file."

```
## Commands

This table IS the command reference. `/guide` renders it — there is no separate guide file.

| Command | Purpose |
|---|---|
| `/compass` | Read the compass, or update Focus / Questions / Flags with what changed |
| `/guide` | Render this Commands table |
| `/capture` | Write a narrative session summary to ops/sessions/last-active.md (optional — never load-bearing) |
| `/decide` | Append an operational decision to ops/decisions.md at the moment it is made |
```

Add rows for each module's commands:
- Module A: `/reduce [file]`, `/reflect`, `/connect [note]`, `/think [question]`
- Module C: `/brief [question]`, `/challenge [claim]`
- `/think` appears in both A and C — include once
- Module G: `/scan [topic]`

---

**§4 — Routing Rules (Always)**

```
## Routing Rules

**Layer separation:**

| Layer | File | What lives there |
|---|---|---|
| Contract | `CLAUDE.md` | Rules, schema, commands, architecture, constraints — no live state |
| Decisions | `ops/decisions.md` | Operational calls made, captured at the moment of insight |
| Position | `compass.md` | DECLARED intent only — Focus / Questions / Flags. No derived/live state. |
| Derived | (computed) | Branch, commits, uncommitted/unpushed, recent files, last session — from `session-orient.sh`, never stored |

**When you learn or decide something, route it:**

| Signal | Destination |
|---|---|
| "We're not doing X because Y" (call made) | `ops/decisions.md` (run `/decide`) |
| "What this vault is trying to do now" (intent) | `compass.md` Focus |
| "An open decision that affects direction" | `compass.md` Questions |
| "A known hazard / blocker" | `compass.md` Flags |
| "This applies to how I work in all projects" | `~/.claude/operator.md` |
| "This is a rule for this vault" | `CLAUDE.md` |

Do NOT write current state, session narrative, or counts into any file — that is DERIVED and computed live by orientation (D1).
```

---

**§5 — Context Loading Table (Module E only)**

```
## Context Loading

| Session intent | Load |
|---|---|
| [Intent type 1 — e.g., "Continue feature work"] | [Files to load — e.g., "compass, active branch files"] |
| [Intent type 2 — e.g., "Design review"] | [Files to load] |
| [Intent type 3 — e.g., "Research"] | [Files to load] |
```

Scaffold with 2–3 placeholder rows. User fills for their session types. No row for "read everything".

---

**§6 — Session Handoff (Always — one-liner, genre retired in v4)**

Write verbatim. Do NOT scaffold a fill-in handoff block (D1 retires the genre):

```
## Session Handoff

There is no handoff block — the genre is retired (D1). Continuity is computed: `session-orient.sh`
prints live DERIVED state every session and the compass carries DECLARED intent. Read those.
```

---

**§7 — Tech Stack (Module D)**

```
## Tech Stack

| Layer | Technology | Version | Notes |
|---|---|---|---|
| | | | |
```

---

**§8 — Architecture (Module D)**

```
## Architecture

[Directory tree here — use a code block with the vault's directory structure]

| Directory | Purpose |
|---|---|
| | |
```

---

**§9 — Code Patterns (Module D)**

```
## Code Patterns

**Follow:**
- [pattern — reason]

**Avoid:**
- [pattern — reason]
```

---

**§10 — Protected Files (Always — documents the native permission rules)**

Write verbatim. This section DOCUMENTS the native `permissions.ask` rules in `.claude/settings.json`; it is not a parallel list:

```
## Protected Files

`CLAUDE.md` and `ops/vault-manifest.md` are gated by native permission rules in
`.claude/settings.json` (`permissions.ask`). The harness prompts for approval BEFORE any Edit or
Write to these paths — enforcement is native and pre-write, not a warn-after hook. To protect
another file, add both `Edit(/path)` and `Write(/path)` to the `ask` array (a Read/Edit rule does
not cover Write). There is no protected-files.txt and no protect.py.
```

---

**§11 — Note Rules (Module A)**

Write verbatim:

```
## Note Rules

Every `.md` file written to `notes/` must satisfy all of the following:

**1. Title is a prose proposition.**
Test: "This note argues that [title]" must be grammatically true.
- Pass: *"Identity change must precede behavioral change for discipline to hold"*
- Fail: *"Discipline and Identity"* (a topic, not a claim)

**2. YAML frontmatter with 6 required fields:**

    ---
    description: One sentence (~150 chars) adding scope or mechanism beyond the title
    type: [controlled vocabulary — see ops/validate-config.yaml]
    source-video: "[[source-slug-in-archive]]"
    source-url: https://[source-url]
    published: YYYY-MM-DD
    created: YYYY-MM-DD
    ---

**3. Description adds beyond the title.**
Must add scope, mechanism, or implication the title doesn't cover.
Restating the title in different words fails.

**4. Topics: footer — required on every note.**

    ---
    Topics:
    - [[domain-moc]]

This is body content (not YAML). It declares MOC membership and makes the graph traversable.

**5. Wikilinks pass the articulation test.**
Every `[[link]]` in prose must be explainable: *"connects because [specific reason]."*
Valid relationship types: extends, grounds, contradicts, exemplifies, synthesizes, enables.
- Pass: *"Since [[prior-note]], the mechanism here is..."*
- Fail: *"See also: [[prior-note]]"*

**6. Generate; do not transcribe.**
Transform the source claim into your formulation. Verbatim phrasing from the source fails.
If you can't argue with the note's claim, it is a summary, not an insight.

**7. Deduplicate before creating.**
Search `notes/dedup-index.md` before writing any note.
Enrich or contradict an existing note rather than duplicating it.

`validate-note.py` fires on every Write to `notes/`. Fix violations before continuing.
```

---

**§12 — MOC Rules (Module A)**

```
## MOC Rules

Every domain MOC must have:
- **Brief orientation** (2–3 sentences: what this domain covers, where to start)
- **Core Ideas** — grouped by conceptual cluster (e.g., **Foundation** → **Framework** → **Applied**); each entry has a context phrase explaining *why* it matters. Never bare links.
- **Tensions** — unresolved conflicts within this domain
- **Open Questions** — gaps needing exploration
- Parent link to `[[index]]`
```

---

**§13 — Schema Enforcement (Module A)**

```
## Schema Enforcement

`validate-note.py` fires on PostToolUse Write to `notes/`. Checks (in order):

1. Frontmatter block present
2. Required fields: description, type, source-video, source-url, published, created
3. Description length: 50–200 characters
4. Date format: YYYY-MM-DD for published and created
5. source-url matches vault's canonical URL prefix (if configured)
6. source-video format: wikilink `[[...]]`
7. type vocabulary: controlled list from ops/validate-config.yaml (hard error if file absent)
8. Topics: footer section present in body
9. Contradiction field: soft warning if type: contradiction but no contradicts: field
10. Prose wikilinks: wikilinks must appear in body prose, not only in Topics footer
11. Broken wikilinks: [[target]] must resolve to an existing file in vault
12. Dedup registration: slug must appear in dedup-index.md

MOC files (-moc.md): bare-link check only (checks 1–12 skipped).
Infrastructure files (compass, methods, index, dedup-index): fully skipped.

Fix before moving on.
```

---

**§14 — Core Insight (Module F)**

```
## Core Insight

[Single paragraph. The fundamental insight driving this project's design.
Not aspirational — what actually makes this different from the generic version of this problem.
Leave blank until the insight is earned, not assumed.]
```

---

**§15 — Constraints (Module F)**

```
## Constraints

Genuinely fixed constraints only. If it can be changed with effort, it is not a constraint.

- [constraint 1]
- [constraint 2]
```

---

**§16 — Epistemic Rules (Module G)**

Write verbatim:

```
## Epistemic Rules

- A fact needs a name, date, or number — or mark it a hypothesis.
- Never pass off synthesis as sourced research.
- When WebSearch fails: declare epistemic status explicitly or surface the blocker. Never silently pivot to training knowledge.
- Unverified claims in body: `~Unverified: claim text~ [needs source]`
- Every intel note must carry a verifiable URL or declare `status: unverified-draft`
```

---

**§17 — Anti-Patterns (Always — unless global layer present)**

Write universal anti-patterns verbatim first, then add module-specific entries:

```
## Anti-Patterns

**Don't paste live state into CLAUDE.md or the compass.** State is computed by orientation; a stored copy only goes stale and misdirects.
**Don't read all context files upfront.** Orientation already gave you the map — load on demand, by session intent.
**Don't reason from scratch.** Pull from ops/decisions.md, the compass, and git history first.
**Don't presume the form of the solution.** Locks architecture before the problem is understood.
**Don't cargo-cult another vault's architecture.** Different problem, different constraints.
**Don't catch and swallow errors in hooks.** A check that cannot run must say so; it never defaults to "fine."
**Don't hardcode domain data in logic.** Makes the system brittle to configuration changes.
**Don't write to decisions.md at session end.** Capture at the moment of insight; run /decide.
**Don't skip /decide at the moment a decision is made.** Missing an entry means the next session re-litigates from scratch.
**Don't use SessionStop as a hook event.** It does not exist; hooks wired to it silently never fire.
**Don't rely on SessionEnd for VS Code tab close.** It doesn't fire on tab close; use /capture instead.
**Don't read a foreign vault beyond its declared `exports:`.** Everything not exported is invisible cross-vault — notes/ above all.
**Don't write to a foreign vault's knowledge graph without explicit instruction.** Deposit into its declared `intake:` instead; never edit in place.
**Don't apply local vault schema rules to foreign vault content.** Each vault has its own schema and validate hooks.
**Don't prune operator.md entries autonomously.** Cross-session entry value is invisible to a single-session observer; flag and defer to human.
```

Module-specific entries to add after:
- Module A: `**Don't write notes that describe rather than argue.** A summary is not an insight.`
- Module B: `**Don't archive without updating backlog.** The backlog is the source of truth for processing history.`
- Module G: `**Don't include unverified claims without epistemic markers.** Mark with ~Unverified: claim~ [needs source] or don't include.`

---

**§18 — Operating Style (Always — unless global layer present)**

```
## Operating Style

- Sharp. No wasted words.
- State session intent in one sentence before loading any context.
- [vault-specific constraint]
```

Always begins with "Sharp. No wasted words." Always includes the session intent line. Then vault-specific constraints.

---

### T-COMPASS: `compass.md`

Location: always `compass.md` at vault root. **Slim (D1): exactly Focus / Questions / Flags + the `*Updated:*` stamp and the contract comment.** No Vault State, Key Files, or Hot Files tables — those are derived state and belong to the orient hook, not the compass.

```markdown
<!--
COMPASS CONTRACT — Vault OS v4 (D1: continuity is computed, not curated)
Holds ONLY what git cannot tell you: declared intent, open decisions, known hazards.
DERIVED state (branch, commits, uncommitted/unpushed, recent files, last session) is computed
live by session-orient.sh every session — never write it here. Update *Updated:* when you edit a
section; past 30 days orientation treats this content as historical.
-->

# Compass

*Updated: {{SCAFFOLD_DATE}}*

## Focus

[What this vault is trying to do right now — one or two sentences of intent, not history. Vault just created.]

## Questions

[Open decisions that affect direction. Number them. None yet.]

## Flags

[Known hazards or blockers. None.]
```

Do NOT append Key Files or Hot Files tables (retired in v4). Modules D and E add their tables to CLAUDE.md, not the compass.

---

### T-DECISIONS: `ops/decisions.md` (Always)

```markdown
# Decisions

*Operational decisions made this project. Injected at every session start.*
*Run /decide at the moment a decision is made — not at session end.*

<!-- Format: - [YYYY-MM-DD] Decision: [what]. Because: [rationale]. Forecloses: [what this rules out]. -->
<!-- Delete an entry when it is reversed or the project moves past it. -->
```

---

### T-INDEX: `notes/index.md` (Module A only)

```markdown
# {{VAULT_NAME}} — Index

[2–3 sentences describing what this vault covers and how to navigate it.]

## Domains

[For each domain identified in Phase 0, add a link and one-line description:]
- [[domain-name-moc]] — [what this domain covers]

[If no domains identified yet:]
- [Add domain MOC links here as the vault is built]

---

**This vault:** [[compass]]
```

---

### T-DEDUP: `notes/dedup-index.md` (Module A only)

```markdown
# Dedup Index

<!-- Auto-maintained by /reduce Phase 6. Do not edit manually. -->
<!-- Format: slug | description (~150 chars) | moc1, moc2 -->
```

---

### T-METHODS: `notes/methods.md` (Module A only)

```markdown
# Methods

Vault-specific operating procedures. Read this before beginning a new processing run.

## Processing Protocol

[Describe the standard workflow for this vault.]
[Example: 1. Drop source files in inbox/. 2. Run /reduce. 3. Run /repair every 20–30 notes. 4. Run /reflect monthly.]

## Deduplication Rules

- Same phenomenon at same abstraction level → enrich existing note, do NOT create a duplicate
- Same phenomenon at different abstraction level (what vs. why vs. how) → distinct note; link explicitly
- Check dedup-index.md before creating any note

## MOC Maintenance

- Core Ideas: grouped by conceptual cluster (Foundation → Framework → Applied)
- Context phrases: added in batch during /repair, not during /reduce
- Bare links are acceptable during active processing; fill context phrases during /repair
```

---

### T-MOC-STUB: Domain MOC stub (Module A, one per domain)

Filename: `notes/[domain-slug]-moc.md`

```markdown
# [Domain Name]

[2–3 sentences: what this domain covers and what the foundational concept to start with is.]

---

## Core Ideas

**Foundation**

**Framework**

**Applied**

---

## Tensions

[Unresolved conflicts within this domain. Add as they emerge.]

---

## Open Questions

[Gaps needing exploration. Add as they emerge.]

---

**Parent:** [[index]]
```

---

### T-MANIFEST: `ops/vault-manifest.md` (Always)

v4 context contract (D3). YAML frontmatter (`---` delimited, consistent with the meta-vault registry). Required fields: `vault-name`, `root-path`, `created`, `last-verified`, `features`, `domains`, and an `exports:` block. A manifest missing `exports:` is read by the orient hook as pre-v4 and triggers a migration offer.

```yaml
---
# ─────────────────────────────────────────────────────────────────────────────
# VAULT MANIFEST — Vault OS v4 context contract (D3: sharing by contract, isolation by default)
#   exports: — the ONLY surfaces a foreign session/agent may READ. Everything not listed is
#              invisible cross-vault (notes/ above all). Isolation is default; sharing is opt-in.
#   intake:  — (optional) deposit-only inbound surface; foreign writers drop new files, never edit.
#   domains: — discovery metadata; foreign intent must match before any load is allowed.
# ─────────────────────────────────────────────────────────────────────────────
vault-name: {{VAULT_NAME}}
root-path: {{VAULT_PATH}}
created: {{SCAFFOLD_DATE}}
last-verified: {{SCAFFOLD_DATE}}
features: [{{FEATURES_LIST}}]
domains:
  - [domain 1 from Phase 0]
  - [domain 2 from Phase 0]

exports:
  compass: compass.md
  [If Module A:] index: notes/index.md      # export the graph ENTRY POINT only — never notes/ itself
  [If Module F:] architecture: architecture/
  # Anything not listed here is invisible cross-vault. Do NOT export notes/.

# intake:                # optional — deposit-only surface for foreign writers/agents
#   [If Module B:] inbox: inbox/

cross-vault-dependencies: []
# Declare an entry ONLY if THIS vault loads from another. Shape:
#   - vault: /absolute/path/to/other-vault   # absolute, forward slashes, no trailing slash
#     slug: 8charsha1                          # first 8 chars of SHA1(normalized root-path)
#     loads-from: [compass]                    # which of that vault's declared EXPORTS this vault reads
---
```

Emit only the `exports:` / `intake:` keys that apply to selected modules. Remove the `[If Module X:]` markers from the final file. If no domains were identified in Phase 0, write `  - [none yet — add as vault is built]` under `domains:`.

---

### T-BACKLOG: `ops/processing-backlog.md` (Module B only)

```markdown
# Processing Backlog

Source of truth for what has been processed and when.
Format: `- [x] Filename — YYYY-MM-DD` when processed.

## Queue

[Add source files here as they arrive in inbox/:]
- [ ] (empty — vault just initialized)
```

---

### T-CMD-COMPASS: `.claude/commands/compass.md` (Always)

```
$ARGUMENTS

Read `compass.md` in full.

If no argument: produce an interpreted report of the three DECLARED sections —
1. **Focus** — what the vault is trying to do now
2. **Questions** — open decisions, priority ordered
3. **Flags** — known hazards / blockers
Do NOT restate git-derived state here (branch, commits, counts) — that is DERIVED and already
shown by orientation. Be honest; don't inflate.

If argument provided — intent changed:
1. Parse what changed
2. Update the relevant section(s) of compass.md — Focus / Questions / Flags only
3. Update `*Updated: [date]*` timestamp to today
4. Report: which sections changed

Keep it honest. The compass holds only what git cannot tell you.
```

---

### T-CMD-GUIDE, T-CMD-CAPTURE, T-CMD-DECIDE

These are global commands (`~/.claude/commands/`). Do not scaffold them locally. They are available in every vault automatically. `/guide` renders CLAUDE.md's Commands table (there is no `ops/guide.md`). `/maintain` is retired in v4 along with `knowledge.md` — do not reference it.

---

### T-CMD-REDUCE: `.claude/commands/reduce.md` (Module A; full pipeline requires Module B)

```
Source files: $ARGUMENTS
(Space-separated list. Single file is valid.)

---

## Phase 1: Orientation reads (parallel)

1. Read source file(s) from `inbox/` (or vault root if Module B not present)
2. Read `compass.md` for current vault state
3. Glob `notes/*.md` to get the full current note list

---

## Phase 2: Overlap scan

Read `notes/dedup-index.md` first. Identify existing notes that overlap with this source's themes.
Read candidate notes in parallel before extracting any new claims.

Overlap rules:
- Same phenomenon at same abstraction level → enrich or contradict existing note; do NOT create a duplicate
- Same phenomenon at different abstraction level (what vs. why vs. how) → distinct note; link explicitly
- Contradicting existing note → use `type: contradiction` and link with articulated reason

---

## Phase 3: Plan

Declare source-url once for this batch.
Output plan table before creating any file:

| # | Filename | Proposition (one sentence) | MOC(s) | Source |
|---|----------|---------------------------|---------|--------|

Write in foundation-before-elaboration order. Do not start writing until the plan table is complete.

---

## Phase 4: Write

Each note must satisfy:
- Title: prose proposition. Test: "This note argues that [title]" must be grammatically true.
- Body: develop the claim with visible reasoning ("because," "therefore," "this suggests").
- Wikilinks: pass the articulation test: "[[note]] connects because [specific reason]."
- Full YAML frontmatter (6 required fields):

      ---
      description: ~150 chars adding scope/mechanism beyond title (not a restatement)
      type: [from ops/validate-config.yaml vocabulary]
      source-video: "[[source-slug]]"
      source-url: [url]
      published: YYYY-MM-DD
      created: YYYY-MM-DD
      ---

- Topics: footer (body content, not YAML):

      ---
      Topics:
      - [[domain-moc]]

Quality gate: each note must be specific (named mechanism or framework), non-obvious, and arguable.

---

## Phase 5: Update MOC files

Add each new note as a bare link under the correct conceptual cluster in Core Ideas.
Context phrases are written in batch during periodic /repair runs — bare links are acceptable now.

---

## Phase 6: Housekeeping (requires Module B for archive steps)

1. Append to `notes/dedup-index.md` — format: `slug | description | moc1, moc2`
2. Archive source file(s) to `archive/transcripts/` (Module B only)
3. Update `ops/processing-backlog.md` (Module B only)
4. Update compass counts

---

## Phase 7: Report

Notes created, domains landed, cross-links made to existing notes, broken links deferred,
contradictions found, what remains thin.

Extract claims; do not summarize.
```

---

### T-CMD-BRIEF: `.claude/commands/brief.md` (Module C)

```
$ARGUMENTS

Read `compass.md` first. Then read `notes/index.md`.

Navigate vault: follow domain MOC links relevant to the question. Read relevant notes.

Produce a memo:
- Max 400 words
- BLUF (bottom line up front)
- Pull from vault content — do not reason from scratch
- Name the specific notes you drew from
- Flag if vault coverage is thin on this topic

Sharp. No filler.
```

---

### T-CMD-THINK: `.claude/commands/think.md` (Module A; Module C shares this — write once)

```
$ARGUMENTS

Cross-domain synthesis. Reason; do not summarize.

1. Read `compass.md` for vault context
2. Read `notes/index.md`. Identify all domains that bear on this question — including non-obvious ones.
3. Read relevant notes. Extract specific claims — named frameworks, mechanisms, distinctions.
4. Name explicitly what each domain contributes and how the contributions connect.
5. Think through the question — show reasoning, options, tradeoffs.
6. Clear position + what would flip it.

Direct. No filler. Genuine reasoning, not performed reasoning.
```

---

### T-CMD-CHALLENGE: `.claude/commands/challenge.md` (Module C)

```
$ARGUMENTS

If argument names a note, read it in full.
If argument states a claim, treat as proposition.

Step 1: Steel-man — make the strongest possible case using vault specifics, not generic arguments.
Step 2: Attack — find real weaknesses: assumed without evidence, contradicted by other vault notes,
        exploitable by a critic.
Step 3: Verdict — ready to use as-is, or what needs resolving first?

Before steelmanning, check whether the vault contains contradictory notes on the same topic.
A contradiction found is a better result than a confirmed position.

Tone: adversarial. Find holes before someone else does.
```

---

### T-CMD-CONNECT: `.claude/commands/connect.md` (Module A)

```
$ARGUMENTS

Graph traversal task. Find non-obvious cross-domain connections for a note or concept.

1. If argument names a note, read it in full.
   If argument states a concept, find the most relevant existing note(s) first.
2. Read `notes/index.md` to map all domains.
3. For each domain not currently linked to this note: ask whether any mechanism here operates the
   same way, produces the same outcome, or prevents the same thing.
4. Read relevant notes to confirm. Do not guess.
5. Apply the articulation test to each candidate: can you complete "[[this note]] connects to
   [[candidate]] because [specific mechanism]"? If not, skip it.
6. Output: list of non-obvious connections with one sentence explaining the linking mechanism.
7. Ask: should any of these be written as new notes or added as prose wikilinks in existing notes?

/connect maps an existing note outward across the graph. /think reasons about a question.
```

---

### T-CMD-REFLECT: `.claude/commands/reflect.md` (Module A)

```
Vault health audit. Scan all domains.

1. **Orphaned notes** — notes with no wikilinks in or out, or missing Topics: footer
2. **Dangling wikilinks** — [[links]] pointing to notes that do not exist
3. **Schema violations** — notes in notes/ missing required YAML fields or missing Topics: footer
4. **Stale MOCs** — bare links with no context phrases; notes listed as stubs never created
5. **Thin domains** — MOC file exists but fewer than 5 substantive notes
6. **Unlinked contradictions** — notes with type: contradiction lacking a contradicts: field,
   or pairs of notes making conflicting claims without explicit linking
7. **Near-duplicates** — notes making essentially the same claim from different sources

Write full report to `ops/health/YYYY-MM-DD-reflect.md` (dated file).
Summarize findings in chat.
Recommend: which failure mode is most urgent to address first, and why.
```

---

### T-CMD-SCAN: `.claude/commands/scan.md` (Module G)

```
$ARGUMENTS

Live intelligence sweep on the given topic.

1. Read `compass.md` for current vault state
2. Read `notes/dedup-index.md` to identify existing coverage on this topic
3. WebSearch for the topic — use multiple queries if needed for coverage
4. Evaluate each result:
   - Enriches an existing note → read that note, update with new information + source URL
   - Represents genuinely new content → create an intel note in notes/
5. Every intel note must carry a verifiable URL in source-url frontmatter
6. Unverified claims: mark `~Unverified: claim text~ [needs source]`
7. If WebSearch fails: declare epistemic status explicitly. Never silently pivot to training knowledge.

Intel notes use the same 6-field schema as atomic notes. source-url is mandatory — no URL, no note.

Report: what was found, what was updated, what remains unverified.
```

---

## Verification Checklist

After scaffolding, verify:

1. `bash .claude/hooks/session-orient.sh --selftest` passes; `bash .claude/hooks/session-capture.sh --selftest` passes
2. Open vault root in a new Claude Code session → orientation fires; DERIVED (branch/commits/…) and DECLARED (compass Focus/Questions/Flags) both appear
3. `compass.md` exists at vault root with exactly Focus / Questions / Flags + an `*Updated:*` stamp (no Vault State / Key Files / Hot Files)
4. `ops/vault-manifest.md` frontmatter has `vault-name`, `root-path`, `created`, `last-verified`, `features`, `domains`, and an `exports:` block
5. `.claude/settings.json` is valid JSON; wires `"SessionStart"` and `"SessionEnd"` (not "SessionStop") with `bash "$CLAUDE_PROJECT_DIR"/…` commands
6. `.claude/settings.json` has `permissions.ask` rules: `Edit(/CLAUDE.md)`, `Write(/CLAUDE.md)`, `Edit(/ops/vault-manifest.md)`, `Write(/ops/vault-manifest.md)`
7. Editing `CLAUDE.md` triggers a native permission prompt; there is NO `protect.py` and NO `protected-files.txt`; there is NO `ops/knowledge.md` and NO `ops/guide.md`
8. `ops/decisions.md` exists with header comment
9. **If Module A:** `ops/validate-config.yaml` exists with `type-vocabulary`; `validate-note.py` present and wired as a PostToolUse Write hook
10. **If Module A:** Write a malformed note to `notes/` → `validate-note.py` outputs violation with "Fix before moving on."
11. **If Module A:** Write a note with a type not in validate-config.yaml → check 7 fires; unregistered slug → dedup check fires; bare MOC link → bare-link warning fires
12. Run `/guide` → renders CLAUDE.md's Commands table; `/compass` → reads compass and returns oriented report
13. **If Module A + C:** Run `/brief [question]` → reads compass, navigates graph, returns memo
