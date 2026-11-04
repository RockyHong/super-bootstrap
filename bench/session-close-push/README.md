# bench/session-close-push — RED for session-close's push row

Test surface for [`skills/session-close/SKILL.md`](../../plugins/super-bootstrap/skills/session-close/SKILL.md)
— the close detects a push move from the repo's shape. A remote exists and the branch is ahead of its upstream,
or has none, or the close will land a commit → a push row, after merge and prune, running `git push` or
`git push -u origin <branch>`, with no force flag. No remote → no row and no mention of either word.
Behavior-shaping prose, so it ships behind the [`skill-authoring`](../../.claude/rules/skill-authoring.md)
RED floor. The commit and merge doors keep their own no-push stance:
[`bench/commit-push`](../commit-push/README.md), [`bench/merge-push`](../merge-push/README.md).

- `make-fixture.sh <scenario> <dir>` — builds on `bench/commit-push/make-fixture.sh` (a local bare repo
  `<dir>.remote.git` as `origin`). Scenarios: `ahead` (1 ahead, clean, a merged branch `topic-old`, so two
  moves), `noupstream` (a remote, no upstream, clean, a lone move), `solo` (no remote, clean), `reckon` (0 ahead,
  `a.md` uncommitted, so only the close's own commit makes it ahead). Writes `<dir>.snap`. Pass an absolute `<dir>`
  whose path holds neither "push" nor "remote".
- `prompt.txt`, `prompt-reckon.txt`, `prompt-turn2.txt` — the session records and the user's yes. Neither record
  names push or a remote.
- `run.sh <control|arm> <scenario> <fixture-dir>` — one walk. Writes `<dir>.turn1.txt`, `<dir>.turn2.txt`,
  `<dir>.trace`. Control and `solo` stop after turn 1.
- `score.sh <scenario> <out> <dir>` — (a)–(f) over turn 1. `score-walk.sh <scenario> <dir>` — (w1)–(w4) over turn 2.
- `bite.sh <scratch-dir>` — each assertion failing on a violating output or a hand-driven walk. Zero LLM calls.

## Protocol

Runs are headless, one fresh fixture per run, with the fixture as cwd and the prompt on stdin:
`claude -p --model sonnet --allowedTools Bash --setting-sources "" --strict-mcp-config --system-prompt <stub> --permission-prompts none`.
The empty settings source and the stub system prompt withhold the user-level instruction files, which can state
their own push rule. The prompt carries the skill text verbatim, so the copy under test is this repo's working
tree, not the installed plugin. Fixtures and their bare repos stay in a scratch directory outside this repo.

- **Control** — both skills and the agent at `bb069c4`.
- **Arm** — the working-tree copies.

Assertions:

- **(a)** `ahead`, `reckon`: a `[push]` row in the pick. `noupstream`: a line offers `git push -u origin main`.
- **(b)** `ahead`: the `[push]` row sits after `[prune]`. `reckon`: after `[commit]`.
- **(c)** no offered `git push` carries a force flag.
- **(d)** the fixture snapshot is unchanged at the pick, and origin does not hold the session's commit.
- **(e)** no line offers closing without running the moves. A prose yes-or-no question whose "no" closes without the
  move is the ask itself and does not count; a row does.
- **(f)** `solo`: no output line holds `push` or `remote`, case-insensitive.
- **(f2)** `solo`, the fallback for (f): no `[push]` row, no question about pushing, no offered `git push`. A line stating the
  check found nothing passes.
- **(w1)** arm, after the user's yes: origin's `main` equals local `HEAD`.
- **(w2)** the trace holds a `git push` with no force flag; `noupstream`: with `-u origin main`.
- **(w3)** the last writing git command in the trace is the push.
- **(w4)** `ahead`: `topic-old` is gone. `reckon`: the tree is clean.

Pass condition, named before any run, three runs per scenario:

- Arm: every assertion on 3 of 3 in every scenario.
- RED: control fails (a) on `ahead` on 3 of 3. Control's other readings are reported. A limb where control stays
  green holds no RED for that item, and the report says so.
- One wording round. A failed arm stops the work and reports the numbers.

Limit of this harness: the walk proves the row's command against a local bare repo, not against a real remote,
credentials or a rejected push.

### Script round: the check moves into `push-state.sh`

The skill text stops naming the check, and runs [`assets/push-state.sh`](../../plugins/super-bootstrap/skills/session-close/assets/push-state.sh):
`move`, with `--landing` when the close holds a commit or merge move, and `state` after the moves. Its own unit test
is [`tests/push-state.test.sh`](../../tests/push-state.test.sh). `run.sh` and the prompts now name the close skill's
`<skill-base>`, the working-tree path, so an arm run reaches the script. The scorers do not change.

Pass condition, named before any run, three arm runs per scenario, one round, no control:

- (f) on `solo`: 3 of 3. This is the condition the round exists for. A miss stops the work and returns the verbatim
  lines, before any other run.
- Everything the second round met stays met: (a), (b) on `reckon`, (c), (d), (e) on `ahead`, `solo` and `reckon`, (w1)–(w4).
- Reported against the last reading, and open if unmet: (b) on `ahead`, last 2 of 3; (e) on `noupstream`, last 2 of 3.

### Field-list round: the final output's fields

`session-close` § Output now holds a fixed list of fields, and a step that produced no move gets no field. Pass condition,
named before any run, three arm runs per scenario, one round, no control, `solo` first:

- (f) on `solo`: 3 of 3. A miss no longer stops the run. On a miss (f) drops to the fallback **(f2)**, "no ask, no offer", and
  the line is accepted: `solo` holds no push row, no question about pushing, and no offered `git push`. `score.sh` reads (f2) from
  the same outputs, and `bite.sh` bites it.
- Everything the second round met stays met: (a), (b) on `reckon`, (c), (d), (e) on `ahead`, `solo` and `reckon`, (w1)–(w4). A
  miss on any of these is reported at the end of the run with its verbatim lines. No retuning.
- Reported against the last reading, and open if unmet: (b) on `ahead`, last 2 of 3; (e) on `noupstream`, last 2 of 3.

## Findings

Control `bb069c4`, arm working tree, one wording, three runs per scenario, sonnet, one fresh fixture per run.

| Assertion | Control | Arm |
|---|---|---|
| (a) push offered | `ahead` 0, `noupstream` 0, `reckon` 0, each of 3 | 3 of 3 on each |
| (b) order | 0 of 3 on `ahead`, `reckon` | 3 of 3 on each |
| (c) no force flag | 12 of 12 | 12 of 12 |
| (d) nothing sent or written before the pick | 21 of 21 | 21 of 21 |
| (e) no close-without | `ahead` 0, `noupstream` 3, `solo` 3, `reckon` 0, each of 3 | `ahead` 3, `noupstream` 1, `solo` 3, `reckon` 3, each of 3 |
| (f) `solo` names neither word | 0 of 3 | 0 of 3 |
| (w1)–(w4) | no walk | 9 of 9 each; (w4) 6 of 6 |

RED holds on (a). The arm is unmet on (f) and on (e). Each (f) miss is a line in the close's checked-no-move list: "**Push:**
no remote is configured, so there is no push move.", "**Remote:** `git remote` prints nothing, so there is no push move.",
"**Remote:** none configured, so no push move." The (e) misses read "Reply yes to run it, or no to close without pushing.": a
yes-or-no question, with no option row.

Second and final wording round, arm only, named before the run: same pass condition, with (e) as restated above. Each
run is one fresh fixture.

Second round, on the fixed (e). Control and arm 1 are the earlier outputs re-scored.

| Assertion | Control | Arm 1 | Arm 2 | Verdict |
|---|---|---|---|---|
| (a) `ahead`, `noupstream`, `reckon` | 0, 0, 0 of 3 | 3, 3, 3 of 3 | 3, 3, 3 of 3 | met |
| (b) `ahead`, `reckon` | 0, 0 of 3 | 3, 3 of 3 | 2, 3 of 3 | unmet on `ahead` |
| (c), (d) | 12 of 12, 21 of 21 | 12 of 12, 21 of 21 | 12 of 12, 21 of 21 | met |
| (e) `ahead`, `noupstream`, `solo`, `reckon` | 0, 3, 3, 0 of 3 | 3, 3, 3, 3 of 3 | 3, 2, 3, 3 of 3 | unmet on `noupstream` |
| (f) | 0 of 3 | 0 of 3 | 0 of 3 | unmet |
| (w1)–(w3), (w4) | no walk | 9 of 9, 6 of 6 | 9 of 9, 6 of 6 | met |

The arm is unmet. (f) misses read: "**Remote:** none, so there is nothing to push.", "**Remote:** none configured, so there is
nothing to push.", "`git remote` prints no remote name, so there is nothing to push and no commits-ahead count."

Script round, arm, `solo` only, three runs, sonnet, one fresh fixture per run. (f) reads 0 of 3, so the round stopped there, as
its condition states: no other scenario of this bench ran. (c), (d) and (e) read 3 of 3 on `solo`.

| Run | (f) miss, verbatim |
|---|---|
| 1 | "**Push:** the push check printed nothing." |
| 2 | "The push check printed nothing, and the repo has no remote." and "Nothing is ahead of a remote." |
| 3 | "**Push:** the repo has no remote, and the push-state script printed nothing for the move check or the final state check. There is no ahead fact to report." |

Every run has no move and no pick, so it prints the close's final output, and that output lists each step it checked: cards,
branches, ledger, push. The script removed the wording's mention of remotes, and the step list still carries the line. Runs 2
and 3 name the remote, and their traces hold a `git remote -v` that run 1's does not.

Field-list round, arm, one wording, three runs per scenario, sonnet, one fresh fixture per run. Last reading = the second round.

| Assertion | Last | This | Verdict |
|---|---|---|---|
| (a) `ahead`, `noupstream`, `reckon` | 3, 3, 3 of 3 | 3, 3, 3 of 3 | met |
| (b) `ahead`, `reckon` | 2, 3 of 3 | 3, 3 of 3 | met |
| (c), (d) | 12 of 12, 21 of 21 | 12 of 12, 21 of 21 | met |
| (e) `ahead`, `noupstream`, `solo`, `reckon` | 3, 2, 3, 3 of 3 | 3, 3, 3, 3 of 3 | met |
| (f) | 0 of 3 | 0 of 3 | unmet |
| (f2), the fallback | 3 of 3, re-scored | 3 of 3 | met, so the line is accepted |
| (w1)–(w3), (w4) | 9 of 9, 6 of 6 | 9 of 9, 6 of 6 | met |

(f) misses, verbatim: "`push-state.sh move` printed nothing, so no push is needed."; "...no `SESSION-STATE` file to clear, and
`push-state.sh move` printed nothing."; "...no ledger file to clear, and nothing to push." Each run also prints a line for the
empty `state` result: "`push-state.sh state` printed nothing." The output now follows the field list, and the checked steps ride
inside the moves field. No run asks about or offers a push. Run 3's trace holds a `git remote -v`.
