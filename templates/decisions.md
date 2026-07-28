# Decisions

*Operational decisions captured at the moment of insight. Run `/decide` mid-session — not at session end.*

<!-- Example entry:

- [2026-01-15] Decision: Use SQLite for the local prototype
  Decision-ID: 20260115-sqlite-local-prototype
  Because: The app is single-user, needs no concurrent writes, and SQLite removes a Docker dependency before the workflow is validated.
  Forecloses: PostgreSQL from day one because it adds deployment complexity; flat JSON because it lacks query and schema support.
  Governs: Local persistence for the first product iteration.
  Encoded in: src/db/config.ts + DATABASE_URL default
  Completeness check: A clean local checkout starts and persists data without PostgreSQL or Docker.
  State: encoded

-->
