# bench/rot-row-contract — micro-test for the rot row's sync-report contract

Test surface for [`skills/harness-bootstrap/SKILL.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md)
§ 2b's **rot scan** row contract and the § 2c gate + receipt write that consume it — the clauses
that make a rot row a first-class sync-report row rather than a transient per-run proposal.
Behavior-shaping prose, so it ships behind the
[`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor: the wording is held against
the wording it replaces, reading-only (no fixture repo — the model is handed the governing excerpts
plus a synthetic sync report and asked what the next step does).

## Protocol

Arms run headless (`claude -p --model haiku`, no tools) with the prompt on stdin, three trials per
arm. Control = the pre-fix wording, arm = the shipped wording; every other excerpt in the prompt is
held identical across arms, so the clause under test is the only variable.

Three scenarios were tried for the rot-row clauses, one per clause carrying a candidate
behavioral cut. Only the third discriminates; the other two are reported below as non-results
rather than dropped. A later card re-ran the same § 2c receipt paragraph on a different axis
under this protocol — § GAP-084 at the foot of this file.

- **Scenario A — § 2c gate** (the strongest a-priori candidate). A sync report whose per-section
  rows are all `✓ matches` and whose one rot row carries no resolution, handed to a model asked
  whether § 2c's gate commits or halts. Excerpts: § 2b's rot scan + § 2c's gate paragraph.
  Control's gate enumerates `⚠ drifted` / `⊕ new` / `⊘ missing` only; the arm's adds `a rot row its
  own (migrated / declined ({reason}))`. Expectation: control COMMIT → RED.
- **Scenario B — § 2b acceptance.** A rot row surfaced, the user replying either a bare `n` or
  `n — {reason}`; the model reports whether the pipeline prompts again and what resolution the
  report row records. Excerpts: the section lane's own Block 2 acceptance rule (unchanged — in the
  real file it sits six lines above the rot scan) + the rot scan paragraph. Control's acceptance is
  `y / n / per-row`; the arm's is `y / n — {reason} / per-row` plus the resolution sentence.
  Expectation: control records nothing → RED.
- **Scenario C — § 2c receipt write** (the discriminating one). A completed sync whose report
  carries one section row resolved `declined (…)` and one rot row resolved `declined (…)`; the model
  writes the receipt and reports the exact `covered` and `declined` lists. Excerpts: Phase 1's
  receipt-shape sentence (unchanged) + § 2c's receipt-write paragraph. Control's derivation
  enumerates its `declined` sources and closes with "For those two the report is the receipt's sole
  source"; the arm's adds rot rows to both `covered` and `declined` and names the row identity
  `{file} § rot:{old}`. **Axis under test** — does the rot decline reach `declined`, under a key
  that can still match on the next run, without breaking `declined ⊆ covered`. The arm excerpt is
  the byte-exact shipped paragraph.

## Findings

Run 2026-09-21, `claude -p --model haiku`, no tools, three trials per arm.

### Scenario C — § 2c receipt write (the axis that discriminates)

| Arm | Trial | rot row in `declined` | identity used | `declined ⊆ covered` |
|---|---|---|---|---|
| Control (pre-fix) | 1 | yes | `docs/overview.md:14` (line-keyed) | **violated** — absent from `covered` |
| Control | 2 | **no** — dropped | — | n/a, nothing written |
| Control | 3 | **no** — dropped | — | n/a, nothing written |
| Arm (shipped) | 1 | yes | `docs/overview.md § rot:sp-bootstrap` | held |
| Arm | 2 | yes | `docs/overview.md § rot:sp-bootstrap` | held |
| Arm | 3 | yes | `docs/overview.md § rot:sp-bootstrap` | held |

**Verdict: RED → GREEN on the axis under test.** The control reproduced both failure modes the card
predicts, and nothing else. Trials 2 and 3 dropped the rot decline entirely, each quoting the
derivation's own closed enumeration back — "`covered` is copied mechanically from the sync-report's
**per-section** rows" (trial 2) and the identity spelling `{file} § {Section}` excluding a
line-level rot finding (trial 3). That is the memory gap verbatim: the decline reaches no receipt,
so the next run's `previously declined:` has nothing to render from. Trial 1 admitted it to
`declined` but not to `covered` — breaking the `declined ⊆ covered` invariant the Phase 1 sentence
states — and keyed it `docs/overview.md:14`, a line-bearing key that cannot match across runs once
the file shifts. The arm landed the `{file} § rot:{old}` identity 3/3 with the invariant intact.

