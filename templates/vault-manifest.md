# Vault Manifest

```yaml
vault-name: my-vault
features: [baseline]
root-path: ~/Projects/my-vault
created: YYYY-MM-DD
last-verified: YYYY-MM-DD
registry: false
domains: []

export-surfaces:
  compass: ops/compass.md

load-instruction: >
  Read ops/vault-manifest.md, then ops/compass.md.
  Stop unless session intent matches a declared domain.

cross-vault-dependencies: []
```
