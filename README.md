# XPascal / XRTL Platform

XPascal is a modern FreePascal-powered application platform for desktop, web, and server development.

The project starts with a CLI-first foundation, pinned FreePascal tooling, CI/CD traceability, and an auditable Codex + GLM collaboration workflow. The long-term direction is documented in [docs/proposal.md](docs/proposal.md).

## First Slice

The current bootstrap focuses on:

- FreePascal 3.3.1 toolchain checks
- `xpc` CLI skeleton
- Windows-first CI
- manual validation scripts for Windows, macOS, and Ubuntu 26.04 LTS
- GitHub issue, branch, and draft PR workflow
- file-based Codex + GLM review records

## Requirements

- Git
- FreePascal 3.3.1
- PowerShell 7+ on Windows, or POSIX shell on macOS/Linux

GitHub CLI is useful for local publishing workflows, but issue and pull request creation can also use the GitHub connector.

## Bootstrap Commands

Windows:

```powershell
./tools/install-fpc.ps1
./tools/check-toolchain.ps1
./tools/build-xpc.ps1
./build/xpc.exe version
./build/xpc.exe doctor
```

macOS / Ubuntu:

```bash
./tools/install-fpc.sh
./tools/check-toolchain.sh
./tools/build-xpc.sh
./build/xpc version
./build/xpc doctor
```

## Collaboration Records

Codex and GLM collaboration artifacts live under:

- `ai/briefs/`
- `ai/glm-outputs/`
- `ai/reviews/`

Use [ai/briefs/README.md](ai/briefs/README.md) for task packet rules.
