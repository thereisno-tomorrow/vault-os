# [Vault Name]

[One-line description of what this vault is for.]

**Start here:** [[compass]] — orientation is also injected automatically at every session start.

---

**Operating frame:**
- **[VERB 1]** — [what the first operating mode does]
- **[VERB 2]** — [what the second operating mode does]
- **[VERB 3]** — [what the third operating mode does]

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

There is no handoff block here — the genre is retired. Continuity is computed, not curated:
`session-orient.sh` prints live DERIVED state (branch, recent commits, uncommitted/unpushed,
recently-changed files, last session record) every session, and the compass carries DECLARED
intent (Focus / Questions / Flags). Read those, not a stale narrative pasted into this file.

---

## Protected Files

`CLAUDE.md` and `ops/vault-manifest.md` are gated by **native permission rules** in
`.claude/settings.json` (`permissions.ask`). The harness prompts for approval BEFORE any Edit
or Write to these paths — enforcement is native and pre-write, not a warn-after hook. To
protect another file, add both `Edit(/path)` and `Write(/path)` to the `ask` array (a Read/Edit
rule does not cover Write). There is no `protected-files.txt` and no `protect.py`.

---

## Anti-Patterns

**Don't paste live state into CLAUDE.md or the compass.** State is computed by orientation; a stored copy only goes stale and misdirects.
**Don't read all context files upfront.** Orientation already gave you the map — load on demand, by session intent.
**Don't reason from scratch.** Pull from `ops/decisions.md`, the compass, and git history first.
**Don't catch and swallow errors in hooks.** A check that cannot run must say so; it never defaults to "fine."
**Don't read a foreign vault beyond its declared `exports:`.** Everything not exported is invisible cross-vault — `notes/` above all.

---

## Operating Style

- Sharp. No wasted words.
- State session intent in one sentence before loading any context.
