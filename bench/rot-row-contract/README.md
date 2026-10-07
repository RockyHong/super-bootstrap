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
under this protocol — § GAP-084 at the foot of this file. Two more re-ran § 2c's commit
predicate: § Scenario E (`BUG-083`) below it, and § Scenario F after it, which corrects E's clause
and is the one the shipped text is justified against.

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

## BUG-083 — § 2c commit predicate (third run, same section)

`BUG-083` put § 2c's **commit decision** under test — not the receipt write, the one sentence that
branches the phase between committing and reporting no changes. Run under Scenario C's protocol, so
it is recorded here rather than in a new bench directory.

### Scenario E — zero-effect re-run, which branch

Run 2026-10-08, `claude -p --model haiku`, no tools (`--disallowedTools` over the full default set,
`--strict-mcp-config`), prompt on stdin, three trials per arm, cwd a neutral empty directory outside
this repo (§ decontamination). CC 2.1.292.

Prompt (both arms, held identical but for the clause under test —
[`scenario-e-prompt-control.txt`](scenario-e-prompt-control.txt) ·
[`scenario-e-prompt-arm.txt`](scenario-e-prompt-arm.txt)): § 2b's drift-check paragraph, § 2c's
gate, § 2c's receipt-write lead, **the commit-decision clause (the variable)**, the stage list, and
§ 2c's run-artifact cleanup — then one run's state and a forced three-way answer
(`VERDICT: COMMIT | SKIP | NEITHER`, plus the clause decided on and a one-line why).

The run put in front of both arms is the measured one: a re-run whose only non-`✓ current` row is
`AGENTS.md` `⚠ drifted` resolved `declined ({reason})` from the prior run, no file written this run,
the receipt overwritten byte-identical (`git diff` on it empty), and
`.claude/bootstrap-sync-report.md` present and untracked in the working tree at the moment the
predicate is read.

**Axis under test** — does the predicate route a zero-effect re-run to a named branch. Correct
behavior is `SKIP`: the downstream text names exactly two outcomes ("After the commit lands (or
after reporting no-changes)", Phase 3's "After committing (or reporting no changes needed)"), and
the otherwise-branch is a dead end because `/super-bootstrap:commit` has nothing to stage.

Control = the pre-fix sentence, byte-exact: "If every row is `✓ current` and nothing changed on
disk, report and skip the commit." Arm = the effect-keyed rewrite, scoped to § 2c's own stage list.

Pre-registered before any arm ran, scored mechanically off each trial's first `VERDICT:` line and
nothing else ([`score-scenario-e.sh`](score-scenario-e.sh)): **RED** iff the control emits a
non-`SKIP` verdict on ≥ 2 of 3 trials; **GREEN** iff the arm emits `SKIP` 3 of 3. A control reaching
`SKIP` on ≥ 2 of 3 was pre-declared a non-red control — the clause would not ship on this bench.

| Arm | Trial | Verdict | Clause decided on |
|---|---|---|---|
| Control (pre-fix) | 1 | **COMMIT** | the otherwise-branch — "not every row is ✓ current … so the condition to skip the commit is not satisfied" |
| Control | 2 | SKIP | the skip clause, overridden — "no actual changes to stage or commit **despite** the drifted AGENTS.md row" |
| Control | 3 | **COMMIT** | the otherwise-branch — "not every row is `✓ current`; the skip condition is unmet" |
| Arm (shipped) | 1 | SKIP | the arm's effect clause, with the no-op rows and the byte-identical receipt named |
| Arm | 2 | SKIP | same clause — "no paths in the stage list carry uncommitted changes" |
| Arm | 3 | SKIP | same clause |

**Verdict: RED → GREEN on the branch the predicate selects.** Control non-`SKIP` 2/3 clears the
pre-registered RED gate; arm `SKIP` 3/3 clears GREEN. Both control failures land on conjunct 1
exactly as the card predicts — each quotes the verdict column back ("not every row is `✓ current`")
and falls to the otherwise-branch, whose stage set is empty, so the phase routes into
`/super-bootstrap:commit` with nothing to commit.

**The one control trial that reached the right branch did not reach it through the clause.** Trial
2's own rationale carries the concession — it skips "despite the drifted AGENTS.md row", i.e. it
overrode the predicate rather than satisfying it, and it reads "nothing changed on disk" as the
receipt's `git diff` alone while the untracked sync report sits in the tree. The pre-registration
scores the verdict line only, so trial 2 counts as a control pass and is reported as one; what it
demonstrates is the failure mode the card names at the other end — the run completes because the
executor picks a branch the text does not name.

**Conjunct 2 stayed off-axis.** No trial on either arm cited `.claude/bootstrap-sync-report.md` as
the working-tree change that makes the pre-fix "nothing changed on disk" false on every re-run. The
scoping half of the fix therefore ships on the file's own reading — § 2b writes the report before
Block 1 and § 2c deletes it only after this step, so it is present whenever the predicate is read,
and no runway-written `.gitignore` line covers it — not on a reproduced failure at this model and
prompt shape. Recorded as unproven rather than dropped: both halves sit in one sentence, and the
rewrite that removes conjunct 1 is the same edit that scopes conjunct 2.

