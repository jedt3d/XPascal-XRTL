# 0002: Initial Supported Platforms

Date: 2026-06-12

## Status

Accepted.

## Context

Bootstrap validation is focused on three first-class targets:

- Windows x86_64
- macOS Apple Silicon aarch64
- Ubuntu 26.04 x86_64

The project previously hit a macOS compiler selection problem where Apple Silicon needed the `ppca64` compiler directly. That made the CPU architecture distinction operationally important for scripts, documentation, and manual validation.

## Decision

The initial platform set is Windows x86_64, macOS Apple Silicon aarch64, and Ubuntu 26.04 x86_64.

macOS Intel x86_64 is not supported in the bootstrap phase.

## Consequences

- Installer and validation scripts should prefer explicit platform identifiers instead of treating all macOS hosts as equivalent.
- Documentation and issue acceptance criteria should say "macOS Apple Silicon" when referring to the supported macOS target.
- Future macOS Intel support requires a new issue, validation plan, toolchain lock update, and decision record update.
