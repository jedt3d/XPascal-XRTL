# 0006: XRTL.Core Foundation Contract

Date: 2026-06-12

## Status

Accepted.

## Context

XRTL has a shared architecture and per-library planning gate, but the first runtime foundation still needs a concrete contract before implementation begins.

Core is the first library every other XRTL library may depend on. If Core grows too much, it becomes a dependency trap. If it is too vague, later libraries will duplicate status, error, optional-value, and capability shapes.

The project also needs to protect the current working rule: design first, review, then implementation. Issue #32 provided that design gate. During review, the user requested a release-note-first FreePascal research pass before implementation so the design would not rely on stale wiki pages or source-code guessing.

The relevant compiler research found:

- The latest official stable FreePascal release remains `3.2.2`.
- FPC `3.2.4-rc1` is a 2025 fixes-branch release candidate, not a new language-major release.
- The project intentionally pins development snapshot `3.3.1`, but upstream warns that development versions and snapshots do not carry the same support or bug-free guarantees as official releases.
- Recent release-candidate feedback exposed compatibility-sensitive generic callback signature details on macOS Apple Silicon, so modern generic APIs must be validated in this repository before becoming public.

## Decision

`XRTL.Core` should start as a dependency-free foundation library that owns only the smallest shared primitives:

- Status and result shape for expected success/failure.
- Error identity with stable domain and code fields plus human-readable message.
- Presence marker and simple generic option shape for optional values.
- Simple generic value-result shape if it passes all supported-platform tests.
- Minimal capability marker shape.
- Contract version identity for the Core public surface.

The first implementation should prefer ObjFPC mode, advanced records, enums, constants, and small helper functions. Expected failures should return result/error values rather than use public exception flow.

The library is named `XRTL.Core`, but the first Pascal implementation must use conservative flat unit name `xrtl_core.pas`. Dotted Pascal unit names require a later ADR and platform validation pass.

Core v0 must not use anonymous functions, function references, record composition, nested structured error causes, IO, process execution, logging, clock/time primitives, database, HTTP, or web behavior.

Runtime implementation belongs in a follow-up issue and PR after this design PR merges.

## Consequences

- Other XRTL libraries get a shared error/result vocabulary without depending on Diagnostics, IO, Process, Data, Database, HTTP, or Web.
- Core deliberately avoids time, text, filesystem, process, data, database, HTTP, and web responsibilities.
- Generic result/option types are allowed only with direct three-platform validation evidence. If they fail on any supported target, the implementation PR must remove them or defer them.
- Chained errors and structured detail fields are deferred because ownership and memory rules need more design.
- Capability reporting gets one shared neutral shape, preventing future adapters from inventing incompatible support-report contracts.
- A follow-up implementation issue should be opened after this design merges, and it should reference this ADR as the contract.

## Links

- Issue: https://github.com/jedt3d/XPascal-XRTL/issues/32
- Design PR: https://github.com/jedt3d/XPascal-XRTL/pull/33
- Related issue: https://github.com/jedt3d/XPascal-XRTL/issues/24
- Related issue: https://github.com/jedt3d/XPascal-XRTL/issues/26
- Related docs:
  - ../xrtl/core.html
  - ../xrtl/architecture.html
  - ../xrtl/testing.html
- Research sources:
  - https://www.freepascal.org/
  - https://sourceforge.net/p/freepascal/news/2021/06/free-pascal-322-released/
  - https://lists.freepascal.org/pipermail/fpc-devel/2025-June/045993.html
  - https://lists.freepascal.org/pipermail/fpc-devel/2025-June/045994.html
  - https://www.freepascal.org/develop.var
