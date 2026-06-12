# 0010: XRTL.Database Raw Mapping Data

Date: 2026-06-12

## Status

Accepted

## Context

Issue #50 is the next local-only Database feature slice under epic #47. After SQLite v0 (#40) and public transactions plus parameter binding (#48), callers need a way to read multi-column, multi-row query results without depending on SQLDB cursor or dataset types.

The design must keep PostgreSQL, MySQL/MariaDB, Firebird, and all network database providers out of scope. It must also keep SQLDB, SQLite3Conn, TSQLQuery, TSQLTransaction, TParam, TField, and TDataset out of the public XRTL.Database contract.

## Decision

Add detached XRTL-owned raw mapping types:

- `TXrtlSqliteValueKind`.
- `TXrtlSqliteValue`.
- `TXrtlSqliteField`.
- `TXrtlSqliteRow`.
- `TXrtlSqliteResultSet`.
- `TXrtlSqliteDatabase.QueryRows`.

`QueryRows` fills a caller-owned result set and copies all returned values before the SQLDB query object is closed and freed. The first value kinds are null, text, and int64. Result-set and row lookup helpers report missing rows, columns, or fields through `TXrtlResult` error codes instead of requiring callers to catch SQLDB exceptions.

## Consequences

- Applications can read raw SQLite query results without exposing SQLDB, TField, or TDataset.
- The next app dataset abstraction can be built over an XRTL-owned row/value snapshot instead of a live database cursor.
- The mapping intentionally stays small: no decimal, date/time, blob, stream, or typed dataset behavior yet.
- Migration, query builder, and ORM layers remain later slices under issue #47.

## Links

- Epic: https://github.com/jedt3d/XPascal-XRTL/issues/47
- Issue: https://github.com/jedt3d/XPascal-XRTL/issues/50
- Related docs:
  - ../xrtl/database.html
  - ../xrtl/testing.html
