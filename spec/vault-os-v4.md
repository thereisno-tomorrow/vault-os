# Vault OS v4

*Canonical specification for vault construction and cross-vault interoperability.*
*Supersedes `vault-os-v2.md` (kept for history, marked SUPERSEDED). Derived from the approved
design `meta-vault/docs/plans/2026-07-16-vault-os-v4-design.md` (decisions D1–D9).*

---

## 0. Purpose

Session continuity + agent coordination: any session or agent picks up a project cold and knows
where it stands, and context flows between vaults through **declared channels** with enough
isolation that one vault's context never pollutes another's.

Not the center of v4: the knowledge-graph layer (Modules A–C remain available, unchanged, for the
vaults that use them) and life-goal tracking (`quests/` parked).

## 1. Principles (every rule below satisfies all five)

1. **Survive neglect** — no component depends on a human ritual.
2. **Fail loudly** — a check that cannot run says so; it never defaults to "fine".
3. **Admission criterion** — "would anyone notice within a week if this broke?" If no, it isn't built.
4. **Native-first** — Claude Code primitives (auto-memory, skills, agents, permissions, hooks) before bespoke re-implementations.
5. **Derived over declared** — if a fact can be computed from disk/git, never ask a human or session to maintain it.

---

## 2. What a conforming v4 vault has

A **vault** is a project directory with all four baseline components. Missing any one → it is a
workspace, not a vault.

| Component | Path | Purpose |
|---|---|---|
| Contract | `CLAUDE.md` | Identity, commands, rules. No live state. |
| Position | `compass.md` (root) or `ops/compass.md` | DECLARED intent only: Focus / Questions / Flags + `*Updated:*` stamp. |
| Hooks | `.claude/hooks/session-orient.sh` + `session-capture.sh` | Computed orientation; minimal capture. Versioned, `--selftest`-able. |
| Contract (cross-vault) | `ops/vault-manifest.md` | The context contract: `exports:` / `intake:` / `domains:`. |

Wired in `.claude/settings.json`: `SessionStart→session-orient.sh`, `SessionEnd→session-capture.sh`
(blank matcher `""`, robust `bash "$CLAUDE_PROJECT_DIR"/.claude/hooks/...` command), plus native
`permissions.ask` rules for protected files.

---

## 3. Continuity is computed, not curated (D1)

State splits by who can know it:

- **DERIVED** — `session-orient.sh` computes live every session: current branch, last 5 commits,
  uncommitted count, unpushed count (no-upstream and no-repo handled loudly), 5 most recently
  modified non-ignored files, and the last session record with its age. No stored copy exists to
  go stale.
- **DECLARED** — `compass.md`, three sections only: **Focus** (what the vault is trying to do now),
  **Questions** (open decisions), **Flags** (known hazards). Only things `git log` cannot tell you.
  Carries an `*Updated: YYYY-MM-DD*` stamp. If the stamp is **>30 days** old, orientation shows the
  compass behind a loud `⚠ intent last declared N days ago — treat as historical` banner.

**Abolished as a genre:** Vault Health tables, "current state" narratives, and Session Handoff
blocks. Per-vault status is computed on demand from derived signals, never cached in a table. The
CLAUDE.md "Session Handoff" heading survives only as a one-line pointer to orientation + compass.

**Verify:** open a fresh session in a vault untouched for a month → orientation shows accurate
DERIVED state + a staleness banner on the DECLARED part; nothing presents stale data as current.

---

## 4. Capture is a hook with a skill on top (D2)

Three write paths, by reliability tier:

