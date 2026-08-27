# DEBT-105 — release-init's rendered `/release` Step 5 commits the whole index, so a concurrent session's staged paths ride into the release commit

**Logged:** 2026-08-27 · **Source:** DEBT-104 triage family sweep
**Problem:** [`release-init/assets/template.md`](../../plugins/super-bootstrap/skills/release-init/assets/template.md) Step 5 runs `git add {{version_file_paths}}` then `git commit` with no index readback — the same shared-index exposure as [DEBT-104](DEBT-104.md): whatever another session or background agent already staged in the checkout lands under `chore: release v{version}` and gets tagged. This repo's own [`.claude/skills/release/SKILL.md`](../../.claude/skills/release/SKILL.md) § Step 5 carries the identical `git add` → `git commit` shape (behavior-divergent from the template per `docs/decisions.md` — not a re-render target, fixed on its own).
**Area:** `plugins/super-bootstrap/skills/release-init/assets/template.md` Step 5 · `.claude/skills/release/SKILL.md` Step 5 (this repo's divergent instance)
**Prior:** mirror whatever readback-and-surface guard DEBT-104 lands in `commit/SKILL.md` § 5 — `git diff --cached --name-only` against the version-file list before `git commit`; land after DEBT-104 so the two share one shape.
**Test-feel:** manual
**Blast:** local
