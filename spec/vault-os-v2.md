# Vault OS v2

*Canonical system specification for vault construction, feature composition, and cross-vault interoperability.*
*All future vault construction is built against this document.*

---

## 1. Purpose — The Four Failure Modes

The vault OS is a context engineering layer. Its job: make Claude immediately productive on session one and on session one hundred, with zero warmup tax.

It exists to prevent four failures:

| Failure | What it looks like |
|---|---|
| **Amnesia** | Claude starts every session from scratch, ignoring prior state |
| **Context burn** | Claude reads everything upfront, wasting tokens on irrelevant material |
| **Retrieval failure** | Claude can't find relevant knowledge in other vaults when a session needs it |
| **Capture failure** | Knowledge is never recorded, or recorded badly, so retrieval has nothing to work with |

Every design decision in this document traces back to one of these four failures. If a rule doesn't prevent a failure, it doesn't belong here.

---

## 2. Vault Definition

A **vault** is a project directory configured as a context machine. It is distinguished from a plain project directory by the presence of all four baseline components:

| Component | File                                                     | Purpose                                            |
| --------- | -------------------------------------------------------- | -------------------------------------------------- |
| Contract  | `CLAUDE.md`                                              | Hard rules, schema, commands, architecture         |
| Position  | `compass.md`                                             | Live operational state — read first, always        |
| Hooks     | `.claude/hooks/session-orient.sh` + `session-capture.sh` | Session orientation and capture                    |
| Manifest  | `ops/vault-manifest.md`                                  | Export surface declaration for cross-vault loading |

A project directory missing any of these four is a **workspace**, not a vault.

**Minimum viable vault:** CLAUDE.md + compass.md + both hooks wired in `.claude/settings.json` + vault-manifest.md. No feature modules required beyond the baseline.

**Three invariants govern every vault:**
1. **Orient fast.** Claude reads one file and knows where it is.
2. **Load on demand.** Never read all context upfront. Load by session intent.
3. **Pull from the graph.** Do not reason from scratch; traverse what already exists.

---

## 3. Architecture: Three-Layer Cascade

```
~/.claude/CLAUDE.md     ← Global: universal rules, inherited by every session on this machine
vault/CLAUDE.md         ← Vault: identity and module-specific rules only
vault/compass.md        ← Position: live state, injected by hook — not part of the cascade
```

**Global layer** (`~/.claude/CLAUDE.md`) — inherited by every Claude Code session on this machine, regardless of project. Contains the universal baseline.

**Required content of `~/.claude/CLAUDE.md`** — these items must be present:
- Universal anti-patterns — verbatim list from Section 15
- Operating style — begins "Sharp. No wasted words." + machine-wide constraints
- Cross-vault rules — all rules from Section 9: read foreign compass before any changes; never glob foreign `notes/`; load is targeted and bounded; stop when context need is met; foreign vault schema rules do not apply locally
- Cross-vault loading protocol — Steps -1 through 7 from Section 8

If `~/.claude/CLAUDE.md` is absent or incomplete, vault CLAUDE.md must include all items designated for the global layer.

What does NOT belong in the global layer:
- Vault identity (project name, description, commands)
- Module-specific rules (note schema, MOC rules, code patterns)
- Live state or session handoff

**Vault layer** (`vault/CLAUDE.md`) — contains only what is genuinely specific to this vault. If a rule exists in the global layer, remove it from here. One source of truth per rule.

**Position layer** (`vault/compass.md`) — injected by the `SessionStart` hook before the conversation begins. Claude receives it as a system-reminder. It is not loaded via the cascade and not read by choice. The hook does orientation; the cascade governs behavior after orientation.

---

## 4. File Taxonomy

Every file in the system. For each: what it holds, who writes it, when, how it's loaded, and what routing rule determines what belongs there.

---

### `~/.claude/CLAUDE.md` — Global rules

**What it holds:** Universal behavioral rules that apply in every session on this machine.

**Written by:** Human. Not updated by Claude.

**Loaded:** Automatically by Claude Code cascade at every session start, every project.

**Routing rule:** "Does this rule apply in every vault on this machine?" If yes, it belongs here. If it's vault-specific, it belongs in the vault CLAUDE.md.

---

### `~/.claude/operator.md` — Operator profile

**What it holds:** Cross-project learning about you — preferences, recurring patterns, workflow habits. Things that apply regardless of which project you're in.

**Written by:** Claude, when asked to remember something or when it identifies a cross-project pattern worth preserving across all vaults.

**Loaded:** Injected by each vault's `session-orient.sh` at session start, conditional on file existence. Not auto-loaded by Claude Code — hook-enforced.

**Routing rule:** "Does this apply to how I work across all projects?" If yes, `~/.claude/operator.md`. If it's specific to one project, it belongs in that vault's `knowledge.md`.

**Lifecycle:** Written during sessions → injected by orient hook at every session start → updated when patterns evolve or are corrected. Claude writes new entries unconditionally. After writing, if the file exceeds 160 lines, append to `/capture` output: `operator.md is now N lines — approaching the 200-line truncation limit. Review and prune manually.` Claude never prunes operator.md entries autonomously.

---

### `vault/CLAUDE.md` — Vault contract

**What it holds:** Rules, schema, commands, architecture, constraints that are specific to this vault. Hot Files and Key Files do not belong here; they are live state and live in compass.md.

**Written by:** Human. Not updated by Claude mid-session.

**Loaded:** Via Claude Code cascade at session start.

**Routing rule:** "Is this rule specific to this vault?" If it also applies globally, move it to `~/.claude/CLAUDE.md`. CLAUDE.md is the contract; it does not hold live state (that's compass.md) or accumulated knowledge (that's knowledge.md).

**Lifecycle:** Written at vault creation → updated when vault architecture or rules change → never holds session state.

---

### `vault/compass.md` — Live operational state

**What it holds:** Current state: counts, progress, open questions, flags, current focus, what's broken, what's in progress. Hot Files and Key Files tables.

