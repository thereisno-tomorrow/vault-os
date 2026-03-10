---
name: new-vault
description: Scaffold a new vault conforming to vault-os-v2. Invoked when user says "new vault", "create vault", "scaffold vault", or describes a project that needs a vault. Extracts context from chat, asks ≤3 questions, confirms, then writes all files.
---

# new-vault

Scaffold a complete vault conforming to vault-os-v2 standards. When invoked, execute phases 0–4 below. All file content is defined inline — no external files consulted at runtime. Everything needed is here.

---

## Module Catalog

The vault manifest (`ops/vault-manifest.md`) is always created — it is a baseline component, not a module.

| ID | Name | Key additions | Requires |
|---|---|---|---|
| A | Knowledge Graph | `notes/` (flat), MOCs, `dedup-index.md`, `validate-note.py`, `ops/validate-config.yaml`, `/reduce` `/reflect` `/connect` `/think` | — |
| B | Inbox Pipeline | `inbox/`, `archive/transcripts/`, `processing-backlog.md`, full `/reduce` pipeline | A |
| C | Synthesis Commands | `/brief`, `/challenge` (+ `/think` shared with A) | A |
| D | Project State | Session Handoff, Hot Files in compass.md, Tech Stack, Architecture, Code Patterns, Protected Files, `protect.py` | — |
| E | Context Loading Table | Context Loading Table in CLAUDE.md + Key Files Table in compass.md | — |
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
Hooks: session-orient.sh, session-capture.sh[, validate-note.py (Module A)][, protect.py (Module D)]
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

**Step 6 (Module D only): Write `.claude/hooks/protect.py`** — see T-PROTECT. Also write `.claude/protected-files.txt` — see T-PROTECTED.

**Step 7: Write `.claude/settings.json`** — see T-SETTINGS. Choose the correct variant based on modules selected.

**Step 8: Write `CLAUDE.md`** — assemble sections per T-CLAUDE. Sections in canonical order 1–20; omit module-conditional sections when their module is not selected.

**Step 9: Write `compass.md`** — see T-COMPASS.

**Step 10: Write `ops/knowledge.md`** — see T-KNOWLEDGE. Always.

**Step 11: Write `ops/decisions.md`** — see T-DECISIONS. Always.

**Step 12 (Module A): Write `notes/index.md`, `notes/dedup-index.md`, `notes/methods.md`** — see T-INDEX, T-DEDUP, T-METHODS.

**Step 13 (Module A, only if domains identified in Phase 0): Write domain MOC stubs** — see T-MOC-STUB. One file per domain.

**Step 14: Write `ops/vault-manifest.md`** — see T-MANIFEST. Always.

**Step 15 (Module B): Write `ops/processing-backlog.md`** — see T-BACKLOG.

**Step 16: Write `.claude/commands/` files** — write one file per active command:
- Always: `compass.md` (T-CMD-COMPASS) — local override because new vaults place compass at root, not ops/
- Note: `capture.md`, `decide.md`, `guide.md`, `maintain.md` are global commands in `~/.claude/commands/` — do NOT scaffold them locally
- Module A: `reduce.md` (T-CMD-REDUCE), `reflect.md` (T-CMD-REFLECT), `connect.md` (T-CMD-CONNECT), `think.md` (T-CMD-THINK)
- Module C: `brief.md` (T-CMD-BRIEF), `challenge.md` (T-CMD-CHALLENGE). If A already wrote `think.md`, do not write it again.
- Module G: `scan.md` (T-CMD-SCAN)

**Step 17: Write `ops/guide.md`** — see T-GUIDE. Include only commands from selected modules.

---

### Phase 4 — Report

```
Created: N files in X directories

[directory tree of what was created]

Start here: compass.md
First action: [what to do now — e.g., "Add your first source file to inbox/ then run /reduce" or "Fill Session Handoff in CLAUDE.md with current project state" or "Add domains to notes/index.md"]
```

---

## File Templates

---

### T-ORIENT: `.claude/hooks/session-orient.sh`

Write this file verbatim. Omit the Module B inbox block if Module B not selected. Omit the Module A notes listing block and MODULE A HEALTH block if Module A not selected.

