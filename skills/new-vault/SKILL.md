---
name: new-vault
description: Scaffold a new vault conforming to vault-os-v4. Invoked when user says "new vault", "create vault", "scaffold vault", or describes a project that needs a vault. Extracts context from chat, asks ≤3 questions, confirms, then writes all files.
---

# new-vault

Scaffold a complete vault conforming to **vault-os-v4** (`spec/vault-os-v4.md`). When invoked, execute phases 0–5 below. All file content is defined inline — no external files consulted at runtime. Everything needed is here.

**v4 baseline (what changed from v2 — do not scaffold the v2 artifacts):**
- **Slim compass** — three sections only (Focus / Questions / Flags) + an `*Updated:*` stamp. No Vault State, Key Files, or Hot Files tables. Continuity is computed by the orient hook, not curated here.
- **Context-contract manifest** — `exports:` / `intake:` / `domains:`, not `export-surfaces:`.
- **Native permissions** — protected files gated by `permissions.ask` in `.claude/settings.json`. No `protect.py`, no `protected-files.txt`.
- **No `knowledge.md`** and **no `guide.md`** — both retired (D9). `/guide` renders CLAUDE.md's Commands table.
- **Two v4 hooks** (`session-orient.sh` version 4.2.0, `session-capture.sh` version 4.2.0, both `--selftest`-able).
- `validate-note.py` + `ops/validate-config.yaml` remain **Module A only**.

---

## Module Catalog

The vault manifest (`ops/vault-manifest.md`) is always created — it is a baseline component, not a module.

| ID | Name | Key additions | Requires |
|---|---|---|---|
| A | Knowledge Graph | `notes/` (flat), MOCs, `dedup-index.md`, `validate-note.py`, `ops/validate-config.yaml`, `/reduce` `/reflect` `/connect` `/think` | — |
| B | Inbox Pipeline | `inbox/`, `archive/transcripts/`, `processing-backlog.md`, `reduce-skiplist.md`, full `/reduce` pipeline | A |
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
Registry: will register in the meta-vault registry (pending-unpushed until pushed) — standard final step
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

**Step 15b (Module B): Write `ops/reduce-skiplist.md`** — see T-SKIPLIST.

**Step 16: Write `.claude/commands/` files** — write one file per active command:
- Always: `compass.md` (T-CMD-COMPASS) — local override because new vaults place compass at root, not ops/
- Note: `capture.md`, `decide.md`, `guide.md` are global commands in `~/.claude/commands/` — do NOT scaffold them locally. `/guide` renders CLAUDE.md's Commands table; there is no `ops/guide.md`.
- Module A: `reduce.md` (T-CMD-REDUCE), `reflect.md` (T-CMD-REFLECT), `connect.md` (T-CMD-CONNECT), `think.md` (T-CMD-THINK)
- Module C: `brief.md` (T-CMD-BRIEF), `challenge.md` (T-CMD-CHALLENGE). If A already wrote `think.md`, do not write it again.
- Module G: `scan.md` (T-CMD-SCAN)

**Step 17:** *(removed in v4 — no `ops/guide.md`. `/guide` renders the Commands table in CLAUDE.md.)*

---

### Phase 4 — Register in the meta-vault registry

**This is a standard, non-optional final step of standing up a vault** — not an optional foreign-vault write. A scaffolded vault that isn't registered is invisible to cross-vault discovery, and every prior `/new-vault` vault was registered in the same session. Do NOT ask the user whether to register or offer to defer it — just do it. (The global rule *"Claude does not edit cross-vault-dependencies — human decides"* governs a vault declaring its **own** load-dependencies; it does NOT govern entering a newly-created vault into the central registry. Different operation — do not conflate the two.)

Resolve the registry root: `{SYSTEM_REGISTRY}` = `${VAULT_REGISTRY:-$HOME/Projects/meta-vault}` (resolve `$HOME` for this machine — Windows: `C:/Users/<user>`). All steps operate on `{SYSTEM_REGISTRY}/ops/vault-manifest.md`.

**R1 — Read the registry.** Read `{SYSTEM_REGISTRY}/ops/vault-manifest.md`. If it is missing, or has no `registry: true` and no `cross-vault-dependencies:` block, STOP: tell the user the registry wasn't found at the expected path and that registration must be done by hand. Never fabricate a registry.

**R2 — Read the registry's compass first** (its declared `exports.compass`, e.g. `ops/compass.md`) — foreign-compass-before-write. If a Flag there blocks registry edits (e.g. a freeze or migration in progress), STOP and surface it.

**R3 — Compute the slug.** `slug = SHA1(root-path)[:8]`, root-path EXACTLY as the manifest writes paths (forward slashes, no trailing slash, case as shown). Command: `printf '%s' 'C:/Users/<user>/Projects/<vault>' | sha1sum | cut -c1-8`. VERIFY the recipe by reproducing one existing entry's slug first; if it doesn't reproduce, STOP — the recipe or the path form is off, do not guess.

**R4 — Pick the bucket.** A freshly scaffolded vault is almost always `pending-unpushed:` — it has no GitHub remote yet (or no git repo at all), so its compass isn't on a GitHub default branch. Use the `cross-vault-dependencies:` ("registered") spine ONLY if the vault's compass is already verified present on a GitHub default branch. When unsure → `pending-unpushed`.

**R5 — Detect git state** for an accurate `action:` note: `git -C <vault> rev-parse --is-inside-work-tree` (repo?), `git -C <vault> log -1 --oneline` (any commit?), `git -C <vault> remote -v` (remote?). Describe what is actually true — do not assert "pushed" without a remote.

**R6 — Append the entry** under the chosen bucket, matching the shape of the surrounding entries — see T-REGISTRY-ENTRY below. Reuse the vault's own `domains` (write the `[none yet — …]` placeholder if domains were deferred in Phase 0). Include `intake:` only if Module B; `loads-from` = `[compass.md]` plus `notes/index.md` if Module A.

**R7 — Do NOT touch** the registry's top-level `last-verified` or its rebuild-header counts. Those are snapshots of full-registry verifications, not per-add running totals — adding one vault does not re-verify the fleet. (Observed convention: prior single-vault adds left both untouched.)

**R8 — Commit, scoped.** Stage ONLY `ops/vault-manifest.md` (`git -C {SYSTEM_REGISTRY} add ops/vault-manifest.md`) so you don't sweep up unrelated working changes (e.g. an auto-generated `ops/sessions/last-active.md`). Commit message: `registry: add <name> vault (pending-unpushed, slug <slug>)`. Do not push.

**T-REGISTRY-ENTRY** — append under the chosen bucket (`pending-unpushed:` for a fresh vault):

```
  - vault: {{VAULT_PATH}}
    vault-name: {{VAULT_NAME}}
    slug: {{SLUG}}
    features: [{{FEATURES_LIST}}]
    created: {{SCAFFOLD_DATE}}
    last-verified: {{SCAFFOLD_DATE}}
    domains:
      - [none yet — structure deferred; emerges from first sources]   # or the vault's real domains
    compass: compass.md
    intake: inbox/        # Module B only — deposit-only surface; omit this line otherwise
    last-updated: {{SCAFFOLD_DATE}}
    entry-verified: {{SCAFFOLD_DATE}}
    loads-from: [compass.md, notes/index.md]   # drop notes/index.md if no Module A
    action: "NEW entry ({{SCAFFOLD_DATE}}), scaffolded via /new-vault (modules {{FEATURES_LIST}}). <one line on what the vault is>. <git/remote state — e.g. 'git init + first commit on main; no GitHub remote yet — needs remote + push before it enters the derived spine. Visible only via ops/sync-local.sh until then.'> <if domains deferred: 'domains: cannot yet match foreign intent.'>"
```

If the registry is unreachable (R1 stop) or a Flag blocks the edit (R2 stop): finish Phase 5 normally but state plainly in the report that the vault is **NOT registered**, give the reason, and print the exact entry to paste so the user can register by hand.

---

### Phase 5 — Report