**Written by:** Claude, during sessions when state changes. Human can update directly.

**Loaded:** Injected by `session-orient.sh` at session start as a system-reminder. Not loaded via cascade.

**Routing rule:** "Is this the current state of this vault right now?" If it's a rule → CLAUDE.md. If it's stable knowledge → knowledge.md. If it's a fresh decision → decisions.md. If it's what's happening right now → compass.md.

**Lifecycle:** Updated during sessions → injected at every session start → never holds stable rules or accumulated knowledge.

---

### `vault/ops/knowledge.md` — Stable project knowledge

**What it holds:** Project-specific knowledge accumulated over sessions. Things that would be expensive to re-derive. Proven patterns. Permanent constraints. Hard-won discoveries about how this system behaves.

**Structure:** knowledge.md has two sections: `## Core` (always injected, hard cap 60 lines — deliberately curated) and `## Extended` (load on demand — default landing zone for new entries). New entries written by Claude land in Extended. Graduation to Core happens via /maintain.

**Written by:** Claude, when something is proven stable — either graduating from `decisions.md` or when a permanent constraint is first discovered. New entries land in `## Extended`.

**Loaded:** `## Core` section injected at session start. `## Extended` loaded on demand when Core is insufficient for the current task — Claude reads it contextually; no explicit trigger required. If `## Core` is absent (flat or uninitialised file), orient hook emits warning: `KNOWLEDGE: knowledge.md has no Core/Extended structure — run /maintain to migrate.` and skips injection rather than silently injecting nothing.

**Routing rule:** "Would knowing this change how future sessions work on this specific project, and is it stable?" If yes → knowledge.md Extended. If it applies everywhere → graduate to `~/.claude/operator.md`. If it's a fresh call, not yet proven → decisions.md instead.

**Distinct from:**
- `~/.claude/operator.md`: personal/workflow scope vs. project scope
- `decisions.md`: stable and proven vs. fresh and operational
- `compass.md`: permanent knowledge vs. live state

**Graduation path:**
```
decisions.md  →  (proven stable)  →  knowledge.md Extended
knowledge.md Extended  →  (curated via /maintain, within 60-line cap)  →  knowledge.md Core
knowledge.md Core  →  (applies across all projects)  →  ~/.claude/operator.md
```

**Migration:** On first /maintain after upgrade from a flat knowledge.md, Claude proposes a Core/Extended split — entries that apply universally to the vault's domain land in Core (within 60-line cap); all others go to Extended.

**Lifecycle:** Written when stable knowledge is identified → Core injected every session → Extended loaded on demand → entries graduated to Core via /maintain → Core entries graduated to `~/.claude/operator.md` when they prove universal.

---

### `vault/ops/decisions.md` — Operational decisions log

**What it holds:** Fresh operational decisions — calls that constrain future work but haven't yet proven stable. "We're not using X because of Y." "The approach for Z is W." Navigated constraints.

**Written by:** Claude via `/decide` command or direct write at the moment a decision is made — not at session end.

**Loaded:** Injected by `session-orient.sh` at session start (conditional — if file exists).

**Primary purpose:** Prevents re-litigation. Claude starts each session knowing what calls have already been made.

**Routing rule:**
- "Did we make a call that shapes future work?" → decisions.md
- "Did we discover a stable fact?" → knowledge.md
- "Is this current operational state?" → compass.md

**Distinct from:**
- `knowledge.md`: not yet proven stable vs. stable
- `compass.md`: not live state — a decision log, not a status board

**Lifecycle:** Written mid-session when a decision is made → injected every session → entries graduate to knowledge.md when proven stable → entries deleted when reversed or project moves on.

**Capture mechanic:** The CLAUDE.md rule: *"When you make an operational decision — ruling out an approach, choosing a pattern, navigating a constraint — run `/decide` before continuing."* This is instruction-enforced, not hook-enforced. A hook cannot detect when a decision is made; only Claude can.

---

### `vault/ops/sessions/last-active.md` — Session handoff

**What it holds:** What happened in the most recent captured session: what was worked on, what was decided, what is in progress, what is blocked.

**Written by:** `/capture` slash command (primary path) or `session-capture.sh` hook on `SessionEnd` (fires on `/exit` and other clean exits — does NOT fire on VS Code tab close).

**Loaded:** Injected by `session-orient.sh` at session start (conditional — if file exists).

**Quality requirement:** Paragraph-level. Write as if briefing someone who will resume this work cold. One-line summaries are insufficient — they produce amnesia in the next session.

**Important:** Overwritten each capture. Only the most recent session survives.

**Lifecycle:** Written at session end via `/capture` → injected at next session start → overwritten by next capture → never accumulates.

---

### `vault/ops/vault-manifest.md` — Cross-vault export surface

**What it holds:** Declaration of what this vault contains, what it knows about, and how to load from it.

**Written by:** Human at vault creation. Updated when vault focus changes. `last-verified` date stamped whenever the manifest is reviewed.

**Loaded:** Read by other vaults during cross-vault loading. Read by `session-orient.sh` for drift checking.

**Required fields:** See Section 7 (Vault Manifest Standard).

**Lifecycle:** Written at vault creation → updated when vault domains or export surfaces change → `last-verified` updated on review → orient hook warns if not reviewed in 7 days.

---

## 5. Feature Module Catalog

Vaults are assembled from composable modules. A vault can combine any subset. Modules are additive — each adds directories, files, CLAUDE.md sections, commands, or hooks.

### Module A — Knowledge Graph

**What it adds:**
- `notes/` directory (flat — no subfolders; all atomic notes and MOC files coexist at root)
- `notes/index.md` — graph entry point; links to all domain MOCs
- `notes/dedup-index.md` — deduplication registry; consulted before creating any note
- `notes/methods.md` — vault-specific operating procedures
- Domain MOC files (`*-moc.md`) within `notes/`
- `validate-note.py` hook (PostToolUse Write on `notes/`)
- `ops/validate-config.yaml` — validation rule configuration for validate-note.py (required — absence fails check 7 with a hard error, not a skip)
- Commands: `/reflect` — trigger: after adding 3 or more notes to a domain
- CLAUDE.md sections: Note Rules, MOC Rules, Schema Enforcement

