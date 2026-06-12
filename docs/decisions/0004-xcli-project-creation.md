# 0004: XCLI Project Creation

Date: 2026-06-12

## Status

Accepted.

## Context

After `xpc build`, the next phase is XCLI project creation before XRTL library work expands. The project needs a minimal generated structure that is plain text, buildable, and easy for humans and agents to inspect.

## Decision

XCLI starts with `xpc new <project_name>`.

The command creates a project directory with:

- `xproject.toml`
- `src/main.pas`
- `README.md`

Project names must start with a letter or underscore and contain only letters, numbers, and underscores. This keeps the generated Pascal program name valid without adding a naming translation layer.

During this phase, generated projects build through the launcher path:

- Windows: `tools/run-xpc.ps1 build <project_dir>`
- macOS Apple Silicon and Ubuntu: `bash ./tools/run-xpc.sh build <project_dir>`

## Consequences

- XCLI has a concrete project scaffold before XRTL implementation begins.
- `xproject.toml` is introduced as the project marker, but remains intentionally minimal.
- Build orchestration still lives in scripts until the Pascal CLI owns process execution and project-file parsing.

## Links

- Issue: https://github.com/jedt3d/XPascal-XRTL/issues/25
