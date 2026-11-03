# bench/session-close-moves — RED and walk for what a close's pick lands

Test surface for [`skills/session-close/SKILL.md`](../../plugins/super-bootstrap/skills/session-close/SKILL.md)
steps 2–4 and for the § Session-close entries and § 5 of
[`skills/commit/SKILL.md`](../../plugins/super-bootstrap/skills/commit/SKILL.md). One pick can drive several
commits, each with its own part of the session list. A resolve row carries its outcome. A move that writes
the tree brings a commit move and the door's judgment with it, even when the session changed nothing itself.
Behavior-shaping prose, so it ships behind the [`skill-authoring`](../../.claude/rules/skill-authoring.md)
RED floor. Sibling bench for the pre-pick judgment: [`session-close-judgment`](../session-close-judgment/README.md).

## Fixture

- `fixture/base/` — the `brindle` cabinet repo. `config/cabinet.toml` sets `seal_check_days = 14` and
  `outage_report_max_retries = 5`. `docs/maintenance.md` says 30 days; `README.md` says "monthly" and links it.
  `docs/recovery.md` states no retry cap; `docs/console.md` links it and says a report "keeps retrying until it
  succeeds". Open cards: `BUG-rt51` (every Plan step done, outcome in no doc), `BUG-sd22` (every Plan step done,
  outcome stated in `docs/operations.md`), `GAP-ff03` (in motion).
- `fixture/session/` — the `full` scenario's session work: `docs/operations.md` modified, `docs/shutdown.md` new.
- `prompt-{head,full,resolve,fixnow,tail,turn2}.txt` — the session records and the second turn. The other writer's
  files are named nowhere in a prompt.
- `make-fixture.sh <scenario> <dir>` — builds the repo with plumbing, with another writer's staged
  `notes/supplier.md` and dirty `notes/rota.md`, and writes `<dir>.snap`, `<dir>.foreign` and `<dir>.base`.
- `run.sh <control|arm> <scenario> <dir>` — one two-turn walk: turn 1 stops at the pick, turn 2
  (`claude -p --continue`) runs every row. Records every git command in `<dir>.trace` through `GIT_TRACE`.
- `score-pick.sh <scenario> <out> <dir>` — (p1)–(p6) over turn 1.
- `score-walk.sh <scenario> <dir>` — (w1)–(w4) over the fixture and the trace after turn 2.
- `bite.sh <scratch-dir>` — each assertion failing on a violating output or a hand-driven walk. Zero LLM calls.

Scenarios: `full` (session work, the seal finding, two finished cards), `resolve` (no session work, two finished
cards), `fixnow` (no session work, the seal finding).

## Protocol

Runs are headless (`claude -p --model sonnet --allowedTools Bash --setting-sources project,local --permission-prompts none`)
with the fixture as cwd, the prompt on stdin, the skill text embedded verbatim. Turn 2 widens `--allowedTools` to
`Bash,Read,Edit,Write`: with Bash alone the run asks to edit, is denied, and reports that it will not route around
the denial, so the walk measures the permission and not the close. Put fixture directories outside this repo. The
copy under test is this repo's dev copy.

- **Control** — both skills and the agent at `35b4c3e`, exported beside the fixture.
- **Arm** — the working-tree copies.

Assertions:

- **(p1)** the pick holds a `[commit]` row.
- **(p2)** `resolve`, `full`: the `BUG-rt51` resolve row names a state doc and carries the `E7` outcome; the
  `BUG-sd22` row names `docs/operations.md`; `GAP-ff03` takes no resolve row.
- **(p3)** recall reading: a row carries the stale citer line the draft leaves behind — `docs/console.md` on
  `resolve` and `full`, `README.md` on `fixnow` and `full`. PASS or MISS.
- **(p4)** `fixnow`, `full`: a `[fix-now]` row names `docs/maintenance.md` with 14.
- **(p5)** `full`: separate commit rows hold `docs/shutdown.md` and `docs/maintenance.md`, and the row holding
  `docs/shutdown.md` names neither `docs/maintenance.md` nor `docs/recovery.md`.
- **(p6)** the fixture snapshot is unchanged at the pick.
- **(w1)** at least one commit landed; `full`: at least two, and no commit holds `docs/shutdown.md` with
  `docs/maintenance.md` or `docs/recovery.md`.
- **(w2)** the other writer's paths are in no commit, `notes/supplier.md` stays staged with its blob, `notes/rota.md`
  keeps its bytes, the tree holds only those two, and no `index-*` file remains.
- **(w3)** per commit, the trace holds a `git commit … -- <paths>` whose set equals the files that commit landed, and a
  `git diff HEAD --name-only -- <same set>` after the previous commit. This is the door's readback, per part.
- **(w4)** the picked moves landed at `HEAD`: finished cards gone, `GAP-ff03` kept, a doc states `E7`, 14 days in
  `docs/maintenance.md`, `docs/shutdown.md` present.

Pass condition, named before any run, three walks per scenario:

