# GAP-xxfq — doc surface: no signal for one fact restated in K places

**Logged:** 2026-10-27 · **Source:** split off `GAP-j0sr`'s Prior (ComfyUI `workflows/agent` device note, 2026-10-27)
**Problem:** In the consumer commit, one fact (how a workflow toggle is built) was restated in 4 places in README. That restatement count per fact is the direct SSOT-drift signal, but no lane surfaces it; the owner read the commit door's inflated scope count as the SSOT symptom instead. The commit door's grep gate is mechanical by rule and cannot find "a fact" and its restatements.
**Area:** `plugins/super-bootstrap/skills/check-docs-consistency/SKILL.md` (likely home); `plugins/super-bootstrap/skills/commit/SKILL.md` § Rules "Grep-gate is mechanical"
**Prior:** consumer proposed a "changed fact restated in K places" gate line; triage of `GAP-j0sr` placed it outside the commit gate, aimed at the whole-surface backstop.

## Verdict — auto-fix · 2026-10-27

**Fix-shape:** prompt
**Probe-deps:** none
**Execution:** full — depth: a new judgment axis in LLM-executed skill prose (non-deterministic; RED first per `skill-authoring`, tier check per the `catalog-axis` precedent); closure: one skill + one new predicate asset + one new bench fixture + the overview bench roster, no cross-skill contract.

### Repro (pinned)

"In the consumer commit, one fact (how a workflow toggle is built) was restated in 4 places in README. That restatement count per fact is the direct SSOT-drift signal, but no lane surfaces it"

### Root cause (verified)

