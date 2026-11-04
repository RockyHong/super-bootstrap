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