```
Created: N files in X directories

[directory tree of what was created]

Registered: meta-vault registry — [bucket], slug [slug]   (or: NOT registered — [reason] + paste-ready entry)
Start here: compass.md
First action: [what to do now — e.g., "Add your first source file to inbox/ then run /reduce" or "Set the compass Focus to what this vault is trying to do" or "Add domains to notes/index.md"]
```

---

## File Templates

---

### T-ORIENT: `.claude/hooks/session-orient.sh`

Write this file verbatim (vault-os v4.2.0). It is baseline for every vault — no module conditionals. The hook computes state from git + disk, keeps complete decision records inside a 15 KB total payload, and exposes `--conformance` for fleet checks. Do not add per-module blocks; keep one hook lineage (D6).

```bash
#!/bin/bash
# session-orient.sh — Vault OS v4.2
# vault-os-hook-version: 4.2.0
# Fires at SessionStart. Output is bounded; compact may re-inject it safely.

set -u

HOOK_BASE_VERSION="4.2.0"
ORIENTATION_BUDGET_BYTES="${VAULT_OS_ORIENTATION_BUDGET_BYTES:-15000}"
NON_DECISION_BUDGET_BYTES="${VAULT_OS_NON_DECISION_BUDGET_BYTES:-12000}"
OPERATOR_BUDGET_BYTES="${VAULT_OS_OPERATOR_BUDGET_BYTES:-500}"
DECISION_LIMIT="${VAULT_OS_DECISION_LIMIT:-3}"
STALE_DAYS=30

byte_count() {
  wc -c < "$1" | tr -d '[:space:]'
}

hook_version() {
  grep -m1 'vault-os-hook-version:' "$1" 2>/dev/null | sed -E 's/.*vault-os-hook-version:[[:space:]]*//'
}

find_compass() {
  local vault="$1" candidate
  for candidate in ops/compass.md compass.md notes/compass.md; do
    if [ -f "$vault/$candidate" ]; then
      printf '%s\n' "$vault/$candidate"
      return 0
    fi
  done
  return 1
}

frontmatter_status() {
  awk '
    NR == 1 && $0 != "---" { exit 3 }
    NR == 1 { in_fm=1; next }
    in_fm && $0 == "---" { exit found ? 0 : 4 }
    in_fm && $0 ~ /^status:[[:space:]]*/ {
      sub(/^status:[[:space:]]*/, "")
      gsub(/[[:space:]\r]+$/, "")
      print tolower($0)
      found=1
    }
    END {
      if (NR == 0) exit 3
    }
  ' "$1"
}

manifest_intakes() {
  awk '
    function clean(value) {
      sub(/[[:space:]]*#.*/, "", value)
      gsub(/^[[:space:]]+|[[:space:]\r]+$/, "", value)
      return value
    }
    /^intake:[[:space:]]*/ {
      value=$0
      sub(/^intake:[[:space:]]*/, "", value)
      value=clean(value)
      if (value != "") print value
      in_intake=1
      next
    }
    in_intake && /^[^[:space:]#-]/ { in_intake=0 }
    in_intake && /^  [A-Za-z0-9_-]+:[[:space:]]*/ {
      value=$0
      sub(/^  [A-Za-z0-9_-]+:[[:space:]]*/, "", value)
      value=clean(value)
      if (value != "") print value
    }
  ' "$1" 2>/dev/null | sort -u
}

build_decision_records() {
  local file="$1" format="$2" record_dir="$3" index="$4"
  mkdir -p "$record_dir"
  : > "$index"
  awk -v format="$format" -v out="$record_dir" -v index_file="$index" '
    function flush_record(  path) {
      if (record == "") return
      path=sprintf("%s/%06d.md", out, count)
      print record > path
      close(path)
      printf "%s\t%06d\t%s\n", record_date, count, path >> index_file
      record=""
    }
    function is_start(line) {
      if (format == "heading") return line ~ /^## [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/
      return line ~ /^- \[[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\]/
    }
    function extract_date(line) {
      if (format == "heading") return substr(line, 4, 10)
      return substr(line, 4, 10)
    }
    {
      sub(/\r$/, "")
      if (is_start($0)) {
        flush_record()
        count++
        record_date=extract_date($0)
        record=$0
      } else if (count > 0) {
        record=record ORS $0
      }
    }
    END { flush_record() }
  ' "$file"
}

render_decisions() {
  local file="$1" available="$2" work="$3" out="$4"
  local heading_count bullet_count total_count format index sorted selected injected
  local date order path record_bytes current first_line

  : > "$out"
  heading_count=$(grep -cE '^## [0-9]{4}-[0-9]{2}-[0-9]{2}' "$file" 2>/dev/null || true)
  bullet_count=$(grep -cE '^- \[[0-9]{4}-[0-9]{2}-[0-9]{2}\]' "$file" 2>/dev/null || true)
  total_count=$((heading_count + bullet_count))

  {
    echo "--- DECISIONS (bounded) ---"
    if [ ! -s "$file" ]; then
      echo "decisions.md: 0 entries, 0 source bytes"
      echo "full log: ops/decisions.md — grep it"
      return
    fi
    if [ "$heading_count" -gt 0 ] && [ "$bullet_count" -gt 0 ]; then
      echo "⚠ decisions.md mixes heading and bullet schemas — body omitted; normalize the file."
      echo "decisions.md: ${total_count} detected entries, $(byte_count "$file") source bytes"
      echo "full log: ops/decisions.md — grep it"
      return
    elif [ "$heading_count" -gt 0 ]; then
      format="heading"
    elif [ "$bullet_count" -gt 0 ]; then
      format="bullet"
    else
      echo "⚠ decisions.md is non-empty but matches no supported date-keyed schema — body omitted."
      echo "decisions.md: 0 detected entries, $(byte_count "$file") source bytes"
      echo "full log: ops/decisions.md — grep it"
      return
    fi
  } >> "$out"

  index="$work/decision-index.tsv"
  sorted="$work/decision-index-sorted.tsv"
  build_decision_records "$file" "$format" "$work/decision-records" "$index"
  sort -t $'\t' -k1,1r -k2,2n "$index" > "$sorted"

  selected=0
  injected=0
  while IFS=$'\t' read -r date order path; do
    [ "$selected" -lt "$DECISION_LIMIT" ] || break
    record_bytes=$(byte_count "$path")
    current=$(byte_count "$out")
    if [ $((current + record_bytes + 240)) -gt "$available" ]; then
      first_line=$(sed -n '1p' "$path" | cut -c1-160)
      {
        echo "⚠ newest remaining decision does not fit the orientation budget; body omitted."
        echo "  ${date} · ${record_bytes} B · ${first_line}"
      } >> "$out"
      break
    fi
    echo "" >> "$out"
    cat "$path" >> "$out"
    echo "" >> "$out"
    selected=$((selected + 1))
    injected=$((injected + record_bytes))
  done < "$sorted"

  {
    echo "decisions.md: ${total_count} total entries; ${selected} injected; ${injected} record bytes"
    echo "full log: ops/decisions.md — grep it"
  } >> "$out"
}

run_selftest() {
  local fail=0 temp
  if date -d "2026-01-01" +%s >/dev/null 2>&1; then
    echo "PASS: GNU date parses ISO dates — compass staleness available"
  else
    echo "FAIL: GNU date unavailable — compass staleness unavailable"
    fail=1
  fi
  for dependency in grep git stat xargs awk sort wc mktemp sed find head cut cat tr rm rmdir; do
    if command -v "$dependency" >/dev/null 2>&1; then
      echo "PASS: ${dependency} available"
    else
      echo "FAIL: ${dependency} unavailable"
      fail=1
    fi
  done
  if stat -c %Y "$0" >/dev/null 2>&1; then
    echo "PASS: stat reads this hook — recent-file ranking available"
  else
    echo "FAIL: stat cannot read this hook"
    fail=1
  fi
  if printf 'x\0' | xargs -0 -r printf '%s' | grep -q '^x$'; then
    echo "PASS: xargs preserves NUL-delimited paths"
  else
    echo "FAIL: xargs NUL handling broken"
    fail=1
  fi
  temp=$(mktemp -d 2>/dev/null || true)
  if [ -n "$temp" ] && [ -d "$temp" ]; then
    printf '## 2026-01-01 — Older\nold body\n## 2026-01-02 — Newer\nnew body\n' > "$temp/headings.md"
    build_decision_records "$temp/headings.md" heading "$temp/heading-records" "$temp/heading-index.tsv"
    printf '%s\n' \
      '- [2026-01-01] Decision: Older' \
      '  Decision-ID: 20260101-older' \
      '  State: encoded' \
      '- [2026-01-02] Decision: Newer' \
      '  Decision-ID: 20260102-newer' \
      '  State: unencoded' > "$temp/bullets.md"
    build_decision_records "$temp/bullets.md" bullet "$temp/bullet-records" "$temp/bullet-index.tsv"
    if [ "$(wc -l < "$temp/heading-index.tsv")" -eq 2 ] \
      && [ "$(wc -l < "$temp/bullet-index.tsv")" -eq 2 ] \
      && grep -q 'new body' "$temp/heading-records/000002.md" \
      && grep -q 'Decision-ID: 20260102-newer' "$temp/bullet-records/000002.md"; then
      echo "PASS: heading and multiline-bullet decisions parse as complete records"
    else
      echo "FAIL: decision record parser lost or split a record"
      fail=1
    fi
    rm -rf "$temp"
    echo "PASS: temporary workspace available"
  else
    echo "FAIL: temporary workspace unavailable"
    fail=1
  fi
  if [ "$fail" -eq 0 ]; then
    echo "SELFTEST: all checks passed"
    return 0
  fi
  echo "SELFTEST: one or more checks failed"
  return 1
}

run_conformance() {
  local vault="${CLAUDE_PROJECT_DIR:-$PWD}" fail=0 internal=0 compass manifest settings
  local orient capture version retired

  if ! command -v grep >/dev/null 2>&1 || ! command -v find >/dev/null 2>&1; then
    echo "ERROR: conformance checker dependencies unavailable"
    return 2
  fi

  manifest="$vault/ops/vault-manifest.md"
  settings="$vault/.claude/settings.json"
  orient="$vault/.claude/hooks/session-orient.sh"
  capture="$vault/.claude/hooks/session-capture.sh"

  if [ -f "$vault/CLAUDE.md" ]; then
    echo "PASS: CLAUDE.md present"
  else
    echo "FAIL: CLAUDE.md missing — vault contract unavailable"
    fail=1
  fi

  compass=$(find_compass "$vault" 2>/dev/null || true)
  if [ -n "$compass" ] && grep -qE '^\*Updated: [0-9]{4}-[0-9]{2}-[0-9]{2}\*' "$compass"; then
    echo "PASS: compass has Updated stamp"
  else
    echo "FAIL: compass missing or has no Updated stamp — staleness unjudgeable"
    fail=1
  fi

  if [ -f "$manifest" ] && grep -q '^exports:' "$manifest"; then
    echo "PASS: manifest has v4 exports contract"
  else
    echo "FAIL: manifest missing v4 exports contract"
    fail=1
  fi

  if [ -f "$settings" ] &&
     grep -Fq 'Edit(/CLAUDE.md)' "$settings" &&
     grep -Fq 'Edit(/ops/vault-manifest.md)' "$settings"; then
    echo "PASS: both protected files use Edit ask rules"
  else
    echo "FAIL: settings missing one or both Edit ask rules"
    fail=1
  fi

  version=$(hook_version "$orient")
  if [[ "$version" == "$HOOK_BASE_VERSION" || "$version" == "$HOOK_BASE_VERSION"+* ]]; then
    echo "PASS: orient hook version ${version}"
  else
    echo "FAIL: orient hook version '${version:-missing}' does not derive from ${HOOK_BASE_VERSION}"
    fail=1
  fi
  version=$(hook_version "$capture")
  if [[ "$version" == "$HOOK_BASE_VERSION" || "$version" == "$HOOK_BASE_VERSION"+* ]]; then
    echo "PASS: capture hook version ${version}"
  else
    echo "FAIL: capture hook version '${version:-missing}' does not derive from ${HOOK_BASE_VERSION}"
    fail=1
  fi

  if [ -f "$settings" ] &&
     grep -Fq '"SessionStart"' "$settings" &&
     grep -Fq 'session-orient.sh' "$settings" &&
     grep -Fq '"SessionEnd"' "$settings" &&
     grep -Fq 'session-capture.sh' "$settings" &&
     [ "$(grep -Fc '$CLAUDE_PROJECT_DIR' "$settings")" -ge 2 ]; then
    echo "PASS: SessionStart/SessionEnd use CLAUDE_PROJECT_DIR"
  else
    echo "FAIL: hook wiring missing or not rooted in CLAUDE_PROJECT_DIR"
    fail=1
  fi

  retired=""
  for path in "$vault/knowledge.md" "$vault/guide.md" "$vault/.claude/protected-files.txt" "$vault/ops/protected-files.txt"; do
    [ -e "$path" ] && retired="${retired}${retired:+, }${path#$vault/}"
  done
  if [ -z "$retired" ]; then
    echo "PASS: no retired root control artifacts"
  else
    echo "FAIL: retired control artifacts present: ${retired}"
    fail=1
  fi

  if [ "$internal" -ne 0 ]; then
    return 2
  elif [ "$fail" -ne 0 ]; then
    return 1
  fi
  return 0
}

if [ "${1:-}" = "--selftest" ]; then
  run_selftest
  exit $?
elif [ "${1:-}" = "--conformance" ]; then
  run_conformance
  exit $?
fi

VAULT="${CLAUDE_PROJECT_DIR:?ERROR: CLAUDE_PROJECT_DIR not set — hook must be invoked by Claude Code}"
[[ -f "$VAULT/CLAUDE.md" ]] || { echo "ERROR: VAULT root invalid at $VAULT (no CLAUDE.md)"; exit 1; }

VAULT_NAME=$(basename "$VAULT")
MANIFEST="$VAULT/ops/vault-manifest.md"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

HEADER="$WORK/header"
OPERATOR="$WORK/operator"
DERIVED="$WORK/derived"
DECLARED="$WORK/declared"
PLANS="$WORK/plans"
INTAKES="$WORK/intakes"
UNENCODED="$WORK/unencoded"
MIGRATION="$WORK/migration"
DECISIONS_OUT="$WORK/decisions"
OUT="$WORK/orientation"

VERSION=$(hook_version "$0")
{
  echo "╔══════════════════════════════════════════════════════════╗"
  printf "║  %-56s║\n" "${VAULT_NAME} ORIENTATION"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo "Date: $(date +%Y-%m-%d)   hook ${VERSION:-unknown}"
  echo ""
} > "$HEADER"

: > "$OPERATOR"
if [ -f "$HOME/.claude/operator.md" ]; then
  operator_size=$(byte_count "$HOME/.claude/operator.md")
  echo "--- OPERATOR PROFILE ---" >> "$OPERATOR"
  if [ "$operator_size" -le "$OPERATOR_BUDGET_BYTES" ]; then
    cat "$HOME/.claude/operator.md" >> "$OPERATOR"
  else
    head -c "$OPERATOR_BUDGET_BYTES" "$HOME/.claude/operator.md" >> "$OPERATOR"
    echo "" >> "$OPERATOR"
    echo "⚠ operator.md is ${operator_size} B; excerpt capped at ${OPERATOR_BUDGET_BYTES} B." >> "$OPERATOR"
    echo "full profile: $HOME/.claude/operator.md" >> "$OPERATOR"
  fi
  echo "" >> "$OPERATOR"
fi

{
  echo "════════════════════════════════════════════════════════════"
  echo "DERIVED — live from git + disk"
  echo "════════════════════════════════════════════════════════════"
  if ! command -v git >/dev/null 2>&1; then
    echo "ERROR: git not on PATH — branch, history, and recovery posture unavailable"
  elif ! git -C "$VAULT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Git: NONE — no local history and no git-derived recovery"
  else
    branch=$(git -C "$VAULT" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
    echo "Branch: ${branch:-<unknown>}"
    echo "Last 5 commits:"
    if git -C "$VAULT" rev-parse HEAD >/dev/null 2>&1; then
      git -C "$VAULT" log -5 --oneline 2>/dev/null | sed 's/^/  /'
      local_history=yes
    else
      echo "  (no commits yet)"
      local_history=no
    fi

    tracked_changes=$(git -C "$VAULT" status --porcelain 2>/dev/null | grep -cE '^[ MARCUD?!][MDARC]' || true)
    untracked_count=$(git -C "$VAULT" ls-files --others --exclude-standard 2>/dev/null | grep -c . || true)
    untracked_bytes=$(
      cd "$VAULT" || exit 1
      git ls-files --others --exclude-standard -z 2>/dev/null |
        xargs -0 -r stat -c %s 2>/dev/null |
        awk '{total += $1} END {print total+0}'
    )
    remote_count=$(git -C "$VAULT" remote 2>/dev/null | grep -c . || true)
    upstream=$(git -C "$VAULT" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
    if [ -n "$upstream" ]; then
      unpushed=$(git -C "$VAULT" rev-list --count "${upstream}..HEAD" 2>/dev/null || true)
      upstream_state="${upstream}; ${unpushed:-?} unpushed"
    else
      upstream_state="NONE; push status unknown"
    fi
    echo "Recovery posture: local-history=${local_history}; remotes=${remote_count}; upstream=${upstream_state}; tracked-changes=${tracked_changes}; untracked=${untracked_count} files/${untracked_bytes} B"

    echo "Recently modified (non-ignored, top 5):"
    recent=$(
      cd "$VAULT" || exit 1
      git ls-files --cached --others --exclude-standard -z 2>/dev/null |
        xargs -0 -r stat -c '%Y %n' 2>/dev/null |
        sort -rn |
        head -5 |
        cut -d' ' -f2-
    )
    if [ -n "$recent" ]; then
      printf '%s\n' "$recent" | sed 's/^/  /'
    else
      echo "  (none)"
    fi
  fi

  last="$VAULT/ops/sessions/last-active.md"
  if [ -f "$last" ]; then
    last_epoch=$(stat -c %Y "$last" 2>/dev/null || true)
    now_epoch=$(date +%s)
    age_days=$(( (now_epoch - last_epoch) / 86400 ))
    echo "Last session record: ${age_days} day(s) old — ops/sessions/last-active.md"
    sed -n '1,12p' "$last" | sed 's/^/  /'
  else
    echo "Last session record: MISSING"
  fi
  echo ""
} > "$DERIVED"

: > "$DECLARED"
COMPASS=$(find_compass "$VAULT" 2>/dev/null || true)
if [ -n "$COMPASS" ]; then
  compass_size=$(byte_count "$COMPASS")
  {
    echo "════════════════════════════════════════════════════════════"
    echo "DECLARED — compass intent"
    echo "════════════════════════════════════════════════════════════"
  } >> "$DECLARED"
  updated=$(grep -m1 -oE '\*Updated: [0-9]{4}-[0-9]{2}-[0-9]{2}\*' "$COMPASS" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' || true)
  if [ -n "$updated" ]; then
    updated_epoch=$(date -d "$updated" +%s 2>/dev/null || true)
    if [ -n "$updated_epoch" ]; then
      compass_age=$(( ($(date +%s) - updated_epoch) / 86400 ))
      if [ "$compass_age" -gt "$STALE_DAYS" ]; then
        echo "⚠ intent last declared ${compass_age} days ago — treat as HISTORICAL" >> "$DECLARED"
      fi
    fi
  else
    echo "⚠ compass has no '*Updated: YYYY-MM-DD*' stamp — staleness unknown" >> "$DECLARED"
  fi
  if [ "$compass_size" -le 5000 ]; then
    cat "$COMPASS" >> "$DECLARED"
  else
    echo "⚠ compass is ${compass_size} B; body omitted above the 5000 B source cap." >> "$DECLARED"
    echo "full compass: ${COMPASS#$VAULT/}" >> "$DECLARED"
  fi
  echo "" >> "$DECLARED"
fi

: > "$PLANS"
if [ -d "$VAULT/docs/plans" ]; then
  open_count=0
  unknown_count=0
  while IFS= read -r plan; do
    status=$(frontmatter_status "$plan" 2>/dev/null || true)
    case "$status" in
      draft|active|blocked)
        if [ "$open_count" -eq 0 ]; then echo "--- OPEN PLANS ---" >> "$PLANS"; fi
        plan_epoch=$(stat -c %Y "$plan" 2>/dev/null || true)
        plan_age=$(( ($(date +%s) - plan_epoch) / 86400 ))
        echo "  $(basename "$plan") · status=${status} · mtime-age=${plan_age}d" >> "$PLANS"
        open_count=$((open_count + 1))
        ;;
      done|closed) ;;
      *)
        if [ "$unknown_count" -eq 0 ]; then echo "--- PLAN METADATA WARNINGS ---" >> "$PLANS"; fi
        echo "  ⚠ $(basename "$plan") · status=${status:-UNKNOWN}" >> "$PLANS"
        unknown_count=$((unknown_count + 1))
        ;;
    esac
  done < <(find "$VAULT/docs/plans" -maxdepth 1 -type f -name '*.md' | sort)
  [ -s "$PLANS" ] && echo "" >> "$PLANS"
fi

: > "$INTAKES"
if [ -f "$MANIFEST" ]; then
  while IFS= read -r intake; do
    case "$intake" in
      /*|[A-Za-z]:*|*'..'*)
        echo "⚠ invalid intake path in manifest: ${intake}" >> "$INTAKES"
        continue
        ;;
    esac
    intake_dir="$VAULT/${intake%/}"
    if [ ! -d "$intake_dir" ]; then
      echo "⚠ declared intake missing: ${intake}" >> "$INTAKES"
      continue
    fi
    intake_count=$(find "$intake_dir" -maxdepth 1 -type f ! -name 'README.md' | wc -l | tr -d '[:space:]')
    if [ "$intake_count" -gt 0 ]; then
      echo "--- INTAKE: ${intake} (${intake_count} pending) ---" >> "$INTAKES"
      find "$intake_dir" -maxdepth 1 -type f ! -name 'README.md' -printf '%T@ %f\n' |
        sort -rn |
        head -5 |
        cut -d' ' -f2- |
        sed 's/^/  /' >> "$INTAKES"
    fi
  done < <(manifest_intakes "$MANIFEST")
  [ -s "$INTAKES" ] && echo "" >> "$INTAKES"
fi

: > "$UNENCODED"
DECISIONS="$VAULT/ops/decisions.md"
if [ -f "$DECISIONS" ] && grep -qE '^[[:space:]]*State:[[:space:]]*unencoded[[:space:]]*$' "$DECISIONS"; then
  echo "--- UNENCODED DECISIONS ---" >> "$UNENCODED"
  awk '
    /^[[:space:]]*Decision-ID:[[:space:]]*/ {
      id=$0; sub(/^[[:space:]]*Decision-ID:[[:space:]]*/, "", id)
    }
    /^[[:space:]]*Governs:[[:space:]]*/ {
      governs=$0; sub(/^[[:space:]]*Governs:[[:space:]]*/, "", governs)
    }
    /^[[:space:]]*State:[[:space:]]*unencoded[[:space:]]*$/ {
      printf "  %s · %s\n", (id ? id : "<missing-id>"), (governs ? governs : "<missing-governs>")
      id=""; governs=""
    }
  ' "$DECISIONS" >> "$UNENCODED"
  echo "" >> "$UNENCODED"
fi

: > "$MIGRATION"
if [ -f "$MANIFEST" ] && ! grep -q '^exports:' "$MANIFEST" 2>/dev/null; then
  {
    echo "--- MIGRATION ---"
    echo "⚠ PRE-V4 VAULT: manifest has no exports contract. Offer v4.2 migration."
    echo ""
  } > "$MIGRATION"
fi

: > "$OUT"
cat "$HEADER" >> "$OUT"

append_section() {
  local section="$1" key="$2" limit="$3" size used
  size=$(byte_count "$section")
  used=$(byte_count "$OUT")
  if [ "$size" -eq 0 ]; then
    printf -v "${key}_INJECTED" '%s' 0
  elif [ $((used + size)) -le "$limit" ]; then
    cat "$section" >> "$OUT"
    printf -v "${key}_INJECTED" '%s' "$size"
  else
    echo "⚠ ${key,,} section omitted: ${size} B would exceed the non-decision budget." >> "$OUT"
    printf -v "${key}_INJECTED" '%s' 0
  fi
}

append_section "$OPERATOR" OPERATOR "$NON_DECISION_BUDGET_BYTES"
append_section "$DERIVED" DERIVED "$NON_DECISION_BUDGET_BYTES"
append_section "$DECLARED" DECLARED "$NON_DECISION_BUDGET_BYTES"
append_section "$PLANS" PLANS "$NON_DECISION_BUDGET_BYTES"
append_section "$INTAKES" INTAKES "$NON_DECISION_BUDGET_BYTES"
append_section "$UNENCODED" UNENCODED "$NON_DECISION_BUDGET_BYTES"
append_section "$MIGRATION" MIGRATION "$NON_DECISION_BUDGET_BYTES"

DECISIONS_INJECTED=0
if [ -f "$DECISIONS" ]; then
  used=$(byte_count "$OUT")
  available=$((ORIENTATION_BUDGET_BYTES - used - 700))
  if [ "$available" -gt 260 ]; then
    render_decisions "$DECISIONS" "$available" "$WORK" "$DECISIONS_OUT"
    decision_size=$(byte_count "$DECISIONS_OUT")
    if [ "$decision_size" -le "$available" ]; then
      cat "$DECISIONS_OUT" >> "$OUT"
      DECISIONS_INJECTED="$decision_size"
    else
      echo "⚠ decisions section omitted: bounded renderer exceeded its allowance." >> "$OUT"
    fi
  else
    echo "⚠ decisions body omitted: no orientation budget remains; full log: ops/decisions.md" >> "$OUT"
  fi
fi

pre_footer=$(byte_count "$OUT")
{
  echo ""
  echo "--- ORIENTATION COST ---"
  echo "operator=${OPERATOR_INJECTED:-0}B derived=${DERIVED_INJECTED:-0}B declared=${DECLARED_INJECTED:-0}B plans=${PLANS_INJECTED:-0}B intakes=${INTAKES_INJECTED:-0}B decisions=${DECISIONS_INJECTED:-0}B"
  echo "pre-footer=${pre_footer}B budget=${ORIENTATION_BUDGET_BYTES}B"
} >> "$OUT"

total=$(byte_count "$OUT")
if [ "$total" -gt "$ORIENTATION_BUDGET_BYTES" ]; then
  echo "ERROR: orientation renderer produced ${total} B above the ${ORIENTATION_BUDGET_BYTES} B budget; body suppressed."
  echo "Run: CLAUDE_PROJECT_DIR=\"$VAULT\" bash \"$0\" --selftest"
  exit 1
fi

cat "$OUT"
```

