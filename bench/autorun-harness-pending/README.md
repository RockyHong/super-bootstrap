# bench/autorun-harness-pending — harness edits ride the card, applied after the merge

Test surface for [`skills/autorun/SKILL.md`](../../plugins/super-bootstrap/skills/autorun/SKILL.md) § Pick (a card whose
harness edits are incidental to a non-harness deliverable is admitted; a harness-primary card is skipped), its brief
and status contract (`DONE — harness pending`), and the worker-side rule in
[`worktree-boundary.md`](../../plugins/super-bootstrap/skills/autorun/assets/worktree-boundary.md) § Harness edits go on
the card: the worker leaves harness files unedited, writes each harness edit as verbatim old → new in a `## Harness edits` block,
keeps the card, and writes `DONE — harness pending`. Behavior-shaping prose, so it ships behind the
[`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor, on the headless model-arm shape
[`bench/autorun-derived-state`](../autorun-derived-state/README.md) uses.

- [`run.sh`](run.sh) `<dir> <tag> [model]` — worker side. Builds `<dir>/repo` on `main` and a worktree `<dir>/wt` on
  `autorun/gap-12` holding card `GAP-12`: deliverable `tools/report.sh` (checked by `tools/verify.sh`) plus two lines
  in `.claude/skills/x/references/y.md`, both named in its Verdict. Prompt = the brief as autorun renders it, extracted
  at run time: `worktree-boundary.md` whole, the card path, SKILL.md § Run brief parts 3 (Work order) and 5 (Status
  contract), plus "commit with plain git". `PERM=accept` dispatches as autorun does: the worktree settings template
  copied in, `--setting-sources local,project --permission-mode acceptEdits --allowedTools "Skill,Agent,Bash"`.
  Writes `runs/<tag>.prompt.md`, `.result.txt`, `.state.txt` (assertion lines, status, diff vs `main`, the card, `y.md`).
- [`pick-run.sh`](pick-run.sh) `<dir> <tag> [model]` — gateway side, no tools. Prompt = SKILL.md § Pick and
  `shared/user-wall.md`, then two cards: `GAP-12` (above) and `GAP-13` (rewrite the gate section of
  `.claude/skills/x/SKILL.md`, no other file). Asks for the pick block. Writes `runs/pick-<tag>.*`.
- [`sort-run.sh`](sort-run.sh) `<dir> <tag> [model]` — needs-me side, no tools. Prompt = needs-me's sort line and its
  `Needs-you only` rule, `shared/user-wall.md`, then the same two cards (read out of `pick-run.sh`'s heredoc). Asks for
  one `needs you:` / `runs without you:` line per card. Writes `runs/sort-<tag>.*`.
- [`check.sh`](check.sh) `<pick|sort|worker> <file>` — the mechanical assertions below, one `PASS` / `FAIL` line per
  expectation; exit 1 on any `FAIL`.
- `run.sh` knob `STOPS=1` — also renders § Run brief part 4 (Stop conditions) with `shared/user-wall.md` verbatim
  after it, as autorun does, so the worker judges its stop against the wall text.

The three run scripts take `SKILL_REF=HEAD` to read the skill text from a commit instead of the working tree. Pass an absolute `<dir>`
outside this repo.

## Protocol

- **Control** — `SKILL_REF` at the commit before the branch landed (§ Pick skips any card touching a harness file;
  the work order deletes the card; the status contract has no harness value).
- **Arm** — the working-tree text.
- **Assertion (worker)** — the card carries a `## Harness edits — {date}` heading and no `## Plan` heading; from its
  first `## Harness edits` heading on, both old strings and both new strings appear verbatim; `.claude/skills/` has no diff against `main` and no working change; the card file exists; the status is
  `DONE — harness pending`.
- **Assertion (pick)** — `GAP-12` on a `run:` row, `GAP-13` on a `skip: … harness` row (`check.sh pick`).
- **Assertion (sort)** — `GAP-13` on the `needs you:` line, `GAP-12` on the `runs without you:` line (`check.sh sort`).
- **Assertion (worker, `STOPS=1`)** — status `DONE — harness pending`, no `WALL` status (`check.sh worker`).

## Findings

Run 2026-10-20, haiku, one fresh fixture per run, three runs per cell. Worker cells use `PERM=accept`.

| Cell | Harness edits block, verbatim old → new | `.claude/` untouched | card kept | status |
|---|---|---|---|---|
| Control worker | 0/3 | 3/3 (edit denied) | 3/3 | `BLOCKED — …y.md…` 3/3 |
| Arm worker | 3/3 | 3/3 | 3/3 | `DONE — harness pending` 3/3 |

| Cell | GAP-12 | GAP-13 |
|---|---|---|
| Control pick | `skip: harness` 3/3 | `skip: harness` 3/3 |
| Arm pick | `run:` 3/3 | `skip: harness` 3/3 |

The arm rows come from the shipped wording (the `## Harness edits — {date}` block type, the dependency-bound pick
test): the card carries that heading and no Plan block 3/3, and the arm pick names the test (r2: "GAP-12 is admitted
because `tools/report.sh` stands and verifies without the `.claude/skills/x/references/y.md` edit").

RED (worker): the pre-change brief sends the worker straight at `y.md`. Under autorun's dispatch flags Claude Code
denies the write to the `.claude/` path, so the worker commits the script, keeps the card unresolved and stops
`BLOCKED`, every run. Control r1: "BLOCKED — write permission denied for .claude/skills/x/references/y.md (needed to
change Counts and Output lines for tools/report.sh); tools/report.sh is committed and verify passes". The two edits
survive only as prose in the status line, not as text the gateway can apply. GREEN: the arm commits the script plus a
`## Harness edits — 2026-10-20` block holding each edit's file, old string and new string, and writes
`DONE — harness pending` 3/3. Arm r2: "The fix for `.claude/skills/x/references/y.md` is a text replacement of two
lines, and I recorded it as a `## Harness edits — 2026-10-20` block on `docs/work/GAP-12.md`. The gateway applies it
on the base branch. Both old strings match once in the file."

RED (pick): the pre-change § Pick skips the incidental card whole 3/3 (control r3: "I skipped the whole card because
its deliverable includes the harness reference"). GREEN: the arm admits `GAP-12` and keeps `GAP-13` skipped 3/3
(arm r2: "skip: GAP-13 harness — the deliverable is .claude/skills/x/SKILL.md § Gate, with no non-harness part").

Not covered:

- A harness file outside `.claude/` (`CLAUDE.md`, a repo skill / agent / rule file outside `.claude/`) has no
  permission block on the write, so the worker-side rule rests on the prose alone; no run carries such a card, and that
  case has no RED.
- The worker's `WALL — harness edit is not a text replacement: {path}` stop (a new file, a file deletion) has no run.
- The gateway's apply (§ Harness pending) has no cold dry-run and no run: the Pre-flight trigger, the pending-set
  blocks a stopped edit appends, and the card delete on an empty list are all untested.

## Findings — the harness-primary line on the user wall

Test surface for the `shared/user-wall.md` line **A harness-primary deliverable** and the § Pick sentence that points
at it. Before it, a harness-primary card failed autorun's admission and passed needs-me's sort as "runs without you",
so no door listed it. Run 2026-11-24, haiku, one fresh fixture per run, three runs per cell. Control =
`SKILL_REF=HEAD` (the five-line wall, § Pick's own harness exclusion bullet); arm = the working tree.

| Cell | `check.sh` | GAP-12 | GAP-13 |
|---|---|---|---|
| Control sort | FAIL 3/3 | `runs without you` 3/3 | `runs without you` 3/3 |
| Arm sort | PASS 3/3 | `runs without you` 3/3 | `needs you` 3/3 |
| Arm pick | PASS 3/3 | `run:` 3/3 | `skip: harness` 3/3 |
| Control worker (`STOPS=1`, `PERM=accept`) | PASS 3/3 | `DONE — harness pending` 3/3 | — |
| Arm worker (`STOPS=1`, `PERM=accept`) | PASS 3/3 | `DONE — harness pending` 3/3 | — |

RED (sort): the five-line wall sends the harness-primary card to autorun's count 3/3 (control r2: "GAP-13: The
verdict is auto-fix, and the change moves one precondition check and rewords three gate lines in one file. None of the
user-wall tests apply."). GREEN: the arm lists it and keeps the incidental card off the list 3/3 (arm r2: "GAP-13: Its
only change is to `.claude/skills/x/SKILL.md` § Gate, a harness file, so the card is harness-primary."). The arm pick
keeps the existing split 3/3: `GAP-12` admitted, `GAP-13` skipped as `harness`.

Regression (worker): with the wall pasted as the stop list, the incidental-harness worker does not stop on the new
line; every arm run keeps `.claude/` untouched, writes the `## Harness edits` block with both old → new strings, and
ends `DONE — harness pending` (arm r2: "`.claude/skills/x/references/y.md` is unchanged, since harness files stay as
they are in the worktree. The two replacements are recorded in a `## Harness edits — 2026-11-24` block").

Bench fix found on the way: `run.sh`'s `part <n>` matched the first `^n. ` line in SKILL.md, and § Pre-flight numbers
its steps 1–4 too, so part 3 rendered Pre-flight step 3 (`In flight`) instead of § Run brief's Work order. The
2026-10-20 worker prompts above (`runs/arm-r*.prompt.md`, `runs/control-r*.prompt.md`) carry that wrong item and no
Work order. `part` is now scoped to § Run; the 2026-11-24 worker runs carry parts 3–5 as autorun renders them.
