# 0015: XRTL.Database ORM Mapping Primitives

Date: 2026-06-12

## Status

Accepted

## Context

Issue #60 is the final local-only Database feature-stack slice under epic #47. The lower layers now exist: provider facade, transactions, parameters, raw mapping, app dataset, migrations, and SELECT query builder primitives. The ORM layer should prove row-to-record mapping without becoming a full persistence framework.

This slice must keep the project future-proof by avoiding magic, code generation, relationships, lazy loading, dirty tracking, and write lifecycle behavior until real application needs justify them.

## Decision

Add minimum ORM mapping primitives:

- `TXrtlDatabaseOrmField` for application field name to database column mapping.
- `TXrtlDatabaseOrmSchema` for explicit table, int64 id column, and mapped fields.
- `TXrtlDatabaseOrmRecord` for XRTL-owned mapped values.
- `TXrtlDatabaseOrmMapper.FindByInt64Id` for read-oriented mapping through `TXrtlDatabaseConnection` and `TXrtlDatabaseSelectBuilder`.

The mapper does not create a new SQL execution path. It builds a SELECT query, executes it through the provider facade, and maps detached raw values into the record container.

## Consequences

- The local Database feature stack now has a minimal ORM foundation without committing to a full active-record or data-mapper framework.
- Public API remains independent of SQLDB internals.
- Insert/update/delete, relationships, identity maps, lazy loading, dirty tracking, schema introspection, and code generation remain deferred.
- Network database providers remain out of scope.

## Links

- Epic: https://github.com/jedt3d/XPascal-XRTL/issues/47
- Issue: https://github.com/jedt3d/XPascal-XRTL/issues/60
- Related docs:
  - ../xrtl/database.html
  - ../xrtl/testing.html