**Hard constraints:**
- `VAULT` set from `$CLAUDE_PROJECT_DIR` with sentinel check — never hardcode paths.
- Do NOT cat CLAUDE.md, notes, or any file beyond compass / decisions / last-active / operator.md.
- Keep the `--selftest` block, `--conformance` primitive, and the `vault-os-hook-version: 4.2.0` stamp intact.
- Everything fails loudly (D6): a check that cannot run says so; it never defaults to "fine".

---

### T-CAPTURE: `.claude/hooks/session-capture.sh`

Write this file verbatim (vault-os v4.2.0). It archives any narrative handoff byte-for-byte before writing a minimal machine record on SessionEnd; `/capture` enriches with narrative when invoked. Fires on clean exits only (NOT VS Code tab close).

```bash
#!/bin/bash
# session-capture.sh — Vault OS v4.2
# vault-os-hook-version: 4.2.0
# Fires at SessionEnd (clean exits only; editor/tab termination may not fire it).

set -u

SELF_MARK="auto-generated by session-capture.sh"

archive_narrative() {
  local source="$1" sessions="$2" raw stamp base target suffix
  [ -f "$source" ] || return 0
  grep -q "$SELF_MARK" "$source" 2>/dev/null && return 0

  raw=$(grep -m1 '^Date:' "$source" 2>/dev/null | sed -E 's/^Date:[[:space:]]*//' || true)
  if [[ "$raw" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})[[:space:]]+([0-9]{2}):([0-9]{2})(:([0-9]{2}))? ]]; then
    stamp="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}${BASH_REMATCH[3]}${BASH_REMATCH[5]:-00}"
  elif [[ "$raw" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})$ ]]; then
    stamp="${BASH_REMATCH[1]}-000000"
  else
    echo "ERROR: cannot archive narrative session record — unparseable Date line; original preserved" >&2
    return 1
  fi

  mkdir -p "$sessions"
  base="$sessions/${stamp}.md"
  target="$base"
  suffix=2
  while [ -e "$target" ]; do
    target="$sessions/${stamp}-${suffix}.md"
    suffix=$((suffix + 1))
  done
  cp -p "$source" "$target" || {
    echo "ERROR: failed to archive narrative session record to $target; original preserved" >&2
    return 1
  }
  echo "Archived narrative session record: ${target##*/}" >&2
}

run_selftest() {
  local fail=0 temp sessions source first second
  for dependency in date grep sed cp mkdir git awk sort mktemp rm; do
    if command -v "$dependency" >/dev/null 2>&1; then
      echo "PASS: ${dependency} available"
    else
      echo "FAIL: ${dependency} unavailable"
      fail=1
    fi
  done

  temp=$(mktemp -d 2>/dev/null || true)
  if [ -n "$temp" ] && [ -d "$temp" ]; then
    sessions="$temp/sessions"
    source="$sessions/last-active.md"
    mkdir -p "$sessions"
    printf 'Date: 2026-07-28 12:54\nNarrative\n' > "$source"
    archive_narrative "$source" "$sessions" >/dev/null 2>&1 || fail=1
    archive_narrative "$source" "$sessions" >/dev/null 2>&1 || fail=1
    first="$sessions/2026-07-28-125400.md"
    second="$sessions/2026-07-28-125400-2.md"
    if [ -f "$first" ] && [ -f "$second" ]; then
      echo "PASS: narrative archive uses Windows-safe collision-free names"
    else
      echo "FAIL: narrative archive collision test failed"
      fail=1
    fi
    rm -rf "$temp"
  else
    echo "FAIL: temporary workspace unavailable"
    fail=1
  fi

  if [ "$fail" -eq 0 ]; then
    echo "SELFTEST: all checks passed"
    return 0
  fi
  echo "SELFTEST: one or more checks failed"
  return 1
}

if [ "${1:-}" = "--selftest" ]; then
  run_selftest
  exit $?
fi

VAULT="${CLAUDE_PROJECT_DIR:?ERROR: CLAUDE_PROJECT_DIR not set — hook must be invoked by Claude Code}"
SESSIONS="$VAULT/ops/sessions"
LAST="$SESSIONS/last-active.md"
mkdir -p "$SESSIONS"

if [ -f "$LAST" ] && ! grep -q "$SELF_MARK" "$LAST" 2>/dev/null; then
  archive_narrative "$LAST" "$SESSIONS" || exit 1
fi

DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)
BRANCH="(not a git repo)"
FILES=""

if command -v git >/dev/null 2>&1 && git -C "$VAULT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  BRANCH=$(git -C "$VAULT" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
  DIRTY=$(git -C "$VAULT" status --porcelain 2>/dev/null | awk '{print $NF}')
  TODAY_COMMIT=""
  if git -C "$VAULT" rev-parse HEAD >/dev/null 2>&1; then
    LAST_COMMIT_DATE=$(git -C "$VAULT" log -1 --format=%cd --date=format:%Y-%m-%d 2>/dev/null || true)
    if [ "$LAST_COMMIT_DATE" = "$DATE" ]; then
      TODAY_COMMIT=$(git -C "$VAULT" show --name-only --format= HEAD 2>/dev/null || true)
    fi
  fi
  FILES=$(printf '%s\n%s\n' "$DIRTY" "$TODAY_COMMIT" | grep -v '^$' | sort -u)
fi

{
  echo "Date: ${DATE} ${TIME}"
  echo "Branch: ${BRANCH:-<unknown>}"
  echo "Source: ${SELF_MARK} (SessionEnd hook — clean exit only; editor/tab termination may not fire)"
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
  echo "a session diff. Run /capture for a narrative summary of what actually happened and why."
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

# Windows portability: default stdout/stderr encoding is often cp1252, which cannot encode the
# violation message's ⚠️ / — characters and would crash the hook with UnicodeEncodeError instead of
# printing the violation. Force UTF-8 on the streams. No-op where already UTF-8 (Linux/macOS).
try:
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
except Exception:
    pass

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


CLI_MODE = False


def cannot_run(msg, detail=""):
    """A check that cannot run must SAY SO — never default to a silent pass. This validator's
    family has produced false passes by swallowing an unreadable file and exiting clean. CLI mode
    exits 2 (could-not-run); hook mode exits 0 so it never breaks the harness, but always prints."""
    print(f"\n⚠️  VALIDATOR COULD NOT RUN — {msg}")
    if detail:
        print(f"   {detail}")
    sys.exit(2 if CLI_MODE else 0)


def main():
    global CLI_MODE
    argv = sys.argv[1:]
    CLI_MODE = "--file" in argv

    # Resolve the target note. CLI: `validate-note.py --file <path>` (real exit codes, for sweeps).
    # Hook: file_path arrives in the PostToolUse JSON on stdin.
    if CLI_MODE:
        i = argv.index("--file")
        if i + 1 >= len(argv):
            cannot_run("--file given with no path argument")
        file_path = argv[i + 1]
    else:
        try:
            data = json.load(sys.stdin)
        except Exception as e:
            cannot_run("could not parse hook input from stdin", f"{type(e).__name__}: {e}")
        file_path = data.get("tool_input", {}).get("file_path", "")
        if not file_path:
            sys.exit(0)

    # Resolve to ABSOLUTE before the scope test: a relative path like "notes/foo.md" contains
    # "notes/" but not "/notes/", so the old test silently skipped it and a sweep "passed" every
    # note without reading one. Absolute-first closes that false pass.
    file_path = os.path.abspath(file_path).replace("\\", "/")
    if "/notes/" not in file_path or not file_path.endswith(".md"):
        if CLI_MODE:
            cannot_run(f"{file_path} is not inside a notes/ directory (or is not .md)")
        sys.exit(0)

    basename = os.path.basename(file_path)

    if basename in SKIP_NAMES:
        sys.exit(0)

    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception as e:
        cannot_run(f"could not read {basename}", f"{type(e).__name__}: {e}")

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
        sys.exit(1 if CLI_MODE else 0)

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
        sys.exit(1 if CLI_MODE else 0)

    if CLI_MODE:
        sys.exit(0)


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

### T-SOURCE-INDEX: `ops/build-source-index.py` (Module A — optional source axis)

**Optional second axis for multi-source vaults.** Alongside topic MOCs, a vault that ingests many
authors can carry a *source axis*: one `source-<author-slug>-moc.md` hub per author, listing that
author's notes. It makes cross-axis queries cheap ("where does author X disagree with the domain
consensus on Y") and is what the `/reduce` template's **(two-axis only)** steps regenerate.

The axis is **derived, never hand-maintained** — keyed off an `author:` frontmatter field. To enable
it: (1) add `author:` to your notes and, to enforce it, to `REQUIRED_FIELDS` in `validate-note.py`;
(2) create a `source-<author-slug>-moc.md` hub per author with the stub below; (3) run this script
after each `/reduce` batch. Single-axis vaults skip all of this.

```python
#!/usr/bin/env python3
"""
Regenerate the "Notes from this source" section of every source-*-moc.md
from the `author:` frontmatter of notes/*.md.

The source axis is DERIVED, not hand-maintained. `author:` is a required field on
every atomic note (enforced by validate-note.py), so the mapping
    author -> source-<slug>-moc.md
is computable. Run this after a /reduce batch; never edit the generated section by hand.

Fails loudly (vault-os v4 P2): authors whose notes exist but who have no source hub are
reported as an error, never silently dropped. Exit 1 on any such gap.

Usage:  python ops/build-source-index.py [--check]
        --check  report author->hub gaps only; write nothing (exit 1 if any gap exists).
                 It does NOT diff the generated sections — it will not tell you a hub is stale.
"""