This scenario's arm wording is **not** what ships. A cold `audit-harness-edits` probe found it
under-scoped after this run, and § Scenario F below re-ran the clause with the missing case in the
state block and landed the corrected text. Scenario E stands as the first pass and the record of what
it could not see; the shipped clause is justified against Scenario F.

### Scenario F — same predicate, with a pre-existing dirty stage-list path

**Pre-registered 2026-10-08, before any arm ran.** Scenario E landed a clause that a cold
`audit-harness-edits` probe then found under-scoped: "carries an uncommitted change" is attributed to
the working tree, not to the run, so a stage-list path already dirty before the run (a consumer's
hand edit this run declined, or another session's work in a shared checkout) satisfies it and turns a
no-op sync into a commit — one that then halts at the commit door's own index readback on a path
outside the session file list. Scenario E could not see it: its state block never put a pre-existing
dirty path in the tree. Scenario F adds exactly that fact and nothing else.

**Axis.** Does the predicate route a zero-effect re-run to `SKIP` when a stage-list path carries an
uncommitted hand edit that predates the run and that this run declined?

**Three arms, one variable.** Line 19 of the prompt — the clause under test — is the only difference
between the three files; every other excerpt and the whole state block are byte-identical across
arms (`diff` verified before the runs).

- **Control** — the pre-fix wording ([`scenario-f-prompt-control.txt`](scenario-f-prompt-control.txt)).
- **Arm v1** — the wording Scenario E shipped, i.e. the text the audit found under-scoped
  ([`scenario-f-prompt-armv1.txt`](scenario-f-prompt-armv1.txt)). This arm exists to test the
  **finding itself**: Scenario E's record states conjunct-scoping as unproven behaviorally, and the
  audit's case was never measured. If v1 goes non-`SKIP` here, the finding stops resting on a reading.
- **Arm v2** — the corrected wording, bound to this run's effect
  ([`scenario-f-prompt-armv2.txt`](scenario-f-prompt-armv2.txt)).

**Protocol.** `claude -p --model haiku`, no tools (`--disallowedTools` over the full default set,
`--strict-mcp-config`), prompt on stdin, three trials per arm, cwd a neutral empty directory outside
this repo (§ decontamination). Forced output: first line `VERDICT: COMMIT | SKIP | NEITHER`.

**Correct verdict: `SKIP`.** The run wrote nothing, deleted nothing, and the receipt came out
byte-identical; the only dirty path is the consumer's own edit, which is not the run's effect.

**Gates, fixed before the runs.**

| Gate | Condition | Consequence |
|---|---|---|
| RED | control emits non-`SKIP` on ≥ 2/3 | the scenario discriminates |
| FINDING | arm v1 emits non-`SKIP` on ≥ 2/3 | the audit finding is reproduced behaviorally |
| GREEN | arm v2 emits `SKIP` on 3/3 | the corrected clause ships |

- Control `SKIP` ≥ 2/3 → **non-red control**: do not land, return the call to the gateway.
- Arm v1 `SKIP` ≥ 2/3 → the finding is **not** behaviorally reproduced at this model and prompt
  shape. It still stands on the file's own reading (the stage list's `CLAUDE.md` entry reads
  `(new, modified, or post-migration)`, which a declined hand edit satisfies), so v2 still ships —
  recorded as unproven behaviorally, the way Scenario E recorded conjunct 2.
- Arm v2 anything but `SKIP` 3/3 → **do not land the corrected prose**; return to the gateway.

**Scoring.** `score-scenario-f.sh <runs-dir>` reads the first `VERDICT:` line of each trial and
nothing else. No post-hoc rescoring; the gates above are not revised after seeing results.

**Result.** Run 2026-10-08, protocol as pre-registered above. CC 2.1.292. Exact deny list passed:
`Bash,Read,Edit,Write,Glob,Grep,WebFetch,WebSearch,Task,Agent,NotebookEdit,TodoWrite,SlashCommand,Skill,KillShell,BashOutput,Artifact`
— `SlashCommand` matched no tool and was reported as such by the CLI; every other entry took effect,
so the arms ran tool-less as intended.

