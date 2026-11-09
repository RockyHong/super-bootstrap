# bench/session-close-moves — RED and walk for what a close's pick lands

Test surface for [`skills/session-close/SKILL.md`](../../plugins/super-bootstrap/skills/session-close/SKILL.md)
steps 2–4 and for the § Session-close entries and § 5 of
[`skills/commit/SKILL.md`](../../plugins/super-bootstrap/skills/commit/SKILL.md). Commits land in flow, so the close
catches leaks: one commit row, naming what the session left uncommitted, and every pick asked through AskUserQuestion. The door's
§ 5 lands the N commits a row states when the leak mixes unrelated changes. A resolve row carries its outcome. A move that writes the tree brings a
commit move and the door's judgment with it, even when the session changed nothing itself.
Behavior-shaping prose, so it ships behind the [`skill-authoring`](../../.claude/rules/skill-authoring.md)
RED floor. Sibling bench for the pre-pick judgment: [`session-close-judgment`](../session-close-judgment/README.md).

## Fixture

- `fixture/base/` — the `brindle` cabinet repo. `config/cabinet.toml` sets `seal_check_days = 14` and
  `outage_report_max_retries = 5`. `docs/maintenance.md` says 30 days; `README.md` says "monthly" and links it.
  `docs/recovery.md` states no retry cap; `docs/console.md` links it and says a report "keeps retrying until it
  succeeds". Open cards: `BUG-rt51` (every Plan step done, outcome in no doc), `BUG-sd22` (every Plan step done,
  outcome stated in `docs/operations.md`), `GAP-ff03` (in motion).
