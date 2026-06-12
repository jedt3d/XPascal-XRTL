# Agent Instructions

## Project Priorities

- Keep the project CLI-first and CI/CD-first.
- Preserve plain-text, reviewable source artifacts.
- Prefer small, traceable branches linked to GitHub issues.
- Keep FreePascal pinned to version `3.3.1` until a decision record changes it.
- Treat Windows, macOS, and Ubuntu 26.04 LTS as first-class bootstrap targets.

## Source Of Truth

- Product direction: `docs/proposal.md`
- Product requirements: `docs/prd.html`
- Architecture decisions: `docs/decisions/`
- ADR guide: `docs/adr.html`
- XRTL library documentation: `docs/xrtl/`
- Dependency provenance and licensing: `docs/dependencies.html`
- Toolchain lock: `toolchains/fpc-3.3.1.lock`
- Agent harness: `docs/agent-harness.html`
- Codex + GLM task packets and reviews: `ai/`
- Local-only validation host credentials: `.secrets/validation-hosts.local.md` when present. This path is ignored by Git and must never be committed.

## Workflow

1. Start from a GitHub issue. No issue, no non-trivial work.
2. Use a feature branch named `codex/<short-description>`.
3. Keep changes scoped to the issue.
4. Run the relevant toolchain, build, and smoke checks.
5. On macOS/Linux, prefer `bash ./tools/<script>.sh` unless executable bits are known to be preserved.
6. Open a draft PR until validation is complete.
7. Before marking a PR ready, compare the work back against the linked issue acceptance criteria and validation plan.
8. Record GLM suggestions and Codex review decisions when GLM contributes.
9. Revisit this file whenever an issue is closed or project status changes, and update the project progress notes below.
10. Update the PRD when product scope, user workflow, public CLI behavior, platform support, or milestone priority changes.
11. Create or update ADRs when architecture, toolchain policy, runtime API shape, supported platforms, or repository governance changes.
12. For XRTL work, create or update the per-library documentation file in `docs/xrtl/` in the same PR as the library.
13. Before adopting or wrapping third-party code, update `docs/dependencies.html` with license, activity, attribution, and wrap/direct-use rationale.
14. Before implementing or extending an XRTL library, check `docs/xrtl/architecture.html` and the target library page for ownership boundaries, shared helpers, and no-duplication rules.
15. If a proposed helper, type, config policy, diagnostic shape, path/process helper, data contract, or HTTP/Web concept belongs to another XRTL library, use that shared owner or open a refactor issue before adding duplicate code.

## Project Progress

- Keep this section current as issues close, PRs merge, or platform validation status changes.
- Summarize completed issue ranges, merged PRs, active validation work, and explicit out-of-scope decisions.
- Do not include credentials, host passwords, IP secrets, or local-only `.secrets` contents.
- Current bootstrap status: issues `#1`-`#7` merged via PR `#8`; post-merge workflow `#11` via PR `#12`; FPC `3.3.1` checksum finalization `#9` via PR `#13`; agent harness refresh `#14` via PR `#15`; Linux validation captured in `#10`; roadmap `#16` via PR `#17`; PRD/ADR cadence `#18` via PR `#19`; status closeout `#20` via PR `#21`; CLI v0 build command `#22` via PR `#23`; XCLI project creation `#25` via PR `#31`; XRTL library architecture `#26` via PR `#30`; XRTL.Core design `#32` via PR `#33`; XCLI/XRTL epic `#24` remains open with child issues `#27`, `#28`, and `#34`.
- Current active implementation slice: issue `#34` implements `XRTL.Core` v0 primitives and tests from accepted ADR `0006`.
- Latest completed implementation slice: issue `#25` adds XCLI project creation through `xpc new <project_name>` and generated project build support.
- XRTL governance gate: PR `#30` defined XRTL shared architecture, per-library docs, test strategy, and no-duplication rules before meaningful XRTL runtime implementation.
- Target platforms remain Windows x86_64, macOS Apple Silicon aarch64, and Ubuntu 26.04 x86_64. macOS Intel is out of scope.

## Platform Validation

