---
# ─────────────────────────────────────────────────────────────────────────────
# VAULT MANIFEST — Vault OS v4 context contract (D3: sharing by contract, isolation by default)
#   exports: — the ONLY surfaces a foreign session/agent may READ. Everything not listed is
#              invisible cross-vault (notes/ above all). Isolation is default; sharing is opt-in.
#   intake:  — (optional) deposit-only inbound surface; foreign writers drop new files, never edit.
#   domains: — discovery metadata; foreign intent must match before any load is allowed.
# ─────────────────────────────────────────────────────────────────────────────
vault-name: starter-vault
root-path: ~/Projects/starter-vault
created: 2026-01-01
last-verified: 2026-01-01
features: [baseline]
domains: []

exports:
  compass: compass.md           # default export — the compass at the vault root, nothing more
  # Anything not listed here is invisible cross-vault.

# intake:                       # optional deposit-only surface
#   inbox: inbox/

cross-vault-dependencies: []
# Declare an entry ONLY if THIS vault loads from another:
#   - vault: /absolute/path/to/other-vault
#     slug: 8charsha1
#     loads-from: [compass]
---
