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

## Blocked / open questions
[Anything waiting on external input or unresolved]

## Cross-vault loads
[Which foreign vaults were loaded this session, if any]
```

Write as if briefing someone who will resume this work cold. One-line summaries are not sufficient — they produce amnesia in the next session.

After writing last-active.md, assess whether vault state changed this session. "State changed" means any of: current focus shifted, a live question was resolved or surfaced, a flag appeared or was cleared, progress was made on tracked items, direction or priorities changed.

If state changed: update `ops/compass.md` — revise the relevant sections only and update the `*Updated: YYYY-MM-DD*` timestamp to today. Do not rewrite sections that did not change.

If state did not change: skip. Do not touch compass.md.
