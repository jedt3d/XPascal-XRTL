# 0003: CLI v0 Build Command

Date: 2026-06-12

## Status

Accepted.

## Context

The bootstrap project already had platform-specific build scripts. CLI v0 needs `xpc` to become the public entrypoint without duplicating platform-specific compiler logic inside the Pascal binary too early.

macOS Apple Silicon requires SDK linker flags, and all platforms must verify FreePascal `3.3.1` before building.

## Decision

`xpc build` is the first CLI v0 command after `version` and `doctor`.

During bootstrap CLI v0, the supported public path is through the platform launcher:

- Windows: `tools/run-xpc.ps1 build`
- macOS Apple Silicon and Ubuntu: `bash ./tools/run-xpc.sh build`

The launchers delegate to the existing build scripts, which remain responsible for platform-specific compiler flags and smoke executable output. The Pascal CLI recognizes `build` and fails loudly with a launcher hint when run directly.

## Consequences

- Users get a stable `xpc build` command shape before the Pascal CLI owns in-process build orchestration.
- Existing platform-specific build knowledge remains in scripts for now.
- A later ADR can move build orchestration into Pascal after the project defines project files, target selection, and process execution policy.

## Links

- Issue: https://github.com/jedt3d/XPascal-XRTL/issues/22
