# 0008: XRTL.Database SQLite V0 Contract

Date: 2026-06-12

## Status

Accepted

## Context

Issue #40 is the first `XRTL.Database` implementation slice. The user explicitly narrowed scope to local database support only: SQLite through FPC SQLDB. PostgreSQL, MySQL/MariaDB, Firebird, ZeosLib, mORMot, ORM behavior, and service credentials are out of scope for this slice.

The project also wants XRTL public APIs to survive future provider changes. Directly exposing SQLDB, SQLite3Conn, `TDataset`, or SQLDB transaction classes in the public contract would make later provider changes expensive.

## Decision

Add `src/xrtl/database/xrtl_database.pas` as the first Database runtime unit.

The v0 contract provides:

- `TXrtlSqliteConnectionConfig` for file and in-memory SQLite database targets.
- `TXrtlSqliteDatabase` for opening and closing a SQLite database through SQLDB.
- `Execute` for simple SQL statements.
- `QueryInt64` for the first scalar query shape needed by smoke tests.
- `TXrtlResult` and `TXrtlError` from `XRTL.Core` for all public operation results.

The public interface does not expose SQLDB or SQLite3Conn types. SQLDB remains an implementation detail behind XRTL-owned types.

## Consequences

- `XRTL.Database` v0 can prove local SQLite creation and query behavior without network services.
- Build scripts now compile and run Database tests alongside Core tests.
- The Windows PowerShell build adds the FPC package unit paths needed for FCL DB units from the pinned toolchain.
- SQLite native runtime availability remains a platform packaging concern; the v0 tests prove the current validation environment can create and query a local SQLite file.
- Network database work requires later issues with service setup, native client libraries, and credentials outside tracked docs.
- Any future provider adoption still needs dependency provenance review.

## Links

- Issue: https://github.com/jedt3d/XPascal-XRTL/issues/40
- Related docs:
  - ../xrtl/database.html
  - ../xrtl/testing.html
  - ../dependencies.html