import os
import re
import sys

# Windows Python defaults stdout to the console codepage (often cp1252), which cannot encode the
# em-dashes and smart quotes that appear in note descriptions. Force UTF-8 so this script fails on
# real problems, not on printing them. Same guard as validate-note.py.
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

SECTION_HEADING = "## Notes from this source"
GENERATED_PLACEHOLDER = "[Generated by ops/build-source-index.py — do not edit by hand.]"

# Infrastructure files that are not atomic notes and carry no author:
SKIP_NAMES = {"compass.md", "methods.md", "index.md", "dedup-index.md"}


def vault_root():
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def slugify(name):
    """'Ada Lovelace' -> 'ada-lovelace'"""
    s = name.strip().strip('"').strip("'").lower()
    s = re.sub(r"[^a-z0-9]+", "-", s)
    return s.strip("-")


def frontmatter_field(content, field):
    match = re.search(rf"^{re.escape(field)}:\s*(.+)$", content, re.MULTILINE)
    if not match:
        return None
    return match.group(1).strip().strip('"').strip("'")


def collect_notes(notes_dir):
    """Return {author: [(slug, description), ...]} for atomic notes only."""
    by_author = {}
    unattributed = []
    for fname in sorted(os.listdir(notes_dir)):
        if not fname.endswith(".md"):
            continue
        if fname in SKIP_NAMES or fname.endswith("-moc.md"):
            continue
        path = os.path.join(notes_dir, fname)
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
        author = frontmatter_field(content, "author")
        slug = fname[:-3]
        if not author:
            unattributed.append(slug)
            continue
        desc = frontmatter_field(content, "description") or ""
        by_author.setdefault(author, []).append((slug, desc))
    return by_author, unattributed


