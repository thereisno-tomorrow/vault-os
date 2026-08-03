# Contracts

Versioned text that vault-os owns and other systems consume.

| File | Consumed as |
|---|---|
| `agent-contract-1.0.md` | The cross-vault contract block carried by every shared agent |
| `shared-global-rules-1.0.md` | The fleet rules composed into `CLAUDE.md` and `AGENTS.md` |

Both were previously copies. `agent-contract-1.0.md` was pasted into each of the
six agent bodies in `global/agents/`, and `shared-global-rules-1.0.md` was a
whole file (`global/CLAUDE.md`) that `agent-config` had absorbed as personal
authoring. Neither could propagate: the 2026-08-03 audit found the contract text
frozen inside `agent-config`'s agent prompts with no route back here, and found
the global rules claimed by both repositories at once.

Extracting them here makes each a **declared input**. `agent-config` vendors both
at a recorded commit, composes agent prompts from an agent's own body plus the
contract, and composes provider instructions from these rules plus its own
operator profile and routing. Bumping a file here reaches every installed
artifact through a normal release rather than by hand.

Rules:

- These files are canonical. Do not edit a rendered copy in a provider directory,
  and do not edit `agent-config`'s vendored copy — that is drift, not authoring.
- `agent-config` declares both `foreign-owned` with an `upstream` block, and its
  `upstream-sync` validator fails the release if a vendored copy diverges.
- Bump the filename and any in-file version marker together.
- A consumer that pins 1.0 keeps reading that file; add a new one for 1.1.
