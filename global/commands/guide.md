Render the current vault's command reference.

Read `CLAUDE.md` in the current vault root. Find its `## Commands` section (a markdown table of
command → purpose). Render that table verbatim.

If `CLAUDE.md` has no `## Commands` section, say so plainly — do not fabricate one.

After the table, add one pointer line:

> Full spec: vault-os `spec/vault-os-v4.md` (baseline commands, hook contract, context-contract manifest).

This replaces the old static `ops/guide.md` file, retired under Vault OS v4 (D9) — one source per
fact: CLAUDE.md's Commands table is canonical, `/guide` only renders it.