```bash
#!/bin/bash
# session-orient.sh — Fires at SessionStart (all sources including compact).
# Conforms to vault-os-v2.

VAULT="${CLAUDE_PROJECT_DIR:?ERROR: CLAUDE_PROJECT_DIR not set — hook must be invoked by Claude Code}"
[[ -f "$VAULT/CLAUDE.md" ]] || { echo "ERROR: VAULT root invalid at $VAULT"; exit 1; }

# Derive vault name from manifest for runtime state directory
VAULT_NAME=$(awk '/^vault-name:/{gsub(/vault-name:[[:space:]]*|"/, ""); print; exit}' \
  "$VAULT/ops/vault-manifest.md" 2>/dev/null || echo "unnamed")
RUNTIME_DIR="$HOME/.claude/vault-runtime/$VAULT_NAME"
mkdir -p "$RUNTIME_DIR"

echo "╔══════════════════════════════════════════╗"
echo "║       $VAULT_NAME ORIENTATION              ║"
echo "╚══════════════════════════════════════════╝"
echo "Date: $(date +%Y-%m-%d)"

# Operator profile (always — conditional on file existence)
if [ -f "$HOME/.claude/operator.md" ]; then
  echo ""
  echo "--- OPERATOR PROFILE ---"
  cat "$HOME/.claude/operator.md"
fi

# [CONDITIONAL MODULE B — omit this block if Module B not selected]
if [ -d "$VAULT/inbox" ]; then
  echo ""
  echo "--- INBOX ---"
  COUNT=$(find "$VAULT/inbox" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  echo "Transcripts in inbox: $COUNT"
fi
# [END MODULE B BLOCK]

# [CONDITIONAL MODULE A — omit this block if Module A not selected]
if [ -d "$VAULT/notes" ]; then
  echo ""
  echo "--- NOTES STRUCTURE ---"
  find "$VAULT/notes" -maxdepth 1 -name "*.md" | sort | sed "s|$VAULT/notes/||"
fi
# [END MODULE A BLOCK]

# Last session (always — conditional on file existence)
echo ""
echo "--- LAST SESSION ---"
if [ -f "$VAULT/ops/sessions/last-active.md" ]; then
  cat "$VAULT/ops/sessions/last-active.md"
else
  echo "No prior session."
fi

# Decisions (always — conditional on file existence)
if [ -f "$VAULT/ops/decisions.md" ]; then
  echo ""
  echo "--- DECISIONS ---"
  cat "$VAULT/ops/decisions.md"
fi

# Knowledge — Core section only (always — conditional on file existence)
if [ -f "$VAULT/ops/knowledge.md" ]; then
  echo ""
  echo "--- KNOWLEDGE ---"
  if grep -q "^## Core" "$VAULT/ops/knowledge.md" 2>/dev/null; then
    awk '/^## Core/{found=1; next} found && /^## /{exit} found{print}' \
      "$VAULT/ops/knowledge.md"
    CORE_LINES=$(awk '/^## Core/{f=1;next} f&&/^## /{exit} f&&/^-/{c++} END{print c+0}' \
      "$VAULT/ops/knowledge.md")
    EXT_COUNT=$(awk '/^## Extended/{f=1;next} f&&/^## /{exit} f&&/^-/{c++} END{print c+0}' \
      "$VAULT/ops/knowledge.md")
    DEC_COUNT=$(grep -c "^-" "$VAULT/ops/decisions.md" 2>/dev/null || echo 0)
    MAINT=""
    if [ "$EXT_COUNT" -gt 20 ] || [ "$DEC_COUNT" -gt 30 ]; then
      MAINT=" — /maintain recommended"
    fi
    echo "KNOWLEDGE: Core $CORE_LINES lines | Extended $EXT_COUNT entries | decisions.md $DEC_COUNT entries$MAINT"
  else
    echo "KNOWLEDGE: knowledge.md has no Core/Extended structure — run /maintain to migrate."
  fi
fi

# Quest context (always — conditional on quest-link field in manifest)
if [ -f "$VAULT/ops/vault-manifest.md" ]; then
  QUEST_LINK=$(awk '/^quest-link:/{gsub(/quest-link:[[:space:]]*|"/, ""); print; exit}' \
    "$VAULT/ops/vault-manifest.md" 2>/dev/null)
  if [ -n "$QUEST_LINK" ]; then
    QUEST_FILE="$VAULT/$QUEST_LINK"
    if [ -f "$QUEST_FILE" ]; then
      echo ""
      echo "--- QUEST CONTEXT ---"
      head -30 "$QUEST_FILE"
      if ! head -5 "$QUEST_FILE" | grep -qE '^(---|##|\*\*)'; then
        echo "WARNING: QUEST CONTEXT: no front-matter detected in first 30 lines of $QUEST_LINK." >&2
        echo "Quest file should open with a summary block." >&2
      fi
    else
      echo "WARNING: quest file not found at $QUEST_LINK. Update ops/vault-manifest.md or create the file." >&2
    fi
  fi
fi

# [CONDITIONAL MODULE A — omit this block if Module A not selected]
echo ""
echo "--- MODULE A HEALTH ---"
if [ ! -d "$VAULT/notes" ]; then
  echo "MODULE A HEALTH: notes/ directory not found — Module A not initialized."
elif [ ! -f "$VAULT/notes/index.md" ]; then
  echo "MODULE A HEALTH: notes/index.md not found — MOC link check skipped."
else
  NOTE_COUNT=$(find "$VAULT/notes" -maxdepth 1 -name "*.md" \
    ! -name "*-moc.md" ! -name "index.md" ! -name "dedup-index.md" ! -name "methods.md" \
    2>/dev/null | wc -l | tr -d ' ')
  echo "MODULE A HEALTH: $NOTE_COUNT notes tracked, index.md present."
  for moc in "$VAULT/notes/"*-moc.md; do
    [ -f "$moc" ] || continue
    MOC_NAME=$(basename "$moc" .md)
    if ! grep -q "\[\[$MOC_NAME\]\]" "$VAULT/notes/index.md" 2>/dev/null; then
      echo "  Unlinked MOC: $MOC_NAME"
    fi
  done
fi
# [END MODULE A BLOCK]

# Manifest drift check (always — conditional on manifest existence)
if [ -f "$VAULT/ops/vault-manifest.md" ]; then
  echo ""
  echo "--- MANIFEST DRIFT CHECK ---"
  TODAY=$(date +%Y-%m-%d)
  LAST_VERIFIED=$(awk '/^last-verified:/{gsub(/last-verified:[[:space:]]*|"/, ""); print; exit}' \
    "$VAULT/ops/vault-manifest.md" 2>/dev/null)
  WARN_FILE="$RUNTIME_DIR/.last-manifest-warning"
  LAST_WARNED=$(cat "$WARN_FILE" 2>/dev/null || echo "1970-01-01")
  if [ -n "$LAST_VERIFIED" ] && [ "$LAST_WARNED" != "$TODAY" ]; then
    DAYS_OLD=$(python3 -c \
      "from datetime import date; print((date.today()-date.fromisoformat('$LAST_VERIFIED')).days)" \
      2>/dev/null || echo 0)
    if [ "$DAYS_OLD" -gt 7 ]; then
      echo "⚠️  MANIFEST: last-verified $LAST_VERIFIED is $DAYS_OLD days old. Review and stamp ops/vault-manifest.md."
      echo "$TODAY" > "$WARN_FILE"
    fi
  fi
  # Check export-surfaces paths exist
  awk '/^export-surfaces:/{f=1;next} f&&/^[a-z]/{exit} f&&/:[[:space:]]+[^[#{]/{print}' \
    "$VAULT/ops/vault-manifest.md" | grep -oP ':[[:space:]]+\K[\w/.-]+' | while read -r path; do
    [ -n "$path" ] && [ ! -e "$VAULT/$path" ] && \
      echo "⚠️  DRIFT: export-surface '$path' not found. Update ops/vault-manifest.md."
  done
  # Quest-link file existence
  QUEST_LINK=$(awk '/^quest-link:/{gsub(/quest-link:[[:space:]]*|"/, ""); print; exit}' \
    "$VAULT/ops/vault-manifest.md" 2>/dev/null)
  if [ -n "$QUEST_LINK" ] && [ ! -f "$VAULT/$QUEST_LINK" ]; then
    echo "WARNING: quest file not found at $QUEST_LINK. Fix: update quest-link or create the file."
  fi
fi

# Operational state — always last
echo ""
echo "--- OPERATIONAL STATE ---"
cat "$VAULT/compass.md" 2>/dev/null || echo "(compass.md not found)"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  Run /capture before closing this tab.   ║"
echo "╚══════════════════════════════════════════╝"
```