**Requires:** nothing

**Incompatible with:** nothing

**Hard constraint:** `notes/` is always flat. No subfolders. Navigation is via MOCs, not directory structure.

---

### Module B — Inbox Pipeline

**What it adds:**
- `inbox/` directory — unprocessed source files land here
- `archive/` directory — processed source files move here after `/reduce`
- `ops/processing-backlog.md` — source of truth for what has been processed and when
- `/reduce [file]` command: reads inbox → writes notes → archives source → updates backlog

**Requires:** Module A

**Incompatible with:** nothing

---

### Module C — Synthesis Commands

**What it adds:**
- `/brief [question]` — fast synthesis memo from vault, max 400 words
- `/think [question]` — cross-domain synthesis; reasons, does not summarize
- `/challenge [claim]` — steel-man then attack
- `/connect [note]` — find hidden cross-domain connections

**Requires:** Module A

**Incompatible with:** nothing

---

### Module D — Project State

**What it adds:**
- Session Handoff block in CLAUDE.md (live state; updated at session end)
- Hot Files table in **compass.md** (5–10 critical files, one-line purpose each) — live state, not contract
- Code Patterns section in CLAUDE.md (Follow / Avoid)

**Note:** Hot Files lives in compass.md — live state, not contract.
- Protected Files section in CLAUDE.md
- Tech Stack section (stack + versions + cost notes for LLM calls)
- Architecture section (directory tree, one-liner per directory)

**Requires:** nothing

**Incompatible with:** nothing

---

### Module E — Context Loading Table

**What it adds:**
- Context Loading table in CLAUDE.md: `Session intent | Load` mapping
- Key Files table in **compass.md**: file paths with one-line purposes

**Note:** Key Files lives in compass.md — live state, not contract.

**Requires:** nothing

**Note:** If no context loading table exists, Claude asks "What are you trying to do this session?" before loading. The table removes this friction.

---

### Module F — Design Workspace

**What it adds:**
- `context/` directory — domain model, schema, API specs, constraints
- `architecture/` directory — design deliverables
- `research/` directory — exploration notes, test results
- CLAUDE.md sections: Core Insight, Constraints, Anti-Patterns (design-specific)

**Requires:** nothing

**Note:** Module F is for structured design without a knowledge graph. Cleanest alternative to A+B+C for design-phase projects.

---

### Module G — Intelligence Scanning

**What it adds:**
- `sources/` directory — source definitions
- `/scan [topic]` command — live WebSearch sweep; updates existing notes or creates new intel notes
- Epistemic honesty rules in CLAUDE.md
- URL validation requirement: every intel note carries a verifiable URL or declares `status: unverified-draft`

**Requires:** Module A or Module E

**Epistemic rules (required when G is present):**
- A fact needs a name, date, or number — or mark it a hypothesis.
- Never pass off synthesis as sourced research.
- When WebSearch fails: declare epistemic status explicitly. Never silently pivot to training knowledge.
- Unverified claims: `~Unverified: claim text~ [needs source]`

---

---

## 6. Hard-Coded Rules

These rules apply to every vault regardless of features selected.

**Orientation:**
- Compass is always read first. Every session, no exceptions.
- Context loads on demand. Never read all context files at session start.
- CLAUDE.md defines the map. Session intent defines the path.

**Graph integrity (when Module A present):**
- `notes/` is flat. No subfolders, ever.
- Every wikilink in prose passes the articulation test: "connects because [specific reason]."
- Footer-only wikilinks fail the articulation test. Prose links carry meaning; footer links declare membership.
- Deduplication before creation: check `dedup-index.md` and glob `notes/` before writing any note.

**Schema:**
- Every artifact schema has a controlled vocabulary for `type`. Values outside the vocabulary are rejected.
- Every Module A vault must declare a controlled vocabulary for `type` in `ops/validate-config.yaml`. Enforcement is universal; vocabulary values are vault-specific.
- Every note's `description` adds scope, mechanism, or implication beyond the title. Restatement fails.

**Hooks:**
- `session-orient.sh` and `session-capture.sh` are always present in `.claude/hooks/`.
- Both are path-parameterized: vault root is set from `$CLAUDE_PROJECT_DIR` at the top of each file with a sentinel check. Never hardcode full paths throughout the script.
- Both are wired in `.claude/settings.json` under the correct events (see Section 11).

**CLAUDE.md:**
- Anti-Patterns section is always present.
- Operating Style section is always present and always begins with "Sharp. No wasted words."
- CLAUDE.md is the contract. Do not embed live operational state in CLAUDE.md — that belongs in compass.md.

**Layer separation:**

| Layer | File | What lives there |
|---|---|---|
| Contract | `CLAUDE.md` | Rules, schema, commands, architecture, constraints. Not Hot Files or Key Files. |
| Knowledge | `ops/knowledge.md` | Stable project-specific knowledge accumulated over sessions |
| Decisions | `ops/decisions.md` | Fresh operational decisions — calls made this project, not yet stable |
| Position | `compass.md` | Live operational state — counts, progress, open questions, flags. Hot Files and Key Files tables. |
| Manual | `ops/guide.md` | Expanded command reference (linked from CLAUDE.md, not duplicated) |

Session artifacts (`ops/sessions/last-active.md`, `ops/sessions/session-log.md`) are not permanent layers — they are session-scoped outputs injected by hooks.

---

## 7. Vault Manifest Standard

Every vault has `ops/vault-manifest.md`. Required fields:

