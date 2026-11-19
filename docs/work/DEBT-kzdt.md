# DEBT-kzdt — harness-bootstrap's sync-report example shows a Runtime row the seed-once rule never produces

**Logged:** 2026-11-19 · **Source:** DEBT-ymdg session — a build agent's consistency pass over `harness-bootstrap/SKILL.md` while rewriting § 2c's examples
**Problem:** § 2c's sync-report example carries the row `docs/techstack.md: Runtime ⚠ drifted → updated`. § 2b's per-doc handling treats `docs/techstack.md` § Runtime (with Framework, Key Dependencies, Build & Distribution) as a seed-once section, compared on shape only and never rewritten on a re-run. The example shows an outcome the rules do not produce, and an agent reading the example as the report's shape can report or perform an update the rule forbids. Older than the ownership split.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` § 2b per-doc handling, § 2c sync report
**Prior:** Replace the example row with a section that is drift-checked (e.g. `docs/techstack.md § Edit Discipline`).