**Hard constraints:**
- `VAULT` set from `$CLAUDE_PROJECT_DIR` with sentinel check — never hardcode paths.
- Do NOT cat CLAUDE.md, notes, or any file beyond those listed above.
- Module A and B blocks are included or omitted at scaffold time based on module selection.
- `RUNTIME_DIR` created before any suppress file read or write.

---

### T-CAPTURE: `.claude/hooks/session-capture.sh`

Fallback for clean `/exit`. Primary capture is `/capture` (VS Code tab close does not fire SessionEnd).

```bash
#!/bin/bash
# session-capture.sh — Fires at SessionEnd on clean exit.
# Primary capture path: /capture slash command.

VAULT="${CLAUDE_PROJECT_DIR:?ERROR: CLAUDE_PROJECT_DIR not set — hook must be invoked by Claude Code}"
mkdir -p "$VAULT/ops/sessions"
{
  echo "Date: $(date +%Y-%m-%d)"
  echo ""
  echo "Session ended via clean exit. Run /capture for a full paragraph summary."
} > "$VAULT/ops/sessions/last-active.md"
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

### T-PROTECT: `.claude/hooks/protect.py` (Module D only)

```python
#!/usr/bin/env python3
"""
protect.py — Fires on PostToolUse Write.
Warns when a file listed in .claude/protected-files.txt is written to.
"""

