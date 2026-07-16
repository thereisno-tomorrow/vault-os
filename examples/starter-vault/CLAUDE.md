# Starter Vault

Example vault demonstrating the Vault OS v4 baseline. Replace this with your project's identity.

**Start here:** [[compass]] — orientation is also injected automatically at every session start.

---

**Operating frame:**
- **ORIENT** — read the injected DERIVED + DECLARED orientation before acting
- **WORK** — do the task; state session intent in one sentence first
- **CLOSE** — `/decide` at the moment of a decision; `/capture` for a narrative if the session is worth a note

State session intent in one sentence before loading any context.

---

## Commands

This table IS the command reference. `/guide` renders it — there is no separate guide file.

| Command | Purpose |
|---|---|
| `/compass` | Read the compass, or update Focus / Questions / Flags with what changed |
| `/guide` | Render this Commands table |
| `/capture` | Write a narrative session summary to `ops/sessions/last-active.md` (optional — never load-bearing) |
| `/decide` | Append an operational decision to `ops/decisions.md` at the moment it is made |

---

## Session Handoff

There is no handoff block — the genre is retired (D1). Continuity is computed: `session-orient.sh`
prints live DERIVED state every session and the compass carries DECLARED intent. Read those.

---

## Protected Files

`CLAUDE.md` and `ops/vault-manifest.md` are gated by native permission rules in
`.claude/settings.json` (`permissions.ask`) — the harness prompts BEFORE any Edit or Write.
To protect another file, add both `Edit(/path)` and `Write(/path)` to the `ask` array. There is
no `protected-files.txt` and no `protect.py`.

---

## Anti-Patterns

**Don't paste live state into CLAUDE.md or the compass.** State is computed by orientation; a stored copy only goes stale.
**Don't read all context files upfront.** Load on demand, by session intent.
**Don't reason from scratch.** Pull from `ops/decisions.md`, the compass, and git history first.
**Don't read a foreign vault beyond its declared `exports:`.** Everything not exported is invisible cross-vault.

---

## Operating Style

- Sharp. No wasted words.
- State session intent in one sentence before loading any context.
