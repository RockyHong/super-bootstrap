# DEBT-2qm2 — `doc-sync-harness-cochange` (a2) counts a deferral phrase in a non-recommended option

**Logged:** 2026-11-09 · **Source:** GAP-drwb post-audit runs (commit `16616ce`), session-close of the same session
**Problem:** `bench/doc-sync-harness-cochange/score.sh` (a2) failed run `d1` on "Acknowledge ep-prep as accurate for now and leave it for a separate harness edit." That line is the description of an alternative AskUserQuestion option ("Row 1 only"). The recommended option landed `ep-prep` this round. (a2) reads every line that names `ep-prep`, so an offered alternative reads as the run deferring the item.
**Area:** `bench/doc-sync-harness-cochange/score.sh` (a2), `bench/doc-sync-harness-cochange/bite.sh`
**Prior:** Score (a2) on the recommended path only (prose rows plus the first / recommended option of the ask), then re-bite.

## Verdict — auto-fix · 2026-11-09

**Fix-shape:** systematic
**Probe-deps:** none
**Execution:** inline — depth: the existing item-scoping rule in `block()` / `ep_own` (fence lines stand alone, clause split on numbered rows) extended by one more filter, checked by zero-LLM `bite.sh`; closure: three files in one bench directory, no consumer outside it

### Repro (pinned)

`bench/doc-sync-harness-cochange/score.sh` (a2) failed run `d1` on "Acknowledge ep-prep as accurate for now and leave it for a separate harness edit." That line is the description of an alternative AskUserQuestion option ("Row 1 only"). The recommended option landed `ep-prep` this round.

### Root cause (verified)

- premise age: clean — no commit touched `bench/doc-sync-harness-cochange/` since 2026-11-09; the bench's last commit is `16616ce` itself, the card's source.
- The `d1` output is not kept in the repo (`run.sh:39` writes `<fixture-dir>.out.txt` outside it), so the trace is static. It holds for every shape the output can take:
  - `prompt.txt:13` makes the run print each AskUserQuestion call as a fenced ```` ```AskUserQuestion ```` block of its JSON input.
  - `score.sh:15-25` `block()`: inside a fence, every line that matches `ep-prep` is printed on its own. No line knows which option it belongs to. So an option's `"description": "Acknowledge ep-prep … separate harness edit."` line joins `$ep`.
  - `score.sh:50-54` `ep_own` drops only lines that name `clip-cut|served|foreign`. It splits by clause only when a line names `rows? [0-9]`. With "Row 1 only" on the same line, the clause "…leave it for a separate harness edit." still names `ep-prep` and stays. With "Row 1 only" on its own `"label"` line, the description line passes unfiltered.
  - `score.sh:29` `defer_re` holds `separate (harness )?edit`. `score.sh:55-56` then fails (a2) with "separate harness edit".
- The defect: (a2) scores every offered option. Its contract (README "the `ep-prep` item carries no deferral") is the run's own route. An alternative the run offers is not a route the run takes.
- Fix (implementation choice, settled here): before the `ep_own` filter, drop from the `ep-prep` lines in each ```` ```AskUserQuestion ```` fence the lines of each non-recommended option. Per question, the recommended option is the option whose `label` holds `recommend` (case-insensitive). The AskUserQuestion convention marks the pick with a `(Recommended)` label suffix, and the device `CLAUDE.md` § Ask Threshold names the same marker. When no label holds it, the first option is the recommended one. The awk must handle both one option per line set (`"label"` / `"description"` on separate lines) and compact JSON, where all options sit on one line: split that line on `"label"` before it scores. Prose rows outside the fence stay as they are, as the Prior asks. A deferral in a prose alternative still fails. That is in scope: the prompt routes every ask through the fence.
- Monotone: the change only removes lines from the (a2) input, so a reading that passed stays a pass. Only an earlier (a2) FAIL can turn into a PASS.
- Family (out of aim, for the gateway): (a1) at `score.sh:40-44` reads the same unfiltered `$ep`, and `land_re`'s `\bnow\b` matches the alternative's "for now". So (a1) can false-PASS on an offered option, which is the mirror defect. This verdict scopes to (a2) per the aligned aim. If (a1) should read the same filtered block, that is one more call site of the same filter. Re-anchor or log it. No other bench uses `defer_re` (grep over `bench/`).
- Aim: no overlapping open card (`DEBT-2bx1` is the `session-close-moves` fixture). There is no `docs/decisions.md` row on this bench or on scoring by option.

### Files (fix surface)

- `bench/doc-sync-harness-cochange/score.sh:12-25` — `block()` or a new helper: mark each ```` ```AskUserQuestion ```` line with its option index and a recommended flag, so the (a2) input can drop the lines of non-recommended options
- `bench/doc-sync-harness-cochange/score.sh:46-57` — (a2) comment and `ep_own` pipeline: score the recommended path only
- `bench/doc-sync-harness-cochange/bite.sh` — two new cases. (1) Should PASS (a2): good output plus an AskUserQuestion whose recommended option lands `ep-prep` and whose alternative's description says "leave it for a separate harness edit". Run it in both pretty and compact JSON. (2) Should FAIL (a2): the same ask with the deferral in the recommended option (`(Recommended)` label, and as a second variant the first option with no label marker). Report the induced FAIL text verbatim. The existing (a2) case at `bite.sh:35-36` must still fail.

### Doc Impact

- `bench/doc-sync-harness-cochange/README.md:37` — the (a2) assertion line: the deferral check reads the recommended path (prose plus the recommended option of each ask)
- `bench/doc-sync-harness-cochange/README.md:42` — "An item is its line…": add the option scoping for (a2)
- `bench/doc-sync-harness-cochange/README.md:49-52` — Findings: add this scorer change to the list. "Every row is scored with the final `score.sh`" is no longer provable. The walk outputs are not kept, and only earlier (a2) FAILs (the RED row, 0 of 3) could flip. The RED verdict still holds on (a3) 0 of 3 and (a1) 1 of 3. Reword the line to say so, or re-run.
- `docs/overview.md:48` (bench roster line) — read, unchanged: it names the bench's aim, not its scorer.

### Test Strategy: unit

## Amendment — 2026-11-09 · gateway, on the verdict's concern 1

Scope widens to (a1): it reads the same unfiltered `$ep`, so `land_re`'s `\bnow\b` can match "for now" in a non-recommended option and false-PASS. The card's root intention — score the run's own recommended path only — covers both assertions, so the recommended-option filter applies to (a1) and (a2) alike, with a bite case each way for (a1) too.