```yaml
vault-name: string                         # Human-readable name
features: [A, B, C, ...]                  # Modules selected from the catalog (A–G)
root-path: /absolute/path/to/vault        # Absolute path, no trailing slash
created: YYYY-MM-DD
last-verified: YYYY-MM-DD                 # Date manifest was last reviewed for accuracy
registry: true                            # Optional — marks this vault as the ecosystem discovery point
domains:
  - subject area 1                         # What this vault knows about
  - subject area 2
export-surfaces:
  compass: compass.md                      # Always present
  index: notes/index.md                   # Module A only
  notes-dir: notes/                       # Module A only
  inbox-dir: inbox/                       # Module B only
  backlog: ops/processing-backlog.md      # Module B only
  architecture-dir: architecture/         # Module F only
  context-dir: context/                   # Module F only
load-instruction:
  - "Read ops/vault-manifest.md"
  - "Read {compass path}"
  - "Read {index path}"                   # If Module A
  - "Identify relevant domain MOC from index"
  - "Read target MOC; follow prose links to specific notes only"
  - "Stop when session context need is satisfied"
cross-vault-dependencies:
  - vault: /absolute/path/to/other-vault  # Optional
    slug: 8charsha1                        # First 8 chars of SHA1(normalized root-path); see Section 11
    loads-from: [domains or files]
quest-link: quests/filename.md            # Optional — links this vault to a life-goal quest file
```

**Registry manifest — enriched dependency entries:** When `registry: true` is set, each `cross-vault-dependencies` entry must include `vault-name`, `domains`, and `entry-verified` in addition to the standard fields:

```yaml
cross-vault-dependencies:
  - vault: /absolute/path/to/vault
    vault-name: string               # Human-readable name
    domains: [domain1, domain2]      # What this vault knows about — copied from its manifest
    entry-verified: YYYY-MM-DD       # When this entry was last confirmed accurate
    loads-from: [files]              # What the registry vault reads from this vault (optional)
```

**Registry entry validation:** A registry manifest with entries missing `vault-name`, `domains`, or `entry-verified` is incomplete for discovery purposes. Do not use an incomplete registry for Step -1 of the context loading protocol (Section 8). If the registry is unreachable, its entries lack domains, or `SYSTEM_REGISTRY` is not defined in `~/.claude/CLAUDE.md`: fall back to your own `cross-vault-dependencies` and declare the limitation.

**Required field validation:** A manifest missing `vault-name`, `features`, `root-path`, `created`, `last-verified`, or `load-instruction` is incomplete. Do not use an incomplete manifest for cross-vault loading.

**`last-verified`:** Stamp this date whenever the manifest is reviewed for accuracy. The orient hook warns if it is older than 7 days. A stale manifest is worse than no manifest — it produces confident wrong loads with no indication anything is wrong.

---

## 8. Context Loading Protocol

This protocol governs how vault A loads context from vault B.

**Steps (in order):**

```
-1. Discover candidate vaults.
    → Read the system registry manifest (see Section 9 for the designated registry vault).
    → Extract all cross-vault-dependencies entries. Each entry with domains declared is a candidate.
    → This list is the input to Step 0.
    → If the registry is unreachable, its entries lack domains, or `SYSTEM_REGISTRY` is not defined in
       `~/.claude/CLAUDE.md`: fall back to your own `cross-vault-dependencies`. Declare this limitation —
       do not treat partial discovery as complete.

0. Declare session intent.
   → State what you are working on this session (one sentence).
   → Compare this declaration against manifest.domains in candidate vaults.
   → Only proceed to Step 1 for vaults whose domains match the declaration.
   → If no domain match: stop. Do not load. Do not speculate.

1. Read {vault-B}/ops/vault-manifest.md
   → Validate completeness: vault-name, features, root-path, created, last-verified, and load-instruction must all be present.
   → If any required field is missing: stop. Do not proceed with an incomplete manifest.
   → Extract: root-path, features, domains, export-surfaces, load-instruction

2. Read {vault-B}/{export-surfaces.compass from manifest}
   → Purpose: know the current state of vault B before reading any notes.
   → Required: never skip this step.

3. Evaluate whether vault B is relevant to the session's purpose.
   → If Step 0 already confirmed a domain match, proceed.
   → If no domain match was confirmed: stop. Do not load further.

4. If Module A present: read {vault-B}/notes/index.md
   → Identify which domain MOC(s) are relevant.

5. Read target MOC(s) only.
   → Never glob notes/. Never read all notes.

6. Follow prose wikilinks from the MOC to specific notes.
   → Load only notes that the session requires.
   → Articulation test applies: follow a link only if you can state why.

7. Stop.
   → When session context need is satisfied, stop loading.
   → Do not pre-load for hypothetical future queries.
   → After completing a cross-vault load, note the vault name in the session summary. The human decides
     whether the load represents a structural dependency and updates `cross-vault-dependencies` manually.
     Claude does not update `cross-vault-dependencies`.
```

**Protocol properties:** Discovered (Step -1 enumerates candidates from the registry), targeted (loads for a topic), ordered (follows manifest), cheap (compass + index first; notes only if needed), bounded (stops when satisfied).

---

## 9. Cross-Vault Rules

These rules apply whenever one vault loads from another.

- **meta-vault is the system registry.** The vault designated as the system registry holds `registry: true` and its manifest is the canonical discovery point for the ecosystem. Any session that may require cross-vault context begins by reading its manifest (Step -1 of Section 8) to enumerate candidate vaults. A session that skips this step and loads only from its own `cross-vault-dependencies` has incomplete discovery — declare this when it occurs.
- **Read the foreign vault's compass before making any changes to it.** Writing without orientation is not permitted. Writes to foreign vault knowledge graphs (`notes/`) require explicit user instruction. Note: this is a deliberate softening of the v1 policy, which prohibited all foreign vault writes. The current policy permits writes under two conditions only: compass read first, and knowledge graph writes require explicit user instruction.
- **Never read a foreign vault's full `notes/` directory.** Load via the manifest's load-instruction only.
- **Load is targeted.** A topic-specific load reads one or two MOCs and only the notes required to satisfy the session's specific question — not the full graph. Stop when the context need is met.
- **Declare cross-vault dependencies in your own manifest.** The `cross-vault-dependencies` field in `ops/vault-manifest.md` is required if your vault loads from another.
- **Foreign vault rules do not apply locally.** Each vault has its own schema and validate hooks. Do not apply vault A's validation rules to content from vault B.

