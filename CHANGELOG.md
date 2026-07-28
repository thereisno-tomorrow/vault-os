# Changelog

## 4.2.0 — 2026-07-28

- Bound SessionStart orientation to 15 KB with source-byte accounting and the
  three newest complete decision records.
- Add recovery-posture axes, open-plan status, unresolved decision IDs,
  manifest-driven intake surfacing, and a local `--conformance` primitive.
- Archive narrative session records byte-for-byte before SessionEnd replacement.
- Remove dead `Write(...)` permission rules and correct the exports contract
  from technical enforcement to reviewed routing policy.
- Restore the repository as the source for global rules, commands, the
  registry-aware new-vault skill, and six shared agent definitions.
- Add narrow named-agent exports and document canonical/sanctioned hook
  distribution.
