# GLM Task Packets

Use this folder for prompts sent to GLM.

Every packet should use this shape:

```markdown
# Task

One clear objective.

# Source Of Truth

Repo facts and excerpts. Do not invent beyond this.

# Constraints

Hard requirements and forbidden changes.

# Output Format

Exact sections, JSON, or table expected.

# Quality Bar

How Codex will judge the result.

# Do Not

Forbidden assumptions or risky shortcuts.
```

Codex must review GLM output before applying it. Save the raw response under `ai/glm-outputs/` and Codex's accept/modify/reject notes under `ai/reviews/`.
