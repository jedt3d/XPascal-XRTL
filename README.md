# XPascal / XRTL Platform

XPascal is a modern FreePascal-powered application platform for desktop, web, and server development.

The project starts with a CLI-first foundation, pinned FreePascal tooling, CI/CD traceability, and an auditable Codex + GLM collaboration workflow. The long-term direction is documented in [docs/proposal.md](docs/proposal.md).

Bootstrap PR #8 has merged into `main`. Current foundation work now includes the CLI skeleton, project creation, `xpc build`, `XRTL.Core` v0, and the first `XRTL.Database` local SQLite slice. Start every non-trivial follow-up from a GitHub issue, keep the work traceable through a branch/PR, and compare the result back to the issue acceptance criteria before closing it.

## First Slice

The current foundation focuses on:

- FreePascal 3.3.1 toolchain checks
- `xpc` CLI skeleton
- `xpc build` and `xpc new <project_name>`
- `XRTL.Core` v0 result/error/option primitives
- `XRTL.Database` v0 local SQLite smoke over FPC SQLDB
- `XRTL.Database` public transactions and parameter binding for local SQLite
- `XRTL.Database` detached raw row/field/value mapping for local SQLite
- `XRTL.Database` app dataset iteration over detached SQLite rows
- `XRTL.Database` SQLite-only provider abstraction facade
- `XRTL.Database` apply-only migration primitives over the provider facade
- `XRTL.Database` SELECT query builder primitives
- Windows-first CI
- manual validation scripts for Windows, macOS, and Ubuntu 26.04 LTS
- GitHub issue, branch, and draft PR workflow
- file-based Codex + GLM review records

Validated so far:

- Windows x86_64
- macOS Apple Silicon aarch64
- Linux x86_64 / Ubuntu 26.04 LTS

Checksum status:

- Windows, macOS Apple Silicon, and Linux FPC 3.3.1 snapshot SHA256 values are pinned in `toolchains/fpc-3.3.1.lock`.

## Requirements

- Git
- FreePascal 3.3.1
- SQLite native runtime for `XRTL.Database` tests:
  - Windows: `sqlite3.dll` on `PATH`
  - macOS: `libsqlite3.dylib`
  - Ubuntu: `sudo apt-get install libsqlite3-dev`
- PowerShell 7+ on Windows, or POSIX shell on macOS/Linux

GitHub CLI is useful for local publishing workflows, but issue and pull request creation can also use the GitHub connector.

## Bootstrap Commands

Windows:

```powershell
./tools/install-fpc.ps1
./tools/check-toolchain.ps1
./tools/run-xpc.ps1 build
./tools/run-xpc.ps1 version
./tools/run-xpc.ps1 doctor
./tools/run-xpc.ps1 new sample_app
./tools/run-xpc.ps1 build sample_app
```

macOS / Ubuntu:

```bash
bash ./tools/install-fpc.sh
bash ./tools/check-toolchain.sh
bash ./tools/run-xpc.sh build
bash ./tools/run-xpc.sh version
bash ./tools/run-xpc.sh doctor
bash ./tools/run-xpc.sh new sample_app
bash ./tools/run-xpc.sh build sample_app
```

If your checkout preserved executable bits, you can also run the shell scripts directly as `./tools/*.sh`. If not, either keep using `bash ./tools/<script>.sh` or run:

```bash
chmod +x ./tools/*.sh
```

## Platform Profiles

## XCLI Project Creation

After building the bootstrap CLI, create a minimal project with:

```bash
# Windows
./tools/run-xpc.ps1 build
./tools/run-xpc.ps1 new sample_app
./tools/run-xpc.ps1 build sample_app

# macOS / Ubuntu
bash ./tools/run-xpc.sh build
bash ./tools/run-xpc.sh new sample_app
bash ./tools/run-xpc.sh build sample_app
```

The generated project contains `xproject.toml`, `src/main.pas`, and `README.md`.

The bootstrap scripts detect and isolate toolchains by platform:

| Platform | Script profile | Status |
| --- | --- | --- |
| Windows x86_64 | `windows-x86_64` | Supported by `tools/*.ps1` |
| macOS Apple Silicon M1/M2/M3/M4 | `macos-aarch64` | Supported by `tools/*.sh` |
| Linux x86_64 / Ubuntu 26.04 | `linux-x86_64` | Supported by `tools/*.sh` |

macOS Intel x86_64 is intentionally not supported.

After `install-fpc.sh` runs, it writes `.toolchains/current.env`. The check, build, and run scripts read this file so `FPC_BIN` does not need to be exported manually between commands.

For Apple Silicon Macs, the selected compiler should be the aarch64 Darwin compiler, usually named `ppca64` inside the snapshot. If the script says that compiler cannot be executed, run:

```bash
uname -m
find .toolchains/fpc-3.3.1/macos-aarch64 -name ppca64 -exec file {} \;
```

and paste the output into the PR or issue.

## Collaboration Records

Codex and GLM collaboration artifacts live under:

- `ai/briefs/`
- `ai/glm-outputs/`
- `ai/reviews/`

Use [ai/briefs/README.md](ai/briefs/README.md) for task packet rules.

## Human Documentation

Project documentation starts as static HTML:

- [Documentation Home](docs/index.html)
- [Captain's Log](docs/captains-log/index.html)
- [Agent Harness](docs/agent-harness.html)
- [Roadmap Gantt](docs/roadmap.html)
- [Product Requirements](docs/prd.html)
- [Architecture Decisions](docs/adr.html)
- [XRTL Library Docs](docs/xrtl/index.html)
- [XRTL Shared Architecture](docs/xrtl/architecture.html)
- [XRTL Test Strategy](docs/xrtl/testing.html)
- [Dependency Provenance](docs/dependencies.html)
- [Issue Map](docs/issues/index.html)
- [Developer Docs EN](docs/en/index.html)
- [Developer Docs TH](docs/th/index.html)

The long-term docs pipeline may move to Hugo or another static-site generator, but checked-in HTML keeps early links reviewable immediately.
