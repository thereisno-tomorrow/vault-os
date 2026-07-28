# Global Rules — Claude Code on this machine

*Inherited by every session on this machine regardless of project.*
*SYSTEM_REGISTRY: `${VAULT_REGISTRY:-$HOME/Projects/meta-vault}` — resolve `$HOME` for the current machine before any file read (Windows desk: `C:/Users/Nic`; Linux box: `/home/nic`). Hooks and scripts resolve it the same way in shell. Never hardcode a machine-specific absolute path when referencing the registry.*

---

## Universal Anti-Patterns

| Anti-pattern | Why it fails |
|---|---|
| Read all context files upfront | Burns context window before any work happens |
| Reason from scratch instead of pulling from graph | Defeats the vault's purpose |
| Presume the form of the solution | Locks architecture before the problem is understood |
| Cargo-cult another vault's architecture | Different problem, different constraints |
| Catch and swallow errors | Hides failure; corrupts state silently — machinery must fail loudly (vault-os v4 P2) |
| Hardcode domain data in logic | Makes the system brittle to configuration changes |
| Generic analysis without grounding in project constraints | Outputs that could apply to any project = useless |
| Over-specify upfront | Design should emerge from the problem |
| Create notes before deduplicating | Compounds overlap across high-volume vaults |
| Embed live state in CLAUDE.md | CLAUDE.md is the contract; derived orientation + the slim compass are the current position |
| Present stale declared state as current | Compass carries intent, not state; if its Updated stamp is old, say so — orientation derives real state from git |
| Write to decisions.md at session end | Capture at the moment of insight; nuance is gone by session end |
| Route project-specific knowledge to `~/.claude/operator.md` | `operator.md` is for personal/workflow patterns that apply everywhere; project facts go to the vault's decisions.md or auto-memory |
| Use SessionStop as a hook event | It does not exist; hooks wired to it silently never fire |
| Rely on SessionEnd for VS Code tab close | It doesn't fire on tab close; derived orientation (git) is the safety net, /capture the enrichment |
| Assert a vault's state without reading its orientation | Health tables are abolished (v4 D1); state is computed per-vault, never cached |
| Read a foreign vault outside its declared `exports:` | The path is out of contract (v4 D3); manifests declare allowed surfaces, but filesystem permissions do not enforce the boundary |
| Write into a foreign vault anywhere but its `intake:` | Deposits only, never in-place edits; knowledge-graph writes additionally require explicit user instruction |
| Not running `/decide` at the moment a decision is made | Decisions lose nuance by session end; missing an entry means the next session re-litigates from scratch |
| Apply local vault schema rules to foreign vault content | Each vault has its own schema and validate hooks; running local validation against imported notes produces false violations |
| Prune operator.md entries autonomously | Cross-session entry value is invisible to a single-session observer; pruning risk is permanent and unrecoverable — flag and defer to human |

---

## Archie Framework

When analysis is done and the next step is populating multiple structured files from it,
prefer `/archie` over filling them by hand. The skill's `description` carries the live trigger
signals and the Setup-mode scaffold — recognition lives there now, not in this paragraph.

---

## Operating Style

- Sharp. No wasted words.
- State session intent in one sentence before loading any context.
- Context loads on demand. Never read all context files at session start.
- When operator.md exceeds 160 lines, append to /capture output: "operator.md is now N lines — approaching the 200-line truncation limit. Review and prune manually." Never prune autonomously.

---

## Cross-Vault Rules (vault-os v4)

- **meta-vault is the system registry.** Any session that may require cross-vault context begins by reading `{SYSTEM_REGISTRY}/ops/vault-manifest.md` to enumerate candidate vaults. A session that skips this step has incomplete discovery — declare this when it occurs.
- **Sharing is by contract.** A vault's manifest declares `exports:` (the only surfaces foreign sessions/agents should read) and optionally `intake:` (the only place foreign writers should deposit — new dated files only, never edits). Everything undeclared is out of contract, not technically inaccessible.
- **Read the foreign vault's compass (its default export) before any deposit into it.** Writing without orientation is not permitted.
- **Never read a foreign vault's `notes/`.** If a vault exports a MOC surface (e.g. `notes/index.md`), follow it only as far as the export declares.
- **Load is targeted.** Read only what the task needs; stop when the context need is met.
- **Fleet-level notices go to meta-vault's `handoffs/` intake** (dated markdown, `YYYY-MM-DD-source-topic.md`); meta-vault orientation surfaces undigested deposits.
- **Foreign vault rules do not apply locally.** Each vault has its own schema and validate hooks.

---

## Cross-Vault Loading Protocol (v4)

```
-1. Discover: read {SYSTEM_REGISTRY}/ops/vault-manifest.md.
    → Candidates = entries whose domains match the declared session intent.
    → Registry unreachable: fall back to your own manifest's
      cross-vault-dependencies; declare the limitation.

0.  Declare session intent (one sentence). No domain match → stop; do not speculate.

1.  Read {vault-B}/ops/vault-manifest.md (or the manifest path the registry names).
    → Validate: vault-name, root-path, and exports (legacy vaults: load-instruction).
    → Missing → stop and flag the vault as pre-v4 in the session summary.

2.  Read the compass named in exports. It carries INTENT (Focus/Questions/Flags),
    not state — if its Updated stamp is stale, treat it as historical.

3.  Read further export surfaces only as the task requires. Never beyond exports.

4.  Deposits (if any) go only into the vault's declared intake:, as new dated files.

5.  Stop when the context need is met. Note loaded vaults + any deposits in the
    session summary. Claude does not edit cross-vault-dependencies — human decides.
```
