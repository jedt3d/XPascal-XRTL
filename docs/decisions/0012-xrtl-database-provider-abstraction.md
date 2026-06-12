# 0012: XRTL.Database SQLite Provider Abstraction

Date: 2026-06-12

## Status

Accepted

## Context

Issue #54 is the next local-only Database feature slice under epic #47. After app dataset iteration (#52), migrations should not be built directly against only `TXrtlSqliteDatabase`; the project needs a small provider abstraction that can keep application code pointed at an XRTL-owned connection facade while SQLite remains the only concrete backend.

The design must keep PostgreSQL, MySQL/MariaDB, Firebird, and all network database providers out of scope. It must also avoid duplicating SQLDB execution behavior already implemented in the SQLite backend.

## Decision

Add a small provider abstraction layer:

- `TXrtlDatabaseProviderKind`.
- `TXrtlDatabaseProviderCapabilities`.
- `TXrtlDatabaseConnectionConfig`.
- Provider-neutral aliases for value, field, row, result-set, parameter, and dataset types.
- `TXrtlDatabaseConnection`.

`TXrtlDatabaseConnection` delegates to `TXrtlSqliteDatabase`. SQLite is the only provider kind in this slice. Capability metadata records that the current provider is local-only and supports transactions, parameters, raw results, and datasets.

## Consequences

- Applications can begin using a provider-neutral connection facade while SQLite remains the only backend.
- The implementation avoids a second SQL execution path.
- Migrations can target the facade next, instead of depending directly on the concrete SQLite wrapper.
- The abstraction intentionally does not add non-SQLite providers, service credentials, client libraries, connection pooling, migrations, query builder, or ORM behavior.

## Links

- Epic: https://github.com/jedt3d/XPascal-XRTL/issues/47
- Issue: https://github.com/jedt3d/XPascal-XRTL/issues/54
- Related docs:
  - ../xrtl/database.html
  - ../xrtl/testing.html
