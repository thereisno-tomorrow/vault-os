# Vault OS

Session memory for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Two small shell scripts tell the agent where a project stands when a session starts, and record what changed when it ends, so you stop re-briefing it by hand.

**Status:** personal tool, v4.2.0, MIT. I started building it in February 2026 and published the first version that March, when Claude Code had no good way to carry project state from one session to the next. The current Claude Code desktop app covers most of that itself, through session history and built-in memory, so most people no longer need this. I'm leaving it up as a worked example of the approach, and because two things are still not covered (see [Where it still helps](#where-it-still-helps)).

## The problem, as it was in early 2026

When I started this, Claude Code began every session knowing nothing about your project. You could re-explain it each time, or keep a status file for the agent to read. I tried the status file first (v2 of this project) and it went stale.

v4 rests on one rule: **if a machine can compute it, nobody should be asked to remember it.** Branch, recent commits, uncommitted work and recently edited files are one `git` call away. The only things worth writing by hand are the things git cannot know: what you are trying to do, what is undecided, and what to watch out for.

## What you get

- **`session-orient.sh`** runs when a session starts. It prints the branch, the last five commits, uncommitted and unpushed counts, the five most recently edited files and the last session record, all computed on the spot. Nothing is cached, so nothing can go stale.
- **`session-capture.sh`** runs when a session ends. It writes a short record to `ops/sessions/last-active.md` with the time, branch and files touched.
- **`compass.md`** is the one file you write. It has three short sections: Focus, Questions and Flags. If its `Updated:` date is more than 30 days old, orientation shows it behind a warning instead of presenting old intent as current.

Both hooks are plain bash and git. No model calls, no network, no database.

## What it prints

Real output from `hooks/session-orient.sh` on a fresh copy of `examples/starter-vault`, trimmed:

```
╔══════════════════════════════════════════════════════════╗
║  demo-vault ORIENTATION                                  ║
╚══════════════════════════════════════════════════════════╝
Date: 2026-10-27   hook 4.2.0

════════════════════════════════════════════════════════════
DERIVED — live from git + disk
════════════════════════════════════════════════════════════
Branch: main
Last 5 commits:
  ee817c7 scaffold starter vault
Recovery posture: local-history=yes; remotes=0; upstream=NONE; push status unknown; tracked-changes=1; untracked=0 files/0 B
Recently modified (non-ignored, top 5):
  ops/vault-manifest.md
  ops/sessions/last-active.md
  ops/decisions.md
  compass.md
  CLAUDE.md

════════════════════════════════════════════════════════════
DECLARED — compass intent
════════════════════════════════════════════════════════════
⚠ intent last declared 299 days ago — treat as HISTORICAL
...
--- ORIENTATION COST ---
operator=0B derived=911B declared=1059B plans=0B intakes=0B decisions=209B
```

Everything under DERIVED is recomputed at startup. The starter vault's compass is dated 2026-01-01, so orientation put it behind a banner and pointed the agent back at the computed state.

## Where it still helps

Built-in memory holds notes the model chose to keep. Two things it does not do:

- **State that cannot drift.** Branch, commits, uncommitted work and recent files are recomputed from git at every start. They are never a remembered copy that could be out of date.
- **State that lives in the project.** The compass, decisions log and session record are plain files in the repo, so they are versioned, reviewable and move with the project between machines. Built-in memory lives in the app's own folder.

## Try it

You need Claude Code, bash and git. Python 3 is only for the optional note validator.

```bash
cp -r examples/starter-vault ~/Projects/my-project
cd ~/Projects/my-project
git init && git add -A && git commit -m "start"
CLAUDE_PROJECT_DIR="$PWD" bash .claude/hooks/session-orient.sh
```

The last line shows the orientation without opening Claude Code. Open the folder in Claude Code and `.claude/settings.json` runs both hooks at session start and end.

To check the hooks themselves, run `bash tests/test-hooks.sh`. It runs 13 checks, including broken fixtures (a manifest missing its `exports:` block, a stale hook version, bad wiring) that the checker has to name correctly.

The starter vault's `CLAUDE.md` lists `/capture`, `/decide`, `/guide` and `/compass`. Those are skills in my own setup and are not in this repo. The hooks work without them. `/capture` only adds a narrative summary on top of the automatic record.

## Design decisions and what they cost

- **Compute, don't curate.** The hooks only know what git and the disk know. Why a decision was made still needs a person, through the decisions log (`ops/decisions.md`).
- **Say so when something is stale.** A stale compass is demoted behind a banner, not hidden and not trusted. The cost is that dormant projects open with a warning.
- **Cap what gets injected.** Orientation lands in the agent's context every session, so it has a 15 KB budget. The three newest decisions show in full, and older ones stay visible only while unresolved. The cost is that old, resolved decisions need a grep.
- **Use Claude Code's own permission rules.** Protected files (`CLAUDE.md`, the manifest) sit behind `permissions.ask`. My first version was a Python hook that watched one tool, warned after the write, and guarded an empty list. The cost of the native rule is that it prompts you. It does not hard-block.
- **Share between projects by declared list.** A project's `ops/vault-manifest.md` lists the files other sessions may read (`exports:`), and anything unlisted is out of bounds. That is routing policy, not a security boundary: the filesystem still allows the read.

## Limits

- Claude Code only. The hooks use its session start and session end events.
- Session end does not fire when you close a VS Code tab, and "files touched" is an approximation, because a hook cannot diff against the session start.
- The compass still depends on a person. The system demotes it when it goes stale. It does not fix it.
- This is plumbing around the session. It does nothing about retrieval or about how the model uses the context once it has it.

## Repo map

- `hooks/`: the two hooks (single source of truth), plus `validate-note.py` for the optional knowledge-graph module
- `examples/starter-vault/`: a minimal working vault
- `templates/`: blank versions of each vault file
- `spec/vault-os-v4.md`: the current spec. `spec/design-principles.md` has the reasoning. `spec/vault-os-v2.md` is superseded and kept for history.
- `tests/`: the 13-check suite above
- `skills/new-vault/`: a Claude Code skill that scaffolds a vault. It was written for my own setup and I have not tested it outside it, so use the manual copy above.
- `contracts/`: text shared with my own multi-repo setup. You do not need it to use Vault OS.

Seven optional modules (A to G) add a notes graph, inbox processing, synthesis commands and similar. They are described in `spec/vault-os-v2.md`, section 5. The baseline above needs none of them.

## License

MIT
