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
- Codex + GLM task packets and reviews: `ai/`

## Workflow

1. Start from a GitHub issue.
2. Use a feature branch named `codex/<short-description>`.
3. Keep changes scoped to the issue.
4. Run the relevant toolchain, build, and smoke checks.
5. On macOS/Linux, prefer `bash ./tools/<script>.sh` unless executable bits are known to be preserved.
6. Open a draft PR until validation is complete.
7. Record GLM suggestions and Codex review decisions when GLM contributes.

## Issue Discipline

- Every non-trivial change must map to one GitHub issue.
- Each issue must explain the relevant proposal section, problem, scope, acceptance criteria, implementation evidence, and validation status.
- Commits and PR descriptions should reference the issue numbers they advance.
- Keep issue status current: `planned`, `in progress`, `implemented in PR`, `blocked`, or `done after merge`.
- Do not close bootstrap issues until the implementing PR is merged unless the issue is explicitly marked `not planned`.
- Update `docs/issues/index.html` when issue scope, status, or relationships change.

## Quality Bar

- Scripts must fail loudly with actionable messages.
- Bootstrap commands must work from a clean checkout.
- CI must verify the compiler version before building.
- Documentation should be beginner-friendly and suitable for both human developers and AI agents.