def render_section(entries):
    """Bare links are correct here — a source hub is an address index, not an argument map."""
    if not entries:
        return GENERATED_PLACEHOLDER + "\n"
    lines = []
    for slug, desc in sorted(entries):
        lines.append(f"- [[{slug}]] — {desc}" if desc else f"- [[{slug}]]")
    return "\n".join(lines) + "\n"


def rewrite_hub(hub_path, entries):
    """Replace the generated section in place. Returns (changed, error)."""
    with open(hub_path, "r", encoding="utf-8") as f:
        content = f.read()

    pattern = re.compile(
        rf"({re.escape(SECTION_HEADING)}\n\n)(.*?)(\n---\n)", re.DOTALL
    )
    if not pattern.search(content):
        return False, (
            f"{os.path.basename(hub_path)}: no '{SECTION_HEADING}' section followed by "
            "a '---' rule. Cannot regenerate — fix the hub's structure."
        )

    new_content = pattern.sub(
        lambda m: m.group(1) + render_section(entries) + m.group(3), content, count=1
    )
    if new_content == content:
        return False, None
    with open(hub_path, "w", encoding="utf-8") as f:
        f.write(new_content)
    return True, None


def main():
    check_only = "--check" in sys.argv
    root = vault_root()
    notes_dir = os.path.join(root, "notes")

    if not os.path.isdir(notes_dir):
        print(f"ERROR: notes/ not found at {notes_dir}")
        sys.exit(1)

    by_author, unattributed = collect_notes(notes_dir)

    hubs = {}
    for fname in os.listdir(notes_dir):
        if fname.startswith("source-") and fname.endswith("-moc.md"):
            hubs[fname[len("source-"):-len("-moc.md")]] = os.path.join(notes_dir, fname)

    errors = []
    changed = []

    for author, entries in sorted(by_author.items()):
        slug = slugify(author)
        if slug not in hubs:
            errors.append(
                f"author '{author}' has {len(entries)} note(s) but no hub at "
                f"notes/source-{slug}-moc.md — create it or correct the author field."
            )
            continue
        if check_only:
            continue
        did_change, err = rewrite_hub(hubs[slug], entries)
        if err:
            errors.append(err)
        elif did_change:
            changed.append(f"source-{slug}-moc.md ({len(entries)} note(s))")

    # Hubs with no notes yet are fine (a hub created before its first note) — reset to placeholder.
    if not check_only:
        for slug, path in sorted(hubs.items()):
            if not any(slugify(a) == slug for a in by_author):
                did_change, err = rewrite_hub(path, [])
                if err:
                    errors.append(err)
                elif did_change:
                    changed.append(f"source-{slug}-moc.md (reset — no notes yet)")

    total_notes = sum(len(v) for v in by_author.values())
    print(f"Scanned {total_notes} note(s) across {len(by_author)} author(s); {len(hubs)} hub(s).")
    for c in changed:
        print(f"  updated  {c}")
    if unattributed:
        print(f"\nWARNING: {len(unattributed)} note(s) with no author: field:")
        for slug in unattributed[:10]:
            print(f"  • {slug}")

    if errors:
        print("\nERRORS:")
        for e in errors:
            print(f"  • {e}")
        sys.exit(1)

    if check_only:
        print("(--check: nothing written)")
    sys.exit(0)


