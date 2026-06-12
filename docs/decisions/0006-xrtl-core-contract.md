# 0006: XRTL.Core Foundation Contract

Date: 2026-06-12

## Status

Proposed.

## Context

XRTL has a shared architecture and per-library planning gate, but the first runtime foundation still needs a concrete contract before implementation begins.

Core is the first library every other XRTL library may depend on. If Core grows too much, it becomes a dependency trap. If it is too vague, later libraries will duplicate status, error, optional-value, and capability shapes.

The project also needs to protect the current working rule: design first, review, then implementation. This ADR is therefore proposed, not accepted, until the design PR is reviewed.

## Decision

`XRTL.Core` should start as a dependency-free foundation library that owns only the smallest shared primitives:

- Status and result shape for expected success/failure.
- Error identity with stable domain and code fields plus human-readable message.
- Presence marker for optional values.
- Capability marker shape only if review agrees it is needed in the first implementation.
- Contract version identity for the Core public surface.

The first implementation should prefer plain records, enums, constants, and small helper functions. Expected failures should return result/error values rather than use public exception flow.

The library is named `XRTL.Core`, but the first Pascal implementation should use conservative flat unit names such as `xrtl_core.pas` unless the implementation PR validates dotted unit behavior with FreePascal `3.3.1` on all supported platforms.

Runtime implementation is blocked until issue #32 and the design PR are reviewed.

## Consequences

- Other XRTL libraries get a shared error/result vocabulary without depending on Diagnostics, IO, Process, Data, Database, HTTP, or Web.
- Core deliberately avoids time, text, filesystem, process, data, database, HTTP, and web responsibilities.
- Generic result/option types are deferred unless review accepts them or a later implementation issue proves the need.
- Chained errors and structured detail fields are deferred because ownership and memory rules need more design.
- A follow-up implementation issue should be opened only after this design is accepted.

## Links

- Issue: https://github.com/jedt3d/XPascal-XRTL/issues/32
- Related issue: https://github.com/jedt3d/XPascal-XRTL/issues/24
- Related issue: https://github.com/jedt3d/XPascal-XRTL/issues/26
- Related docs:
  - ../xrtl/core.html
  - ../xrtl/architecture.html
  - ../xrtl/testing.html
