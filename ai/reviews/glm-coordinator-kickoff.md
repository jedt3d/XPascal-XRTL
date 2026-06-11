# GLM Coordinator Kickoff Note

## Purpose
This note defines how Codex should keep GLM useful during the XPascal/XRTL bootstrap without letting GLM become an untracked source of truth. Codex coordinates implementation, verification, GitHub traceability, and final repository edits. GLM drafts and critiques documentation from packets supplied by Codex.

## Write Scope For This Kickoff
Only these files were created by this coordinator pass:
- `ai/briefs/glm-docs-captains-log-kickoff.md`
- `ai/reviews/glm-coordinator-kickoff.md`

No README, source, CI, or docs files were edited.

## Update Cadence
After each meaningful bootstrap event, Codex should send GLM a compact event packet with:
- event title
- date/time and timezone if available
- branch, PR, issue, and commit references
- platform and system configuration
- commands run
- important output or failure text
- fix or decision made
- current follow-ups

Meaningful events include:
- Windows, macOS, or Linux validation results
- FPC installer, checker, builder, or launcher script changes
- CI failures and fixes
- GitHub issue or PR workflow updates
- platform support decisions
- documentation structure decisions

## Recommended Codex Packet Template
````markdown
# Documentation Event Packet

## Metadata
- Project:
- Branch:
- PR:
- Related issue(s):
- Commit(s):
- Date/time:

## Event
- Title:
- Summary:
- Why it matters:

## System Configuration
- OS:
- CPU/architecture:
- Shell:
- FPC path/version:
- Toolchain profile:

## Commands And Results
```text
<commands and key output>
```

## Decisions
- Accepted:
- Rejected:
- Pending:

## Requested GLM Output
- Captain's Log entry:
- English developer docs fragment:
- Thai developer docs fragment:
- Questions only if blocked:
````

## Review Contract
Codex should review every GLM response before applying it:
- Accept only source-backed statements.
- Rewrite speculative language into verified facts or mark it pending.
- Keep English docs authoritative first; translate to Thai after the English version is stable.
- Preserve unsupported-platform decisions, especially that macOS Intel is intentionally unsupported.
- Record accepted, modified, and rejected GLM suggestions in `ai/reviews/`.

## Current Baseline For GLM
GLM should start from the kickoff task packet in `ai/briefs/glm-docs-captains-log-kickoff.md`.

Known validated platforms:
- Windows x86_64 with FPC 3.3.1 snapshot via `ppcrossx64.exe`.
- macOS Apple Silicon M2 / macOS 26.5.1 using `ppca64`, explicit unit path, and macOS SDK link flags.

Known validated platform:
- Linux x86_64 / Ubuntu 26.04 LTS, validated by Side Chat.
- Commit `09b76e6 Fix Linux FPC bootstrap` pinned the Linux snapshot SHA256 and changed Linux compiler selection to prefer `ppcx64` before `fpc`.

Known unsupported platform:
- macOS Intel, intentionally unsupported.

## Immediate Next GLM Task
Ask GLM for first-pass drafts of:
- Captain's Log from bootstrap planning through Windows/macOS validation.
- English HTML-oriented developer docs index.
- Thai translation draft of the same developer docs.

Codex should then review the drafts and, in a separate implementation step, decide where the human-facing generated docs will live.