Off-axis noise, arm trials 1 and 3: `covered`'s pre-existing section-row entries came back
inconsistently spelled (`CLAUDE.md` for `CLAUDE.md § Doc Sync` in trial 3; trial 1's rationale
mis-stated the copy as being from "per-section rows" alone). Both concern the section-row spelling
that predates this fix, and each appears on a single trial.

### Scenario A — § 2c gate (no RED)

| Arm | Trial | Verdict | Cited clause |
|---|---|---|---|
| Control (pre-fix enumeration) | 1 | HALT | the rot row "does not appear in the shown report" |
| Control | 2 | HALT | "an unresolved row … halts the same way" |
| Control | 3 | HALT | same trailing clause — the rot row "carries no resolution" |
| Control (v2 prompt) | 1–3 | HALT ×3 | the same trailing "an unresolved row" clause, 3/3 |
| Arm (shipped) | 1–3 | HALT ×3 | the arm's explicit rot-row resolution requirement |

**No RED — control landed HALT 6/6 across two prompt shapes.** The gate's pre-fix sentence closes
with a generalization, "an unresolved row, or a `declined` row carrying no reason, halts the same
way", and this model reads that trailing clause as governing every row it can see rather than only
the three verdicts the sentence just enumerated. Control trial 1 of the first prompt shape also
misread the report layout, claiming the rot row was absent when it sat below the table; the v2
prompt states outright that the row is transcribed exactly as § 2b specifies, which removed that
misread and left the verdict unchanged at HALT 3/3. Reported as a non-result. The clause ships
because the enumeration it sits in is exhaustive by construction, and a reader who takes that
enumeration literally — the reading for which the `registration:` row class was already given its
own explicit entry in the same sentence — gets a gate that commits over an unresolved rot row. The
bench does not reproduce that reader at this model and prompt shape.

### Scenario B — § 2b acceptance (no RED)

| User reply | Arm | Trials | Prompts again? | Resolution recorded |
|---|---|---|---|---|
| bare `n` | Control | 1–3 | PROMPT-AGAIN ×3 | NOTHING ×3 |
| bare `n` | Arm | 1–3 | PROMPT-AGAIN ×3 | NOTHING ×3 |
| `n — {reason}` | Control | 1–3 | RESOLVE-NOW ×3 | `declined ({reason})` ×3 |
| `n — {reason}` | Arm | 1–3 | RESOLVE-NOW ×3 | `declined ({reason})` ×3 |

**No RED — control matched the arm 6/6.** Two separate things went wrong, and the honest reading is
that this scenario cannot cut. The bare-`n` pass is ill-posed: a bare `n` re-prompts under the
*shipped* wording too, so "what resolution does the row now carry" is correctly NOTHING on both
sides — the arm's own answer, not a control failure. The reason-carrying pass is the real test, and
the control answered it correctly 3/3 by generalizing the section lane's Block 2 rule — which both
arms carry verbatim, because in the real file it sits six lines above the rot scan — onto the rot
lane unprompted. Shipped anyway, on the ground [`bench/scale-fact-fields`](../scale-fact-fields/README.md)
records for the same situation: the pre-fix `y / n / per-row` was the only acceptance line in the
file capturing no reason while the gate one section away halts on a reason-less decline, and a
contradiction between two rules is patched whichever way a model happens to resolve it. No
bench-demonstrated behavioral bug for this clause.

### Coverage

Five clauses shipped; the three carrying a candidate behavioral cut were benched. Two were not: the
rot row's `previously declined:` render and its `{file} § rot:{old}` keying are the *consumers* of
Scenario C's receipt entry — with the control writing no entry at all there is nothing for a render
test to read, so that lane's confirmation belongs in the scratch-repo re-run queued alongside the
`GAP-072` item's own still-unverified render tail in [`docs/test-queue.md`](../../docs/test-queue.md).

## Post-bench revision of the shipped wording

The clauses shipped after these trials ran are not byte-identical to the arm texts above. Three
changes landed between the bench and the commit, and each is recorded here rather than folded
silently into the tables, since a trial's evidence belongs to the text it was run against.

- **Row granularity (§ 2b).** A cold dry-run of the § 2c receipt contract found the benched shape
  admitted an identity collision: two hits of one literal in one file with opposite outcomes
  collapsed to one `{file} § rot:{old}` key. The shipped text removes the collision at its source —
  one rot row now covers one literal in one file, lists its line hits for display, and takes a
  single answer. Scenario C's arm text is the § 2c receipt paragraph, which this change does not
  touch, so its RED→GREEN result stands as recorded.
- **Render-rule duplication (§ 2b).** A cold audit found the benched arm re-stating Block 2's
  three-way render rule verbatim instead of pointing at it. The shipped text points. Neither
  benched scenario turned on that clause.
