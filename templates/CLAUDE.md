# [Vault Name]

[One-line description of what this vault is for.]

**Start here:** [[compass]]

---

**Operating frame:**
- **[VERB 1]** — [What the first operating mode does]
- **[VERB 2]** — [What the second operating mode does]
- **[VERB 3]** — [What the third operating mode does]

---

## Commands

| Command | Purpose |
|---|---|
| `/compass` | Read vault state or update with what changed |
| `/guide` | Show command reference |
| `/capture` | Write session summary to `ops/sessions/last-active.md` + update compass |
| `/decide` | Capture an operational decision to `ops/decisions.md` immediately |
| `/maintain` | Periodic vault maintenance |

---

## Key Files

| File | Purpose |
|---|---|
| `ops/compass.md` | Live state — where the project stands right now |
| `ops/decisions.md` | Operational decisions log — write at moment of insight |
| `ops/knowledge.md` | Stable facts promoted from decisions |
| `ops/sessions/last-active.md` | Last session summary |

---

## Session Handoff

**Last session:** YYYY-MM-DD
**Current state:** [Brief description]
**What's broken:** [Known issues, or "nothing"]
**In progress:** [Active work, or "nothing"]

---

## Hot Files

| File | Purpose |
|---|---|
| `ops/compass.md` | Updated every session |

---

## Tech Stack

| Layer | Technology | Notes |
|---|---|---|
| [Layer] | [Tech] | [Notes] |

---

## Architecture

| Directory | Purpose |
|---|---|
| `ops/` | Vault control files: compass, manifest, guide |
| `.claude/` | Hooks, commands, settings |

---

## Protected Files

Files requiring explicit user permission before modification:

- `CLAUDE.md`
- `ops/vault-manifest.md`

See `.claude/protected-files.txt` for hook consumption.

---

## Anti-Patterns

**Don't read all context files upfront.** Burns context window before any work happens.
**Don't reason from scratch instead of pulling from graph.** Defeats the vault's purpose.
**Don't embed live state in CLAUDE.md.** CLAUDE.md is the contract; compass.md is the current position.
**Don't leave Session Handoff stale.** Stale handoff is worse than no handoff.

---

## Operating Style

- Sharp. No wasted words.
