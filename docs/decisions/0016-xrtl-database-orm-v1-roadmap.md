# 0016: XRTL.Database ORM V1 Roadmap

Date: 2026-06-12

## Status

Accepted

## Context

Issue #60 completed the first ORM mapping primitives: explicit schema/field mapping, a mapped record container, and read-only find-by-int64-id behavior. The project now needs a fuller ORM plan before implementation continues so that write behavior, caching, repositories, sessions, attachments, and future data-aware UI integration do not drift into unrelated mini-frameworks.

The project direction remains SQLite-only for Database V1. Network databases stay deferred. External references such as SQLModel, SQLAlchemy, and ZeosLib may inform design thinking, but XRTL must keep a clean-room implementation with clear provenance and no copied source/API text.

## Decision

Define ORM V1 as a staged Data Mapper architecture over the existing XRTL.Database stack:

- Keep SQLDB/SQLite behind the existing provider facade.
- Use explicit schema and field mappings before reflection, attributes, code generation, or schema introspection.
- Add CRUD mapper behavior before repository/session abstractions.
- Add repositories as thin application-facing persistence classes.
- Add an explicit Session / Unit of Work boundary for transaction lifecycle, pending changes, and identity-map caching.
- Add 80/20 caching first: immutable schema cache, deterministic generated SQL cache, and session-scoped identity map.
- Treat file attachments as a separate storage/upload concern. ORM may map attachment metadata and relationships, but it must not own upload transport, raw file bytes, or byte caching.
- Keep global query result caching, automatic lazy loading, network provider support, and broad relationship magic out of V1.

## Consequences

- ORM can become complete enough for local SQLite CRUD screens without forcing the project into a large framework clone.
- The first caching work is useful and low-risk because cache ownership and invalidation are explicit.
- Attachment support can be designed early without contaminating ORM with storage responsibilities.
- Future XRTL.Data, MVVM, and UI work will have a cleaner persistence boundary.
- Later issues must create child slices for CRUD mapper, repositories, session/identity map, ORM migrations, attachment metadata, validation/hooks, and DataSource bridge planning.

## Links

- Issue: https://github.com/jedt3d/XPascal-XRTL/issues/62
- Related issues:
  - https://github.com/jedt3d/XPascal-XRTL/issues/47
  - https://github.com/jedt3d/XPascal-XRTL/issues/60
  - https://github.com/jedt3d/XPascal-XRTL/issues/64
- Related docs:
  - ../xrtl/database.html
  - ../xrtl/database-orm-v1-spec.html
  - ../dependencies.html