if __name__ == "__main__":
    main()
```

**Source-hub stub** — create `notes/source-<author-slug>-moc.md` as:

```markdown
# [Author Name]

Source hub — notes extracted from this author.

## Notes from this source

[Generated by ops/build-source-index.py — do not edit by hand.]

---

Topics:
- [[index]]
```

---

### T-SETTINGS: `.claude/settings.json`

Event keys: `"SessionStart"` and `"SessionEnd"` exactly — not `"Start"` / `"Stop"` / `"SessionStop"`.
`SessionStart` with blank matcher (`""`) matches all sources: startup, resume, clear, compact.
Commands use `bash "$CLAUDE_PROJECT_DIR"/...` for robust path resolution regardless of cwd.

The `permissions.ask` block is **always written** — it gates protected files with native, pre-write
prompts (D5). Rule syntax verified against the official Claude Code permissions docs: `Edit(/path)`
uses gitignore-spec patterns; a leading `/path` anchors at the project root (the settings source).
`Write(/path)` rules are never matched by Claude Code (verified against 2.1.211's startup warning) —
`Edit(/path)` alone gates file-modification checks, so each protected file needs only the
`Edit(...)` rule. No `protect.py`, no `protected-files.txt`.

**Baseline (Module A not selected):**

```json
{
  "permissions": {
    "ask": [
      "Edit(/CLAUDE.md)",
      "Edit(/ops/vault-manifest.md)"
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
      "Edit(/ops/vault-manifest.md)"
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
another file, add `Edit(/path)` to the `ask` array (a `Write(/path)` rule is never matched — Edit
alone gates file-modification checks). There is no protected-files.txt and no protect.py.
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

**Two run modes.** The PostToolUse hook exits 0 even on violations (they surface as feedback, not a
harness error). For batch sweeps use CLI mode — `python .claude/hooks/validate-note.py --file <path>`
— which returns real exit codes: **0** clean · **1** violations · **2** the validator could not
inspect the note. Exit 2 exists because a check that cannot run must never be counted as a pass.
Run a negative control (point it at a deliberately broken note, confirm exit 1) before trusting a
sweep result.

Fix before moving on.
```

---

**§13b — Retrieval Protocol (Module A)**

Note Rules govern writing to the graph; this governs reading from it — every command, and any
ad-hoc question answered from vault content. Write verbatim:

```
## Retrieval Protocol

The vault is a distillation ladder. Load the cheapest level that answers the question; never load a
level you do not need.

| Level | Surface | When |
|---|---|---|
| 3 | Every note title (`Glob notes/*.md`) | **always, first** |
| 2 | One domain (or source) MOC | question is domain-shaped |
| 1 | One note | only what level 3 selected |
| 0 | One `inbox/` source | only to verify a quote or re-extract |

**Two-stage retrieval is mandatory for any question that reads from the graph.**

**Stage 1 — survey.** Glob `notes/*.md`. Because every title is a prose proposition (Note Rule 1),
the listing is a complete semantic index of every claim in the vault at a fraction of the cost of
the notes themselves. Select candidates from titles alone. Open nothing at this stage.

**Stage 2 — read.** Read only what stage 1 selected, in full. Follow prose wikilinks one hop where
an argument depends on them. Stop when the question is answered.

Never bulk-read `notes/`. Never open a note to find out what it says — the title already said it.
Open a note to find out *why* it holds.

**Typed filtering.** When the question is typed rather than topical, grep frontmatter at stage 1
instead of listing:

    grep -l '^type: contradiction' notes/*.md      # the contradiction subgraph
    grep -l '^author: <name>' notes/*.md            # one source's claims (two-axis vaults)

**`notes/dedup-index.md` grows large — grep it, never Read it.** Reading it can cost several times
the entire title index. Note Rule 7's "search dedup-index" means `grep`.

**Note Rule 1 is load-bearing infrastructure, not a style preference.** The claim index works only
while every title states a proposition. A note titled for its topic is invisible to stage 1 and has
to be read to be found.
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
**Don't read a foreign vault beyond its declared `exports:`.** Everything not exported is out of contract even if filesystem permissions make it technically readable — notes/ above all.
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
#   exports: — the ONLY surfaces a foreign session/agent should READ. Everything not listed is
#              out of contract (notes/ above all); this is policy, not filesystem enforcement.
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
  # Anything not listed here is out of contract cross-vault. Do NOT export notes/.

# agent-exports:         # optional — narrow extra paths for one named shared agent
#   agent-name:
#     - relative/path.md

# intake:                # optional — deposit-only surface for foreign writers/agents
#   [If Module B:] inbox: inbox/

cross-vault-dependencies: []
# Declare an entry ONLY if THIS vault loads from another. Shape:
#   - vault: /absolute/path/to/other-vault   # absolute, forward slashes, no trailing slash
#     slug: 8charsha1                          # first 8 chars of SHA1(normalized root-path)
#     loads-from: [compass]                    # which of that vault's declared EXPORTS this vault reads
---
```

Emit only the `exports:` / `intake:` keys that apply to selected modules. Add
`agent-exports:` only when the user has deliberately authorized a named agent and
specific relative paths. Remove the `[If Module X:]` markers from the final file.
If no domains were identified in Phase 0, write
`  - [none yet — add as vault is built]` under `domains:`.

---

### T-SKIPLIST: `ops/reduce-skiplist.md` (Module B)

Sources with no extractable argument. `/reduce` honours this list (Phase 1) and never extracts from
a listed file. A skip silently suppresses content, so every entry is verified by **reading** the
file, never inferred from the title. Scaffold with the header and empty tables; entries accrue as
`/reduce` flags housekeeping sources.

```markdown
# Reduce Skip-list

Sources in `inbox/` that carry **no extractable argument** — announcements, index pages, jobs
boards, pure link roundups. `/reduce` must not extract notes from these.

Every entry is **verified by reading the file**, never inferred from its title — titles misclassify
at a high rate. Record the reason. When in doubt, leave it off: a weak note is recoverable, a
silently dropped source is not.

| File | Reason |
|---|---|

## Blocked pending missing assets — NOT skipped

Files that carry a real argument whose substance sits in an asset that did not survive fetch
(images, tables). Deferred, not suppressed — re-assess once the asset is supplied. Do not migrate
these into the table above.

| File | Missing | Why deferred |
|---|---|---|
```

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

The proven orchestrated pipeline (validated at scale in the pmm vault). The main loop
ORCHESTRATES — it orients, dispatches, and does housekeeping; **it never reads a source file or the
dedup index itself.** Extraction runs on delegated Sonnet subagents, where tokens cost several times
less than the (often Opus) main loop. Do not collapse this back into a single-agent, main-loop
reduce — that is the naive version this template replaced, and it is both costlier and blind to the
dedup index's real cost at scale.

The two-axis steps (source hubs, `build-source-index.py`) are marked **(two-axis only)** — omit them
for a single-axis vault. See T-SOURCE-INDEX for the opt-in source axis.

```
Source files: $ARGUMENTS
(Space-separated list. Single file is valid.)

Extraction runs on delegated Sonnet subagents, not the main loop. The main loop orients,
dispatches, and does housekeeping — it never reads a source file or the dedup index itself.

---

## Phase 1: Orient (main loop — cheap)

1. If `ops/reduce-skiplist.md` exists, read it. Any source listed there carries no extractable
   argument — drop it from this batch and name it in the Phase 4 report. Never extract from a skipped file.
2. Read `compass.md` for declared vault intent.

Do NOT read the source files here. Do NOT read `notes/dedup-index.md`. Do NOT glob `notes/`.
That work happens inside the subagent, where tokens cost less.

---

## Phase 2: Dispatch extraction (one Sonnet subagent per source file)

Spawn with the Agent tool, `subagent_type: general-purpose`, **`model: 'sonnet'` passed
explicitly** — general-purpose inherits the main loop otherwise (Opus, if settings pin it), which is
the whole cost problem.

Run source files concurrently (one message, multiple tool calls). Each subagent owns exactly one
source file and writes only to `notes/`. It never touches MOCs, the dedup index, or the archive —
those are serialized in Phase 3 to avoid concurrent writers on the same file.

Brief each subagent with the following, substituting the source path:

> Extract atomic notes from `inbox/<file>` into this vault's knowledge graph.
> The project CLAUDE.md defines the Note Rules and schema — follow them exactly.
>
> **Step 1 — read the source.** If it proves to be pure housekeeping (announcement, index page,
> link roundup with no arguable claim), stop and return `SKIP: <reason>`. Judge by reading, never
> by the title — titles misclassify at a high rate.
>
> **Step 2 — overlap scan.** `notes/dedup-index.md` can be very large (100KB+ at scale). **Grep it;
> never Read it.** One record per line, format `slug | description | moc1, moc2`, so a keyword hit
> returns the whole record without opening the file:
>
>     grep -i -E 'theme-a|theme-b|theme-c' notes/dedup-index.md
>
> Run one grep per theme the source argues. Then Read only the handful of overlapping notes the
> greps surfaced — in parallel, in full.
>
> Overlap rules:
> - Same phenomenon at same abstraction level → enrich or contradict the existing note; never duplicate
> - Same phenomenon at different abstraction level (what vs. why vs. how) → distinct note; link explicitly
> - Contradicts an existing note → `type: contradiction`, link with an articulated reason
>
> **Step 3 — plan.** Produce this table before writing any file, in foundation-before-elaboration order:
>
> | # | Filename | Proposition (one sentence) | MOC(s) | Source |
> |---|----------|---------------------------|---------|--------|
>
> **Step 4 — write.** Each note must satisfy:
> - Title: prose proposition. Test: "This note argues that [title]" must be grammatically true.
> - Body: develop the claim with visible reasoning ("because," "therefore," "this suggests").
> - Wikilinks: pass the articulation test — "[[note]] connects because [specific reason]."
>   Before linking, confirm the target exists: `ls notes/<slug>.md`. Do not glob all of `notes/`.
> - Full YAML frontmatter — the required fields defined in CLAUDE.md Note Rules. Declare source-url
>   once for this source and reuse it across its notes.
> - Topics: footer (body content, not YAML) declaring MOC membership.
>
> Quality gate: each note is specific (named mechanism or framework), non-obvious, and arguable.
> Extract claims; do not summarize. `validate-note.py` fires on every Write to `notes/` — fix
> violations before continuing.
>
> **Return** (this is data for the orchestrator, not a human-facing message):
> the plan table as written, one `slug | description | moc1, moc2` line per note created for the
> dedup index, cross-links made to existing notes, contradictions found, and what remains thin.

---

## Phase 3: Housekeeping (main loop — serialized)

Run after all subagents return. Order matters.

1. **Cross-batch reconciliation** — run only when two or more subagents returned notes (one
   extracting subagent cannot collide with itself). Each subagent deduped against the *existing*
   graph but was blind to its siblings' writes this batch, so two sources arguing the same claim can
   produce twin notes. Scan the returned `slug | description | mocs` lines *across* subagents for
   pairs describing the same phenomenon at the same abstraction level. This runs on the summary lines
   the subagents already returned — open no notes unless a pair looks like a genuine collision.
   Different abstraction levels (what vs. why vs. how) are not collisions. For each real collision,
   **name both slugs in the Phase 4 report** for a later merge; do not let a same-claim twin pass
   unreported.
2. **Domain MOCs** — add each new note as a bare link under the correct conceptual cluster in Core
   Ideas. Context phrases are written in batch during periodic `/repair` runs; bare links are fine now.
   (Two-axis only: `source-*-moc.md` hubs are generated in step 5 and are never hand-edited.)
3. **Dedup index** — append each subagent's returned `slug | description | mocs` lines to
   `notes/dedup-index.md`.
4. **Archive** source file(s) to `archive/transcripts/` (Module B); update `ops/processing-backlog.md`.
   Any subagent that returned `SKIP` → add that file to `ops/reduce-skiplist.md` with its reason
   instead of archiving.
5. **(Two-axis only) Regenerate the source axis:** `python ops/build-source-index.py`
   Derives every `source-*-moc.md` from note `author:` fields. Exits 1 if an author has notes but no
   hub — create `notes/source-<author-slug>-moc.md` and re-run. Do not hand-edit the generated section.

Do NOT write counts or state into `compass.md`. That is DERIVED (D1) and computed live by orientation.

---

## Phase 4: Report

Notes created, domains landed, cross-links made to existing notes, broken links deferred,
contradictions found, intra-batch collisions flagged (Phase 3 step 1), files skipped and why,
what remains thin.

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
6. `.claude/settings.json` has `permissions.ask` rules: `Edit(/CLAUDE.md)`, `Edit(/ops/vault-manifest.md)`
7. Editing `CLAUDE.md` triggers a native permission prompt; there is NO `protect.py` and NO `protected-files.txt`; there is NO `ops/knowledge.md` and NO `ops/guide.md`
8. `ops/decisions.md` exists with header comment
9. **If Module A:** `ops/validate-config.yaml` exists with `type-vocabulary`; `validate-note.py` present and wired as a PostToolUse Write hook
10. **If Module A:** Write a malformed note to `notes/` → `validate-note.py` outputs violation with "Fix before moving on."
11. **If Module A:** Write a note with a type not in validate-config.yaml → check 7 fires; unregistered slug → dedup check fires; bare MOC link → bare-link warning fires
12. Run `/guide` → renders CLAUDE.md's Commands table; `/compass` → reads compass and returns oriented report
13. **If Module A + C:** Run `/brief [question]` → reads compass, navigates graph, returns memo
14. **Registered:** `{SYSTEM_REGISTRY}/ops/vault-manifest.md` has a new entry under the correct bucket (`pending-unpushed:` for a fresh vault) with the computed slug, and the registry change is committed scoped to `ops/vault-manifest.md` only. (If the registry was unreachable, the report says NOT registered and gives a paste-ready entry.)
