# DEBT-114 — the dogfood runway receipt is ten releases behind the plugin it stamps

**Logged:** 2026-09-10 · **Source:** `session-close` after the `/pull-issue` triage that logged GAP-076 — checking this repo's own copy for the same stale-consumer shape
**Problem:** `.claude/super-bootstrap-runway.json` records `2.39.0` as the synced plugin version while `plugin.json` is `2.49.0`, so ten releases of pipeline-owned sections and frozen assets have never been drift-checked against this repo's own install. The frozen hooks happen to be current (BUG-060 synced `commit-channel` v6 by direct edit, byte-identical to the asset), but the receipt exists so a re-run compares against settled divergences instead of re-proposing them — a stale one means the next `/super-bootstrap:harness-bootstrap` run carries a wider diff than the author expects. Sibling of [GAP-076](GAP-076.md) (the missing ambient signal); this card is the chore itself.
**Area:** `.claude/super-bootstrap-runway.json`; `.claude/hooks/`; `.claude/settings.json` hook entries; `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` § Version-staleness signal
**Prior:** Run `/super-bootstrap:harness-bootstrap` and walk its proposals; the receipt's `declined` record is what keeps the pass short.
**Test-feel:** manual · **Blast:** repo
