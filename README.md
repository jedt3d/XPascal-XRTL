# XPascal / XRTL Platform

XPascal is a modern FreePascal-powered application platform for desktop, web, and server development.

The project starts with a CLI-first foundation, pinned FreePascal tooling, CI/CD traceability, and an auditable Codex + GLM collaboration workflow. The long-term direction is documented in [docs/proposal.md](docs/proposal.md).

Bootstrap PR #8 has merged into `main`. Start every non-trivial follow-up from a GitHub issue, keep the work traceable through a branch/PR, and compare the result back to the issue acceptance criteria before closing it.

## First Slice

The current bootstrap focuses on:

- FreePascal 3.3.1 toolchain checks
- `xpc` CLI skeleton
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
```

macOS / Ubuntu:

```bash
bash ./tools/install-fpc.sh
bash ./tools/check-toolchain.sh
bash ./tools/run-xpc.sh build
bash ./tools/run-xpc.sh version
bash ./tools/run-xpc.sh doctor
```

If your checkout preserved executable bits, you can also run the shell scripts directly as `./tools/*.sh`. If not, either keep using `bash ./tools/<script>.sh` or run:

```bash
chmod +x ./tools/*.sh
```

## Platform Profiles

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
