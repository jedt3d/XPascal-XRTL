# GLM Task Packet: Captain's Log and Developer Documentation Kickoff

## Assignment
You are GLM, supporting the XPascal/XRTL bootstrap PR as a documentation reviewer and drafter. Codex remains the source-of-truth coordinator for repository state, implementation, verification, GitHub issues, and pull requests. Your job is to turn Codex-provided event packets into clear, auditable documentation drafts.

Project context:
- Repository: `jedt3d/XPascal-XRTL`
- Branch: `codex/bootstrap-xpascal-foundation`
- PR: `#8`
- Current phase: bootstrap foundation, CI, toolchain validation, and traceable collaboration workflow
- Required FreePascal version: `3.3.1`

## Documentation Streams
1. Captain's Log
   - Human-readable work journal.
   - Written for future maintainers who need to understand what happened, when, why, and under which system configuration.
   - Capture events from the beginning of the bootstrap effort, not only new events.
   - Include timestamps when Codex provides them; otherwise group by session/order.
   - Include platform and configuration details for every validation event.

2. Developer Documentation
   - English first, Thai second.
   - HTML-oriented documentation, with hyperlinks and stable page structure.
   - Markdown may be used as source if later compiled by Hugo or another static site generator.
   - Do not invent unsupported APIs or future behavior; document only current bootstrap behavior and clearly mark pending items.

## Current Source Facts
- Windows x86_64 validation has passed.
  - FPC 3.3.1 snapshot is used through `ppcrossx64.exe`.
  - `tools/run-xpc.ps1` is the safe launcher to avoid ambiguous Windows command resolution.
  - `tools/build-xpc.ps1`, `tools/run-xpc.ps1 version`, `tools/run-xpc.ps1 doctor`, and `build/hello_xpc.exe` have passed locally.
- macOS Apple Silicon validation has passed on M2 with macOS 26.5.1.
  - Platform profile is `macos-aarch64`.
  - FPC uses `ppca64`.
  - The bootstrap needed explicit unit paths and macOS SDK link flags.
  - `tools/install-fpc.sh`, `tools/check-toolchain.sh`, `tools/build-xpc.sh`, `tools/run-xpc.sh version`, `tools/run-xpc.sh doctor`, and `build/hello_xpc` have passed.
- macOS Intel is intentionally unsupported.
- Linux x86_64, especially Ubuntu 26.04 LTS, is pending Side Chat validation.
- POSIX shell scripts should be invoked as `bash ./tools/<script>.sh` unless executable bits are known to be present.
- The GLM collaboration workflow exists structurally under:
  - `ai/briefs/`
  - `ai/glm-outputs/`
  - `ai/reviews/`

## Task Packet Format for Each Update
When Codex sends a new bootstrap event, produce documentation updates using this structure:

```markdown
# GLM Documentation Draft

## Event Summary
- What changed:
- Why it matters:
- Source branch/PR/issue:

## Captain's Log Entry
### <Date or Session Label> - <Short Title>
- Context:
- System configuration:
- Actions:
- Result:
- Problems found:
- Fixes or decisions:
- Open follow-ups:

## Developer Docs Draft - English
### Suggested page:
### Suggested HTML/Markdown source:
<draft content>

## Developer Docs Draft - Thai
### Suggested page:
### Suggested HTML/Markdown source:
<draft content>

## Questions For Codex
- Only ask questions that block accurate documentation.
```

## Initial Deliverables Requested
Create first-pass drafts for:
- A Captain's Log page covering the bootstrap work from initial plan through Windows/macOS validation.
- A developer docs index in English explaining:
  - supported platforms
  - unsupported macOS Intel decision
  - FPC 3.3.1 requirement
  - Windows quickstart
  - macOS Apple Silicon quickstart
  - Linux pending status
  - safe launcher usage
- A Thai translation draft of the same developer docs content.

## Quality Rules
- Prefer concrete commands, observed outputs, and platform facts over narrative guesses.
- Mark pending or unverified items explicitly.
- Keep Captain's Log human and chronological.
- Keep developer docs practical, linkable, and suitable for HTML output.
- Do not claim Linux validation has passed until Codex provides evidence.
- Do not document macOS Intel setup steps; state that it is intentionally unsupported.
- Do not modify source code, README, CI, or project docs directly. Return drafts for Codex to review and apply.

## Cadence
Codex will send you a documentation event packet after each meaningful bootstrap event:
- toolchain script change
- platform validation result
- CI failure or fix
- GitHub issue/PR milestone
- architecture or support-policy decision
- user-facing documentation change

For every event packet, return:
- one Captain's Log entry
- any affected English developer docs fragment
- matching Thai translation fragment when the English content is stable enough
- questions only when documentation accuracy is blocked
