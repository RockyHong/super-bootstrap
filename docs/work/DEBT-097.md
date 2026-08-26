# DEBT-097 — 2a-hooks copy-on-drift ignores the runway receipt's `declined` list

**Logged:** 2026-08-27 · **Source:** consumer pilot sync report (2.34.2 → 2.40.0, GAP-064 / OUT-001 tail) — anomaly 6
**Problem:** [`harness-bootstrap/SKILL.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md) § 2a hooks re-places a drifted hook script or settings snippet from the asset unconditionally ("copy-on-drift … silent when already current"), while § Pipeline-owned sections honour `.claude/super-bootstrap-runway.json`'s `declined` list as "divergence accepted, not pending". A consumer that keeps its own variant of a shipped hook (the pilot's multi-root `consult-check-{sessionstart,check}.sh`, declined at 2.34.2) is asked to overwrite it on every sync and can only hold the line by re-declining by hand — and the skill text, read literally, says overwrite. Receipt protection is asymmetric: sections yes, hook files no.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` § 2a hooks · [`assets/hooks-ensure-infra.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks-ensure-infra.md) (copy-on-drift procedure) · § 2c receipt write (`declined` row identity for whole-file artifacts)
**Prior:** Let hook artifacts carry `declined` rows in the receipt like any other whole-file artifact — ensure-infra skips a drifted hook whose path is in `declined`, and the sync report shows it as `⚠ drifted → declined (receipt)`; an upstream fix then reaches the consumer only when the receipt version is bumped past the decline.
**Test-feel:** manual
**Stochastic:** llm
**Blast:** local
