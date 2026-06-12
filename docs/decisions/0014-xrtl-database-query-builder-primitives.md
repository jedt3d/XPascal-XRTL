# 0014: XRTL.Database Query Builder Primitives

Date: 2026-06-12

## Status

Accepted

## Context

Issue #58 is the next local-only Database feature slice under epic #47. After migration primitives in #56, application code needs a small way to generate deterministic read queries without embedding SQL string assembly throughout higher layers. This is a prerequisite for ORM work, but it must not become an ORM itself.

The first query builder must remain provider-facade friendly, avoid raw SQL fragments, and reject unsafe identifiers. It must keep PostgreSQL, MySQL/MariaDB, Firebird, and network provider concerns out of scope.

## Decision

Add `TXrtlDatabaseSelectBuilder` with:

- Explicit table selection.
- Explicit selected columns, with `*` only as the default when no columns are added.
- Parameterized text and int64 equality filters.
- Ordered `order by` clauses with ascending/descending direction.
- Non-negative row limits.
- Deterministic SQL generation and caller-owned `TXrtlDatabaseParameters` output.

The builder is execution-neutral. Callers pass generated SQL and parameters to `TXrtlDatabaseConnection` query APIs. Identifier validation is intentionally conservative and ASCII-only for this slice.

## Consequences

- Query generation becomes testable before ORM exists.
- Public API remains independent of SQLDB internals.
- The first surface avoids raw fragments, joins, grouping, aggregates, expression trees, insert/update/delete builders, and dialect abstraction.
- ORM can build on a validated SELECT builder later instead of inventing its own SQL assembly rules.

## Links

- Epic: https://github.com/jedt3d/XPascal-XRTL/issues/47
- Issue: https://github.com/jedt3d/XPascal-XRTL/issues/58
- Related docs:
  - ../xrtl/database.html
  - ../xrtl/testing.html
