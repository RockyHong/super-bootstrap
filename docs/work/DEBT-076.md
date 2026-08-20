# DEBT-076 — drain's .gitignore append falls outside the runway's staging row

**Logged:** 2026-08-21 · **Source:** DEBT-075 triage verdict — same failure mode on an opt-in lane, scoped out
**Problem:** `drain`'s `ensure-infra` appends `.claude/worktrees/` + `.drain-status` to `.gitignore`, while `harness-bootstrap/SKILL.md` § 2c's `.gitignore` staging row carries a hooks-only condition ("when 2a-hooks appended `.claude/.consult-catalog`") and the trailing catch-all says "created" — an appended line on an existing `.gitignore` matches neither, so when the scale-module / drain seed runs inside a runway pass the `.gitignore` change can be left unstaged.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` § 2c `.gitignore` row; `plugins/super-bootstrap/skills/drain/assets/ensure-infra.md`
**Prior:** Widen the § 2c `.gitignore` row's condition to "when any 2a step appended a line" (hooks, drain infra), or have drain's `ensure-infra` own its own commit when invoked standalone. Harness edit — `audit-harness-edits` binds.
