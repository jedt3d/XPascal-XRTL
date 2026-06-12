# 0005: XRTL Shared Architecture And Library Boundaries

Date: 2026-06-12

## Status

Accepted.

## Context

XRTL will grow into the XPascal Extended RunTime Library. The project needs a structure that can reuse good open source work without becoming a pile of unrelated wrappers or duplicated mini-frameworks.

The project is not required to mirror Delphi, Lazarus, or historical FPC library boundaries. It needs an XPascal-owned runtime architecture that is stable, testable, and clear enough for multiple agents and contributors to work safely.

## Decision

XRTL adopts a layered library plan before implementation:

- Foundation: Core and Time.
- Support: Diagnostics, Config, Collections, Text, IO, and Process.
- Data model: Data.
- Adapters: Database and HTTP.
- Application runtime: Web.

Each XRTL library must have a documentation page under `docs/xrtl/` before meaningful implementation lands. That page must describe purpose, non-purpose, dependencies, no-duplication obligations, tests, and dependency provenance gates.

Every implementation PR must check the shared ownership catalog in `docs/xrtl/architecture.html`. If a helper or concept belongs to another library, the PR should use that shared owner or open a refactor issue. Duplication across libraries requires explicit justification.

Third-party dependencies remain behind XRTL contracts unless an issue and ADR conclude that direct exposure is the correct long-term public API. Database and HTTP/Web candidates are research-only until license, maintenance, platform, and test evidence is recorded.

## Consequences

- Runtime implementation starts slower but with better long-term survival odds.
- XRTL.Database cannot leak SQLDB, Zeos, or mORMot types into public contracts without a later decision.
- XRTL.HTTP and XRTL.Web have separate responsibilities: HTTP owns transport primitives; Web owns routing and application composition.
- XRTL.Config and XRTL.Diagnostics must coordinate secret redaction and failure reporting instead of each library inventing output behavior.
- Future contributors and agents get a concrete checklist before adding runtime units.

## Links

- Issue: https://github.com/jedt3d/XPascal-XRTL/issues/26
- Related issues:
  - https://github.com/jedt3d/XPascal-XRTL/issues/24
  - https://github.com/jedt3d/XPascal-XRTL/issues/27
  - https://github.com/jedt3d/XPascal-XRTL/issues/28
- Related docs:
  - ../xrtl/architecture.html
  - ../xrtl/testing.html
  - ../dependencies.html
