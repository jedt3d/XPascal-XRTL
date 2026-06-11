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
5. Open a draft PR until validation is complete.
6. Record GLM suggestions and Codex review decisions when GLM contributes.

## Quality Bar

- Scripts must fail loudly with actionable messages.
- Bootstrap commands must work from a clean checkout.
- CI must verify the compiler version before building.
- Documentation should be beginner-friendly and suitable for both human developers and AI agents.
