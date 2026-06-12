# Task

Review the `XRTL.Database` app dataset slice for maintainability risks before provider abstraction begins. Codex remains the source of truth and will accept, modify, or reject your suggestions before any repository change.

# Source Of Truth

Repository: `jedt3d/XPascal-XRTL`

Current phase:
- `XRTL.Database` local SQLite v0 is complete through issue #40.
- Public transactions and parameter binding are complete through issue #48.
- Detached raw mapping is complete through issue #50.
- Active slice: issue #52, `XRTL.Database app dataset abstraction over raw SQLite results`.
- Parent epic: issue #47, `XRTL.Database local feature stack roadmap`.

Key files to review:
- `src/xrtl/database/xrtl_database.pas`
- `tests/xrtl/database/database_dataset_tests.pas`
- `docs/xrtl/database.html`
- `docs/decisions/0011-xrtl-database-app-dataset.md`
- `docs/xrtl/testing.html`

Implemented dataset responsibilities:
- Detached dataset state over copied raw rows.
- Active/inactive state.
- Record count and field count.
- Cursor-style `First`, `Next`, and `Eof`.
- Current row lookup.
- Current value lookup by field name.
- Loading from `TXrtlSqliteResultSet`.
- `QueryDataSet` overloads with and without parameters.

Non-scope:
- No provider abstraction beyond SQLite yet.
- No migrations.
- No query builder.
- No ORM.
- No UI data binding.
- No PostgreSQL, MySQL/MariaDB, Firebird, or network database providers.

# Constraints

- FreePascal must remain version `3.3.1`.
- Supported platforms are Windows x86_64, macOS Apple Silicon aarch64, and Ubuntu 26.04 x86_64.
- macOS Intel is out of scope.
- Do not recommend exposing SQLDB, SQLite3Conn, TSQLQuery, TSQLTransaction, TParam, TField, or TDataset as public XRTL.Database types.
- Do not propose migrations, query-builder behavior, or ORM behavior in this slice.
- Keep the next slice focused on separating the concrete SQLite provider surface before migrations begin.

# Output Format

Return this structure:

```markdown
# GLM XRTL.Database App Dataset Review

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
- Only include questions that block the next provider abstraction slice.

## Verdict
Ready for merge | Ready with small guardrails | Needs another design pass
```

# Quality Bar

Codex will judge the response by:
- Whether it protects long-term maintainability over short-term speed.
- Whether it keeps dataset behavior separate from provider abstraction, migrations, query builder, and ORM.
- Whether it avoids leaking SQLDB or TDataset ideas into the public contract.
- Whether suggestions are concrete enough to become issue comments or documentation edits.
- Whether it respects the supported platform and FPC constraints.

# Do Not

- Do not invent implemented APIs.
- Do not write Pascal implementation code.
- Do not propose network database work.
- Do not recommend broad Delphi/Lazarus compatibility goals unless the current docs support them.
- Do not include credentials, hostnames, IP addresses, or local validation secrets.
