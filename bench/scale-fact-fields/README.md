# bench/scale-fact-fields — micro-test for the 2a-scale step 6 marker-vs-drift precedence

Test surface for [`skills/harness-bootstrap/SKILL.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md)
§ 2a-scale step 6's `card-fact-fields.md` bullet — the clause that decides what a
re-run does with an already-present-but-stale fact-fields marker block. Behavior-shaping
prose, so it ships behind the [`skill-authoring`](../../.claude/rules/skill-authoring.md)
RED floor: the wording is held against the wording it replaces, reading-only (no fixture
repo — the model is handed the scenario + three excerpts and asked what it would do).

## Protocol

Arms run headless (`claude -p --model haiku`, no tools) with the prompt on stdin — a
scenario: re-run, scale module installed, `docs/work/README.md`'s fact-fields block carries
an older field shape (Venue / Blocked-on) while `assets/scale/card-fact-fields.md` now
carries the current shape (Test-feel / Stochastic / Blast). The model answers SKIP (leave
as-is) or DRIFT (diff against the asset, present, update on approval), citing which excerpt
decided it. Both arms carry the same three excerpts: the Phase 2 per-artifact rule (§ Phase 2,
"Exists, drifted from template → show diff, get approval per change, then write"), the
§ Pipeline-owned Scale-module bullet (lists the fact-fields marker block as drift-checked),
and the 2a-scale step 6 `card-fact-fields.md` bullet — the only line that differs between arms.

- **Control** — the pre-fix step 6 bullet: `git show HEAD:plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md`'s
  wording (`; skip if the markers are already present.`). Run 3×.
- **Arm** — the shipped step 6 bullet (`. Markers already present → the block is placed;
  § 2b's drift check judges its content against the asset (§ Pipeline-owned), so a re-run
  updates a stale block there, on approval.`). Run 3×.
- **Expectation** — control splits or lands SKIP (the literal read) → RED; arm lands DRIFT
  3/3 → GREEN. If control lands DRIFT 3/3, the clause fails the cut test (the general
  per-artifact rule already resolves it) — report plainly rather than shipping a story.

## Findings

Run 2026-09-10, `claude -p --model haiku`, no tools, three trials per arm.

| Arm | Trial | Answer | Cited reasoning |
|---|---|---|---|
| Control (pre-fix, "skip if markers present") | 1 | DRIFT | Excerpt 1's per-artifact rule ("show diff, get approval per change, then write") + Excerpt 2 confirms the block is pipeline-owned and drift-checked |
| Control | 2 | DRIFT | Excerpt 1: "Exists, drifted from template → show diff, get approval per change, then write." |
| Control | 3 | DRIFT | Excerpt 1 — pipeline-owned sections existing-but-drifted get a diff + approval-gated update |
| Arm (shipped, drift-defers-to-§2b) | 1 | DRIFT | Excerpt 3: "a re-run updates a stale block there, on approval" |
| Arm | 2 | DRIFT | Excerpt 3 explicitly states a re-run updates the stale block there, on approval |
| Arm | 3 | DRIFT | Excerpt 1's per-artifact rule + Excerpt 3's explicit re-run-updates-on-approval line |

**Verdict: no RED — control landed DRIFT 3/3, not SKIP/split.** The pre-fix "skip if the
markers are already present" clause did not actually mislead the model into skipping content
drift when the general Phase 2 per-artifact rule (Excerpt 1: "Exists, drifted from template →
show diff...") and the § Pipeline-owned drift-checked listing (Excerpt 2) sat alongside it —
Haiku resolved the conflict toward the more specific/recent-reading rule in 3/3 trials even
under the ambiguous wording. Arm also landed DRIFT 3/3, as expected. Per the card's own escape
clause (`DEBT-112` step 2), this reports plainly instead of shipping a manufactured RED→GREEN
story: **the card's fix clarifies intent and removes a genuinely-ambiguous reading for a human
or a less-careful executor (the GAP-073 verify run that triggered this card did hit real
confusion in practice), but the micro-test's controlled reading comprehension check does not
reproduce a misread with this model at this prompt shape.** Disposition: shipped as a
documentation-precision fix — the pre-fix clause was literally wrong under the drift rule the
same file states, and a contradiction between two rules is patched whichever way a model
happens to resolve it; the card resolved on that ground, without a bench-demonstrated
behavioral bug.
