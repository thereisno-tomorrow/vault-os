# Vault OS

A context engineering system for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that makes AI sessions resumable, cross-project context loading deterministic, and oversight automatic.

Built for people who generate more ideas than they finish — and want their AI to handle the executive function they lack.

**Canonical spec: [`spec/vault-os-v4.md`](spec/vault-os-v4.md).** `spec/vault-os-v2.md` is superseded — kept for history and for the Module A–C internals it still documents, but do not scaffold new vaults against it.

## The Problem

AI collapsed the cost of execution to nearly nothing. But it shifted the human's job from *doing the work* to *overseeing and directing the work*. For creative types — divergent thinkers, ADHD brains, anyone who starts 12 projects and finishes none — this is the worst possible trade: the bottleneck moved to the exact skill they're weakest at.

You can't fix executive function by trying harder. You fix it by building systems that do the executive functioning for you.

v2 tried to fix this by asking sessions to hand-curate live state (compass tables, handoff narratives). Evidence from a fleet-wide audit showed that fails universally — every hand-curated compass froze within days. v4 rebuilds continuity on a different premise: **state a machine can compute, it must never be asked to remember.**

## What This Is

Vault OS is a context engineering layer built on Claude Code's hooks, commands, and native permissions. Each project lives in its own **vault** — a folder with four baseline components that turn it from a directory into a context machine.

It serves two players:
- **The agent** gets deterministic context loading — orientation computed live from git and disk, never a stale cache, plus a slim declared compass for the handful of things git can't tell it.
- **The human** gets automatic capture. A hook writes a session record whether or not anyone remembers to run a command.

```
EXECUTIVE FUNCTION BOTTLENECK
  ├── Creative types = high idea generation + low follow-through
  ├── AI made execution cheap but oversight expensive
  └── You can't fix it by trying harder → build systems
        │
        ▼
FIVE PRINCIPLES (vault-os-v4)
        │
        ├── Survive neglect — no component depends on a human ritual
        ├── Fail loudly — a check that can't run says so, never "fine"
        ├── Admission criterion — would anyone notice within a week if this broke?
        ├── Native-first — Claude Code primitives before bespoke reimplementations
        └── Derived over declared — if disk/git can answer it, no one has to maintain it
```

## What It Actually Prints

Every session opens with this — computed at startup, no human upkeep. Real output from
`hooks/session-orient.sh` run against [`examples/starter-vault/`](examples/starter-vault):

```
╔══════════════════════════════════════════════════════════╗
║  starter-vault ORIENTATION                               ║
╚══════════════════════════════════════════════════════════╝
Date: 2026-07-23   hooks v4.1.0

--- OPERATOR PROFILE ---
  (your ~/.claude/operator.md — cross-project working patterns, elided here)

--- DERIVED (computed live — git + disk) ---
Branch: master
Last 5 commits:
  a01ba4a fix: remove dead Write() permission rules; document +<vault> hook-version suffix
  4a612eb docs: rewrite README for vault-os v4
  ce75c58 fix: stage guide.md render-the-table rewrite (missed in prior commit)
  d86a755 chore: retire /maintain from global commands, guide.md renders CLAUDE.md table
  b74fcd3 feat: Vault OS v4 template set + computed-orientation hooks (Phase 1, D1–D9)
Uncommitted changes: 0 file(s)
Unpushed commits: 0 (ahead of origin/master)
Recently modified (non-ignored, top 5):
  ops/vault-manifest.md
  CLAUDE.md
  compass.md
  .claude/settings.json
  .claude/hooks/session-orient.sh

Last session record (ops/sessions/last-active.md, 134d old):
  Date: 2026-01-01
  Source: Initial scaffold

--- DECLARED (compass intent — Focus / Questions / Flags) ---
╔══════════════════════════════════════════════════════════╗
║  ⚠ intent last declared 203 days ago — treat as HISTORICAL
║  The compass below reflects intent as of 2026-01-01, not now.
║  Trust the DERIVED section above for current state.       ║
╚══════════════════════════════════════════════════════════╝

# Compass
*Updated: 2026-01-01*
## Focus
Fresh vault. No work started yet — replace this with what the vault is trying to do now.
...

╔══════════════════════════════════════════════════════════╗
║  Continuity is computed. /capture only adds narrative.    ║
╚══════════════════════════════════════════════════════════╝
```

