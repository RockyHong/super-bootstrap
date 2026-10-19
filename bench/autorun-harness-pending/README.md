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

Both take `SKILL_REF=HEAD` to read the skill text from a commit instead of the working tree. Pass an absolute `<dir>`
outside this repo.

## Protocol

- **Control** — `SKILL_REF` at the commit before the branch landed (§ Pick skips any card touching a harness file;
  the work order deletes the card; the status contract has no harness value).
- **Arm** — the working-tree text.
- **Assertion (worker)** — the card carries a `## Harness edits — {date}` heading and no `## Plan` heading; from its
  first `## Harness edits` heading on, both old strings and both new strings appear verbatim; `.claude/skills/` has no diff against `main` and no working change; the card file exists; the status is
  `DONE — harness pending`.
- **Assertion (pick)** — `GAP-12` on a `run:` row, `GAP-13` on a `skip: … harness` row.

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
