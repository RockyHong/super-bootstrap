# GAP-mpv7 — A § Rules bullet left stale by an earlier sync has no row that names it

**Logged:** 2026-11-20 · **Source:** DEBT-w0xk build report (gateway session) — `bench/rule-paths-cochange/README.md` Declared bounds 3
**Problem:** The `paths:` co-change only fires on a placed doc rule's drift row. A repo whose rule file an earlier sync already moved to the current skeleton entries (e.g. `README.md` → `/README.md`) gets no drift row on the next run, so its consumer `CLAUDE.md` § Rules bullet that still restates the old fires-on list is never named and stays stale. The reporting ComfyUI `workflows/agent` repo likely sits in this state (migration, then a regular sync).
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` § 2b Per-doc handling; `assets/rule-paths-coverage.sh`
**Prior:** A re-run compares each placed doc rule's § Rules bullet against its current `paths:` even when the rule file is current (a `rule-paths-coverage.sh` mode, DEBT-w0xk Verdict option C).

## Verdict — surface · 2026-11-20

### Findings

- premise age: 4 commits touched the Area paths on the observation date (2026-11-20, the DEBT-w0xk build report). 17e96c1 is the DEBT-w0xk fix itself; its message lists this gap as "Not covered", so it confirms the premise rather than overturning it. bfef850 (doc preambles, retired artifacts) touches no § Rules bullet lane. f482b23 (language-server pins) and 32c915e (rot scan) predate the card's logging (60eab60) and touch neither lane.
- root cause (gap confirmed against current code): the only lane that may name a placed doc rule's `CLAUDE.md` § Rules bullet rides that rule's `paths:` drift row.
  - `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md:476`: the co-change fires only "when the row changes the skeleton's own entries". A rule file already on the current skeleton entries produces no row, so the clause never runs.
  - `SKILL.md:480` ("Exists, current" → `✓ current`) carries no § Rules comparison. `SKILL.md:311` and `:475` allow no other write to `CLAUDE.md`. `SKILL.md:278` (Registration rule) fires only on a first placement or a deletion.
  - Direct evidence: `bench/rule-paths-cochange/README.md` Scenario 2 holds the stale `dimension-discipline` bullet beside a current rule file. Both arms answer `CO-CHANGE: NONE`, `CLAUDE_WRITES: NONE` 3/3. Declared bound 3 names the gap.
  - `assets/rule-paths-coverage.sh` reads only rule frontmatter and `.claude/doc-surface` (lines 41-42). It does not read `CLAUDE.md` and does not cause the gap.
- aim: no duplicate among open cards (`DEBT-ymdg` only). `DEBT-ymdg` keeps § Rules summary ownership open (lines 25, 92; lean "project"). The DEBT-w0xk Design (in git at `8d97cee`, card deleted by 17e96c1) settled that a re-run may rewrite a placed doc rule's own § Rules bullet. It held whichever way `DEBT-ymdg` settles, because the write stays row-named and approved. No `docs/decisions.md` row closes this fork.
- scope reach:
  - `SKILL.md:476`: the drift bullet's co-change clause. It becomes one general comparison, or the drift case of one.
  - `SKILL.md:480`: the "Exists, current" bullet. Its per-section comparison lines gain a `[§ Rules bullet] ✓ matches` line, so a skipped check is visible.
  - `SKILL.md:311`, `:475`: the `CLAUDE.md` write exceptions.
  - `SKILL.md:736-740`: the receipt `covered` / `declined` identity for a new row class (for example `CLAUDE.md § Rules: {rule}`). A declined row needs an anchor so it does not re-fire every run.
  - `SKILL.md:746`: the stage-list trigger for `CLAUDE.md`.
  - `docs/specs/harness-architecture.md:390-392` and `README.md:84`: both bound the bullet rewrite to "an approved `paths:` drift row".
  - `bench/rule-paths-cochange/` (README, `scenario-2.md`): the Scenario 2 guard currently asserts that the run leaves this bullet alone. Under option A it flips to the RED. New guards are needed: a matching bullet gets no row, a gloss-only difference gets no row, an absent bullet gets no row (planting stays the Registration rule's job).
  - Unchanged after read: `assets/rule-paths-coverage.sh`, `tests/rule-paths-coverage.test.sh` (under A or B), `assets/claude-md-skeleton.md`, and this repo's own `CLAUDE.md` (already `/README.md` (root)).
- attempted: static read of the per-doc, registration, ownership, receipt and coverage lanes, plus the DEBT-w0xk verdict and design and the bench. Stopped at the fork below. The fix adds a run-initiated write to a project-owned file with no rule-file drift behind it. That is a runtime behavior change that the spec (`harness-architecture.md:390-392`) and `README.md:84` state narrower today. Under the spec-touch calibration (condition b), that is not auto-fix.
- excluded as bias input: the card's `**Prior:**` (a script-mode fix lean). It was weighed only as option C below.

### Decision needed

- When a placed doc rule's file is current but its `CLAUDE.md` § Rules bullet restates a fires-on list that differs from the rule's skeleton entries, what does a re-run do?
- options:
  - A. Own row, written on approval. Every re-run compares each placed doc rule's bullet against the rule's current skeleton entries, whether the rule file drifted or not. The comparison is entry by entry, glosses ignored, consumer-tail entries kept. A mismatch earns its own `⚠ drifted` row. Block 2 shows the bullet before and after. Approval rewrites only that bullet's skeleton entries. Decline lands in `declined` with an anchor. The existing drift-row co-change folds into the same comparison. The write boundary widens from "on a `paths:` drift row" to "on that rule's approved bullet row". The spec and `README.md:84` move with it.
  - B. Advisory only. The same comparison prints a Phase 3 line, in the shape of § Doc-rule coverage (`SKILL.md:813`): the stale bullet plus the corrected fires-on list, for the consumer to edit. The `CLAUDE.md` write boundary does not change and the spec stays as it is. The bullet stays stale until the consumer acts, and the line repeats every run until then.
  - C. A mechanical detector. A new `rule-paths-coverage.sh` mode parses the § Rules bullets and prints mismatches, and A or B consumes its output. This is an add-on to A or B, not a third resolution. It adds a parser for consumer-authored prose and a test file.
- recommendation: A, with the detection written in prose and no C. A is the DEBT-w0xk Design's action (row-named, per-row approval, one line of the artifact the row names) applied to the case its trigger missed. The bench shows the prose entry-by-entry match holds 3/3 on haiku (Scenarios 1 and 3). The visible `[§ Rules bullet] ✓ matches` line covers the silent-skip risk that C would otherwise address. The DEBT-w0xk Design deferred C until a consumer-worded bullet defeats the prose match, and none has been observed.
- settles by: authority on the re-run's `CLAUDE.md` write boundary (a product / boundary call). The author's own ruling settles it, or the gateway under a standing delegation, as the DEBT-w0xk Design did (precedent at `8d97cee`). Once ruled, the build is behavior-shaping skill prose, so the `skill-authoring` RED floor applies. Size: `phased build`. Extend `bench/rule-paths-cochange/`: flip Scenario 2 to the RED and add the guards listed above. Then run the headless `claude -p --model haiku` control/arm trials, 3 per arm, per the bench's Protocol.

## Design — 2026-11-20 · gateway, under the author's standing delegation ("your lean best downstream 做完吧")

Option A, detection in prose, no C. Every re-run compares each placed doc rule's `CLAUDE.md` § Rules bullet against the rule's current skeleton `paths:` entries, whether the rule file drifted or not: entry by entry, glosses ignored, consumer-tail entries kept. A mismatch earns its own row, approval rewrites only that bullet's skeleton entries, a decline lands in the receipt's `declined` with an anchor so it does not re-fire. The drift-row co-change folds into the same comparison. A match prints a visible `[§ Rules bullet] ✓ matches` line. An absent bullet earns no row (planting stays the Registration rule's). The write boundary widens from "an approved `paths:` drift row" to "that rule's approved bullet row"; spec `harness-architecture.md` and `README.md` move with it. Settling source: the Verdict's recommendation, ruled by the gateway under the author's delegation, precedent the DEBT-w0xk Design (`8d97cee`).
