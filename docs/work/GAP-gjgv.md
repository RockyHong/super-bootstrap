# GAP-gjgv — CLAUDE.md skeleton § Planning flags consumer-added doc lines as drift

**Logged:** 2026-10-27 · **Source:** device note from claude-config-manager (its 5.3.0 → 5.5.0 runway re-sync)
**Problem:** § Planning is a doc index, and repos add their own docs to it (claude-config-manager: `docs/architecture.md`, `.claude/guidelines/`). The runway's drift check flags each addition, so every consumer that indexes its own docs carries a permanent fork.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/assets/claude-md-skeleton.md` § Planning, `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` drift check
**Prior:** treat § Planning as a repo-fill slot like § Rules — the skeleton's doc lines pipeline-owned, anything a consumer adds below them project-owned grown content.
