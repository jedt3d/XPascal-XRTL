# Task

Review the `XRTL.Database` SQLite provider abstraction slice for maintainability risks before migrations begin. Codex remains the source of truth and will accept, modify, or reject your suggestions before any repository change.

# Source Of Truth

Repository: `jedt3d/XPascal-XRTL`

Current phase:
- `XRTL.Database` local SQLite v0 is complete through issue #40.
- Public transactions and parameter binding are complete through issue #48.
- Detached raw mapping is complete through issue #50.
- App dataset iteration is complete through issue #52.
- Active slice: issue #54, `XRTL.Database SQLite provider abstraction`.
- Parent epic: issue #47, `XRTL.Database local feature stack roadmap`.

Key files to review:
- `src/xrtl/database/xrtl_database.pas`
- `tests/xrtl/database/database_provider_tests.pas`
- `docs/xrtl/database.html`
- `docs/decisions/0012-xrtl-database-provider-abstraction.md`
- `docs/xrtl/testing.html`

Implemented provider responsibilities:
- SQLite provider kind and capabilities.
- Provider-neutral connection configuration.
- Provider-neutral aliases over existing SQLite value/result/parameter/dataset types.
- `TXrtlDatabaseConnection` facade that delegates to `TXrtlSqliteDatabase`.

Non-scope:
- No non-SQLite provider selection.
- No PostgreSQL, MySQL/MariaDB, Firebird, or network database providers.
- No migrations.
- No query builder.
- No ORM.
- No UI data binding.

# Constraints

- FreePascal must remain version `3.3.1`.
- Supported platforms are Windows x86_64, macOS Apple Silicon aarch64, and Ubuntu 26.04 x86_64.
- macOS Intel is out of scope.
- Do not recommend exposing SQLDB, SQLite3Conn, TSQLQuery, TSQLTransaction, TParam, TField, or TDataset as public XRTL.Database types.
- Do not propose network database work.
- Keep the next slice focused on minimum migration primitives over the provider facade.

# Output Format

Return this structure:

```markdown
# GLM XRTL.Database Provider Review

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
- Only include questions that block the next migration slice.

## Verdict
Ready for merge | Ready with small guardrails | Needs another design pass
```

# Quality Bar

Codex will judge the response by:
- Whether it protects long-term maintainability over short-term speed.
- Whether it avoids duplicating SQL execution behavior.
- Whether it keeps provider abstraction separate from migrations, query builder, ORM, and network databases.
- Whether suggestions are concrete enough to become issue comments or documentation edits.
- Whether it respects the supported platform and FPC constraints.

# Do Not

- Do not invent implemented APIs.
- Do not write Pascal implementation code.
- Do not propose network database work.
- Do not recommend broad Delphi/Lazarus compatibility goals unless the current docs support them.
- Do not include credentials, hostnames, IP addresses, or local validation secrets.
