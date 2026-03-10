# Starter Vault

Example vault demonstrating Vault OS v2 baseline structure. Replace this with your project's identity.

**Start here:** [[compass]]

---

## Commands

| Command | Purpose |
|---|---|
| `/compass` | Read vault state or update with what changed |
| `/guide` | Show command reference |
| `/capture` | Write session summary + update compass |
| `/decide` | Capture an operational decision immediately |
| `/maintain` | Periodic vault maintenance |

---

## Key Files

| File | Purpose |
|---|---|
| `ops/compass.md` | Live state — where the project stands right now |
| `ops/decisions.md` | Operational decisions log |
| `ops/knowledge.md` | Stable facts promoted from decisions |
| `ops/sessions/last-active.md` | Last session summary |

---

## Session Handoff

**Last session:** never
**Current state:** Fresh vault. No work done yet.
**What's broken:** nothing
**In progress:** nothing

---

## Protected Files

- `CLAUDE.md`
- `ops/vault-manifest.md`

---

## Anti-Patterns

**Don't read all context files upfront.** Burns context window before any work happens.
**Don't reason from scratch instead of pulling from graph.** Defeats the vault's purpose.
**Don't embed live state in CLAUDE.md.** CLAUDE.md is the contract; compass.md is the current position.
**Don't leave Session Handoff stale.** Stale handoff is worse than no handoff.

---

## Operating Style

- Sharp. No wasted words.
