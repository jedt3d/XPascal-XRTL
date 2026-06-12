# 0009: XRTL.Database Transactions And Parameters

Date: 2026-06-12

## Status

Accepted

## Context

Issue #48 is the first implementation slice under the local-only Database feature-stack epic (#47). The project needs explicit transaction control and parameter binding before row mapping, datasets, migrations, query builders, or ORM behavior can be designed safely.

The implementation must keep PostgreSQL, MySQL/MariaDB, Firebird, and all network database providers out of scope. It must also keep SQLDB, SQLite3Conn, TSQLQuery, TSQLTransaction, TParam, and TDataset out of the public XRTL.Database contract.

## Decision

Extend `xrtl_database` with XRTL-owned public types and methods:

- `TXrtlSqliteParameterKind`.
- `TXrtlSqliteParameter`.
- `TXrtlSqliteParameters`.
- `TXrtlSqliteDatabase.BeginTransaction`.
- `TXrtlSqliteDatabase.Commit`.
- `TXrtlSqliteDatabase.Rollback`.
- `TXrtlSqliteDatabase.InTransaction`.
- Parameterized overloads for `Execute` and `QueryInt64`.

Implicit transactions remain the default for single-statement `Execute` and `QueryInt64` calls. Explicit transactions keep the SQLDB transaction open until the caller commits or rolls back.

## Consequences

- Applications can safely bind text, int64, and null values without string-concatenating SQL values.
- Tests can prove commit and rollback behavior before any dataset/query-builder/ORM layer exists.
- SQLDB remains an implementation detail.
- Error identities now include transaction and binding failures such as `transaction_active`, `no_transaction`, `invalid_parameter`, and `bind_failed`.
- Raw row mapping, app datasets, migrations, query builder, and ORM remain follow-up slices under issue #47.

## Links

- Epic: https://github.com/jedt3d/XPascal-XRTL/issues/47
- Issue: https://github.com/jedt3d/XPascal-XRTL/issues/48
- Related docs:
  - ../xrtl/database.html
  - ../xrtl/testing.html
