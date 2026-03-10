# System Design Guiding Principles

*Living document. Updated as insights emerge during the redesign process.*

> **Proposal:** This file should be referenced in the global `~/.claude/CLAUDE.md` cascade so that every session in every vault inherits these principles automatically. Adherence should be enforced — not aspirational. The exact mechanism (direct include, summary section, or hook-injected) to be decided during Phase 2 design.

---

## Purpose

> The vault OS is a cognitive prosthetic — a context engineering layer that makes Claude an extension of working memory across sessions and vaults.

**The four failure modes it exists to prevent:**
- **Amnesia** — Claude starts every session from scratch, ignoring prior state
- **Context burn** — Claude reads everything upfront, wasting tokens on irrelevant material
- **Retrieval failure** — Claude can't find relevant knowledge in other vaults when a session needs it
- **Capture failure** — Knowledge is never recorded, or recorded badly, so retrieval has nothing to work with

Everything in this document is in service of preventing these four failures. Every design decision traces back to one of them.

---

## Principles

### 1. The working memory problem has two halves: retrieval and capture. Capture is harder.

Retrieval is solvable with hooks — inject the right files at session start, Claude knows what exists. But hooks can only retrieve what was captured well in the first place. Garbage in, garbage out.

**What to capture** is a judgment call, not a mechanical operation. Not everything is worth recording. A solved bug that will never recur — noise. A navigated architectural constraint that shapes every future decision — critical. The filter: only capture things that would change future behavior if known. This cannot be automated — Claude must be instructed to apply this filter actively.

**Where it lives** — different knowledge has different shelf lives and different retrieval moments:
- Solved bugs / navigated issues → `MEMORY.md` (cross-session patterns, stable)
- Prior work artifacts → `compass.md` flags ("this analysis exists at X path")
- Session summary → `last-active.md` (what happened, where things stand)
- Stable architectural decisions → `MEMORY.md`

These are not interchangeable. Mixing them degrades retrieval — Claude can't find the right thing at the right moment if everything is in one place.

**When to capture** — session-end capture is too late and too coarse. The insight happens mid-session: when the bug is solved, when the architectural decision is made, when a prior analysis is discovered. By session end, the nuance is gone. The right model: **capture at the moment of insight**, not at session end. Session end is for the summary only.

**The missing artifact:** a `decisions.md` log — written mid-session when something is learned, surfaced by the hook at the next session start. Different from compass (live state), different from `last-active.md` (session summary), different from `MEMORY.md` (stable cross-session patterns). This artifact does not currently exist in the system.

**Manifestations of capture failure:**
- Claude re-does archaeology already captured in a prior session (e.g. re-reading KNOWLEDGE-EXTRACTION.md)
- Claude hits the same bug twice in one session, investigates from scratch the second time
- Claude loads a vault's entire notes directory because it doesn't know a prior analysis already exists

---

### 2. Hooks enforce outcomes. Instructions govern behavior.

If Claude can accidentally violate a rule mid-session without noticing, an instruction won't save you. It needs a hook.

**Hooks are for:**
- Injecting state at session start (compass.md) — fires before the conversation, can't be skipped
- Writing state at session end (last-active.md) — fires automatically, Claude doesn't have to remember
- Validating on write (note schema) — catches violations the moment they happen
- Blocking writes to protected files — mechanical, Claude can't override it

**Instructions are for:**
- Which files to load for a given task (judgment call — no hook can read session intent)
- Behavioral rules during a session (don't reason from scratch, don't glob everything)
- Schema definition (Claude needs to know the rules before writing, not just get caught after)
- Operating style

---

### 3. Design principles are not instructions.

"Orient fast" is an ideal, not an actionable rule. The hook enforces it mechanically. Putting it in CLAUDE.md adds words without changing behavior. Every instruction in CLAUDE.md must be something Claude can actually act on or violate — if it can't be violated, it doesn't belong there.

---

### 4. One source of truth per rule.

If a rule exists in multiple vault CLAUDE.mds, it will drift. Edit one, miss nine. Global CLAUDE.md is the fix for universal rules. Vault-manifest.md is the fix for cross-vault registry. Compass.md is the fix for live state. Each rule lives in exactly one place.

---

### 5. Global CLAUDE.md = rules Claude follows everywhere, written once.

Three-layer cascade:

```
~/.claude/CLAUDE.md     ← Universal rules (inherited by every session, every vault)
vault/CLAUDE.md         ← Vault identity (only what's genuinely specific to this vault)
vault/compass.md        ← Live state (delivered by hook, not the cascade)
```

Global CLAUDE.md contains:
- Actionable behavioral rules (don't read all context upfront, load on demand, don't glob)
- Cross-vault rules (read foreign compass first, never write to foreign vault)
- Universal anti-patterns (one source of truth — not copy-pasted into every vault)
- Operating style

Vault CLAUDE.md contains only what is unique to that vault. Nothing that belongs globally.

---

### 6. Compass.md is not part of the instruction cascade.

It is injected by the SessionStart hook before the conversation begins. Claude receives it as a system reminder — not something it reads by choice. The hook does orientation; the instruction cascade governs what Claude does after it's oriented.

---

### 7. Single CLAUDE.md doesn't scale.

One file becomes a dumping ground. Every new vault concern gets appended. Claude reads it all, every session, regardless of relevance. The three-layer architecture (global → vault → compass) is the fix: global inherits universals, vault specializes, compass orients. Each layer stays lean because it only holds what belongs there.

---

### 8. Sessions must be resumable, not monolithic.

A session that runs long should produce a `last-active.md` that makes the next session start from where it left off — not from scratch. The session-capture hook is a manual compaction mechanism. Design it to distill the session into a high-fidelity one-paragraph summary, not just a timestamp. The quality of `last-active.md` determines how much amnesia the next session suffers.

---

### 9. Cross-vault loads behave like subagents.

When Claude loads from another vault, it operates with targeted scope — manifest first, compass second, then only the specific notes the session requires. No full graph reads. Stop when satisfied. This is the subagent isolation principle applied to cross-vault context: prevent cross-contamination, keep each load focused.