import sys
import json
import os

VAULT = os.environ.get("CLAUDE_PROJECT_DIR", "")
if not VAULT:
    sys.exit(0)

PROTECTED_LIST = os.path.join(VAULT, ".claude", "protected-files.txt")


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    file_path = data.get("tool_input", {}).get("file_path", "")
    if not file_path:
        sys.exit(0)

    try:
        with open(PROTECTED_LIST, "r", encoding="utf-8") as f:
            protected = [
                line.strip() for line in f
                if line.strip() and not line.startswith("#")
            ]
    except FileNotFoundError:
        sys.exit(0)

    if not protected:
        sys.exit(0)

    norm_vault = VAULT.replace("\\", "/").rstrip("/")
    norm_written = file_path.replace("\\", "/")
    if norm_written.startswith(norm_vault + "/"):
        relative = norm_written[len(norm_vault) + 1:]
    else:
        relative = norm_written

    if relative in protected:
        print(f"\n⚠️  PROTECTED FILE — {relative}")
        print("   Requires explicit user permission before modifying.")


if __name__ == "__main__":
    main()
```

---

### T-PROTECTED: `.claude/protected-files.txt` (Module D only)

```
# Protected files — one relative path per line (from vault root)
# Example: CLAUDE.md
# Keep in sync with the Protected Files section in CLAUDE.md.
# The protect.py hook reads this file on every Write event.
```

---

### T-SETTINGS: `.claude/settings.json`

Event keys: `"SessionStart"` and `"SessionEnd"` exactly — not `"Start"` / `"Stop"` / `"SessionStop"`.
`SessionStart` with blank matcher (`""`) matches all sources: startup, resume, clear, compact.
PostToolUse Write hook required only when Module A or Module D is present.

**Neither A nor D selected:**

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [{"type": "command", "command": "bash .claude/hooks/session-orient.sh"}]
      }
    ],
    "SessionEnd": [
      {
        "matcher": "",
        "hooks": [{"type": "command", "command": "bash .claude/hooks/session-capture.sh"}]
      }
    ]
  }
}
```

**Module A selected, Module D not selected:**

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [{"type": "command", "command": "bash .claude/hooks/session-orient.sh"}]
      }
    ],
    "SessionEnd": [
      {
        "matcher": "",
        "hooks": [{"type": "command", "command": "bash .claude/hooks/session-capture.sh"}]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {"type": "command", "command": "python .claude/hooks/validate-note.py"}
        ]
      }
    ]
  }
}
```

**Module D selected, Module A not selected:**

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [{"type": "command", "command": "bash .claude/hooks/session-orient.sh"}]
      }
    ],
    "SessionEnd": [
      {
        "matcher": "",
        "hooks": [{"type": "command", "command": "bash .claude/hooks/session-capture.sh"}]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {"type": "command", "command": "python .claude/hooks/protect.py"}
        ]
      }
    ]
  }
}
```