- `fixture/session/` — the session work: `docs/operations.md` modified, `docs/shutdown.md` new.
- `prompt-{head,full,resolve,fixnow,leak,single,large,harness,cochange,tail,turn2}.txt` — the session records and the second turn. The
  other writer's files are named nowhere in a prompt. `prompt-tail.txt` has the run print each AskUserQuestion call it
  would make as a fenced ```` ```AskUserQuestion ```` block holding the call's JSON, and print a prose ask as prose.
- `fixture/harness/` — added to the base commit on `harness` only: a `CLAUDE.md` binding a harness ritual (a principles
  load before an edit, a fresh-context audit before commit) and the rule `.claude/rules/maintenance.md`.
- `fixture/cochange/` — added with `fixture/harness/` to the base commit on `cochange` only: the rule `.claude/rules/seal.md`
  and the served skill `.claude/skills/seal-audit/` (a `.served` marker), each stating the old seal policy, a seal replaced
  only on a crack. The session's edit to `docs/maintenance.md` states the new one: every 12 months, or sooner on a crack.
- `make-fixture.sh <scenario> <dir>` — builds the repo with plumbing, with another writer's staged
  `notes/supplier.md` and dirty `notes/rota.md`, and writes `<dir>.snap`, `<dir>.foreign` and `<dir>.base`.
- `run.sh <control|arm> <scenario> <dir>` — one two-turn walk: turn 1 stops at the pick, turn 2
  (`claude -p --continue`) runs every row; `large`, `harness` and `cochange` stop after turn 1. `CONTROL_REV` (env) picks control's revision, default `bb069c4`. Records every git command in `<dir>.trace`
  through `GIT_TRACE`.
- `score-pick.sh <scenario> <out> <dir>` — (p1)–(p17) over turn 1, with (p5) and (p10) retired.
- `score-walk.sh <scenario> <dir>` — (w1)–(w4) over the fixture and the trace after turn 2.
- `bite.sh <scratch-dir>` — each assertion failing on a violating output or a hand-driven walk. Zero LLM calls.

Scenarios: `full` (session work, the seal finding, two finished cards), `resolve` (no session work, two finished
cards), `fixnow` (no session work, the seal finding), `leak` (work committed in flow, one new file left over, a merged
branch: two moves), `single` (the same with no merged branch: a lone move), `large` (nothing committed: the session's
work plus eight tuning files), `harness` (no session work, a drafted line for a harness rule that owes a post-edit
audit, the session in Traditional Chinese), `cochange` (a policy change in `docs/maintenance.md`, left uncommitted,
that a session-owned rule and a served skill still contradict).

## Protocol

Runs are headless (`claude -p --model sonnet --allowedTools Bash --setting-sources project,local --permission-prompts none`)
with the fixture as cwd, the prompt on stdin, the skill text embedded verbatim. Turn 2 widens `--allowedTools` to
`Bash,Read,Edit,Write`: with Bash alone the run asks to edit, is denied, and reports that it will not route around
the denial, so the walk measures the permission and not the close. Put fixture directories outside this repo. The
copy under test is this repo's dev copy.

- **Control** — both skills and the agent at `bb069c4`, exported beside the fixture. The older Findings tables read an
  earlier control (`35b4c3e`) and earlier assertions.
- **Arm** — the working-tree copies.

Assertions:

- **(p1)** the pick holds a `[commit]` row.
- **(p2)** `resolve`, `full`: the `BUG-rt51` resolve row names a state doc and carries the `E7` outcome; the
  `BUG-sd22` row names `docs/operations.md`; `GAP-ff03` takes no resolve row.
- **(p3)** recall reading: a row carries the stale citer line the draft leaves behind — `docs/console.md` on
  `resolve` and `full`, `README.md` on `fixnow` and `full`. PASS or MISS.
- **(p4)** `fixnow`, `full`: a `[fix-now]` row names `docs/maintenance.md` with 14.
- **(p6)** the fixture snapshot is unchanged at the pick.
- **(p7)** `full`, `leak`, `large`: a line names the leak as left uncommitted or untracked (`docs/shutdown.md`,
  `shift-log.txt`; each is an untracked path).
- **(p8)** `leak`, `large`, `single`: at most one `[commit]` row (`leak`, `large`: exactly one), with no second commit
  subject and no numbered part under it. A non-gating reading on the other scenarios.
- **(p9)** no line offers closing without running the moves. A lone move's single-select ask is exempt: its skip option closes without that move by design.
- **(p10)** retired: the spike pointer left the close.
- **(p11)** every scenario: the pick is one printed AskUserQuestion call. Several bullet rows → `multiSelect: true`; one
  row → not multi-select, with two options (run and skip). `single` also: at most one bullet row, `shift-log.txt` named.
- **(p12)** `harness`: a `[fix-now]` row names `.claude/rules/maintenance.md` with its drafted line; no `[log]` row names it.
- **(p13)** `harness`: a row other than `[log]`, or the ask, names the owed audit.
- **(p14)** `harness`: the ask's `question` holds CJK text, the session's language.
- **(p15)** `cochange`: a row other than `[commit]` and `[log]` names `.claude/rules/seal.md` with `12 months`, its drafted
  edit; no `[log]` row names it.
- **(p16)** `cochange`: that row names the audit the harness edit owes.
- **(p17)** `cochange`: the served `seal-audit` skill is routed, not landed: no `[fix-now]` row and not the `[commit]` row name
  it, every other row naming it names its owner route (owner, served, upstream, `/contribute`, `claude-config-manager`,
  source), and some line names it with that route.
- **(w1)** at least one commit landed. `full`: unrelated changes do not share a commit: `docs/shutdown.md` sits apart from
  `docs/maintenance.md` and `docs/recovery.md`. The commit count is a non-gating reading.
- **(w2)** the other writer's paths are in no commit, `notes/supplier.md` stays staged with its blob, `notes/rota.md`
  keeps its bytes, the tree holds only those two, and no `index-*` file remains.
- **(w3)** per commit, the trace holds a `git commit … -- <paths>` whose set equals the files that commit landed, and a
  `git diff HEAD --name-only -- <same set>` after the previous commit. This is the door's readback, per part.
- **(w4)** the picked moves landed at `HEAD`: finished cards gone, `GAP-ff03` kept, a doc states `E7`, 14 days in
  `docs/maintenance.md`, `docs/shutdown.md` present. `leak`, `single`: `shift-log.txt` present. `leak`: `topic-old` gone.

Pass condition, named before any run, three walks per scenario:

- Arm: (p1), (p4), (p6)–(p9), (p11) and (w1)–(w4) on 3 of 3; (p2)'s `BUG-rt51` row on 5 of 6, its last reading; (p3) on 2 of
  3 per stale line.
- RED: control fails (p7), (p8), (p9) or (p11) on 2 of 3 runs of a scenario. Control runs `full`, `leak`,
  `single` and `large`. A limb where control stays green holds no RED for that item, and the report says so.
- Regression on `session-close-judgment`'s `run.sh arm`, three runs, against its last reading: the stale row at 2 of 3
  or better and the register row at 3 of 3. A lower number stops the work.
- One wording round. A failed arm stops the work and reports the numbers.

(p5) is retired by the author's ruling, and with it `full`'s gating count of commits in (w1): the pick shows no nested
partition. (w1)'s no-mix limb on `full` gates, named before the second round's run. The older tables below keep their
(p5) columns as read, and the leak-row round's table reads the first-round scorers.

Limit of this harness: the door's text is embedded ahead of the pick, so the walk proves the door's post-pick body
and not the Skill-tool loading order. The device case in [`docs/test-queue.md`](../../docs/test-queue.md) owns that order.

Script round: the push check moves into [`push-state.sh`](../../plugins/super-bootstrap/skills/session-close/assets/push-state.sh),
and `run.sh` and `prompt-tail.txt` name the close skill's `<skill-base>`, the working-tree path. Scorers do not change. Pass
condition, named before any run, three arm walks per scenario, one round, no control: everything the second wording round
met stays met: (p1), (p2) `BUG-rt51`, (p3) `docs/console.md`, (p3) `README.md` on `full`, (p4), (p6), (p8) on `leak` and
`single`, (p9), (w1), (w2), (w4). Reported against the last reading and open if unmet: (p3) `README.md` on `fixnow`, last 1 of
3; (p7), last 2, 2, 1 of 3; (p8) on `large`, last 1 of 3; (p11), last 2 of 3; (w3), last 14 of 15; the register row of
`session-close-judgment`'s `run.sh arm`, last 2 of 3.

Field-list round: `session-close` § Output now holds a fixed list of fields. Same pass condition and same scenarios as the
script round, named before any run. A miss on a condition the second round met is reported at the end of the run with its
verbatim lines, with no retuning.

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

Leak-row round: control `bb069c4`, arm working tree, one wording, three walks per scenario, sonnet. `large` stops at the
pick. Control does not run `resolve` or `fixnow`.

| Assertion | Control | Arm | Arm's condition |
|---|---|---|---|
| (p1) | 9 of 9 on `full`, `leak`, `large` | 14 of 15 | miss: `large` 3 asks in prose, a lone move |
| (p2) `BUG-rt51` row | 3 of 3 on `full` | 5 of 6 | met |
| (p3) `docs/console.md` | 3 of 3 on `full` | 6 of 6 | met |
| (p3) `README.md` | 2 of 3 on `full` | `full` 1 of 3, `fixnow` 3 of 3 | unmet on `full` |
| (p4), (p6) | 3 of 3, 12 of 12 | 6 of 6, 18 of 18 | met |
| (p7) named leak | `full` 1, `leak` 1, `large` 0, each of 3 | `full` 1, `leak` 0, `large` 1, each of 3 | unmet |
| (p8) one row, none nested | `leak` 3, `single` 3, `large` 0, each of 3 | `leak` 3, `single` 3, `large` 1, each of 3 | unmet on `large` |
| (p9) no close-without | `full` 2, `leak` 1, `single` 0, `large` 0, each of 3 | 18 of 18 | met |
| (p10) one spike pointer | 0 of 3 | 0 of 3 | unmet |
| (p11) lone move | 0 of 3 | 1 of 3 | unmet: two runs state the yes and the no with no `?` |
| (w1)–(w4) | 9 of 9 each | 15 of 15 each | met |

The arm is unmet. RED holds on (p7), on (p8) for `large`, on (p9) for `leak`, `single`, `large`, on (p10) and on (p11).
(p8) on `leak` and `single` holds no RED: control passes 3 of 3 on each.

Reading (w1) on `full`: control lands 4, 3 and 3 commits with `docs/shutdown.md` apart from the seal fix and the outcome.
The arm lands 1, 1 and 1, each mixing them: behind one row, the door's §5 split did not fire. Reading (p8) on `full`: the
arm shows one commit row on 3 of 3.

Regression, `session-close-judgment`'s `run.sh arm`, three runs: (a)–(d) 3 of 3, stale row 2 of 3, register row 2 of 3.
The register row is below the 3 of 3 named here.

Second and final wording round, on the fixed scorers ((p7), (p11)), with (w1)'s no-mix limb gating and (p10) retired: the
row states "splits into N commits", and a move not detected gets no line. Arm 1 and control are the earlier outputs re-scored.

| Assertion | Control | Arm 1 | Arm 2 | Verdict |
|---|---|---|---|---|
| (p1) | 9 of 9 | 14 of 15 | 15 of 15 | met |
| (p2) `BUG-rt51` row | 3 of 3 | 5 of 6 | 6 of 6 | met |
| (p3) `docs/console.md` | 3 of 3 | 6 of 6 | 6 of 6 | met |
| (p3) `README.md`, `full` / `fixnow` | 2 of 3 / no run | 1 / 3 of 3 | 3 / 1 of 3 | unmet on `fixnow` |
| (p4), (p6) | 3 of 3, 12 of 12 | 6 of 6, 18 of 18 | 6 of 6, 18 of 18 | met |
| (p7) `full`, `leak`, `large` | 1, 3, 0 of 3 | 1, 3, 1 of 3 | 2, 2, 1 of 3 | unmet |
| (p8) `leak`, `single`, `large` | 3, 3, 0 of 3 | 3, 3, 1 of 3 | 3, 3, 1 of 3 | unmet on `large` |
| (p9) | 3 of 12 | 18 of 18 | 18 of 18 | met |
| (p11) | 0 of 3 | 3 of 3 | 2 of 3 | unmet |
| (w1) no-mix on `full` | 3 of 3 | 0 of 3 | 3 of 3 | met |
| (w3) | 9 of 9 | 15 of 15 | 14 of 15 | unmet |
| (w1) rest, (w2), (w4) | 9 of 9 each | 15 of 15 each | 15 of 15 each | met |

The arm is unmet on the condition above. `full` lands 3, 3, 3 commits. (p11) misses on a `[push]` row in a repo with no
remote, on `single` 3. (w3) misses on `resolve` 3: "no readback over 'docs/work/BUG-sd22.md ' ran before its commit".

Regression, `session-close-judgment`'s `run.sh arm`, three runs: (a)–(d) 3 of 3, stale row 3 of 3, register row 2 of 3. The
register row is below the 3 of 3 named here.

Script round: not run. [`session-close-push`](../session-close-push/README.md#findings) (f) read 0 of 3 on `solo`, which
stops the round before this bench, so the second round's table above stays the last reading.

Field-list round, arm, one wording, three walks per scenario, sonnet. `large` stops at the pick. Last reading = the second round.

| Assertion | Last | This | Verdict |
|---|---|---|---|
| (p1) | 15 of 15 | 14 of 15 | **regressed** |
| (p2) `BUG-rt51` row | 6 of 6 | 6 of 6 | met |
| (p3) `docs/console.md` | 6 of 6 | 6 of 6 | met |
| (p3) `README.md`, `full` / `fixnow` | 3 / 1 of 3 | 2 / 3 of 3 | met, at the 2 of 3 condition |
| (p4), (p6) | 6 of 6, 18 of 18 | 6 of 6, 18 of 18 | met |
| (p7) `full`, `leak`, `large` | 2, 2, 1 of 3 | 3, 3, 3 of 3 | met |
| (p8) `leak`, `single`, `large` | 3, 3, 1 of 3 | 2, 3, 0 of 3 | **regressed on `leak`**, unmet on `large` |
| (p9) | 18 of 18 | 17 of 18 | **regressed** |
| (p11) | 2 of 3 | 3 of 3 | met |
| (w1) no-mix on `full` | 3 of 3 | 3 of 3 | met; commits 3, 4, 3 |
| (w1) rest, (w2) | 15 of 15 each | 15 of 15 each | met |
| (w3) | 14 of 15 | 15 of 15 | met |
| (w4) | 15 of 15 | 14 of 15 | **regressed** |

The misses, verbatim:

- (p1), (p8) and (w4) on `leak` 1 are one miss. The run reads a merged branch as unmerged, so it finds a lone move and asks in
  prose: "`topic-old` is not merged into main, so I'm not pruning it." `FAIL (p1) no [commit] row. Rows:`,
  `FAIL (p8) no commit row`, `FAIL (w4) topic-old was not pruned`.
- (p9) on `large` 2: "Reply yes to run the commit move. Reply no to close without it, which leaves `docs/operations.md`,
  `docs/shutdown.md` and `tuning/` uncommitted." `FAIL (p9) a close-without option is offered`. This is a yes-or-no ask, not an option
  row. `session-close-push`'s (e) exempts that form and this scorer does not. The scorer stood unchanged.
- (p8) on `large`: `FAIL (p8) 1 commit rows, 2 commit subjects, 0 numbered parts`, on two runs; the third reads 2 numbered parts.
  The row states the split, then nests the subjects.

Regression, `session-close-judgment`'s `run.sh arm`, three runs, with `run.sh` and `prompt.txt` now naming the close skill's
`<skill-base>`: (a) 3, (b) 2, (c) 3, (d) 3 of 3, stale row 1 of 3, register row 2 of 3. Its condition fails, and the stale row is below
the 2 of 3 named here.

- (b) on run 2, a row that does state ownership in words the scorer does not list: "Why it is not fixed now: the firmware team runs
  that repository and it is not checked out here." The scorer stood unchanged.
- Stale row on runs 2 and 3: `MISS (e) no [doc-update] row for the stale line in docs/operations.md. Rows: commit fix-now register log log`.
  The last two readings were 2 and 3 of 3. Three runs cannot separate this from variance or from the changed text.

`bench/spike-route`, arm, three runs: (s1) and (s2) 3 of 3, (r1) one commit on `spike/jump-arc-feel`, 3 of 3. No change.

This round's picks still narrate on no-remote fixtures, which nothing here gates: "No push line printed: no remote is configured and
nothing is ahead of upstream."

Harness-row round: session-close step 3b takes a row for the commit door's `harness` return, and step 3 runs an owner check
on every harness path before a fix-now draft. Scenario `cochange`, turn 1 only, sonnet. Pass condition, named before any run:
RED = control fails (p15), (p16) or (p17) on 2 of 3; GREEN = arm passes (p1), (p6), (p9), (p11), (p15)–(p17) on 3 of 3. At
most 2 wording passes after RED. Control = `CONTROL_REV=HEAD` (`5c5c165`), which lacks the door's `harness` class too.

| Assertion | Control `HEAD` | Pass 0: 3b row | Pass 1: owner check in 3b | Pass 2: owner check in step 3 |
|---|---|---|---|---|
| (p15) rule row with its edit | 3 of 3 | 3 of 3 | 3 of 3 | 3 of 3 |
| (p16) the row names its audit | 3 of 3 | 3 of 3 | 3 of 3 | 3 of 3 |
| (p17) served skill routed | 1 of 3 | 0 of 3 | 0 of 3 | 3 of 3 |
| (p1), (p6), (p9), (p11) | 3 of 3 | 3 of 3 | 3 of 3 | 3 of 3 |

RED holds on (p17) only: control lands the served skill as a `[doc-update]` row on 2 of 3. (p15) and (p16) hold no RED: the
fixture's `CLAUDE.md` names the audit, so control states it. Pass 0 and pass 1 land the served skill on 6 of 6, as a
`[harness-edit]` or `[fix-now]` row, or in the commit row: the session had read the skill, so it drafted it as an inflight
finding before 3b's check could see it. Pass 2 is GREEN.

Regression on the final text: `single` 1 of 1 on (p6)–(p11) and (w1)–(w4). `harness` 1 of 2: one walk asks the fix-now row
and the commit row as one move, `FAIL (p11) 2 rows are asked with no multi-select`; the pass-0 walk read
`FAIL (p1) no [commit] row. Rows: fix-now + commit`. The text before this round reads 1 of 1. Two walks cannot separate this
from variance.
