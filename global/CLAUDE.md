# Global Rules — Claude Code

*Inherited by every session on this machine regardless of project.*
*SYSTEM_REGISTRY: ~/Projects/meta-vault*

---

## Universal Anti-Patterns

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
| Not running `/decide` at the moment a decision is made | Decisions lose nuance by session end; missing an entry means the next session re-litigates from scratch |
| Apply local vault schema rules to foreign vault content | Each vault has its own schema and validate hooks; running local validation against imported notes produces false violations |
| Prune operator.md entries autonomously | Cross-session entry value is invisible to a single-session observer; pruning risk is permanent and unrecoverable — flag and defer to human |

---

## Operating Style

- Sharp. No wasted words.
- State session intent in one sentence before loading any context.
- Context loads on demand. Never read all context files at session start.
- When operator.md exceeds 160 lines, append to /capture output: "operator.md is now N lines — approaching the 200-line truncation limit. Review and prune manually." Never prune autonomously.

---

## Cross-Vault Rules

- **The system registry vault holds `registry: true`.** Any session that may require cross-vault context begins by reading its manifest (Step -1 of the loading protocol below) to enumerate candidate vaults. A session that skips this step has incomplete discovery — declare this when it occurs.
- **Read the foreign vault's compass before making any changes to it.** Writing without orientation is not permitted.
- **Writes to foreign vault knowledge graphs (`notes/`) require explicit user instruction.**
- **Never read a foreign vault's full `notes/` directory.** Load via the manifest's load-instruction only.
- **Load is targeted.** A topic-specific load reads one or two MOCs and only the notes required — not the full graph. Stop when the context need is met.
- **Declare cross-vault dependencies in your own manifest.** The `cross-vault-dependencies` field in `ops/vault-manifest.md` is required if your vault loads from another.
- **Foreign vault rules do not apply locally.** Each vault has its own schema and validate hooks.

---

## Cross-Vault Loading Protocol

Steps executed in order whenever loading context from another vault:

```
-1. Discover candidate vaults.
    → Read {system-registry}/ops/vault-manifest.md (system registry).
    → Extract all cross-vault-dependencies entries with domains declared.
    → If registry unreachable: fall back to your own cross-vault-dependencies. Declare this limitation.

0.  Declare session intent (one sentence).
    → Match intent against manifest.domains in candidate vaults.
    → Only proceed for vaults whose domains match.
    → If no domain match: stop. Do not load. Do not speculate.

1.  Read {vault-B}/ops/vault-manifest.md
    → Validate: vault-name, features, root-path, created, last-verified, load-instruction must be present.
    → If any required field missing: stop.

2.  Read {vault-B}/{compass path from manifest}
    → Know the current state of vault B before reading anything else.
    → Required. Never skip.

3.  Evaluate relevance. If no domain match confirmed: stop.

4.  If Module A present: read {vault-B}/notes/index.md
    → Identify relevant domain MOC(s).

5.  Read target MOC(s) only. Never glob notes/.

6.  Follow prose wikilinks from MOC to specific notes only as needed.
    → Articulation test: follow a link only if you can state why.

7.  Stop when session context need is satisfied.
    → Note which vaults were loaded in the session summary.
    → Claude does not update cross-vault-dependencies — human decides.
```
