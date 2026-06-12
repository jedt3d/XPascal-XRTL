# 0013: XRTL.Database Migration Primitives

Date: 2026-06-12

## Status

Accepted

## Context

Issue #56 is the next local-only Database feature slice under epic #47. After the provider facade in #54, schema evolution should target `TXrtlDatabaseConnection` instead of the concrete SQLite wrapper. The first migration layer must be deterministic, idempotent, and small enough to validate on Windows, macOS Apple Silicon, and Ubuntu without external services.

This slice must not start query builder or ORM work. It must also keep PostgreSQL, MySQL/MariaDB, Firebird, and all network database providers out of scope.

## Decision

Add minimum migration primitives:

- `TXrtlDatabaseMigration` for explicit migration id, description, and ordered SQL statements.
- `TXrtlDatabaseMigrationPlan` for an ordered list with duplicate-id validation.
- `TXrtlDatabaseMigrationRunner` for applying a plan through `TXrtlDatabaseConnection`.
- An XRTL-owned metadata table named `xrtl_schema_migrations`.

The runner creates the metadata table when needed, skips already-applied migrations, rejects out-of-order applied migrations, and wraps each pending migration in a transaction. The first slice intentionally supports apply-only migrations; rollback/down migrations, schema diffing, external migration tools, query builder behavior, and ORM behavior are deferred.

## Consequences

- Applications can evolve local SQLite schema through an XRTL-owned contract.
- Migration bookkeeping is internal to XRTL and does not expose SQLDB, SQLite3Conn, TSQLQuery, TSQLTransaction, or dataset types.
- Query builder work can now build on stable schema setup behavior.
- The apply-only model is conservative; down migrations require a later issue once real application needs are clearer.
- Network database providers remain out of scope.

## Links

- Epic: https://github.com/jedt3d/XPascal-XRTL/issues/47
- Issue: https://github.com/jedt3d/XPascal-XRTL/issues/56
- Related docs:
  - ../xrtl/database.html
  - ../xrtl/testing.html