| Arm | Trial 1 | Trial 2 | Trial 3 |
|---|---|---|---|
| Control (pre-fix) | **COMMIT** | **COMMIT** | **COMMIT** |
| Arm v1 (Scenario E's shipped wording) | SKIP | SKIP | SKIP |
| Arm v2 (corrected, run-scoped) | SKIP | SKIP | SKIP |

`PASS: RED held (control non-SKIP 3/3), GREEN held (arm v2 SKIP 3/3).`

**RED is cleaner here than in Scenario E** — 3/3 against E's 2/3. Adding the pre-existing dirty path
removes the escape E's control trial 2 took: with a stage-list path visibly modified, "nothing changed
on disk" is unambiguously false, so the pre-fix wording commits every time. Scenario F is the stronger
discriminator for this clause and is the one the shipped text is justified against.

**The audit finding did not reproduce behaviorally — and the arms say why.** Arm v1 carries the
wording the cold probe called under-scoped, and it answered `SKIP` 3/3. Its own rationales supply the
limiting term the text omits:

- v1 trial 1 — "AGENTS.md's decline carries no changes **from this run**"
- v1 trial 2 — "no files in the stage list carry changes **introduced by this run**"

The text says "carries an uncommitted change"; the reader added "by this run". So the finding is real
as an omission and wrong as a prediction of behavior at this model and prompt shape: the correct
branch was reached by inference the clause does not license, which is the same shape as Scenario E's
control trial 2 reaching the right branch by overriding its clause. Recorded, not scored — the
pre-registration fixed `FINDING` as a report line, not a landing gate, precisely so this outcome could
not be read as a refutation after the fact.

**Arm v2 ships anyway, and the reason is not the measurement.** v2 states the scope the clause was
relying on a reader to supply. Its rationale quotes the term directly ("If this run wrote or deleted
no path in the stage list below"), so the right answer no longer depends on the reader's inference.
The literal-reading exposure stands on the file: the stage list's `CLAUDE.md` entry reads
`(new, modified, or post-migration)`, which a declined consumer hand edit satisfies, and nothing in
the v1 wording excludes it.

The shipped § 2c clause is byte-identical to the arm-v2 excerpt in
[`scenario-f-prompt-armv2.txt`](scenario-f-prompt-armv2.txt) (verified after landing).

**Second pass — arm v3, pre-registered 2026-10-08 before it ran.** Arm v2 never shipped. A second
cold `audit-harness-edits` pass on it returned two confirmed defects, both in the wording the
dispatcher had authored:

1. **The predicate could never be satisfied.** It read "If this run wrote or deleted no path in the
   stage list below — the receipt write above included". Line 579 writes the receipt on *every* sync
   ("fresh install writes it new, re-run overwrites whole" — re-Read and confirmed), and v2 counted
   that write explicitly, so a literal reader never reaches the skip branch. Only the trailing
   illustration ("over a byte-identical receipt") rescued the case, and an illustration is not a
   predicate.
2. **The trailing clause asserted something false.** "no row there reads `✓ current`" claims a fact
   about the skip side, but an all-`✓ current` run over an unchanged receipt also belongs on the skip
   side, and there every row reads `✓ current`.

Arm v3 keys the predicate on **changed bytes** and drops the trailing sentence entirely. That also
dissolves the bind the no-op list was caught in — v2 wrote "and others of that kind" to avoid the
closed-list omission GAP-084 measured, which the audit then read as a fuzzy bound. With the predicate
on bytes, the resolution vocabulary is not load-bearing at all: a `declined` row, a `kept (fork)`, a
`registration:` row `none` and anything else that writes nothing all change no bytes, so none of them
needs naming.

Gate for this pass, fixed before the run: **arm v3 emits `SKIP` 3/3, or the prose does not land.**
Control and arms v1 / v2 are not re-run; their trials above stand as recorded.

| Case | Expected | Why |
|---|---|---|
| declined drift, nothing written, receipt byte-identical | SKIP | no stage-list bytes changed |
| the same, plus a pre-existing uncommitted hand edit | SKIP | the edit predates the run |
| all rows `✓ current`, receipt byte-identical | SKIP | no stage-list bytes changed |
| all rows `✓ current`, plugin version bumped | COMMIT | the receipt's bytes changed |
| fresh install | COMMIT | every placed path's bytes changed |

**Arm v3 result.** Run 2026-10-08, same protocol; the deny list dropped the bogus `SlashCommand`
entry the first pass reported as matching no tool.

| Arm | Trial 1 | Trial 2 | Trial 3 |
|---|---|---|---|
| Arm v3 (shipped) | SKIP | SKIP | SKIP |

`PASS: RED held (control non-SKIP 3/3), GREEN held (arm v3 SKIP 3/3).`

**The clause is now the reason, not the reader's inference.** All three v3 trials quote the predicate
itself and give the byte comparison as the ground — "The receipt was overwritten but is byte-identical
to its prior committed version; AGENTS.md was declined and not written" (t1); "no other stage-list
files were modified by this run" (t2, t3). That is the difference the arm was for: v1 reached the same
verdict only by supplying "by this run" itself, and v3 states it.

**What this pass cost, recorded so the shape is visible.** Two of the three wordings the dispatcher
authored carried a defect a cold audit caught — v2's predicate could not be satisfied at all, and its
trailing clause asserted something false about the skip side. Neither was caught by the bench: v2
scored `SKIP` 3/3 on the same scenario that v3 did. A micro-test on one scenario confirms the branch
an arm reaches; it does not confirm the clause is sound, and here the model's willingness to repair a
broken predicate hid the break. The audit, not the bench, is what held this line.

The shipped § 2c clause is byte-identical to the arm-v3 excerpt in
[`scenario-f-prompt-armv3.txt`](scenario-f-prompt-armv3.txt) (verified after landing).
