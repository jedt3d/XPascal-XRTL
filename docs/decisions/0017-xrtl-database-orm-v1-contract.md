# 0017: XRTL.Database ORM V1 Contract

Date: 2026-06-12

## Status

Accepted

## Context

Issue #62 defined the ORM V1 direction after the first read-only mapping primitives landed in issue #60. The next implementation issue, #64, needs a durable public contract for SQLite-only write-side ORM behavior without widening scope into network databases, upload handling, global caching, or a full Active Record framework.

## Decision

Implement ORM V1 as a small Data Mapper stack over the existing `TXrtlDatabaseConnection` provider facade.

The accepted V1 surface is:

- `TXrtlDatabaseOrmField` gains `Required` and `Writable` flags.
- `TXrtlDatabaseOrmRecord` gains typed setters and `CopyFrom`.
- `TXrtlDatabaseOrmMapper` supports `Insert`, `FindByInt64Id`, `Update`, and `DeleteByInt64Id`.
- `TXrtlDatabaseOrmSqlCache` caches deterministic generated SQL for CRUD operations.
- `TXrtlDatabaseOrmSchemaCache` caches validated schema signatures.
- `TXrtlDatabaseOrmSession` owns explicit unit-of-work boundaries and a session identity-map cache.
- `TXrtlDatabaseOrmRepository` provides a thin repository wrapper over a session and schema.
- `TXrtlDatabaseAttachmentMetadataStore` stores attachment metadata only; upload/storage bytes remain outside ORM.

SQLite through SQLDB remains the only runtime backend for this slice. PostgreSQL, MySQL/MariaDB, Firebird, network-driver setup, schema introspection, code generation, relationship loading, query-result caching, and file upload pipelines are out of scope.

## Consequences

Applications can now build simple local SQLite CRUD screens with explicit mappings, repository/session boundaries, rollback behavior, and predictable generated SQL.

The ORM remains intentionally small. It does not hide transaction boundaries, it does not use reflection or global sessions, and it does not expose SQLDB/SQLite classes in public XRTL types.

Attachment support is limited to metadata rows with owner, filename, media type, size, hash, storage URI, state, and timestamp. A future storage/upload layer can reference that metadata without making ORM responsible for file bytes.

## Links

- Issue: https://github.com/jedt3d/XPascal-XRTL/issues/64
- Related spec: ../xrtl/database-orm-v1-spec.html
- Related docs: ../xrtl/database.html
