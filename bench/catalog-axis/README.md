# bench/catalog-axis — RED fixture + tier probe for the catalog-row axis

Test surface for the index-row-to-entry-file claim axis that
[`skills/check-docs-consistency/SKILL.md`](../../plugins/super-bootstrap/skills/check-docs-consistency/SKILL.md)
carries in Step 1 (extraction) and Step 2 (P0/P1), gated on the catalog predicate.
super-bootstrap is the SSOT of that axis; this directory is the fixture the axis was
written against and the probe that settles which model tier can execute it. An edit to
the axis text or to the predicate re-runs here first.

The corpus is synthetic — a fictional port-management toolkit, no real skill text — so
a judge cannot answer from repo familiarity.

- `fixture/index.md` — an eight-row catalog. Rows name their entry by backticked
  convention, not by markdown link, and each carries a dense multi-clause summary: both
  halves of the predicate the axis gates on (resolvability, not linkage; prose beyond
  the pointer).
- `fixture/entries/*.md` — the eight entry files, 45–56 lines each, three to four `##`
  sections apiece. Planted defects: one contradiction, two contract-class whole-section
  omissions, one descriptive whole-section omission, one rhetorical-role-heading decoy,
  three clean controls.
- `fixture/ANSWER-KEY.md` — expected verdict per row with the row span, the entry
  section, and why. Judge-inputs never include it.
- `axis-draft.md` — the graft text in three pieces: the `assets/catalog-predicate.md`
  candidate body, the Step 1 extraction bullet, and the Step 2 P0/P1 bullets plus the
  door-boundary rider.
- `probe-prompt.md` — the self-contained judge prompt, carrying the axis text verbatim.

## Running the probe

Dispatch `probe-prompt.md` to a cold agent at the tier under test — `sonnet` and `opus`
are the two rungs the axis has to choose between, three runs each so a single lucky or
unlucky pass does not decide it. The prompt is self-contained: pass it as the whole
task, add no context, and give the agent read-only tools.

Score each returned findings list against `fixture/ANSWER-KEY.md`:

- **Recall per shape** — contradiction, contract-class omission (two rows), descriptive
  omission. A shape found at the wrong P-level counts for recall, not for leveling.
- **False positives** — any finding on a clean control, and separately any finding on
  the decoy row. The decoy is scored on its own: it is the shape the measured
  deterministic tier fails, so a run clean everywhere except the decoy still fails.
- **Section precision** — a finding on a defect row that names the wrong entry section
  counts as both a miss and a false positive.

The tier gate: a rung passing both P0 shapes at 2 of 3 or better with no decoy false
positive carries the axis rung-agnostic. A rung failing either lands the one-line
rung-1 note in
[`assets/workflow-fanout.md`](../../plugins/super-bootstrap/skills/check-docs-consistency/assets/workflow-fanout.md)
instead, so a fanned-out run states the axis as not-covered rather than under-firing
silently.

**Measured reach** (this fixture, 3 runs per rung): `sonnet` 3/3 and `opus` 3/3 — every
run recovers all four planted defects at the correct P-level and the correct entry
section, with no finding on the decoy or any clean control. Both rungs pass the gate;
the shipped axis carries no rung note.

## Decontamination

`probe-prompt.md` names the files the judge may open and names `ANSWER-KEY.md` as
off-limits; a run that reads anything else is void. The axis text's own worked examples
are drawn from outside this corpus on purpose — an example lifted from the fixture
would hand the judge its decoy.
