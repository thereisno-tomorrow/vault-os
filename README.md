# Vault OS

A context engineering system for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that makes AI sessions resumable, cross-project context loading deterministic, and oversight automatic.

Built for people who generate more ideas than they finish — and want their AI to handle the executive function they lack.

## The Problem

AI collapsed the cost of execution to nearly nothing. But it shifted the human's job from *doing the work* to *overseeing and directing the work*. For creative types — divergent thinkers, ADHD brains, anyone who starts 12 projects and finishes none — this is the worst possible trade: the bottleneck moved to the exact skill they're weakest at.

You can't fix executive function by trying harder. You fix it by building systems that do the executive functioning for you.

## What This Is

Vault OS is a context engineering layer built on Claude Code's hooks, commands, and structured markdown files. Each project lives in its own **vault** — a folder with four baseline components that turn it from a directory into a context machine.

It serves two players:
- **The agent** gets deterministic context loading. Same protocol every time. No reasoning from scratch about what to pull.
- **The human** gets automatic capture. Session state, decisions, and project knowledge are recorded without discipline.

```
EXECUTIVE FUNCTION BOTTLENECK
  ├── Creative types = high idea generation + low follow-through
  ├── AI made execution cheap but oversight expensive
  └── You can't fix it by trying harder → build systems
        │
        ▼
THREE SYSTEM LAYERS
        │
        ├── 1. SEPARATION (one vault per project)
        │     └── Solves: context contamination
        │
        ├── 2. AUTO-CAPTURE (hooks fire without you)
        │     └── Solves: forgetting state, stale handoffs
        │
        └── 3. STRUCTURED PROTOCOL (cross-vault interop)
              └── Solves: non-deterministic context loading
```

## How It Works

### Four files keep the layers clean

| File | Role | Changes |
|---|---|---|
| `CLAUDE.md` | The contract. Rules, schemas, commands. | Rarely |
| `ops/compass.md` | Live state. What's in progress, what's blocked. | Every session |
| `ops/decisions.md` | Decisions captured at the moment of insight. | Mid-session |
| `ops/knowledge.md` | Stable facts graduated from decisions. | Periodically |

### Three hooks fire without you

**Session start** (`session-orient.sh`) — Before you type a word, the system loads your last session summary, active decisions, accumulated knowledge, and the compass. You don't have to remember what you were doing yesterday.

**Session end** (`session-capture.sh`) — If you ran `/capture` during the session, the hook backs off. If you didn't (because you forgot, because ADHD, because whatever), the hook writes a fallback entry. Either way, the next session starts with context.

**Write protection** (`protect.py`) — Warns when critical files are modified without explicit permission.

### Five commands (slash commands in Claude Code)

| Command | What it does |
|---|---|
| `/compass` | Read vault state. With argument: update what changed. |
| `/capture` | Write session summary + update compass if state changed. |
| `/decide` | Capture a decision mid-session. Don't wait until session end. |
| `/guide` | Show command reference. |
| `/maintain` | Periodic maintenance: review decisions, graduate knowledge, prune. |

### Cross-vault loading protocol

Each vault publishes a **manifest** declaring what it contains and how to load from it. When one vault needs context from another, a fixed protocol runs:

1. Discover available vaults from a central registry
2. Match against declared domains
3. Read the target vault's compass (current state)
4. Load only what's relevant
5. Stop when satisfied

No reasoning from scratch. Same sequence every time.

## Repo Structure

```
vault-os/
├── README.md
├── spec/                              # System specification & design docs
│   ├── vault-os-v2.md                 # Canonical spec (the full system)
│   ├── design-principles.md           # The "why" behind every decision
│   └── hooks-reference.md             # Claude Code hooks deep reference
├── global/                            # Copy to ~/.claude/
│   ├── CLAUDE.md                      # Universal rules for all vaults
│   └── commands/                      # Slash commands available everywhere
│       ├── capture.md
│       ├── compass.md
│       ├── decide.md
│       ├── guide.md
│       └── maintain.md
├── hooks/                             # Reference implementations
│   ├── session-orient.sh              # SessionStart: inject context
│   ├── session-capture.sh             # SessionEnd: fallback capture
│   ├── protect.py                     # PostToolUse Write: file protection
│   └── validate-note.py              # PostToolUse Write: knowledge graph validation (Module A)
├── templates/                         # Reference templates for vault files
│   ├── CLAUDE.md                      # Per-vault contract
│   ├── settings.json                  # Hook wiring
│   ├── compass.md
│   ├── decisions.md
│   ├── knowledge.md
│   ├── guide.md
│   └── vault-manifest.md
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

3. **Edit the files** — replace placeholder values in `CLAUDE.md`, `ops/compass.md`, and `ops/vault-manifest.md` with your project details.

## Module System

Beyond the baseline, vaults can opt into feature modules:

| Module | Name | What it adds |
|---|---|---|
| A | Knowledge Graph | `notes/` directory, MOCs, schema validation, wikilink traversal |
| B | Inbox Pipeline | `inbox/`, transcript processing, `/reduce` command |
| C | Synthesis Commands | `/brief`, `/think`, `/challenge`, `/connect` |
| D | Project State | Tech stack, architecture docs, code patterns, hot files |
| E | Context Loading | Intent-to-file mapping tables |
| F | Design Workspace | `context/`, `architecture/`, `research/` directories |
| G | Intelligence Scanning | `sources/`, `/scan` command, live web research |

See [spec/vault-os-v2.md](spec/vault-os-v2.md) Section 5 for the full module catalog and composition rules.

## Design Philosophy

Nine principles govern the system. The full reasoning is in [spec/design-principles.md](spec/design-principles.md). The short version:

1. **Capture is harder than retrieval.** Only capture things that would change future behavior if known.
2. **Hooks enforce outcomes. Instructions govern behavior.** If Claude can accidentally violate a rule, it needs a hook, not a prompt.
3. **Design principles are not instructions.** If a rule can't be violated, it doesn't belong in CLAUDE.md.
4. **One source of truth per rule.** If it exists in two places, it will drift.
5. **Three-layer cascade.** Global rules → vault rules → live state (injected by hook).
6. **Compass is injected, not loaded.** The hook delivers state before the conversation begins.
7. **Single CLAUDE.md doesn't scale.** Separate global from vault-specific from live state.
8. **Sessions must be resumable.** `last-active.md` makes the next session start from where you left off.
9. **Cross-vault loads behave like subagents.** Targeted scope. Stop when satisfied.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (CLI or VS Code extension)
- Bash (Git Bash on Windows)
- Python 3 (for `protect.py` and `validate-note.py`)

## License

MIT
