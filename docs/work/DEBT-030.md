# DEBT-030 — /log dispatch costs ~30k tokens per row, and the "all rows route through log" contract has no transcription exception

**Logged:** 2026-07-25 · **Source:** live session — three `/log` dispatches measured while carding the de-routing work
**Problem:** Each `/super-bootstrap:log` invocation dispatches the Sonnet `log` subagent to classify + dedup + write. Measured this session: 23.3k / 35.3k tokens for batches of 1 and 9 entries respectively — cost is near-flat in entry count, so a single-row capture pays nearly the same as a nine-row batch. DEBT-022 records the same disproportion for `todo` but is scoped to that agent only; nothing covers `log`. Separately, `CLAUDE.md` § log states all new rows route through the funnel with no stated exception, while the device-level dispatch doctrine carves out transcription (content already in hand, zero propagation closure) as inline work — GAP-041 was written inline under that carve-out, so the two contracts currently disagree.
**Area:** `plugins/super-bootstrap/agents/log.md`; `plugins/super-bootstrap/skills/log/SKILL.md`; root `CLAUDE.md` § log routing statement
**Prior:** Two facets, possibly one fix: right-size the classify+write pass to entry count, and decide whether the funnel admits a transcription exception. The contract half is a harness-doctrine call — likely wants brainstorming adjudication alongside the de-routing overhaul rather than a unilateral edit.

## Amendment — 2026-08-01 · GAP-047 substrate landing

Contract half resolved: the funnel now admits a sanctioned transcription path — hand-copying `TEMPLATE.md` with the same high-water bump (`docs/work/README.md` § routing). Remaining scope: the cost half only — right-size the log dispatch's classify+write pass to entry count.
