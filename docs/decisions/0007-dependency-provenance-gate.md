# 0007: Dependency Provenance Gate

Date: 2026-06-12

## Status

Accepted.

## Context

XRTL will need database, HTTP, web, and support libraries. Some capabilities should come from active open source projects rather than being rebuilt. At the same time, adopting libraries too quickly can leak upstream APIs into XPascal contracts, create licensing surprises, or make future replacement difficult.

Issue #27 exists to make dependency evaluation auditable before issue #28 performs deeper database and web server research.

## Decision

The project adopts `docs/dependencies.html` as the dependency provenance register.

Before any third-party source is copied, vendored, linked, wrapped, or exposed through public XRTL APIs, the dependency must have a provenance record that includes:

- canonical upstream source
- exact source, release, tag, or artifact under consideration
- license file links and license verification state
- attribution, NOTICE, redistribution, and modification obligations
- activity and maintenance signal
- supported-platform evidence
- feature fit and missing capabilities
- security or supply-chain risks
- decision status
- wrap/direct-use rationale
- linked issue and ADR when public API or architecture is affected

Dependency status values are:

- `candidate`
- `research-only`
- `prototype-approved`
- `adopted`
- `wrapped`
- `inspiration-only`
- `rejected`

Database and HTTP/Web candidates remain `candidate` or `research-only` until issue #28 records source-backed recommendations. XRTL.Core remains dependency-free.

## Consequences

- Issue #27 can close with a durable register and gate, without prematurely deciding issue #28.
- Future library PRs have a consistent provenance checklist.
- Third-party APIs stay behind XRTL contracts unless a later issue and ADR explicitly choose direct exposure.
- Dependency adoption is slower, but the project avoids accidental license, attribution, platform, or API lock-in.
- Candidate research can proceed in #28 using the register's status model and record template.

## Links

- Issue: https://github.com/jedt3d/XPascal-XRTL/issues/27
- Related issues:
  - https://github.com/jedt3d/XPascal-XRTL/issues/24
  - https://github.com/jedt3d/XPascal-XRTL/issues/28
- Related docs:
  - ../dependencies.html
  - ../xrtl/architecture.html
  - ../xrtl/testing.html