**Both Module A and Module D selected:**

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [{"type": "command", "command": "bash .claude/hooks/session-orient.sh"}]
      }
    ],
    "SessionEnd": [
      {
        "matcher": "",
        "hooks": [{"type": "command", "command": "bash .claude/hooks/session-capture.sh"}]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {"type": "command", "command": "python .claude/hooks/validate-note.py"},
          {"type": "command", "command": "python .claude/hooks/protect.py"}
        ]
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

Include only commands from selected modules. Always include all five baseline commands.

```
## Commands

| Command | Purpose |
|---|---|
| `/compass` | Vault state, progress, live questions |
| `/guide` | Show full command reference |
| `/capture` | Write paragraph session summary to ops/sessions/last-active.md — write as if briefing someone resuming cold. Run before closing. |
| `/decide` | Capture current decision to ops/decisions.md — run at moment of decision, not session end |
| `/maintain` | Periodic maintenance: decisions.md review, knowledge.md pruning and graduation |
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
| Contract | `CLAUDE.md` | Rules, schema, commands, architecture, constraints |
| Knowledge | `ops/knowledge.md` | Stable project-specific knowledge accumulated over sessions |
| Decisions | `ops/decisions.md` | Fresh operational decisions — calls made, not yet proven stable |
| Position | `compass.md` | Live operational state — counts, progress, questions, flags. Hot Files and Key Files. |
| Manual | `ops/guide.md` | Expanded command reference |

**When you learn or decide something, route it:**

| Signal | Destination |
|---|---|
| "We're not doing X because Y" (call made) | `ops/decisions.md` |
| "It turns out X works this way" (stable fact) | `ops/knowledge.md` |
| "What I'm tracking right now" (live state) | `compass.md` |
| "Last session I worked on X" (session summary) | `ops/sessions/last-active.md` |
| "This applies to how I work in all projects" | `~/.claude/operator.md` |
| "This is a rule for this vault" | `CLAUDE.md` |

**Knowledge graduation path:**
```
decisions.md  →  (proven stable)  →  ops/knowledge.md Extended
ops/knowledge.md Extended  →  (curated via /maintain)  →  ops/knowledge.md Core
ops/knowledge.md Core  →  (applies across all projects)  →  ~/.claude/operator.md
```
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

**§6 — Session Handoff (Module D)**

```
## Session Handoff

**Last session:** [date]
**Current state:** [what is working; active branch or feature]
**What's broken:** [nothing / describe]
**In progress:** [nothing / describe]
```

Blank template. Updated at session end. Never leave stale.

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

**§10 — Protected Files (Module D)**

```
## Protected Files

Files requiring explicit user permission before modification:

- [list protected files here]

See `.claude/protected-files.txt` for hook consumption. Keep this list in sync with that file.
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

**Don't read all context files upfront.** Burns context window before any work happens.
**Don't reason from scratch instead of pulling from graph.** Defeats the vault's purpose.
**Don't presume the form of the solution.** Locks architecture before the problem is understood.
**Don't cargo-cult another vault's architecture.** Different problem, different constraints.
**Don't catch and swallow errors.** Hides failure; corrupts state silently.
**Don't hardcode domain data in logic.** Makes the system brittle to configuration changes.
**Don't produce generic analysis without grounding in project constraints.** Outputs that could apply to any project = useless.
**Don't over-specify upfront.** Design should emerge from the problem.
**Don't create notes before deduplicating.** Compounds overlap across high-volume vaults.
**Don't embed live state in CLAUDE.md.** CLAUDE.md is the contract; compass.md is the current position.
**Don't leave ops/sessions/last-active.md stale.** Stale handoff is worse than no handoff — it misdirects the next session.
**Don't write to decisions.md at session end.** Capture at the moment of insight; nuance is gone by session end.
**Don't route project-specific knowledge to operator.md.** operator.md is for patterns that apply everywhere; use knowledge.md for project-specific facts.
**Don't use SessionStop as a hook event.** It does not exist; hooks wired to it silently never fire.
**Don't rely on SessionEnd for VS Code tab close.** It doesn't fire on tab close; use /capture instead.
**Don't update a vault's health without reading its compass first.** Stale state misdirects.
**Don't write to a foreign vault's knowledge graph without explicit instruction.** Cross-vault writes require user authorization.
**Don't skip /decide at the moment a decision is made.** Decisions lose nuance by session end; missing an entry means the next session re-litigates from scratch.
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

Location: always `compass.md` at vault root.

```markdown
# Compass

*Updated: {{SCAFFOLD_DATE}}*

## Vault State

[Initialized. No content processed yet.]

## Current Focus

[Nothing yet — vault just created.]

## Live Questions

[None.]

## Flags

[None.]
```

**If Module D or E selected**, append Key Files table:

```markdown
## Key Files

| File | Purpose |
|---|---|
| | |
```

**If Module D selected**, also append Hot Files table:

```markdown
## Hot Files

| File | Purpose |
|---|---|
| | |
```

Blank rows at scaffold time. User fills after creation. These tables live in compass.md, not CLAUDE.md.

---

### T-KNOWLEDGE: `ops/knowledge.md` (Always)

```markdown
# Knowledge

*Project-specific knowledge accumulated over sessions.*
*New entries land in Extended. Graduate to Core via /maintain.*

## Core

<!-- Always injected at session start. Hard cap: 60 lines. -->
<!-- Entries are curated, high-signal facts that change how every session operates. -->
<!-- Graduate from Extended via /maintain. -->

## Extended

<!-- Default landing zone. Load on demand. No cap. -->
<!-- Format: - [fact or proven pattern] (YYYY-MM-DD) -->
```

---

### T-DECISIONS: `ops/decisions.md` (Always)

```markdown
# Decisions

*Operational decisions made this project. Injected at every session start.*
*Run /decide at the moment a decision is made — not at session end.*

<!-- Format: - [YYYY-MM-DD] Decision: [what]. Because: [rationale]. Forecloses: [what this rules out]. -->
<!-- Graduate to knowledge.md when proven stable. Delete when reversed or project moves on. -->
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

Required fields: `vault-name`, `features`, `root-path`, `created`, `last-verified`, `load-instruction`. A manifest missing any of these cannot be used for cross-vault loading.

```yaml
---
vault-name: {{VAULT_NAME}}
features: [{{FEATURES_LIST}}]
root-path: {{VAULT_PATH}}
created: {{SCAFFOLD_DATE}}
last-verified: {{SCAFFOLD_DATE}}
domains:
  - [domain 1 from Phase 0]
  - [domain 2 from Phase 0]
export-surfaces:
  compass: compass.md
  [If Module A:] index: notes/index.md
  [If Module A:] notes-dir: notes/
  [If Module B:] inbox-dir: inbox/
  [If Module B:] backlog: ops/processing-backlog.md
  [If Module F:] architecture-dir: architecture/
  [If Module F:] context-dir: context/
# quest-link: quests/filename.md  # Optional — links this vault to a life-goal quest file
load-instruction:
  - "Read ops/vault-manifest.md"
  - "Read compass.md"
  [If Module A:] - "Read notes/index.md"
  [If Module A:] - "Identify relevant domain MOC from index"
  [If Module A:] - "Read target MOC; follow prose links to specific notes only"
  - "Stop when session context need is satisfied"
cross-vault-dependencies: []
# cross-vault-dependencies entry format:
#   - vault: /absolute/path/to/vault
#     slug: 8charsha1    # SHA1(normalized root-path)[:8]
#     loads-from: [domains or files]
---
```

Emit only the `export-surfaces` keys and `load-instruction` lines that apply to selected modules. Remove the `[If Module X:]` markers from the final file.

If no domains were identified in Phase 0, write `  - [none yet — add as vault is built]` under `domains:`.

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

If no argument: produce an interpreted report —
1. **Vault State** — coverage, completeness, outstanding work
2. **Current Focus** — what is active
3. **Live Questions** — unresolved items, priority ordered
4. **Flags** — anything blocking progress
Be honest. Don't inflate progress.

If argument provided — something changed:
1. Parse what happened
2. Update relevant sections of compass.md
3. Update `*Updated: [date]*` timestamp to today
4. Rewrite compass.md with all updates applied
5. Report: which sections changed

Keep it honest. The compass is only useful if it reflects reality.
```

---

### T-CMD-GUIDE, T-CMD-CAPTURE, T-CMD-DECIDE, T-CMD-MAINTAIN

These are global commands (`~/.claude/commands/`). Do not scaffold them locally. They are available in every vault automatically.

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

### T-GUIDE: `ops/guide.md`

Assemble from selected modules. Include only commands that exist in this vault.
Substitute `{{VAULT_NAME}}`, `{{VAULT_PATH}}`, `{{FEATURES_LIST}}`, `{{SCAFFOLD_DATE}}`.

```markdown
# {{VAULT_NAME}} — Command Reference

## Core (always available)

| Command | Usage | Purpose |
|---|---|---|
| `/compass` | `/compass` or `/compass [what changed]` | Read vault state. With argument: update compass with what happened. |
| `/guide` | `/guide` | Show this reference. |
| `/capture` | `/capture` | Write paragraph session summary. Run before closing. |
| `/decide` | `/decide [optional: decision text]` | Capture current decision to ops/decisions.md. Run at moment of decision. |
| `/maintain` | `/maintain` | Periodic maintenance: decisions.md review, knowledge.md pruning and graduation. |

[Include section below only if Module A selected:]

## Knowledge Graph

| Command | Usage | Purpose |
|---|---|---|
| `/reduce` | `/reduce filename.ext` | Process source from inbox into atomic notes. |
| `/reflect` | `/reflect` | Vault health audit. Writes dated report to ops/health/. |
| `/connect` | `/connect [note-slug or concept]` | Find non-obvious cross-domain connections. |
| `/think` | `/think [question]` | Cross-domain synthesis. Reasons; does not summarize. |

[Include section below only if Module C selected:]

## Synthesis

| Command | Usage | Purpose |
|---|---|---|
| `/brief` | `/brief [question]` | Fast synthesis memo, max 400 words. Pull from vault only. |
| `/challenge` | `/challenge [note or claim]` | Steel-man then attack. |

[Include section below only if Module G selected:]

## Intelligence Scanning

| Command | Usage | Purpose |
|---|---|---|
| `/scan` | `/scan [topic]` | Live web intelligence sweep. Updates or creates notes with sourced URLs. |

---

## Vault Info

- **Root:** {{VAULT_PATH}}
- **Compass:** compass.md
- **Features:** {{FEATURES_LIST}}
- **Created:** {{SCAFFOLD_DATE}}
```

---

## Verification Checklist

After scaffolding, verify:

1. Open vault root in a new Claude Code session → `session-orient.sh` fires; vault name and compass appear in system-reminder
2. `compass.md` exists at vault root; contains the initialized template
3. `ops/vault-manifest.md` has all 6 required fields: `vault-name`, `features`, `root-path`, `created`, `last-verified`, `load-instruction`
4. `.claude/settings.json` uses `"SessionStart"` and `"SessionEnd"` (not "SessionStop")
5. `ops/knowledge.md` has `## Core` and `## Extended` sections
6. `ops/decisions.md` exists with header comment
7. **If Module A:** `ops/validate-config.yaml` exists with `type-vocabulary` list
8. **If Module A:** Write a malformed note to `notes/` → `validate-note.py` outputs violation with "Fix before moving on."
9. **If Module A:** Write a note with a type value not in validate-config.yaml → check 7 fires with controlled vocabulary error
10. **If Module A:** Write a valid note without registering in `dedup-index.md` → check 12 fires
11. **If Module A:** Write a MOC file with a bare `- [[link]]` line in Core Ideas → bare-link warning fires
12. **If Module D:** Write to a path listed in `.claude/protected-files.txt` → `protect.py` warns
13. Introduce a missing export-surface path in `vault-manifest.md` → drift warning appears on next SessionStart
14. Run `/guide` → shows all installed commands for selected modules
15. Run `/compass` → reads compass and returns oriented report
16. **If Module A + C:** Run `/brief [question]` → reads compass, navigates graph, returns memo
