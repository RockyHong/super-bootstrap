# bench/session-continue-lifecycle — RED for session-continue's hold + retire

Test surface for [`skills/session-continue/SKILL.md`](../../plugins/super-bootstrap/skills/session-continue/SKILL.md)
§ 2. Two behaviours: a carry whose next step names `not before` a later date is held out of the resume
options and named "held until YYYY-MM-DD" (card `GAP-qp6a`); carries the skill judges dead are offered
for **retire** and deleted only on the user's pick (card `GAP-pp1p`, option A). This is behavior-shaping
prose, so it ships behind the [`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor. The
new wording is tested against the HEAD wording on the same fixture.

- `make-fixture.sh <dir>` — makes a scratch repo with one initial commit that holds a `docs/work/`
  substrate (`README.md` with the `not before` contract line, plus four live cards). It also writes an
  untracked root `SESSION-STATE/` ledger of six carries, each with its mtime set back to its age:
  (a) `GAP-wt01` 4 days, Next step `not before <today+10>`; (b) `BUG-x9z1`, whose card is deleted;
  (c) `GAP-dn02` 6 days, whose card has a 2-day-old Progress recording the carry's next step as done;
  (d) `GAP-dup3-dddd4444`, a 12-day pointer stub, and `GAP-dup3-eeee5555`, 1 day old, on the same card;
  (e) `GAP-lv05` 2 days, a plain live carry. The future date goes to `.git/bench-future`. Pass an
  absolute `<dir>`.
- `prompt.txt` — the session opens with only `/super-bootstrap:session-continue` (this session's id is
  `42547892`). The arm stops where the procedure needs the user and prints what it would present.
- `run.sh <control|arm> <fixture-dir> <out-file> [model] [control-rev]` — builds the fixture, embeds the
  skill text verbatim after the prompt, runs one headless arm, writes its output, and runs `check.sh`.
- `check.sh <fixture-dir> <out-file>` — prints one PASS/FAIL line per assertion, with the output line
  that decided it.

## Protocol

Arms run headless (`claude -p --model sonnet --allowedTools Bash --setting-sources project,local --permission-prompts none`)
with the fixture as cwd and the prompt on stdin. The prompt carries the skill text verbatim, so the copy
under test is this repo's working tree, not the installed plugin.

- **Control** — `SKILL.md` at `HEAD` (pre-change, `ae609f3`), via `git show`.
- **Arm** — the working-tree `SKILL.md`.
- **Assertions** — A1: a line names `GAP-wt01` held with its date, and no option line offers to resume
  it. A free-text hint ("you can also type …") is the skill's named-label path, not an option. A2b/c/d:
  a retire line names `BUG-x9z1`, `GAP-dn02`, and the older `GAP-dup3` (`dddd4444`). A3: a resume line
  names `GAP-lv05`. A4: all six carries are still on disk with unchanged names.

## Findings

Run 2026-11-26, one fresh fixture per run, `--model sonnet`.

| Run | A1 held | A2b gone | A2c passed | A2d older dup | A3 live | A4 ledger |
|---|---|---|---|---|---|---|
| Control 1 | FAIL — wt01 in the live table, offered as a free-text resume | FAIL — "Stale, so not offered" | FAIL — live row | FAIL — both dup3 live | PASS | PASS |
| Control 2 | FAIL — wt01 in the live table, "waiting until" only in question text | FAIL — "Stale, not offered" | FAIL — live row | FAIL — both dup3 live | PASS | PASS |
| Arm 1 | PASS | PASS | PASS | PASS | PASS | PASS |
| Arm 2 | PASS | PASS | PASS | PASS | PASS | PASS |
| Arm 3 | PASS | PASS | PASS | PASS | PASS | PASS |

The result goes from RED 2/2 (the control offers the date-gated carry and the passed and duplicate
carries as live, and names the gone-card carry only as "not offered") to GREEN 3/3. All three arms
present two questions: a single-select pick with two resume options, other work and leave, and a
multi-select retire question with the three candidates. The passed candidate shows the carry's Next step
beside the card's Progress line. No run renamed or deleted a file.

The control met A3 and A4 in every run. A hand-written violating result (`GAP-lv05` claimed and
`BUG-x9z1` deleted, with no resume line) bites both assertions: `FAIL A3 resume live | no resume line for GAP-lv05:`
and `FAIL A4 ledger | GAP-dn02-cccc3333.md GAP-dup3-dddd4444.md GAP-dup3-eeee5555.md GAP-lv05-42547892.md GAP-wt01-aaaa1111.md`.
