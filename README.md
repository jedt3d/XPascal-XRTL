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
./tools/run-xpc.ps1 version
./tools/run-xpc.ps1 doctor
```

macOS / Ubuntu:

```bash
bash ./tools/install-fpc.sh
bash ./tools/check-toolchain.sh
bash ./tools/build-xpc.sh
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