- **Acceptance attribution (§ 2b).** The same audit found "Acceptance pattern matches legacy
  migration" false for the half that changed — legacy migration's prompt captures no reason at
  all. The shipped text credits the three-way shape to legacy migration and the reason capture to
  Block 2. Scenario B was a non-result either way, and its cause was the control generalizing from
  Block 2 — which this rewording now states outright, so the shipped text is if anything further
  from a RED than the benched arm was.

## GAP-084 — § 2c receipt determinacy (second run, same paragraph)

`GAP-084` put the *same* § 2c receipt-write paragraph under test on a
different axis: not whether a rot decline reaches `declined`, but whether a cold author can derive
the whole `covered` / `declined` pair from the paragraph alone — row-class membership, element
shape, and the report-row → row-identity transcode. Run under Scenario C's protocol, so it is
recorded here rather than in a new bench directory.

### Scenario D — row-class membership + identity transcode

Run 2026-09-21, `claude -p --model haiku`, no tools (`--disallowedTools` covering the full default
set), three trials per arm, cwd a neutral empty directory outside this repo (§ decontamination:
in-repo runs read the answer off CLAUDE.md and the commit log). CC 2.1.278.

Prompt: Phase 1's receipt-shape sentence (unchanged, both arms) + § 2c's **Sync report** lead,
illustrative table, and receipt-write prose (the arm variable) + one synthetic completed sync report
for the run under test, exercising all four row classes at once — a section row resolved
`declined (…)`, a section row `✓ current`, a whole-file artifact row (`AGENTS.md`) resolved
`updated`, a `registration:` row resolved `updated`, and a rot row resolved `migrated`. Output: the
exact `covered` and `declined` values, plus a per-entry rationale.

Control = the shipped-at-`0612a0c` paragraph, byte-exact. Arm = the paragraph split by concern
(`covered` / `declined` / `placed`), with the transcode named, `covered`'s element shape stated, the
`registration:` exclusion stated, the version source cross-referenced to Phase 1, and a worked
receipt example rendered from the illustrative table beside it.

Expected `covered` = the two section identities, the `AGENTS.md` path, the rot identity — four
strings, no registration entry.

| Arm | Trial | `registration:` row in `covered` | rot row in `covered` | section identity | whole-file identity |
|---|---|---|---|---|---|
| Control | 1 | **yes** — `registration: docs/outward/ → README.md docs list` | yes | `CLAUDE.md § Doc Sync` | `AGENTS.md` |
| Control | 2 | **yes** — same string | yes | correct | correct |
| Control | 3 | **yes** — same string | yes | correct | correct |
| Arm v1 | 1 | no | yes | correct | correct |
| Arm v1 | 2 | no | yes | correct | correct |
| Arm v1 | 3 | no | **dropped** | correct | correct |
| Arm v2 (shipped) | 1 | no | yes | correct | correct |
| Arm v2 | 2 | no | yes | correct | correct |
| Arm v2 | 3 | no | yes | correct | correct |

**Verdict: RED → GREEN on row-class membership.** The control admitted a `registration:` identity to
`covered` 3/3, verbatim off the report row and with a rationale line asserting it belongs — the
silence the card read two ways resolves, at this model, uniformly the wrong way. The shipped arm
excludes it 3/3, and trial 2's rationale states the rule back ("registration 列：報告專用，不計入
covered/declined").

**The worked example's omissions are read as rules — measured, not inferred.** Arm v1's example
rendered the illustrative table, which carries no rot row, and its lead-in listed only what the
example *did* contain. Trial 3 then dropped the rot row from `covered` entirely — the same
omission-as-rule failure the card's verdict predicted for `registration:`, landing instead on the
class the example happened not to show. Two changes shipped as arm v2: the `covered` clause names
all three admitted row classes positively ("its per-section rows, its whole-file artifact rows, and
its rot rows") instead of glossing them, and the example's lead-in states outright that the report it
renders has no rot row to carry. 3/3 after.

**Off-axis, honestly: the section-identity spelling did not go red here.** The card's strongest
argument for the example is the transcode — the report renders `CLAUDE.md: Doc Sync`, the identity
is `CLAUDE.md § Doc Sync` — and the off-axis note above records a trial emitting the bare filename.
Under this prompt shape the control spelled every section identity correctly 3/3, so the fix ships
on the registration axis plus the standing observation, not on a reproduced spelling failure. The
difference from the earlier note is prompt shape: Scenario D hands the model the run's own report as
a table, where Scenario C's report was narrower. The transcode clause is retained as determinacy the
paragraph owed either way — the example is what carries it — and its behavioral claim stays
unproven at this model.

The shipped § 2c text is byte-identical to the arm v2 excerpt above (trailing blank line aside).
