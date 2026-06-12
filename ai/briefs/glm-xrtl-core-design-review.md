# Task

Review the proposed `XRTL.Core` foundation contract for XPascal/XRTL. Codex remains the source of truth and will accept, modify, or reject your suggestions before any repository change.

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
# GLM XRTL.Core Review

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
Ready as proposed | Ready with small edits | Needs another design pass
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
