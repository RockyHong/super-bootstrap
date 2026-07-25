# Carry — harness de-routing

## Anchor

Cut super-bootstrap's dependence on superpowers: it stops routing any external
process harness. Decision made, cut sites carded, nothing executed yet.

## Read first

1. `docs/specs/harness-architecture.md` — §4 seam + why `GAP-038` is not executable
   as titled · §5 fence migration + which cards are short · §6 decided-vs-open · §7
   evidence grades · §8 what adopt mode can and cannot retire.
2. `docs/backlog.md` — DEBT-024..030, GAP-038/039/041.
3. `git log --oneline 7f52881..HEAD` — this session's commits, reasoning in the
   bodies. (Never enumerate hashes here; git owns history, the ledger owns the delta.)

## State

Research done, grounding artifact committed, 12 open rows, tree clean, nothing
executed. GAP-040 (the migration gate on the skeleton cards) is resolved and
deleted; its finding lives in spec §8.

## Next step — proceed chain order

The one thing the docs do not hold. Waved by shared consumers, not card number.

- **Wave 1 — skeleton, one logical change unit, one commit:** DEBT-024 → DEBT-025 →
  DEBT-029 → GAP-038 → GAP-039. All five land inside shapes adopt mode migrates
  (§8). Harness edits → `audit-harness-edits` after. **Read §5 before starting: three
  of these five have scope defects, and settling them is one deliberation, not five
  edits.**
- **Wave 2 — DEBT-027** (strip intent classification). Unblocks drain's eligibility
  rewrite. Check whether it subsumes DEBT-022 and BUG-019 before closing.
- **Wave 3 — DEBT-026** (retire `docs/superpowers/specs|plans/`). Widest consumer
  set; carries its own downstream migration (§8 folder hole).
- **Wave 4 — DEBT-028** (drain stage machine → interface-driven). Needs 026's path
  decision and 027's eligibility shape settled first.
- **Anytime, independent:** GAP-041 (read mattpocock at grade A). Gates change B, not
  change A. Wants a clean container.

## Watch-outs

- **Wave 1 is not shovel-ready.** Spec §4 and §5 name the defects; do not execute the
  card titles literally, and do not card the sub-problems — the framing is unsettled
  by decision, not by neglect.
- **Evidence grades are load-bearing** (§7). Every mattpocock claim except the
  issue-tracker option list is grade B. One grade-B claim already proved false
  mid-session (`disable-model-invocation` controls invocation, not dispatch) after it
  had shaped a full round of reasoning.
- **Change B is not approved** (§6). De-routing does not commit to adopting
  mattpocock/skills, and superpowers stays installed and invokable throughout.
- **Funnel bypass precedent:** GAP-041 and DEBT-030 were written inline rather than
  through `/log`. Ruled keep-as-is; the contract question is DEBT-030 and wants
  brainstorming adjudication with the overhaul.
