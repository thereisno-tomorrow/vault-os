---
description: Capture an operational decision as a complete, machine-readable record at the moment it is made
---

Capture the current operational decision to `ops/decisions.md`.

Append an entry in this format:

```
- [YYYY-MM-DD] Decision: [Decision title]
  Decision-ID: YYYYMMDD-short-stable-slug
  Because: [Why this choice was made]
  Forecloses: [What was ruled out and why]
  Governs: [The work, behavior, or artifact this constrains]
  Encoded in: [Stable path plus heading, symbol, or token; use UNENCODED until durable machinery carries it]
  Completeness check: [How a future session can verify the decision was applied]
  State: encoded
```

Use `State: unencoded` whenever `Encoded in:` is `UNENCODED`. Do not claim
`encoded` merely because the decision was written to this log.

Run this at the moment a decision is made — not at session end. Nuance is lost
by the end of the session. Keep each record contiguous so the orient hook can
surface the newest complete records without truncating one mid-field.
