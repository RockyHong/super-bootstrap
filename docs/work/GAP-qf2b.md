# GAP-qf2b — harness-bootstrap § 2a-autorun asks to pre-install infra that autorun installs itself

**Logged:** 2026-10-27 · **Source:** device note from claude-config-manager (its 5.3.0 → 5.5.0 runway re-sync)
**Problem:** On every code-present repo without autorun infra, § 2a-autorun asks "Install `/super-bootstrap:autorun` worktree infra? (y / skip)". The three pieces (worktree settings template, `PreToolUse(Read)` guard, `.gitignore` lines) are already installed idempotently by `/super-bootstrap:autorun` § Pre-flight (`skills/autorun/assets/ensure-infra.md`) on its first call, so the runway prompt adds a question to every sync and buys nothing. The consumer answered skip and wants that answer for every repo.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` § 2a-autorun, its receipt rows
**Prior:** never ask and never place in the runway; install on demand at autorun's first call only. Receipt shape is open: keep `✓ current` rows only where the infra is already present, or drop the step's rows.
