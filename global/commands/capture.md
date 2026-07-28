---
description: Capture a durable session handoff and refresh the compass only when vault state changed
---

Write a session summary to `ops/sessions/last-active.md`.

Before writing, mark any decisions made this session that have been reversed or superseded as [SUPERSEDED] in `ops/decisions.md`.

Then write `ops/sessions/last-active.md` with this structure:

```
Date: YYYY-MM-DD

## What was worked on
[Paragraph describing the work done this session — specific enough that someone resuming cold knows exactly where things stand]

## Decisions made
[Any calls made this session that constrain future work — if none, say so]

## In progress
[What is actively incomplete and needs to be picked up next session]

## Next step
[The single concrete action that should happen first when work resumes]

## Blocked / open questions
[Anything waiting on external input or unresolved]

## Dead ends
[Approaches tried and rejected, with enough reason not to repeat them; if none, say so]

## Cross-vault loads
[Which foreign vaults were loaded this session, if any]
```

Write as if briefing someone who will resume this work cold. One-line summaries are not sufficient — they produce amnesia in the next session.

After writing last-active.md, assess whether vault state changed this session. "State changed" means any of: Focus shifted, a Question was resolved or surfaced, a Flag appeared or was cleared, direction or priorities changed.

If state changed: update the compass (`compass.md` or `ops/compass.md`, whichever the vault uses) — under Vault OS v4 it holds exactly three sections, **Focus / Questions / Flags** (nothing else; no Vault Health table, no narrative "current state" block). Revise only the section(s) that changed and update the `*Updated: YYYY-MM-DD*` timestamp to today. Do not rewrite sections that did not change, and do not add sections outside Focus/Questions/Flags.

If state did not change: skip. Do not touch the compass.