---

## 10. CLAUDE.md Assembly Standard

Canonical section order. Sections marked **Always** are required in every vault. Sections marked with a module letter are conditional.

| # | Section | Condition | Content requirement |
|---|---|---|---|
| 1 | Header | Always | Project name (H1). One-sentence description. One-line start instruction. Max 3 lines total. |
| 2 | Operating Frame | Always | 3 bold verbs declaring cognitive mode. Forces Claude to understand *what it's doing*, not just *what exists*. Include: "State session intent in one sentence before loading any context." |
| 3 | Commands Table | Always | `/compass`, `/capture`, `/decide`, `/guide`, `/maintain` at minimum. Module-specific commands added. `/capture` definition must state the paragraph-level quality requirement: write as if briefing someone who will resume this work cold. |
| 4 | Routing Rules | Always | Layer separation table (Contract / Knowledge / Decisions / Position). Routing signal→destination table (from Section 12). Knowledge graduation path: `decisions.md` → `knowledge.md Extended` → `knowledge.md Core` → `~/.claude/operator.md`. |
| 5 | Context Loading Table | Module E | `Session intent \| Load` mapping. No row for "read everything". |
| 6 | Key Files Table | Module D or E | 5–10 files. One-line purpose per file. Lives in **compass.md**, not CLAUDE.md. |
| 7 | Session Handoff | Module D | `Last session:`, `Current state:`, `What's broken:`, `In progress:`. Never left stale. |
| 8 | Hot Files | Module D | Table of most frequently modified files. Lives in **compass.md**, not CLAUDE.md. |
| 9 | Tech Stack | Module D (engineering) | Stack, versions, cost notes for LLM calls. |
| 10 | Architecture | Module D (engineering) | Directory tree with one-liner per directory. |
| 11 | Code Patterns | Module D | Follow (with reason) and Avoid (with reason). |
| 12 | Protected Files | Module D | Explicit list. Files not in this list can be modified. |
| 13 | Note Rules | Module A | Numbered, testable rules. Pass/fail examples required. Hook reference required. |
| 14 | MOC Rules | Module A | Required sections per MOC: orientation, Core Ideas, Tensions, Open Questions, parent link. |
| 15 | Schema Enforcement | Module A | What the hook checks, in what order. "Fix before moving on." |
| 16 | Core Insight | Module F | Single paragraph. The fundamental insight driving design. |
| 17 | Constraints | Module F | Genuinely fixed constraints only. |
| 18 | Epistemic Rules | Module G | Source requirements, unverified-draft protocol, WebSearch failure protocol. |
| 19 | Anti-Patterns | Always | Universal anti-patterns first (from this spec). Then vault-specific entries. |
| 20 | Operating Style | Always | Always begins: `- Sharp. No wasted words.` Then project-specific constraints. |

**Ordering is canonical.** Do not reorder for aesthetics.

**Do not duplicate.** If a rule is in `~/.claude/CLAUDE.md` (global layer), do not repeat it in the vault CLAUDE.md. When the global layer is present, sections 19–20 may be omitted from the vault CLAUDE.md.

**Global layer fallback.** If `~/.claude/CLAUDE.md` is absent or incomplete, vault CLAUDE.md must include all items designated for the global layer: sections 19–20 (anti-patterns, operating style) and the full cross-vault protocol (Section 8 steps + Section 9 rules).

---

## 11. Hook Standard

### Required Hooks

Every vault requires exactly two hook scripts:

| Script | Events wired | Purpose |
|---|---|---|
| `session-orient.sh` | `SessionStart` (blank matcher — matches all sources including compact) | Inject orientation context at session start and after compaction |
| `session-capture.sh` | `SessionEnd` | Write last-active.md on clean exit |

### `.claude/settings.json` Wiring (required)

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "bash .claude/hooks/session-orient.sh" }
        ]
      }
    ],
    "SessionEnd": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "bash .claude/hooks/session-capture.sh" }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          { "type": "command", "command": "python .claude/hooks/validate-note.py" }
        ]
      }
    ]
  }
}
```

PostToolUse Write hook required when Module A is present. Omit if Module A is absent.

**Critical event name notes:**
- `SessionStop` does not exist. Do not use it. Hooks wired to it silently never fire.
- `SessionEnd` fires on `/exit` and other clean exits. It does **not** fire when closing the VS Code tab.
- `SessionStart` with blank matcher (`""`) matches **all** sources: `startup`, `resume`, `clear`, and `compact`. A single blank-matcher entry handles both initial orientation and post-compaction re-injection. Do not add a separate `compact` matcher entry — it causes double injection on every compaction event.

---

### `session-orient.sh` Content Spec

**Output structure (in order):**

```
[Opening banner]
Date: YYYY-MM-DD

[Always — if ~/.claude/operator.md exists]
--- OPERATOR PROFILE ---
<contents of ~/.claude/operator.md>

[Module B, if present]
--- INBOX ---
Transcripts in inbox: N

