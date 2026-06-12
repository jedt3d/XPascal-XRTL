# 0011: XRTL.Database App Dataset

Date: 2026-06-12

## Status

Accepted

## Context

Issue #52 is the next local-only Database feature slice under epic #47. After raw query mapping (#50), applications need a small cursor-style abstraction for iterating detached rows without using SQLDB or `TDataset`.

The design must keep PostgreSQL, MySQL/MariaDB, Firebird, and all network database providers out of scope. It must also keep SQLDB, SQLite3Conn, TSQLQuery, TSQLTransaction, TParam, TField, and TDataset out of the public XRTL.Database contract.

## Decision

Add `TXrtlSqliteDataSet` as an app-facing dataset abstraction over detached raw SQLite results.

The first dataset contract includes:

- active/inactive state
- record count
- field count
- current index
- `First`
- `Next`
- `Eof`
- `CurrentRow`
- `ValueByName`
- `LoadFromResultSet`
- `TXrtlSqliteDatabase.QueryDataSet`

The dataset owns a copied result snapshot. It does not hold a live SQLDB cursor, connection, transaction, query, field, or `TDataset` reference.

## Consequences

- Applications can iterate query results without depending directly on raw result-set indexing.
- The next provider abstraction slice can decide whether the public names remain SQLite-specific or gain backend-neutral aliases.
- The dataset layer stays intentionally small: no editing, posting, filtering, sorting, indexes, observers, UI binding, migrations, query builder, or ORM behavior yet.
- Error identities now include dataset state failures such as `dataset_not_active`, `no_current_row`, and `invalid_dataset`.

## Links

- Epic: https://github.com/jedt3d/XPascal-XRTL/issues/47
- Issue: https://github.com/jedt3d/XPascal-XRTL/issues/52
- Related docs:
  - ../xrtl/database.html
  - ../xrtl/testing.html
