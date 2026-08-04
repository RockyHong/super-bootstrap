# DEBT-030 — /log dispatch costs ~30k tokens per row, and the "all rows route through log" contract has no transcription exception

**Logged:** 2026-07-25 · **Source:** live session — three `/log` dispatches measured while carding the de-routing work
**Problem:** Each `/super-bootstrap:log` invocation dispatches the Sonnet `log` subagent to classify + dedup + write. Measured this session: 23.3k / 35.3k tokens for batches of 1 and 9 entries respectively — cost is near-flat in entry count, so a single-row capture pays nearly the same as a nine-row batch. DEBT-022 records the same disproportion for `todo` but is scoped to that agent only; nothing covers `log`. Separately, `CLAUDE.md` § log states all new rows route through the funnel with no stated exception, while the device-level dispatch doctrine carves out transcription (content already in hand, zero propagation closure) as inline work — GAP-041 was written inline under that carve-out, so the two contracts currently disagree.
**Area:** `plugins/super-bootstrap/agents/log.md`; `plugins/super-bootstrap/skills/log/SKILL.md`; root `CLAUDE.md` § log routing statement
**Prior:** Two facets, possibly one fix: right-size the classify+write pass to entry count, and decide whether the funnel admits a transcription exception. The contract half is a harness-doctrine call — likely wants brainstorming adjudication alongside the de-routing overhaul rather than a unilateral edit.

## Amendment — 2026-08-01 · GAP-047 substrate landing

Contract half resolved: the funnel now admits a sanctioned transcription path — hand-copying `TEMPLATE.md` with the same high-water bump (`docs/work/README.md` § routing). Remaining scope: the cost half only — right-size the log dispatch's classify+write pass to entry count.

## Amendment — 2026-08-02 · user-reviewed dispatch audit (DEBT-044 per-item pass)

Card re-scopes from cost-only to shape + contract, two new facts:

- **Collapse-to-inline candidate.** The dispatch prompt already carries each observation phrased for cold pickup — classification is near-done at prompt-authoring; ID assignment + TEMPLATE write are mechanical. The agent's only remaining real judgment is dedup. The bias-exclusion rationale (shell never pre-classifies) has lost weight as models strengthened. Evaluate collapsing the log agent into gateway-inline capture — the sanctioned transcription path (README § Routing) is already half the shape.
- **Dedup must surface, not auto-resolve.** Current contract auto-drops pure dups and auto-appends Amendments on new-fact dups — the user never sees the call. Contract change: dup / suspected-dup → write nothing, return the match + context to the gateway → gateway MCQs the user (amend / new card / drop).

## Design — 2026-08-04 · user-settled (doctrine 批)

**Collapse to gateway-inline, no escape hatch; the `log` agent retires.**

- Offload accounting closed the hygiene claim: dispatch keeps only the dedup card-reads out of the gateway — the observation is already in gateway context, the dispatch prompt transcribes it out, the report transcribes it back. Inline Grep replaces the card-reads at near-zero cost. Net offload ≈ 0; the ~21.8k fixed floor buys nothing.
- The funnel contract is untouched: all new cards still route through the `/super-bootstrap:log` door (classification, dedup check, ID high-water bump, TEMPLATE shape all kept) — only the implementation moves from dispatch to gateway-inline. The findings-persistence closed fork (docs/decisions.md) binds the door, not the container.
- Dedup: suspected dup → write nothing, surface match + context, user picks amend / new card / drop. Judgment moves to the user, per escalation-design (preference-grade call).
- Bias-exclusion rationale (shell never pre-classifies) retired: capture does no worth-judgment by contract; the fresh-eyes home is the triage lane downstream.
- No heavy-context escape hatch: Finding Triage's context-budget axis already covers "heavy context → log terse now"; inline card-write is the minimal action.
