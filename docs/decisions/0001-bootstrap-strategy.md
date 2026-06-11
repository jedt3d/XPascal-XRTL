# 0001 Bootstrap Strategy

## Status

Accepted

## Context

XPascal/XRTL is starting from a nearly empty repository. The first useful slice must create a reliable foundation before implementing platform features such as XUI, X.Data, XServer, or XDesktop.

The project requires FreePascal `3.3.1`, even though that is a development snapshot line. The initial target platforms are Windows, macOS, and Ubuntu 26.04 LTS.

## Decision

Bootstrap the repository with:

- pinned FPC 3.3.1 toolchain metadata
- install/check scripts for Windows, macOS, and Linux
- a minimal `xpc` CLI with `version` and `doctor`
- Windows-first CI
- manual validation scripts for macOS and Ubuntu 26.04
- GitHub issue and draft PR traceability
- file-based Codex + GLM collaboration records

The first implementation branch must not attempt the full platform. XUI, X.Data, XServer, and XDesktop will be designed and implemented in later issues.

## Consequences

- The first PR is intentionally infrastructure-heavy.
- FPC snapshot URLs and checksums are explicit and reviewable.
- Platform behavior is not considered real until it is covered by `xpc doctor`, build checks, and smoke tests.