Two things to notice. Everything under DERIVED is recomputed from git and disk at startup —
there is no cached copy that can drift. And the compass didn't quietly present a stale Focus
as current: because its declared stamp is past the 30-day threshold, orientation demoted it
behind a banner and pointed the agent back at computed state. That is *fail loudly* and
*derived over declared* doing their jobs in the same frame.

(The two ages measure different things on purpose: the session record is aged by file mtime,
the compass by the stamp a human last wrote.)

## How It Works

### Continuity is computed, not curated

State splits by who can know it:

- **DERIVED** — `session-orient.sh` computes this live, every session: current branch, last 5 commits, uncommitted/unpushed counts, the 5 most recently modified files, and the last session record with its age. No stored copy exists to go stale.
- **DECLARED** — `compass.md` holds only three sections: **Focus** (what the vault is trying to do now), **Questions** (open decisions), **Flags** (known hazards) — plus an `*Updated:*` stamp. If that stamp is more than 30 days old, orientation shows the compass behind a loud staleness banner instead of presenting it as current.

Vault Health tables, "current state" narratives, and Session Handoff blocks are gone as a genre — that kind of status is computed on demand, never cached.

### Capture is a hook, not a ritual

**`session-capture.sh`** (SessionEnd hook) writes a minimal machine record to `ops/sessions/last-active.md` on every clean exit — timestamp, branch, files touched (an approximation, since a true session diff isn't available to a hook). It never clobbers a richer same-day `/capture` entry. **`/capture`** layers narrative on top when you use it, but nothing is load-bearing on that happening: if you close a session without it, the next orientation still reconstructs what happened from derived signals plus the hook's record.

### Sharing by contract, isolation by default

Each vault's `ops/vault-manifest.md` carries a context contract in its YAML frontmatter:

```yaml
exports:                    # the ONLY surfaces foreign sessions/agents may READ
  compass: compass.md       # default — everything not listed is invisible cross-vault, notes/ above all
# intake:                   # optional — where foreign writers may DEPOSIT (never edit in place)
#   inbox: inbox/
domains: [ ... ]            # discovery metadata, matched against a foreign session's stated intent
cross-vault-dependencies: []
```

Cross-vault loading simplifies to: match domains → read exports → stop. Pollution control is structural — you *can't* read what isn't exported — not disciplinary.

Agents ride the same rails: they discover vaults via the meta-vault registry, read exports, and deposit into intakes. Meta-vault keeps a `handoffs/` intake for fleet-level notices any agent or session can drop and the next orientation surfaces. No message bus, no queue, no daemon — that only gets built when a real workflow outgrows deposit-files.

### Enforcement is native

Protected files (`CLAUDE.md`, `ops/vault-manifest.md`) are gated by native `permissions.ask` rules in `.claude/settings.json`, enforced by the harness *before* the write — not warned after the fact. `protect.py` is retired; it watched one tool, warned post-hoc, and guarded an empty list while claiming protection it didn't deliver.

### One hook lineage, tested, versioned

Exactly two hooks — `session-orient.sh` and `session-capture.sh` — live in this repo as the single source of truth for every vault. Each ships a `--selftest` mode that exercises its own dependencies (date parsing, grep regex, git availability, path resolution) and fails loudly on any broken dependency. Each carries a `vault-os-hook-version` stamp.

### Portable root

Hooks and scripts resolve the vault from `$CLAUDE_PROJECT_DIR` and the meta-vault registry as `${VAULT_REGISTRY:-$HOME/Projects/meta-vault}`. No hardcoded absolute user paths in the templates.

## What v4 Retired

`knowledge.md` and its Core/Extended graduation machinery, `guide.md` as a separate file (`/guide` now renders CLAUDE.md's own Commands table — one source per fact), `protect.py` and `protected-files.txt`, `/maintain`, Vault Health tables, and Session Handoff narrative blocks. All confirmed dead weight — either zero organic use or actively misdirecting. See [`spec/vault-os-v4.md`](spec/vault-os-v4.md) §11 for the full list and the reasoning.

## Repo Structure

```
vault-os/
├── README.md
├── spec/                              # System specification & design docs
│   ├── vault-os-v4.md                 # Canonical spec (current)
│   ├── vault-os-v2.md                 # SUPERSEDED — kept for history + Module A–C internals
│   ├── design-principles.md           # The "why" behind every decision
│   └── hooks-reference.md             # Claude Code hooks deep reference
├── global/                            # Copy to ~/.claude/
│   ├── CLAUDE.md                      # Universal rules for all vaults
│   └── commands/                      # Slash commands available everywhere
│       ├── capture.md
│       ├── compass.md
│       ├── decide.md
│       └── guide.md                   # renders CLAUDE.md's Commands table
├── hooks/                             # Reference implementations — the single hook source of truth
│   ├── session-orient.sh              # SessionStart: computed orientation, --selftest
│   ├── session-capture.sh             # SessionEnd: minimal machine capture, --selftest
│   └── validate-note.py               # PostToolUse Write: knowledge graph validation (Module A only)
├── templates/                         # Reference templates for vault files
│   ├── CLAUDE.md                      # Per-vault contract
│   ├── settings.json                  # Hook wiring + native permissions.ask rules
│   ├── compass.md                     # Slim Focus/Questions/Flags compass
│   ├── decisions.md
│   └── vault-manifest.md              # exports/intake/domains context contract
├── skills/
│   └── new-vault/
│       └── SKILL.md                   # /new-vault scaffolding command
└── examples/
    └── starter-vault/                 # A complete minimal vault, ready to use
```

## Quickstart

### Option A: Scaffold a new vault automatically

1. **Install global files:**
   ```bash
   # Copy global CLAUDE.md (universal rules)
   cp global/CLAUDE.md ~/.claude/CLAUDE.md

   # Copy slash commands
   cp global/commands/*.md ~/.claude/commands/

   # Copy the scaffolding skill
   mkdir -p ~/.claude/skills/new-vault
   cp skills/new-vault/SKILL.md ~/.claude/skills/new-vault/SKILL.md
   ```

2. **Open any project in Claude Code and run:**
   ```
   /new-vault
   ```
   The skill asks a few questions, then writes all files in the correct structure.

### Option B: Copy the starter vault manually

1. **Install global files** (same as above).

2. **Copy the example:**
   ```bash
   cp -r examples/starter-vault/ ~/Projects/my-project/
   ```

3. **Edit the files** — replace placeholder values in `CLAUDE.md`, `compass.md`, and `ops/vault-manifest.md` with your project details.

## Module System

The baseline above is the whole system for most vaults. Beyond it, vaults can opt into feature modules — unchanged by v4:

| Module | Name | What it adds |
|---|---|---|
| A | Knowledge Graph | `notes/` directory, MOCs, schema validation, wikilink traversal |
| B | Inbox Pipeline | `inbox/`, transcript processing, `/reduce` command |
| C | Synthesis Commands | `/brief`, `/think`, `/challenge`, `/connect` |
| D | Project State | Tech stack, architecture docs, code patterns, hot files |
| E | Context Loading | Intent-to-file mapping tables |
| F | Design Workspace | `context/`, `architecture/`, `research/` directories |
| G | Intelligence Scanning | `sources/`, `/scan` command, live web research |

See [spec/vault-os-v2.md](spec/vault-os-v2.md) Section 5 for the full module catalog and composition rules (unchanged from v2 — v4 doesn't touch module internals).

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (CLI or VS Code extension)
- Bash (Git Bash on Windows)
- Python 3 (for `validate-note.py`, Module A only)

## License

MIT
