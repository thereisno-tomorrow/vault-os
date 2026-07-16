---
# ─────────────────────────────────────────────────────────────────────────────
# VAULT MANIFEST — Vault OS v4 context contract (D3: sharing by contract, isolation by default)
#
# This is the ONLY negotiated surface between this vault and the rest of the fleet.
#   exports: — the ONLY surfaces a foreign session/agent may READ. Everything NOT listed here
#              is invisible cross-vault. notes/ above all: it is never exported by default.
#              Isolation is the default; sharing is opt-in, one path at a time.
#   intake:  — (optional) where foreign writers may DEPOSIT. Deposits only: a foreign writer
#              drops a NEW file into the intake dir and never edits an existing file in place.
#   domains: — discovery metadata. A foreign session matches its stated intent against these
#              before it is allowed to load anything from this vault.
# ─────────────────────────────────────────────────────────────────────────────
vault-name: my-vault
root-path: ~/Projects/my-vault
created: YYYY-MM-DD
last-verified: YYYY-MM-DD
features: [baseline]
domains: []                     # e.g. [payments-infrastructure, mas-regulation]

exports:
  compass: compass.md           # default export — the compass, nothing more
# handoffs: handoffs/           # optional — a dir of fleet-level notices this vault chooses to publish
  # Anything not listed above is invisible cross-vault. Do NOT export notes/ without a deliberate reason.

# intake:                       # optional — deposit-only inbound surface for foreign writers/agents
#   inbox: inbox/               # foreign writers drop new files here; they never edit in place

cross-vault-dependencies: []
# Declare an entry ONLY if THIS vault loads from another. Shape:
#   - vault: /absolute/path/to/other-vault   # absolute, forward slashes, no trailing slash
#     slug: 8charsha1                          # first 8 chars of SHA1(normalized root-path)
#     loads-from: [compass]                    # which of that vault's declared EXPORTS this vault reads
---
