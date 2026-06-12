# Agent Instructions

## Project Priorities

- Keep the project CLI-first and CI/CD-first.
- Preserve plain-text, reviewable source artifacts.
- Prefer small, traceable branches linked to GitHub issues.
- Keep FreePascal pinned to version `3.3.1` until a decision record changes it.
- Treat Windows, macOS, and Ubuntu 26.04 LTS as first-class bootstrap targets.

## Source Of Truth

- Product direction: `docs/proposal.md`
- Architecture decisions: `docs/decisions/`
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

## Platform Validation

- For platform-affecting changes, validate Windows x86_64, macOS Apple Silicon aarch64, and Linux x86_64 / Ubuntu 26.04.
- Windows validation runs locally or in CI with the PowerShell scripts.
- macOS validation targets Apple Silicon only; macOS Intel is intentionally unsupported.
- Linux validation targets Ubuntu 26.04 x86_64 first.
- Remote validation host details and credentials belong only in `.secrets/validation-hosts.local.md`.
- Record host, OS, architecture, compiler path/version, commands, and results in `docs/captains-log/index.html`.

## PR Closeout

- Before opening or updating a PR, compare the change against the linked issue acceptance criteria.
- Before merging, confirm CI status, review threads, issue map status, and documentation updates.
- After merging, verify that auto-closed issues actually closed.
- Sync local `main` with `origin/main` after merge.
- Update Captain's Log when the merge changes project state, validation state, or operating rules.

## Issue Discipline

- Every non-trivial change must map to one GitHub issue.
- Each issue must explain the relevant proposal section, problem, scope, acceptance criteria, implementation evidence, and validation status.
- Commits and PR descriptions should reference the issue numbers they advance.
- Keep issue status current: `planned`, `in progress`, `implemented in PR`, `blocked`, or `done after merge`.
- Close issues only when their close criteria are satisfied. Prefer PR auto-close keywords when the issue closes at merge time.
- Do not close bootstrap issues until the implementing PR is merged unless the issue is explicitly marked `not planned`.
- Update `docs/issues/index.html` when issue scope, status, or relationships change.

## Quality Bar

- Scripts must fail loudly with actionable messages.
- Bootstrap commands must work from a clean checkout.
- CI must verify the compiler version before building.
- Supported toolchain archives must be checksum-verified before extraction.
- Documentation should be beginner-friendly and suitable for both human developers and AI agents.
