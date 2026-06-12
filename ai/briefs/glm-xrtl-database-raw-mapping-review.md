# Task

Review the `XRTL.Database` raw mapping slice for maintainability risks before the next app dataset abstraction begins. Codex remains the source of truth and will accept, modify, or reject your suggestions before any repository change.

# Source Of Truth

Repository: `jedt3d/XPascal-XRTL`

Current phase:
- `XRTL.Database` local SQLite v0 is complete through issue #40.
- Public transactions and parameter binding are complete through issue #48.
- Active slice: issue #50, `XRTL.Database raw row and field mapping data`.
- Parent epic: issue #47, `XRTL.Database local feature stack roadmap`.

Key files to review:
- `src/xrtl/database/xrtl_database.pas`
- `tests/xrtl/database/database_raw_mapping_tests.pas`
- `docs/xrtl/database.html`
- `docs/decisions/0010-xrtl-database-raw-mapping.md`
- `docs/xrtl/testing.html`

Implemented raw mapping responsibilities:
- Detached raw query result snapshots.
- XRTL-owned value, field, row, and result-set types.
- `QueryRows` overloads with and without parameters.
- Supported value kinds: null, text, int64.
- Row, column, and field lookup helpers that return `TXrtlResult` failures for invalid lookup paths.

Non-scope:
- No app dataset abstraction yet.
- No provider abstraction beyond SQLite yet.
- No migrations.
- No query builder.
- No ORM.
- No PostgreSQL, MySQL/MariaDB, Firebird, or network database providers.

# Constraints

- FreePascal must remain version `3.3.1`.
- Supported platforms are Windows x86_64, macOS Apple Silicon aarch64, and Ubuntu 26.04 x86_64.
- macOS Intel is out of scope.
- Do not recommend exposing SQLDB, SQLite3Conn, TSQLQuery, TSQLTransaction, TParam, TField, or TDataset as public XRTL.Database types.
- Do not propose ORM, migrations, or query-builder behavior in this slice.
- Keep the next slice focused on app dataset abstraction over detached raw result sets.

# Output Format

Return this structure:

```markdown
# GLM XRTL.Database Raw Mapping Review

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
- Only include questions that block the next dataset abstraction slice.

## Verdict
Ready for merge | Ready with small guardrails | Needs another design pass
```

# Quality Bar

Codex will judge the response by:
- Whether it protects long-term maintainability over short-term speed.
- Whether it avoids duplicated contracts across future XRTL libraries.
- Whether it keeps raw mapping separate from app dataset and ORM concerns.
- Whether suggestions are concrete enough to become issue comments or documentation edits.
- Whether it respects the supported platform and FPC constraints.

# Do Not

- Do not invent implemented APIs.
- Do not write Pascal implementation code.
- Do not propose network database work.
- Do not recommend broad Delphi/Lazarus compatibility goals unless the current docs support them.
- Do not include credentials, hostnames, IP addresses, or local validation secrets.
