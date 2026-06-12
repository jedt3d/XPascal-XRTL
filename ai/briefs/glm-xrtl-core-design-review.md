# Task

Review the accepted `XRTL.Core` foundation contract for XPascal/XRTL before runtime implementation begins. Codex remains the source of truth and will accept, modify, or reject your suggestions before any repository change.

# Source Of Truth

Repository: `jedt3d/XPascal-XRTL`

Current phase:
- `xpc build` is complete through issue #22 / PR #23.
- XCLI project creation is complete through issue #25 / PR #31.
- XRTL architecture planning is complete through issue #26 / PR #30.
- Active design issue: #32, `Design XRTL.Core foundation contract`.

Key files to review:
- `docs/xrtl/architecture.html`
- `docs/xrtl/testing.html`
- `docs/xrtl/core.html`
- `docs/decisions/0005-xrtl-shared-architecture.md`
- `docs/decisions/0006-xrtl-core-contract.md`

Proposed `XRTL.Core` responsibilities:
- Status/result shape.
- Error identity with domain, code, and message.
- Optional presence marker.
- Capability marker shape if review agrees it is needed early.
- Core contract version identity.

Proposed non-responsibilities:
- No logging or diagnostic output.
- No clocks, durations, or timeouts.
- No text encoding or formatting policy.
- No filesystem, process execution, OS/CPU detection, database, HTTP, or web behavior.
- No runtime implementation before design review.

Release-note-first compiler research:
- Official stable FreePascal is still `3.2.2`.
- FPC `3.2.4-rc1` is a 2025 fixes-branch release candidate with bug fixes, glibc/Darwin debug improvements, and no intentional broad compatibility break claimed in the announcement.
- The project intentionally pins FPC `3.3.1`, but upstream treats `3.3.x` as development/snapshot and warns there is no support guarantee for development versions.
- macOS Apple Silicon compatibility feedback in the 3.2.4-rc1 thread exposed generic callback signature sensitivity, so generic Core APIs must be accepted only with direct supported-platform validation.

Resolved Core v0 choices after review:
- Use flat unit name `xrtl_core` first; dotted unit names require a later ADR.
- Use advanced records for small value-like primitives.
- Allow simple generic option/value-result records only if they compile and run on Windows x86_64, macOS Apple Silicon aarch64, and Ubuntu 26.04 x86_64.
- Include a minimal neutral capability marker.
- Defer structured error detail, nested causes, anonymous functions, and function references.

# Constraints

- FreePascal must remain version `3.3.1`.
- Supported platforms are Windows x86_64, macOS Apple Silicon aarch64, and Ubuntu 26.04 x86_64.
- macOS Intel is out of scope.
- Do not assume Delphi/Lazarus compatibility is a requirement.
- Do not recommend exposing third-party library APIs from Core.
- Keep Core small enough that every XRTL library can safely depend on it.
- Avoid duplicated primitives across future libraries.
- Treat runtime implementation as blocked until design review completes.

# Output Format

Return this structure:

```markdown
# GLM XRTL.Core Implementation-Risk Review

## Strong Agreements
- ...

## Design Risks
- Risk:
  Impact:
  Suggested change:

## API Surface Suggestions
- Keep:
- Change:
- Defer:

## Test Strategy Suggestions
- ...

## Questions For Codex
- Only include questions that block the design from being accepted.

## Verdict
Ready for implementation | Ready with small implementation guardrails | Needs another design pass
```

# Quality Bar

Codex will judge the response by:
- Whether it protects long-term maintainability over short-term speed.
- Whether it prevents duplicated contracts across XRTL libraries.
- Whether it keeps `XRTL.Core` small and dependency-free.
- Whether suggestions are concrete enough to become issue comments or documentation edits.
- Whether it respects the supported platform and FPC constraints.

# Do Not

- Do not invent implemented APIs.
- Do not write Pascal implementation code.
- Do not propose Database, HTTP, Web, or IO APIs inside Core.
- Do not recommend broad framework compatibility goals unless the current docs support them.
- Do not include credentials, hostnames, IP addresses, or local validation secrets.