- For platform-affecting changes, validate Windows x86_64, macOS Apple Silicon aarch64, and Linux x86_64 / Ubuntu 26.04.
- Windows validation runs locally or in CI with the PowerShell scripts.
- macOS validation targets Apple Silicon only; macOS Intel is intentionally unsupported.
- Linux validation targets Ubuntu 26.04 x86_64 first.
- Remote validation host details and credentials belong only in `.secrets/validation-hosts.local.md`.
- Record host, OS, architecture, compiler path/version, commands, and results in `docs/captains-log/index.html`.
- Temporary-worktree validation is preferred for remote hosts; installer scripts must create their ignored local state directories before writing env files.

## PR Closeout

- Before opening or updating a PR, compare the change against the linked issue acceptance criteria.
- Before merging, confirm CI status, review threads, issue map status, and documentation updates.
- After merging, verify that auto-closed issues actually closed.
- Sync local `main` with `origin/main` after merge.
- Update Captain's Log when the merge changes project state, validation state, or operating rules.
- Update the Project Progress section in this file whenever the merge closes an issue or changes roadmap status.
- Update the PRD and ADR guide/records when the issue changes product requirements or architecture decisions.
- Update roadmap, issue map, and PRD status immediately after a merge closes planning or documentation work, before opening the next epic.

## PRD And ADR Cadence

- Treat `docs/prd.html` as the living product requirements document for current scope, users, milestones, and open product questions.
- Treat `docs/adr.html` and `docs/decisions/` as the architecture decision system.
- Before implementation, check whether the linked issue changes PRD requirements or requires an ADR.
- During closeout, update PRD/ADR docs in the same PR as the relevant implementation when the change affects product or architecture direction.
- Keep proposal updates for broad vision changes; keep PRD updates for current requirements; keep ADRs for durable technical decisions.

## XCLI And XRTL Direction

- Follow the sequence `xpc build` -> XCLI project creation -> XRTL foundation.
- XRTL means XPascal Extended RunTime Library; do not rename this phase to XRT.
- Treat `docs/xrtl/architecture.html` as the XRTL layering and ownership contract.
- Treat `docs/xrtl/testing.html` as the minimum test strategy for XRTL library work.
- The first XRTL planning gate must happen before runtime implementation grows. This does not replace the XCLI sequence; it prevents generated projects and future runtime units from drifting apart.
- XRTL is not required to mirror Delphi, Lazarus, or historical FPC library boundaries.
- Prefer shared XRTL primitives over duplicated per-library helpers.
- Keep Core and Time small. Process owns OS/CPU detection behavior; Core may own only neutral platform/capability value shapes if needed.
- Prefer active, compatible open source libraries when they are a strong long-term fit.
- Do not choose dependencies only because they are quick to assemble; future maintainability is the first priority.
- If wrapping open source, document why a wrapper is needed, what is wrapped, why direct use was not chosen, and what license/NOTICE obligations apply.
- Candidate areas such as database access and web server support require research and provenance notes before implementation.
- Database and Web candidates remain research-only until license, maintenance, platform validation, testability, and API-shape evidence are recorded.

## Issue Discipline

- Every non-trivial change must map to one GitHub issue.
- Each issue must explain the relevant proposal section, problem, scope, acceptance criteria, implementation evidence, and validation status.
- Commits and PR descriptions should reference the issue numbers they advance.
- Keep issue status current: `planned`, `in progress`, `implemented in PR`, `blocked`, or `done after merge`.
- Close issues only when their close criteria are satisfied. Prefer PR auto-close keywords when the issue closes at merge time.
- Do not close bootstrap issues until the implementing PR is merged unless the issue is explicitly marked `not planned`.
- Update `docs/issues/index.html` when issue scope, status, or relationships change.
- When an issue reaches `done after merge`, reflect the progress change in this file during the same closeout pass.

## Quality Bar

- Scripts must fail loudly with actionable messages.
- Bootstrap commands must work from a clean checkout.
- CI must verify the compiler version before building.
- Supported toolchain archives must be checksum-verified before extraction.
- Documentation should be beginner-friendly and suitable for both human developers and AI agents.
