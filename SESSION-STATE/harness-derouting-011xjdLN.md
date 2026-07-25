# Carry — harness de-routing

## Anchor

Cut super-bootstrap's dependence on superpowers: it stops routing any external
process harness. Decision made, cut sites carded, nothing executed yet.

## Read first

1. `docs/specs/harness-architecture.md` — §6 decided-vs-open, §7 evidence index
   (A/B/C grades), §8 what adopt mode can and cannot retire.
2. `docs/backlog.md` — DEBT-024..030, GAP-038/039/041.
3. `git log --grep=de-routing` and commits `fe40fdd` · `6f0324b` · `b68336f`.

## State

Research done, grounding artifact committed, 12 open rows. GAP-040 (the migration
gate on the skeleton cards) is resolved and deleted — its finding lives in spec §8.
No cut has been executed. Tree clean.

## Next step — proceed chain order

Not in the docs; this is the volatile payload. Waves are ordered by shared
consumers, not by card number.

- **Wave 1 — skeleton, one logical change unit, one commit:** DEBT-024 (routing
  table + run-route-whole + SDD carve-out) → DEBT-025 (delete
  `docs/specs/superpowers-topology.md`, after 024 drops its references) → DEBT-029
  (§ Coding Principles → `CODING_STANDARDS.md`) → GAP-038 (issue-tracker seed) →
  GAP-039 (verification-before-completion rule). All five land inside shapes adopt
  mode migrates (spec §8). Harness edits → `audit-harness-edits` after.
- **Wave 2 — DEBT-027** (strip intent classification from
  `shared/classify-actionable.md` + `agents/todo.md`). Unblocks drain's eligibility
  rewrite. Check whether it subsumes DEBT-022 and BUG-019 before closing.
- **Wave 3 — DEBT-026** (retire `docs/superpowers/specs|plans/`). Widest consumer
  set; carries its own downstream migration because adopt mode has no folder-removal
  path.
- **Wave 4 — DEBT-028** (drain stage machine → interface-driven). Needs 026's path
  decision and 027's eligibility shape settled first.
- **Anytime, independent:** GAP-041 (read mattpocock at grade A). Gates change B
  (the harness swap), not change A (de-routing). Wants a clean container.

## Watch-outs

- **Evidence grades are load-bearing.** Every mattpocock claim except the
  issue-tracker option list is grade B (small-model fetch summaries, not source).
  Spec §7 marks each. Do not harden a B into a decision without reading the source.
- **One correction already landed:** `disable-model-invocation: true` controls who
  may invoke a skill, not subagent dispatch. An earlier read of it as "anti-fan-out"
  was wrong and fed GAP-041's premise. He does dispatch — `code-review` runs two
  parallel `general-purpose` sub-agents, for isolation rather than offload.
- **DEBT-026 is the only cut adopt mode cannot migrate** (folder hole, spec §8).
  Downstream repos keep orphaned `docs/superpowers/` dirs that `/todo` and `drain`
  still scan.
- **Funnel bypass precedent set:** GAP-041 and DEBT-030 were written inline rather
  than through `/log`. Ruled keep-as-is; the contract question is carded as DEBT-030
  and wants brainstorming adjudication with the overhaul, not a unilateral edit.
- **Change B is not approved.** De-routing does not commit to adopting
  mattpocock/skills. superpowers may stay installed — it just stops being routed.
