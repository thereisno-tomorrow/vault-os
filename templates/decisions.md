# Decisions

*Operational decisions captured at the moment of insight. Run `/decide` mid-session — not at session end.*

<!-- Example entry:

## 2026-01-15 — Use SQLite instead of PostgreSQL for local prototype
Decided to use SQLite for the first iteration. The app is single-user, no concurrent writes needed, and SQLite removes the Docker dependency for local dev. PostgreSQL is the target for production — the ORM abstraction means the switch costs one config change.
What was ruled out: PostgreSQL from day one (adds deployment complexity before we've validated the core workflow). Flat JSON files (no query capability, schema enforcement is manual).

-->
