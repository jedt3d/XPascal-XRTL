# Task

Review the `XRTL.Database` ORM mapping primitives slice for maintainability risks before the local-only Database epic closes. Codex remains the source of truth and will accept, modify, or reject your suggestions before any repository change.

# Source Of Truth

Repository: `jedt3d/XPascal-XRTL`

Current phase:
- `XRTL.Database` local SQLite v0 is complete through issue #40.
- Public transactions and parameter binding are complete through issue #48.
- Detached raw mapping is complete through issue #50.
- App dataset iteration is complete through issue #52.
- SQLite-only provider abstraction is complete through issue #54.
- Apply-only migration primitives are complete through issue #56.
- SELECT query builder primitives are complete through issue #58.
- Active slice: issue #60, `XRTL.Database ORM mapping primitives`.
- Parent epic: issue #47, `XRTL.Database local feature stack roadmap`.

Key files to review:
- `src/xrtl/database/xrtl_database.pas`
- `tests/xrtl/database/database_orm_tests.pas`
- `docs/xrtl/database.html`
- `docs/decisions/0015-xrtl-database-orm-mapping-primitives.md`
- `docs/xrtl/testing.html`

Implemented ORM responsibilities:
- Explicit schema with table name and int64 id column.
- Explicit application field name to database column mapping.
- XRTL-owned mapped record container.
- Read-oriented `FindByInt64Id` mapper using `TXrtlDatabaseSelectBuilder` and `TXrtlDatabaseConnection.QueryRows`.
- Mapped values use XRTL-owned detached value types.

Non-scope:
- No full active-record framework.
- No insert/update/delete ORM operations.
- No dirty tracking, identity map, relationships, lazy loading, or code generation.
- No raw SQL fragments or dialect abstraction.
- No PostgreSQL, MySQL/MariaDB, Firebird, or network database providers.

# Constraints

- FreePascal must remain version `3.3.1`.
- Supported platforms are Windows x86_64, macOS Apple Silicon aarch64, and Ubuntu 26.04 x86_64.
- macOS Intel is out of scope.
- Do not recommend exposing SQLDB, SQLite3Conn, TSQLQuery, TSQLTransaction, TParam, TField, or TDataset as public XRTL.Database types.
- Do not propose network database work.
- Treat this as the closeout slice for issue #47. Suggest follow-up issues only if they should not block closing the epic.

# Output Format

Return this structure:

```markdown
# GLM XRTL.Database ORM Review

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
- Only include questions that block closing issue #47.

## Verdict
Ready for merge | Ready with small guardrails | Needs another design pass
```

# Quality Bar

Codex will judge the response by:
- Whether it protects long-term maintainability over short-term speed.
- Whether it keeps ORM mapping separate from write lifecycle, query builder expansion, and network providers.
- Whether suggestions are concrete enough to become issue comments or documentation edits.
- Whether it respects the supported platform and FPC constraints.

# Do Not

- Do not invent implemented APIs.
- Do not write Pascal implementation code.
- Do not propose network database work.
- Do not recommend broad Delphi/Lazarus compatibility goals unless the current docs support them.
- Do not include credentials, hostnames, IP addresses, or local validation secrets.
