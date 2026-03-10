Run periodic vault maintenance. Do not run every session — only when Extended > 20 entries or decisions.md > 30 entries.

## Step 1 — decisions.md review
Read `ops/decisions.md`. Show all entries with dates.
Flag any marked [SUPERSEDED] or older than 30 days.
For each flagged entry, present with options: delete / keep / graduate to knowledge.md.
Claude proposes; user confirms before any write.

## Step 2 — knowledge.md Extended review
Read `ops/knowledge.md`. Show Extended entry count and total line count.
For each Extended entry: present with options: graduate to Core / delete / keep.

## Step 3 — Graduation check
Before graduating any Extended entry to Core, show current Core line count.
If Core is at or above 60 lines, present current Core entries for pruning before accepting any graduation — forced trade, no silent overflow.

## Step 4 — Summary
Show final Core line count and Extended entry count. Session complete.
