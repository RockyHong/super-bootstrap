# DEBT-yyae — split-outward.py ships with no declared degrade path

**Logged:** 2026-11-24 · **Source:** `DEBT-fb09` triage verdict (2026-11-24), via the docs-consistency follow-through
**Problem:** `plugins/super-bootstrap/skills/harness-bootstrap/assets/scale/split-outward.py`, invoked at `harness-bootstrap/SKILL.md` Phase 2a when `docs/outward.md` exists, has no fallback when `python3` is absent, while `.claude/rules/asset-dialects.md` asks every Python asset to declare its degrade path (scope per the `DEBT-fb09` triage verdict, unconfirmed)
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/assets/scale/split-outward.py`, `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md`, `docs/techstack.md` § Runtime
**Prior:** Declare a degrade path (a manual split route, or a stop with a named prerequisite) in the SKILL step that invokes it.
