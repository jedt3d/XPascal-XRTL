# Task

Review the `XRTL.Database` query builder primitives slice for maintainability risks before ORM work begins. Codex remains the source of truth and will accept, modify, or reject your suggestions before any repository change.

# Source Of Truth

Repository: `jedt3d/XPascal-XRTL`

Current phase:
- `XRTL.Database` local SQLite v0 is complete through issue #40.
- Public transactions and parameter binding are complete through issue #48.
- Detached raw mapping is complete through issue #50.
- App dataset iteration is complete through issue #52.
- SQLite-only provider abstraction is complete through issue #54.
- Apply-only migration primitives are complete through issue #56.
- Active slice: issue #58, `XRTL.Database query builder primitives`.
- Parent epic: issue #47, `XRTL.Database local feature stack roadmap`.

Key files to review:
- `src/xrtl/database/xrtl_database.pas`
- `tests/xrtl/database/database_query_builder_tests.pas`
- `docs/xrtl/database.html`
- `docs/decisions/0014-xrtl-database-query-builder-primitives.md`
- `docs/xrtl/testing.html`

Implemented query builder responsibilities:
- SELECT query generation only.
- Validated table, column, and parameter identifiers.
- Default `*` selection when no explicit columns are added.
- Explicit selected columns.
- Text and int64 equality filters.
- Ascending/descending order clauses.
- Non-negative row limits.
- Caller-owned `TXrtlDatabaseParameters` output.
- Execution-neutral behavior; generated SQL is executed by `TXrtlDatabaseConnection`.

Non-scope:
- No ORM.
- No insert/update/delete builder.
- No joins, grouping, aggregates, expression trees, raw SQL fragments, or dialect abstraction.
- No schema introspection.
- No PostgreSQL, MySQL/MariaDB, Firebird, or network database providers.

# Constraints

- FreePascal must remain version `3.3.1`.
- Supported platforms are Windows x86_64, macOS Apple Silicon aarch64, and Ubuntu 26.04 x86_64.
- macOS Intel is out of scope.
- Do not recommend exposing SQLDB, SQLite3Conn, TSQLQuery, TSQLTransaction, TParam, TField, or TDataset as public XRTL.Database types.
- Do not propose network database work.
- Keep the next slice focused on the smallest practical ORM layer over provider, migration, and query builder contracts.

# Output Format

Return this structure:

```markdown
# GLM XRTL.Database Query Builder Review

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
- Only include questions that block the next ORM slice.

## Verdict
Ready for merge | Ready with small guardrails | Needs another design pass
```

# Quality Bar

Codex will judge the response by:
- Whether it protects long-term maintainability over short-term speed.
- Whether it keeps query builder behavior separate from ORM and network providers.
- Whether suggestions are concrete enough to become issue comments or documentation edits.
- Whether it respects the supported platform and FPC constraints.

# Do Not

- Do not invent implemented APIs.
- Do not write Pascal implementation code.
- Do not propose network database work.
- Do not recommend broad Delphi/Lazarus compatibility goals unless the current docs support them.
- Do not include credentials, hostnames, IP addresses, or local validation secrets.