[Module A, if present]
--- NOTES STRUCTURE ---
<glob notes/*.md sorted>

[Always — if file exists]
--- LAST SESSION ---
<contents of ops/sessions/last-active.md>

[Always — if file exists]
--- DECISIONS ---
<contents of ops/decisions.md>

[Always — if ops/knowledge.md exists]
--- KNOWLEDGE ---
<contents of ## Core section only>
KNOWLEDGE: Core N lines | Extended M entries | decisions.md P entries
[Append "/maintain recommended" if Extended > 20 entries or decisions.md > 30 entries]

[If vault-manifest.md declares quest-link field]
--- QUEST CONTEXT ---
<first 30 lines of linked quest file>
[Quest files should open with a summary front-matter block within the first 30 lines.]
[Hook checks for a recognizable front-matter marker (a line starting with ---, **, or #) within the first 5 lines.]
[If absent, emit WARNING to stderr: "QUEST CONTEXT: no front-matter detected in first 30 lines of {file}. Quest file should open with a summary block." Non-blocking.]

[Module A, if present]
--- MODULE A HEALTH ---
If notes/ directory absent: "MODULE A HEALTH: notes/ directory not found — Module A not initialized." Continue.
If notes/index.md absent: "MODULE A HEALTH: notes/index.md not found — MOC link check skipped." Continue.
If both present (healthy): emit single status line — "MODULE A HEALTH: N notes tracked, index.md present."
  [List unlinked MOCs only when unlinked MOCs exist — do not emit multi-line output for the healthy case.]

[Always — if ops/vault-manifest.md exists]
--- MANIFEST DRIFT CHECK ---
<last-verified warning if older than 7 days>
<missing path warnings for declared export-surfaces>
[If quest-link is declared but file not found:]
WARNING: quest file not found at {path}
To fix: update quest-link in ops/vault-manifest.md or create the missing file.
[Hook continues — broken quest-link does not block session startup.]

**Suppress files** (all live in `~/.claude/vault-runtime/<vault-name>/` — machine-local runtime state, never inside the vault directory):
- `~/.claude/vault-runtime/<vault-name>/.last-manifest-warning` — suppresses the last-verified warning for the day (re-warns next calendar day). If the file does not exist, treat it as infinitely old — the warning fires unconditionally on first run.
- `~/.claude/vault-runtime/<vault-name>/.last-entry-warning-{slug}` — per cross-vault-dependencies entry; suppresses individual staleness warnings for the day. If the file does not exist, treat it as infinitely old — the warning fires unconditionally on first run.

**Suppress file format:** Bare ISO date (`YYYY-MM-DD`), nothing more.

**vault-name derivation:** Derived from the `vault-name` field in `ops/vault-manifest.md` — not the directory basename. This is stable across directory renames. If the manifest's `vault-name` field is renamed, the runtime directory must be renamed manually.

**Directory creation:** session-orient.sh must run `mkdir -p ~/.claude/vault-runtime/<vault-name>/` before any timestamp read or write. First-run write must not fail silently.

**Path normalization:** Any `root-path` values read from the manifest must be normalized to POSIX style via `cygpath -u` (on Windows/Git Bash) before use in shell scripts. This prevents path-style mismatch when comparing manifest paths against `$CLAUDE_PROJECT_DIR` or other script-resolved paths.

**Slug definition:** `slug` is the first 8 characters of the SHA1 hash of the entry's `root-path` string. Stored in the manifest entry as the `slug` field — hook reads it directly, no derivation at runtime.

**Slug canonical form:** Before hashing, normalize the `root-path` value: replace all backslashes with forward slashes, uppercase the drive letter, strip trailing slash. Example: `C:\Users\You\Projects\recipe-vault` → `C:/Users/You/Projects/recipe-vault` → SHA1 → first 8 chars. This eliminates hash collisions from path formatting variations on Windows.

**Suppress file cleanup:** After each drift check run, the hook deletes any suppress file whose slug does not appear in the current `cross-vault-dependencies` entry set. Before executing any deletes, validate that the parsed slug set is non-empty — abort cleanup with a warning if the set is empty and manifest entries exist (guards against destructive false positive from a manifest parse bug).

[Always]
--- OPERATIONAL STATE ---
<contents of compass.md>

[Closing banner]
Run /capture before closing if this session is worth keeping.
```

**Path parameterization:** The vault root path is set from `$CLAUDE_PROJECT_DIR`, provided by Claude Code at hook invocation time. Never use `BASH_SOURCE` path arithmetic — it depends on undocumented cwd assumptions and breaks under relative invocation paths.

```bash
VAULT="${CLAUDE_PROJECT_DIR:?ERROR: CLAUDE_PROJECT_DIR not set — hook must be invoked by Claude Code}"
[[ -f "$VAULT/CLAUDE.md" ]] || { echo "ERROR: VAULT root invalid at $VAULT"; exit 1; }
```

All subsequent paths are built from `$VAULT`.

**Output:** Written to stdout. Claude receives this as a system-reminder at session start.

**Do not include:** File contents beyond those listed above. Do not cat CLAUDE.md or any notes. The hook orients; it does not load context.

---

### `session-capture.sh` Content Spec

**Fires:** `SessionEnd` — clean exits only. Does NOT fire on VS Code tab close.

**Primary capture path:** The `/capture` slash command is the reliable mechanism for VS Code usage. This hook is a fallback for `/exit` scenarios.

**Required writes:**
```
Write ops/sessions/last-active.md:
- Date
- Paragraph summary: what was worked on, what was decided, what is in progress, what is blocked.
  Write as if briefing someone who will resume this work cold.
  One-line summaries are not sufficient — they produce amnesia in the next session.
```

**Optional writes:**
- Append a row to `ops/sessions/session-log.md` (date, summary, notes created, transcripts processed).

**Path parameterization:** Same `$CLAUDE_PROJECT_DIR` pattern as `session-orient.sh`. See path parameterization spec above.

---

### `validate-note.py` Content Spec

**Fires:** PostToolUse Write (Module A vaults only).

**Trigger condition:** File path contains `/notes/` and ends in `.md`.

**Skip list:** `compass.md`, `methods.md`, `index.md`, `dedup-index.md`, any file ending in `-moc.md`.

**Checks (in order):**

| # | Check | Failure condition |
|---|---|---|
| 1 | Frontmatter block | File does not begin with `---` |
| 2 | Required fields | Any required field missing |
| 3 | Description length | `description` < 50 chars or > 200 chars |
| 4 | Date format | `published` or `created` not `YYYY-MM-DD` |
| 5 | source-url format | Does not begin with vault's canonical URL prefix (vault-specific; defined as a constant in the script — set to the primary source domain for this vault, e.g. `https://www.youtube.com/`; omit this check if the vault has multiple source types) |
| 6 | source-video format | `source-video` field present but not a wikilink (`[[...]]`); `source-video` is a Module A frontmatter field linking a note to its parent video note |
| 7 | type vocabulary | `type` value not in controlled vocabulary. If `ops/validate-config.yaml` is absent, emit hard error: `MISSING CONFIG: ops/validate-config.yaml required for Module A. Check 7 cannot run.` |
| 8 | Topics footer | Body section `Topics:` absent |
| 9 | Contradiction field | `type: contradiction` set but no `contradicts:` field (soft warning) |
| 10 | Missing prose wikilinks | No wikilinks in body prose, OR wikilinks exist only in the Topics footer with none in body prose |
| 11 | Broken wikilinks | `[[target]]` references a filename that does not exist |

**Check 11 resolution algorithm:** Walk the vault root to collect all `.md` filenames (excluding `.claude/`). A wikilink target is valid if it matches any `.md` filename without extension. Up to 5 broken links shown per note; remainder counted.

**Output format:**
```
⚠️  VAULT VIOLATION — {basename}
   {violation 1}
   {violation 2}
   Fix before moving on.
```

**Exit code:** Always 0. The hook warns; it does not block.

---

### `stop_hook_active` Guard (Stop hooks only)

The required vault hooks do not use the `Stop` event. This guard applies only if you add a custom `Stop` hook.

Any hook wired to `Stop` must include this guard to prevent infinite loops:

```bash
INPUT=$(cat)
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0
fi
```

Without this guard, a blocking `Stop` hook that returns `decision: "block"` causes Claude to work forever — it can never stop because the hook keeps blocking.

---

## 12. Capture System

How knowledge flows through the system.

### Three Capture Mechanisms

**1. `/capture` — deliberate session capture (primary)**
- Run before closing the VS Code tab
- Writes `ops/sessions/last-active.md` — paragraph-level session summary
- Reliable for VS Code usage (SessionEnd does not fire on tab close)
- The orient hook's closing banner reminds: "Run /capture before closing if this session is worth keeping."
- Pre-write: mark any reversed decisions in `decisions.md` as [SUPERSEDED] — requires only this-session context.
- Post-write: assess whether vault state changed this session (focus shifted, questions resolved or surfaced, flags changed, progress made). If yes, update `compass.md` — relevant sections only, plus timestamp. If no state change, skip.

**Note:** Maintenance tasks (decisions.md review, knowledge.md pruning and graduation) are not /capture tasks — they require cross-session judgment. They live in /maintain.

**2. `SessionEnd` hook — automatic fallback**
- Fires on `/exit` and other clean exits
- Same output as `/capture`
- Does not fire on VS Code tab close — confirmed by test
- Wire it anyway; it costs nothing and catches the cases where it does fire

**3. `/decide` — mid-session decision capture**
- Run at the moment a decision is made — not at session end
- Writes to `ops/decisions.md`
- Instruction-enforced via CLAUDE.md rule: *"When you make an operational decision, run `/decide` before continuing."*
- A hook cannot detect when a decision is made; this requires Claude to act deliberately

### Cross-Vault Load Tracking

The session summary (written by `/capture`) should record which foreign vaults were loaded this session. The human decides whether any load represents a structural dependency and updates `cross-vault-dependencies` manually — Claude does not update it.

**Limitation:** Cross-vault load tracking is best-effort. If `/capture` is skipped (e.g., tab close), the load goes unrecorded with no recovery mechanism. This is an accepted limitation.

### Knowledge Graduation Path

```
decisions.md  →  (proven stable across sessions)  →  ops/knowledge.md Extended
ops/knowledge.md Extended  →  (curated via /maintain)  →  ops/knowledge.md Core
ops/knowledge.md Core  →  (applies across all projects)  →  ~/.claude/operator.md
```

### Routing Rules

When deciding where something goes:

| Signal | Destination |
|---|---|
| "We're not doing X because Y" (call made) | `ops/decisions.md` |
| "It turns out X works this way" (stable fact) | `ops/knowledge.md` |
| "What I'm tracking right now" (live state) | `compass.md` |
| "Last session I worked on X" (session summary) | `ops/sessions/last-active.md` |
| "This applies to how I work in all projects" | `~/.claude/operator.md` |
| "This is a rule for this vault" | `CLAUDE.md` |

---

## 13. Session Lifecycle

What happens at each phase of a session.

### Session Start (automatic)

1. Orient hook fires (`SessionStart`)
2. Hook injects (in order): operator.md → last-active.md → decisions.md → knowledge.md → quest context (if linked) → manifest drift warnings → MODULE A HEALTH → compass.md
3. Claude reads orientation output before responding to first prompt
4. Claude states session intent (one sentence) — used to evaluate cross-vault loads

### During Session

- Load additional context on demand, guided by session intent
- Cross-vault loads follow the Section 8 protocol (Step 0 first: declare intent, match domains)
- When a decision is made → run `/decide` → write to `decisions.md` immediately
- When something stable is learned → write to `ops/knowledge.md`

### After Compaction

- `SessionStart` fires again with `source: "compact"` — matched by the blank matcher
- Orient hook re-injects full orientation context
- Claude resumes with orientation restored — no context loss from compaction

### Session End

- Run `/capture` before closing tab → writes `ops/sessions/last-active.md` paragraph summary → updates `compass.md` if state changed
- `SessionEnd` hook fires if exiting via `/exit` → same output
- Promote any `decisions.md` entries proven stable → `ops/knowledge.md`
- Run `/maintain` periodically — not every session. Required when Extended > 20 entries or decisions.md > 30 entries.

**In-session convention:** If this session's work clearly supersedes a specific decision or knowledge entry, flag it in the session summary. Human decides at /maintain time.

---

## 14. Baseline Commands

Every vault has these commands regardless of modules selected:

| Command | Purpose |
|---|---|
| `/compass` | Read compass.md — current operational state |
| `/guide` | Show full command reference |
| `/capture` | Write paragraph session summary to ops/sessions/last-active.md — run before closing |
| `/decide` | Capture current decision to ops/decisions.md — run at moment of decision |
| `/maintain` | Periodic maintenance: decisions.md review, knowledge.md pruning and graduation. Run periodically, not every session. |

**`/maintain` procedure:**
1. **decisions.md review:** Show all entries with dates. Flag any marked [SUPERSEDED] or older than 30 days. For each flagged entry, present with delete/keep/graduate prompt. Claude proposes; human confirms before any write.
2. **knowledge.md Extended review:** Show Extended entry count and total line count. For each Extended entry: present with graduate/delete/keep prompt.
3. **Graduation check:** Before graduating any Extended entry to Core, show current Core line count. If Core is at or above 60 lines, present current Core entries for pruning before accepting graduation — forced-trade, no silent overflow.
4. **Summary:** Show final Core line count and Extended entry count. Session complete.

Module-specific commands are added per feature (see Module Catalog).

---

## 15. Universal Anti-Patterns

These appear in the Anti-Patterns section of every vault's CLAUDE.md. When a global `~/.claude/CLAUDE.md` is present, they live there instead.

| Anti-pattern | Why it fails |
|---|---|
| Read all context files upfront | Burns context window before any work happens |
| Reason from scratch instead of pulling from graph | Defeats the vault's purpose |
| Presume the form of the solution | Locks architecture before the problem is understood |
| Cargo-cult another vault's architecture | Different problem, different constraints |
| Catch and swallow errors | Hides failure; corrupts state silently |
| Hardcode domain data in logic | Makes the system brittle to configuration changes |
| Generic analysis without grounding in project constraints | Outputs that could apply to any project = useless |
| Over-specify upfront | Design should emerge from the problem |
| Create notes before deduplicating | Compounds overlap across high-volume vaults |
| Embed live state in CLAUDE.md | CLAUDE.md is the contract; compass.md is the current position |
| Leave `ops/sessions/last-active.md` stale | Stale handoff is worse than no handoff — it misdirects the next session |
| Write to decisions.md at session end | Capture at the moment of insight; nuance is gone by session end |
| Route project-specific knowledge to `~/.claude/operator.md` | `operator.md` is for personal/workflow patterns that apply everywhere; use knowledge.md for project-specific facts |
| Confuse vault knowledge.md with `~/.claude/operator.md` | Different scope, different lifecycle — project-specific vs. cross-project personal |
| Use SessionStop as a hook event | It does not exist; hooks wired to it silently never fire |
| Rely on SessionEnd for VS Code tab close | It doesn't fire on tab close; use /capture instead |
| Update a vault's health without reading its compass first | Stale state misdirects |
| Write to a foreign vault's knowledge graph without explicit instruction | Cross-vault writes require user authorization |
| Not running `/decide` at the moment a decision is made | Decisions lose nuance by session end; the file that most prevents re-litigation has no fallback mechanism — missing an entry means the next session re-litigates from scratch |
| Apply local vault schema rules to foreign vault content | Each vault has its own schema and validate hooks; running local validation against imported notes produces false violations and corrupts the load |
| Prune operator.md entries autonomously | Cross-session entry value is invisible to a single-session observer; pruning risk is permanent and unrecoverable — flag and defer to human |

---

## 16. Changelog

| Date | Change | Rationale |
|---|---|---|
| 2026-03-07 | Renamed "system MEMORY.md" to `~/.claude/operator.md` throughout | The Claude Code harness uses per-project memory files at `~/.claude/projects/.../memory/MEMORY.md`, not a global file. The spec's cross-project graduation tier requires a genuinely global file. `operator.md` is a new explicitly-defined file with true machine-wide scope, loaded via hook injection rather than harness auto-load. |
| 2026-03-07 | Added `~/.claude/operator.md` injection to `session-orient.sh` output spec | Without hook injection, `operator.md` would never reach Claude — Claude Code does not auto-load arbitrary files in `~/.claude/`. Orient hook injects it conditionally if the file exists. |
| 2026-03-07 | Hot Files and Key Files moved from CLAUDE.md to compass.md | Live state belongs in compass.md; eliminates CLAUDE.md write conflict |
| 2026-03-07 | validate-config.yaml made required for Module A; no defaults | Per-vault vocabulary is correct; absence should be a hard error, not a silent skip |
| 2026-03-07 | Warning timestamp files moved to ~/.claude/vault-runtime/ | Machine-local runtime state does not belong in the vault directory |
| 2026-03-07 | Per-entry registry suppress files: slug defined as SHA1(root-path), cleanup pass added | Slug collision risk eliminated; orphan files no longer accumulate |
| 2026-03-07 | Claude removed from cross-vault-dependencies authorship | Structural architectural decisions require human judgment and cross-session context |
| 2026-03-07 | /capture items 2–3 removed; /maintain command added | Cross-session maintenance requires human judgment; Claude cannot evaluate entry validity without full history |
| 2026-03-07 | operator.md: Claude warns at /capture if >160 lines; never prunes autonomously | Cross-session entry value is invisible to single-session observer; pruning risk is permanent and unrecoverable |
| 2026-03-07 | knowledge.md split into Core (injected) and Extended (on demand) | Prevents unbounded context injection while preserving full knowledge accumulation |
| 2026-03-07 | Quest file injection capped at first 30 lines | Full-file injection is unbounded; front-matter block is sufficient for orientation |
| 2026-03-07 | /reflect condition 2 removed (dead instruction) | External load events are invisible to the agent inside this vault |
| 2026-03-07 | MODULE A HEALTH: explicit warnings for missing notes/ and index.md | Implementation-defined behavior replaced with specified fallbacks |
| 2026-03-07 | Dynamic VAULT resolution: $CLAUDE_PROJECT_DIR with sentinel check | Silent wrong-path failure is worse than hardcoded path's loud failure |
| 2026-03-07 | Section 13 inject order updated: operator.md and MODULE A HEALTH added | Inject order was inconsistent with actual hook output |
| 2026-03-07 | Section 4 vault-manifest lifecycle: 90-day threshold corrected to 7 days | Inconsistent with Section 7 change in drift-plan.md |