- premise age: 1 commit touched a named surface after the observation (`cf9d8d0`, 09:17, the card's own logging commit): `3f0bf21` (`commit/SKILL.md` §3, adds `hits --by-term` per-term counts on ceiling trip). It counts grep hits per *term*, not restatements per *fact*. It does not overturn the premise. `10020f5` (09:17:35) predates the card's commit by 5 s and is the `BUG-g66v` stdin fix, also unrelated to restatement.
- Gap confirmed against `plugins/super-bootstrap/skills/check-docs-consistency/SKILL.md`. No Step 2 class flags a fact stated consistently in K places:
  - P0 "Same concept defined differently in two docs" (`:76`) fires only on *contradiction*. A consistent restatement passes it.
  - P2 "Field/concept name mismatch" (`:94`) fires only on *naming* divergence.
  - P3 link gap (`:104`, `assets/link-predicate.md`) is cross-doc (A uses, B defines) and only asks "is there a link". It never counts copies. It structurally cannot see the consumer case: 4 copies in *one* README have no other-doc home, and `ssot-doc-link` allows one link per concept per doc, so 3 copies stay unlinked by design.
  - Step 1 extracts "Feature/module names mentioned across multiple docs" (`:51`) and "Field/concept names that appear in multiple docs" (`:61`). These are names, not fact content, and cross-doc only. Intra-doc restatement is never extracted.
- The commit door is correctly excluded. § Rules "Grep-gate is mechanical" bars semantic fact-finding from §3, and `GAP-j0sr`'s verdict placed the item here. `decisions.md` row "Invert the commit door's citer lane" re-states the same bar ("'Carries a claim beside the link' is a judgment the gate's mechanical contract excludes"). `check-docs-consistency` is the judgment-grade whole-surface lane, so the home is right.
- Aim: no other open card (only `GAP-xxfq` in `docs/work/`). No closed fork re-walked. The `GAP-082` row (whole-surface backstop firing cadence) closes *when* the scan runs, not *what* it checks. The `GAP-059` row (judge posture-class miss) closes the commit-door judge prose, not a new whole-surface axis. Its stated reopen path, "a mechanical carrier … its enumeration step named", matches the Step 1 extraction shape settled below.
- Design trade-offs settled from repo doctrine, not user judgment:
  - **What counts as a restatement.** CLAUDE.md § Doc Sync: "any restated fact a reader lands on reaches its SSOT home in one hop — a markdown link on the asserting line". `link-predicate.md:4-5`: copying "forks the truth and drifts on first edit". Plugin README `:94`: "source-of-truth strings appear in exactly one file". So the unit is a *fact* (a claim's content), not a term. A copy counts when it carries the content, not when it is a bare pointer.
  - **When it is a finding.** K ≥ 2 copies, where at least one copy lacks a one-hop link to a single home. Intra-doc copies count. For a same-doc restatement, the home is a section and the link is an anchor link. Report K + every location + the home (or "no home" when none is designated). A fully linked K stays out of the finding, because doctrine admits a linked restatement.
  - **Priority: P2.** Consistent now and divergent on the next edit is "Slow-Burn Confusion" by the bucket's own name. A divergent copy is already P0 (`:76`), so dedup keeps the higher class.
- Seen while reading: the per-fact count needs a Step 1 extraction (a fact roster: content + locations, intra-doc included) feeding a Step 2 P2 bullet. Checking it against the extracted set fits `:71`'s "all validations run against the extracted set".

### Files (fix surface)

- `plugins/super-bootstrap/skills/check-docs-consistency/assets/restatement-predicate.md` (new) — predicate: fact vs pointer, copy-counting rule, intra-doc anchor-home case, linked-restatement exemption, guards against counting catalog rows / ephemeral docs (reuse `link-predicate.md` guards 3-4 by link, not by restatement).
- `plugins/super-bootstrap/skills/check-docs-consistency/SKILL.md:43-67` — Step 1 extraction bullet (fact roster with locations, intra-doc included, per the predicate).
- `plugins/super-bootstrap/skills/check-docs-consistency/SKILL.md:92-98` — Step 2 P2 bullet: "fact restated in K places (K + locations + home)".
- `plugins/super-bootstrap/skills/check-docs-consistency/SKILL.md:71` — the intro sentence names P2 dimension-pollution as the only intra-doc check. Add the restatement axis's intra-doc reach there.
- `plugins/super-bootstrap/skills/check-docs-consistency/assets/workflow-fanout.md` — read-and-confirm: no P-class enumeration found by grep. Confirm a fan-out reader's per-doc decomposition does not split a cross-doc fact roster. If it does, the merge rule needs the roster union.
- `bench/restatement-axis/` (new, `bench/catalog-axis/` shape) — synthetic fixture: one fact ×4 in one README (the pinned case), one fact ×2 cross-doc unlinked, one fact ×3 all linked to its home (negative control), one bare-pointer decoy, `ANSWER-KEY.md`, `probe-prompt.md` carrying the axis text verbatim. Run RED first: current SKILL.md text against the fixture. If RED does not go red (the current scan already reports the ×4 case), stop. The axis ships no diff, and the outcome lands as a `docs/decisions.md` row, as on rows `:25` / `:94`.
- Provenance: all paths native to this repo (no `.served` marker in the skill dir). No upstream route.

### Doc Impact

- `docs/overview.md:48` — bench roster "27 measured fixtures" → 28 + the new `restatement-axis/` entry.
- `plugins/super-bootstrap/README.md:21` — skill line "drift, stale references, contradictions". Add restatement count only if the line enumerates classes. Otherwise confirm unchanged.
- `README.md:109` — "whole-surface doc drift scan". Read and confirm unchanged (restatement is drift).
- `SKILL.md` frontmatter `description` — same check as plugin README `:21`.
- `docs/decisions.md` — touched only on the RED-did-not-go-red exit.
- CLAUDE.md § Doc Sync and `harness-bootstrap/assets/claude-md-skeleton.md` — unchanged. They name `check-docs-consistency` as the coverage backstop without enumerating its classes.

### Test Strategy: e2e

## Plan — 2026-10-27

1. Build `bench/restatement-axis/` in `bench/catalog-axis/` shape: synthetic fixture per the Verdict's Files list, `ANSWER-KEY.md`, a RED `probe-prompt` carrying the current `check-docs-consistency` Step 1–2 text verbatim, README.
2. RED: dispatch the probe cold, 3 runs at the tier the skill runs its scan on; score against the key. ×4 case already reported → stop, land a `docs/decisions.md` row, no axis diff.
3. RED went red → author `assets/restatement-predicate.md`, the Step 1 bullet, the Step 2 P2 bullet, the `:71` wording; a GREEN probe-prompt carrying the new text.
4. GREEN: same tier, 3 runs; ×4 + cross-doc cases found, linked control and pointer decoy clean. Tier check against `opus` if `sonnet` misses.
5. `audit-harness-edits`; doc-sync (`docs/overview.md` bench roster; READMEs read-and-confirm).

## Progress — 2026-10-27

- Step 1 done: `bench/restatement-axis/` (fixture, `ANSWER-KEY.md`, `probe-prompt-red.md` carrying current Step 1–2 verbatim). RED tier `sonnet` (`assets/workflow-fanout.md` § Fan-out contract item 4).
- Step 2 done — RED is red, 3 runs `sonnet`: case A (×4 in one README) found 1/3, and that one at P3 as a link gap, never P2; case B (×2 cross-doc) 3/3, only as a P3 link gap with no copy count; case C (all linked) no restatement finding (run 1 flagged its copies for omitting an exception — content omission, not count); case D (pointer decoy) 0/3. Unplanned fixture noise every run: 40 °C start check vs 45 °C fuse; run 2 also an empty-cabinet claim.
- Next: step 3.
