# bench/restatement-axis — RED fixture for a fact-restatement axis

Test surface for a restatement axis in
[`skills/check-docs-consistency/SKILL.md`](../../plugins/super-bootstrap/skills/check-docs-consistency/SKILL.md):
one fact (a claim's content, not a term) stated in K places, where at least one copy
carries no one-hop link to a single home. The RED question is whether the skill's
current Step 1 (extraction) and Step 2 (P0–P3 classes) text already reports that
shape. An edit to the axis text, or to a predicate it leans on, re-runs here first.

The axis shipped in the commit door's doc-sync instead — [`agents/doc-sync-scan.md`](../../plugins/super-bootstrap/agents/doc-sync-scan.md) § Scan step 6, with [`skills/commit/assets/restatement-predicate.md`](../../plugins/super-bootstrap/skills/commit/assets/restatement-predicate.md). `probe-prompt-red.md` stays as the RED record against `check-docs-consistency`; the doc-sync probe pair (§ Doc-sync probes) is the live test surface.

The corpus is synthetic: `brindle`, a fictional bakery proofing-cabinet controller,
with no real repo text. A judge cannot answer from repo familiarity.

- `fixture/README.md` plus `fixture/docs/*.md` — six docs, about 300 lines. Planted
  cases: one fact restated ×4 inside `README.md` with no link (the pinned case), one
  fact ×2 across two docs with no link, one fact ×3 where every copy links one hop to
  its home (negative control), and one bare-pointer decoy (a line that names where a
  fact lives and carries none of its content). The rest is filler written to hold no
  restatement, contradiction, broken link, or orphan.
- `fixture/ANSWER-KEY.md` — expected outcome per case, with line spans, plus the RED
  decision rule. Judge input never includes it.
- `probe-prompt-red.md` — the self-contained judge prompt. It carries the current
  Step 1, Step 2, and Report Format text and the three predicate assets those steps
  cite, verbatim, with no hint about restatement.

## Running the probe

Dispatch `probe-prompt-red.md` (the body below its rule) to a cold agent with
read-only tools, three runs per tier, so one lucky or unlucky pass does not decide it.
Pass it as the whole task and add no context.

RED tier: **`sonnet`**. That is the tier the skill pins for its scan judge —
[`assets/workflow-fanout.md`](../../plugins/super-bootstrap/skills/check-docs-consistency/assets/workflow-fanout.md)
§ Fan-out contract item 4: "Judge `sonnet` … Ceiling is `sonnet`". The default rung-1
inline pass pins no model and runs at the invoking session's tier. A GREEN miss at
`sonnet` earns a tier check at `opus`.

## Scoring

Score each returned report against `fixture/ANSWER-KEY.md`:

- **Case A (×4 in one README)** decides RED. Reported → RED did not go red: stop, and
  record the outcome as a `docs/decisions.md` row with no axis diff. Absent → RED is
  red and the axis build proceeds.
- **Case B (×2 cross-doc)** — record which class fired, if any. The current P3
  link-gap class can plausibly catch it, so it does not decide RED; it is the baseline
  the new axis must not regress.
- **Cases C and D** — any restatement, duplication, or link-gap finding on either is a
  false positive.
- **Unplanted findings** — read each against the corpus by hand: either a fixture
  defect (fix and re-run) or a false positive.

## Decontamination

`probe-prompt-red.md` names the six docs the judge may open and names `ANSWER-KEY.md`
off-limits; a run that reads anything else is void. The prompt copies the skill text
as it stands, so it goes stale when `SKILL.md` § Step 1–2 / § Report Format or the
three predicate assets change — regenerate it before a RED run on changed text.

## Doc-sync probes

`assemble-docsync-prompts.sh` builds four prompts from `diff/` and the scanner text:
`probe-prompt-docsync-{red,green}-{a,c}.md`. Within a case, red and green differ only in
the scanner text — RED is `doc-sync-scan.md` at the commit before step 6, GREEN the
working tree plus the predicate. Re-run the script after editing either file.

- `diff/case-a.diff` changes case A's hold value at one of its four README copies →
  GREEN expects a `restatements` item (K = 4, home `none`, all unlinked) beside the
  three stale copies; RED expects the stale copies only.
- `diff/case-c.diff` changes case C's value at its home → both expect the stale copies
  and no restatement (every outside copy links one hop to the home).

Run each prompt three times at `sonnet` (the cold lane's tier), read-only, and score
the `restatements` section and the stale-copy recall.

Result at authoring (3 runs each): RED-a 0/3 restatement, stale copies 3/3; GREEN-a
3/3 restatement with K = 4, home `none`, all four unlinked, stale copies 3/3; GREEN-c
0/3 restatement, stale copies 3/3.