1. **`session-capture.sh` (SessionEnd hook)** — writes a minimal machine record to
   `ops/sessions/last-active.md`: timestamp, branch, and a files-touched **approximation**
   (uncommitted working-tree changes + files in today's most recent commit — a true session diff
   is unavailable to the hook; the record documents this). Fires on clean exits only; does NOT
   fire on VS Code tab close. It must NOT clobber a richer same-day `/capture` record (detected by
   a same-day date line that lacks the hook's own self-stub marker).
2. **`/capture`** — enriches with narrative when invoked. Optional, never load-bearing.
3. **DERIVED orientation (§3)** — the safety net. Even with zero capture, git is the record.

`ops/decisions.md` is unchanged (it works). `knowledge.md` and its Core/Extended graduation
machinery are **deleted everywhere** (confirmed zero organic use).

**Verify:** close a session without `/capture` → next orientation still reconstructs what happened
from derived signals.

---

## 5. Sharing by contract, isolation by default (D3)

Each vault's `ops/vault-manifest.md` carries a **context contract** in YAML frontmatter:

```yaml
exports:                    # the ONLY surfaces foreign sessions/agents may READ
  compass: compass.md       # default. Everything NOT listed is invisible cross-vault — notes/ above all.
# intake:                   # optional — where foreign writers may DEPOSIT (deposits only, never edits in place)
#   inbox: inbox/
domains: [ ... ]            # discovery metadata — matched against foreign session intent
cross-vault-dependencies: []# declared only if THIS vault loads from another
```

Loading protocol simplifies to: **match domains → read exports → stop.** Pollution control is
structural (you *cannot* read what isn't exported), not disciplinary. The meta-vault registry
remains the derived spine (`sync-local.sh`) plus a hand overlay.

**Verify:** a cross-vault load completes reading only export surfaces; a read into a non-exported
path is a protocol violation visible in the session summary.

---

## 6. Agent coordination rides the same rails (D4)

Agents are cross-vault readers/writers like any session: discover via the registry, read exports,
deposit into intakes. The meta-vault may keep `handoffs/` as its own intake — a place any
agent/session drops fleet-level notices; its orientation surfaces undigested handoffs. **No message
bus, no queue, no daemon** until a real workflow outgrows deposit-files (admission criterion).

---

## 7. Enforcement is native (D5)

Protected files are gated by native `permissions.ask` rules in `.claude/settings.json` —
enforced by the harness **before** the write, not warned after. Rule syntax (verified against the
official Claude Code permissions docs):

- `permissions` object with `allow` / `ask` / `deny` arrays; evaluated **deny → ask → allow**,
  first match wins.
- `Edit(...)` / `Write(...)` take gitignore-spec file-path patterns. A leading `/path` anchors at
  the **settings source** — for a project's `.claude/settings.json` that is the project root.
- A Read/Edit deny does **not** cover Write, so protecting a path requires **both** an `Edit(...)`
  and a `Write(...)` rule.

Baseline:

```json
"permissions": {
  "ask": [
    "Edit(/CLAUDE.md)", "Write(/CLAUDE.md)",
    "Edit(/ops/vault-manifest.md)", "Write(/ops/vault-manifest.md)"
  ]
}
```

`protect.py` and `protected-files.txt` are **retired from the template**. CLAUDE.md's Protected
Files section documents the native rules; it is not a parallel list.

**Verify:** editing `CLAUDE.md` triggers a native permission prompt; grep for `protect.py` in the
template returns nothing.

---

## 8. One hook lineage, tested, versioned (D6)

The vault-os repo is the single hook source of truth: exactly two hooks (orient, capture), each
with a `--selftest` mode that exercises its own dependencies (date parsing, grep regex including
the decisions char class, git availability, `stat`, path resolution) and exits loudly on any
failure. Each hook carries a `vault-os-hook-version` stamp (currently **4.1.0**). Every check
fails loudly; nothing silently no-ops. A vault that intentionally carries a sanctioned superset of
a hook (extra behavior beyond the spec repo's lineage) stamps its version with a `+<vault>` suffix
(e.g. `4.1.0+meta.1`), so byte-drift checks can distinguish an intentional superset from unnoticed
drift.

**Verify:** `bash session-orient.sh --selftest` and `bash session-capture.sh --selftest` pass; a
deliberately broken dependency makes them fail loudly, not silently.

---

## 9. Portable root (D7)

Hooks and scripts resolve the vault from `$CLAUDE_PROJECT_DIR` (sentinel-checked) and the registry
as `${VAULT_REGISTRY:-$HOME/Projects/meta-vault}`. No hardcoded absolute user paths in templates.

---

## 10. Migration (D8)

- Wave 1: meta-vault + this spec repo. Wave 2: the active vaults. Wave 3: dormant vaults migrate
  **on first touch** — `session-orient.sh` detects a pre-v4 vault (manifest has no `exports:`
  contract) and prints a one-line migration offer instead of a speculative fleet pass.

**Verify:** a dormant vault's first post-v4 session shows the migration offer; a migrated vault
does not.

---

## 11. What v4 removes (D9)

`knowledge.md` + graduation machinery · `protect.py` / `protected-files.txt` · Vault Health tables
and Session Handoff narrative blocks · `guide.md` as a separate file (`/guide` renders CLAUDE.md's
Commands table — one source per fact) · Module H references (never defined) · the agent-slack kit
(superseded by D4's deposit model) · `tmp-viz/`.

**Still available (Module A only):** `validate-note.py` + `ops/validate-config.yaml` for vaults
that run a knowledge graph. Not part of the baseline.

---

## 12. Baseline commands

| Command | Purpose |
|---|---|
| `/compass` | Read the compass, or update Focus/Questions/Flags |
| `/guide` | Render CLAUDE.md's Commands table (no separate guide file) |
| `/capture` | Narrative session summary → `ops/sessions/last-active.md` (optional) |
| `/decide` | Append a decision to `ops/decisions.md` at the moment it is made |

(`/maintain` retired from the baseline with `knowledge.md`; a vault running Module A may reinstate
a decisions-review command if it needs one.)

---

## 13. Conformance checklist

A vault conforms to v4 when:

1. `CLAUDE.md`, a compass, both v4 hooks, and `ops/vault-manifest.md` are all present.
2. The compass has exactly Focus / Questions / Flags + an `*Updated:*` stamp and no derived state.
3. `ops/vault-manifest.md` frontmatter has `vault-name`, `root-path`, `created`, `last-verified`,
   `features`, `domains`, and an `exports:` block (plus optional `intake:` /
   `cross-vault-dependencies`).
4. `.claude/settings.json` wires both hooks (blank matcher, `$CLAUDE_PROJECT_DIR` command) and
   carries `permissions.ask` rules for `CLAUDE.md` and `ops/vault-manifest.md` (Edit + Write each).
5. Both hooks pass `--selftest` and stamp version ≥ 4.1.0.
6. No `knowledge.md`, no `guide.md`, no `protect.py`, no `protected-files.txt`.
7. `validate-note.py` present only if the vault runs Module A.