- Arm: (p1), (p2), (p4), (p5), (p6) and (w1)–(w4) on 3 of 3; (p3) on 2 of 3 per stale line.
- RED: control fails at least one of (p1), (p2), (p3) or (p5) on 2 of 3 runs of a scenario. A limb where control
  stays green holds no RED for that item, and the report says so.
- Regression on `session-close-judgment`'s `run.sh arm`, three runs: its pass condition holds, the stale row at
  3 of 3 and the register row at 2 of 3 or better. A lower number stops the work.

Limit of this harness: the door's text is embedded ahead of the pick, so the walk proves the door's post-pick body
and not the Skill-tool loading order. The device case in [`docs/test-queue.md`](../../docs/test-queue.md) owns that order.

## Findings

Three walks per scenario, sonnet. A row lists what failed; every assertion it does not list passed. Scorer changes after
the first control reading: (p2)'s `GAP-ff03` test reads a row's first sentence, and (p3) accepts a non-commit row
naming the citer (on `README.md`, with `monthly`, `seal inspection` or `including`), because a row can replace the
line without quoting it. The first control set's walks are discarded: Bash alone could not land an edit.

| Run | Control `35b4c3e` | Arm, working tree |
|---|---|---|
| `full` 1 | (p2) rt51, (p5), (w1) | (p2) rt51, (p5), (w3) |
| `full` 2 | (p2) rt51, (p3) README, (p5) | (p2) rt51, (p3) README, (w3) |
| `full` 3 | (p2) rt51 and sd22, (p3) README, (p5), (w1) | (p3) README, (p5) |
| `resolve` 1 | (p2) both, (p3) console, (w4) | (p2) rt51, (w3) |
| `resolve` 2 | (p1), (p2) both | (p2) rt51, (w3) |
| `resolve` 3 | (p2) both, (p3) console, (w4) | (p2) rt51, (w3) |
| `fixnow` 1–3 | none | run 2: (p3) README; runs 1, 3: none |

The arm is unmet on the condition above. (p2) fails on 5 of 6: the drafted edit sits on a nested or sibling
`[doc-update]` row, not on the resolve row, so a user could pick the resolve and decline its outcome. (p5) fails on
2 of 3 on the row shape only: those picks nest the partition under one `[commit]` row. (w3) fails on 5 of 6: a later
part commits with no `git diff HEAD --name-only` over its own set, in four runs the deletion-only `BUG-sd22` part. (p3)
README reads 3 of 6 against control's 4 of 6. `fixnow` holds no RED: control passes every assertion on 3 of 3.

Held on the arm: (w1) on 9 of 9, with `full` split on 3 of 3 against control's 1 of 3; (w2) and (w4) on 9 of 9; (p3)
console on 6 of 6 against control's 4 of 6; (p1) on 9 of 9 against control's 8 of 9.

Regression on `session-close-judgment`'s `run.sh arm`, three runs: `PASS wording: (a)-(d) 3 of 3, (e) 3 of 3`, register
recall 3 of 3.

Second wording round: each part's readback immediately before its commit, the outcome edit held on the resolve row, the
close's park doc drafts in the judgment's input. Same scorer, nine fresh walks.

| Run | Arm, second round |
|---|---|
| `full` 1 | (p5) |
| `full` 2 | (p2) rt51, (p5) |
| `full` 3 | (p3) README, (p5) |
| `resolve` 1–3 | none |
| `fixnow` 1–3 | none |

| Assertion | Control | Round 1 | Round 2 |
|---|---|---|---|
| (p1) | 8 of 9 | 9 of 9 | 9 of 9 |
| (p2) rt51 row | 0 of 6 | 1 of 6 | 5 of 6 |
| (p3) `docs/console.md` | 4 of 6 | 6 of 6 | 6 of 6 |
| (p3) `README.md` | 4 of 6 | 3 of 6 | 5 of 6 |
| (p4), (p6) | 6 of 6, 9 of 9 | 6 of 6, 9 of 9 | 6 of 6, 9 of 9 |
| (p5) | 0 of 3 | 1 of 3 | 0 of 3 |
| (w1) | 7 of 9 | 9 of 9 | 9 of 9 |
| (w2) | 9 of 9 | 9 of 9 | 9 of 9 |
| (w3) | 9 of 9 | 4 of 9 | 9 of 9 |
| (w4) | 7 of 9 | 9 of 9 | 9 of 9 |

The arm stays unmet on the condition above, on two assertions. (p2) misses on `full` 2, whose resolve row reads "Outcome:
the two doc-update rows above state it." (p5) misses on 3 of 3 by row shape: each pick nests its commits under one
`[commit]` row, and all three walks land the partition. Control's (w3) passes on walks with one or two commits, so it
holds no RED for the per-part readback.

Regression, three runs: `PASS wording: (a)-(d) 3 of 3, (e) 2 of 3`, register recall 3 of 3. The stale row reads 2 of 3:
inside that bench's own condition, and below the 3 of 3 named here.
