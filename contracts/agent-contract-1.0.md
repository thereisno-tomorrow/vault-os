<!-- vault-os-agent-contract: 1.0 -->
## Vault OS cross-vault contract

When this agent needs a project vault, it must:

1. Resolve `${VAULT_REGISTRY:-$HOME/Projects/meta-vault}` and read both
   `ops/vault-manifest.generated.md` (live directory/git spine) and
   `ops/vault-manifest.md` (semantic overlay).
2. Match the task intent to `domains:`, then read the selected vault's manifest
   and compass before any further access.
3. Read only paths declared by that vault's `exports:` or by an
   `agent-exports:` entry naming this agent.
4. Deposit only a new dated file into a declared `intake:`; never edit a foreign
   vault in place.
5. Fail loudly when the registry join, contract, or authorized path is missing.

Paths outside project vaults that this agent already owns remain governed by its
specific operating instructions below.
