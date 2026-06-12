# Task

Review the `XRTL.Database` migration primitives slice for maintainability risks before query builder work begins. Codex remains the source of truth and will accept, modify, or reject your suggestions before any repository change.

# Source Of Truth

Repository: `jedt3d/XPascal-XRTL`

Current phase:
- `XRTL.Database` local SQLite v0 is complete through issue #40.
- Public transactions and parameter binding are complete through issue #48.
- Detached raw mapping is complete through issue #50.
- App dataset iteration is complete through issue #52.
- SQLite-only provider abstraction is complete through issue #54.
- Active slice: issue #56, `XRTL.Database migration primitives`.
- Parent epic: issue #47, `XRTL.Database local feature stack roadmap`.

Key files to review:
- `src/xrtl/database/xrtl_database.pas`
- `tests/xrtl/database/database_migration_tests.pas`
- `docs/xrtl/database.html`
- `docs/decisions/0013-xrtl-database-migration-primitives.md`
- `docs/xrtl/testing.html`

Implemented migration responsibilities:
- Explicit migration id, description, and ordered SQL statements.
- Ordered migration plans with duplicate-id validation.
- Migration runner over `TXrtlDatabaseConnection`.
- XRTL-owned `xrtl_schema_migrations` metadata table.
- Idempotent reapply behavior.
- Out-of-order applied migration detection.
- Per-migration transaction wrapping and rollback on failed statements.

Non-scope:
- No PostgreSQL, MySQL/MariaDB, Firebird, or network database providers.
- No external migration tool integration.
- No schema diffing.
- No rollback/down migration API.
- No query builder.
- No ORM.
- No UI/admin migration runner.

# Constraints

- FreePascal must remain version `3.3.1`.
- Supported platforms are Windows x86_64, macOS Apple Silicon aarch64, and Ubuntu 26.04 x86_64.
- macOS Intel is out of scope.
- Do not recommend exposing SQLDB, SQLite3Conn, TSQLQuery, TSQLTransaction, TParam, TField, or TDataset as public XRTL.Database types.
- Do not propose network database work.
- Keep the next slice focused on query builder primitives over the provider/migration contracts.

# Output Format

Return this structure:

```markdown
# GLM XRTL.Database Migration Review

## Strong Agreements
- ...

## Design Risks
- Risk:
  Impact:
  Suggested change:

## API Surface Suggestions
- Keep:
- Change:
- Defer:

## Test Strategy Suggestions
- ...

## Questions For Codex
- Only include questions that block the next query builder slice.

## Verdict
Ready for merge | Ready with small guardrails | Needs another design pass
```

# Quality Bar

Codex will judge the response by:
- Whether it protects long-term maintainability over short-term speed.
- Whether it keeps migration behavior separate from query builder, ORM, and network providers.
- Whether suggestions are concrete enough to become issue comments or documentation edits.
- Whether it respects the supported platform and FPC constraints.

# Do Not

- Do not invent implemented APIs.
- Do not write Pascal implementation code.
- Do not propose network database work.
- Do not recommend broad Delphi/Lazarus compatibility goals unless the current docs support them.
- Do not include credentials, hostnames, IP addresses, or local validation secrets.
