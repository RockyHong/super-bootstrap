# bench/session-close-judgment — RED for the close's judgment seam

Test surface for [`skills/session-close/SKILL.md`](../../plugins/super-bootstrap/skills/session-close/SKILL.md)
step 3's inflight triage and step 3b, and the `close-detect` entry of
[`skills/commit/SKILL.md`](../../plugins/super-bootstrap/skills/commit/SKILL.md). A close settles every
judgment inside its one pick: a bounded finding this repo owns is a fix-now row, a log row states why it
cannot finish now, the door's earned returns are rows with their text drafted, and an unearned return gets
no line. Behavior-shaping prose, so it ships behind the
[`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor. Sibling benches:
[`session-close-inflight`](../session-close-inflight/README.md),
[`session-close-push`](../session-close-push/README.md).

The corpus is the synthetic `brindle` proofing-cabinet controller, shared with
[`terminology-register`](../terminology-register/README.md).

## Fixture

- `fixture/base/` — the base commit. `docs/terminology.md` registers **Proof cycle** and **Hold**;
  `docs/maintenance.md` says the door seal is inspected every 30 days; `config/cabinet.toml` sets
  `seal_check_days = 14`; `docs/operations.md`'s intro says power-loss recovery is not documented yet.
- `fixture/session/` — this session's work, copied over the base: `docs/operations.md` modified and
  `docs/recovery.md` untracked, so `git add -N` before the pick shows in the shared index. The new doc coins
  **recovery ramp** (earned), uses the verb "Hold the door" (homonym of a registered term, unearned), and
  uses MQTT, backoff, webhook and cache (general words, unearned).
- `prompt.txt` — the session record: goal delivered, three uncarded findings (seal interval: this repo's and
  bounded; firmware README baud rate: another repo's; humidity reading: cause unknown), nothing launched. Asks
  the run to stop where the procedure needs the user and print a pick as `- [move] ...` bullets.
- `make-fixture.sh <dir>` — builds the repo with plumbing and writes `<dir>.snap`.
- `snapshot.sh <dir>` — HEAD, shared-index entries, status, worktree bytes, stray `index-*` files.
- `run.sh <control|arm> <fixture-dir> <out-file>` — fresh fixture, both skills and the agent body embedded
  verbatim, one headless run, then `score.sh`.
- `score.sh <out-file> <fixture-dir>` — one PASS or FAIL per assertion for (a)–(d), PASS or MISS for (e), and
  a non-gating count of lines naming a dropped candidate.
- `score-wording.sh <out1> <fx1> <out2> <fx2> <out3> <fx3>` — the pass condition over one wording's three runs.
- `bite.sh <scratch-dir>` — shows (b), (c), (d) and (e) failing on violating outputs. Zero LLM calls.

## Protocol

Runs are headless (`claude -p --model sonnet --allowedTools Bash --setting-sources project,local --permission-prompts none`)
with the fixture as cwd, the prompt on stdin. Put fixture directories outside this repo. The copy under test
is this repo's dev copy.

- **Control** — both skills and the agent at `8cb9c9f`, with `<skill-base>` exported beside the fixture.
- **Arm** — the working-tree copies.

Assertions, scored by `score.sh`:

- **(a)** a `[fix-now]` row names `docs/maintenance.md` with 14, and no `[log]` row names it. Control is RED here.
  Non-gating recall reading: a `[register]` row exists with a drafted `**Recovery ramp**:` entry.
- **(b)** a `[log]` row exists for the firmware finding and the humidity finding, and every `[log]` row names a
  reason by closure, investigation or ownership, never by `context`, `token` or `window`.
- **(c)** no move row (commit and close rows aside) has a general word or `Hold` as its subject, its first sentence,
  and no line asks or offers a ruling on a skip. A line that names a dropped candidate without asking does not fail;
  `score.sh` counts it.
- **(d)** `snapshot.sh` matches `<dir>.snap`.
- **(e)** a `[doc-update]` row carries the stale intro line in `docs/operations.md`.

Pass condition: (a)–(d) on 3 of 3 arm runs, (e) on 2 of 3.

The (c) and (e) conditions changed after the arm's reading, by the author's ruling. The earlier conditions were
(c) "the whole output names no general word and no `Hold`" and (e) 3 of 3. Naming a dropped candidate asks nothing
of the user, and two wordings showed the silence trading against the stale row. A stale row miss in the failing
run came from the judge returning no candidate, which is recall, not the seam this bench tests.

Two more conditions changed after the post-audit reading, by the author's ruling. The (c) row test read a move row's
whole text, and failed a `[register]` row for `recovery ramp` that mentioned general words in narration; it now reads
the row's subject. The register limb of (a) gated at 3 of 3; it is now a non-gating recall reading, because a miss
there is the door judge's recall on a fixture that also offers `rise`, not the close's routing.

Limits of this harness: the door's text is embedded ahead of the pick, so a control run can reach the door's
judgment before the pick, which a device close loading the door by Skill tool does not. Control's RED is
therefore carried by the routing limb of (a) and by (c), and the before-or-after-the-pick ordering is not
measured here. A headless run also carries the user-level `CLAUDE.md`: runs cite its account policy on the
firmware finding.

## Findings

Run 2026-11-03, one fresh fixture per run. Every (d) reading: PASS.

| Run | text | (a) | (b) | (c) | (e) | quoted line |
|---|---|---|---|---|---|---|
| Control 1 | `8cb9c9f` | FAIL | FAIL | FAIL | no | "I did not fix it inline because it is off this session's goal." |
| Control 2 | `8cb9c9f` | FAIL | FAIL | FAIL | yes | "This is not a fix-now: it is off this session's goal." |
| Control 3 | `8cb9c9f` | FAIL | FAIL | FAIL | yes | "My lean is to skip, since \"rise\" is also an ordinary word" |
| Wording 0, run 1 | working tree | PASS | PASS | FAIL | no | "Webhook, backoff and cache are ordinary programming words, not project terms." |
| Wording 0, run 2 | working tree | PASS | PASS | PASS | no | "Investigating would pull large unrelated reads into this thread." |
| Wording 0, run 3 | working tree | PASS | PASS | FAIL | yes | "MQTT, webhook, backoff and cache are ordinary programming words, so they are not terms." |
| Revision 1, run 1 | working tree | PASS | PASS | FAIL | yes | "The `Hold` match at `docs/recovery.md:7` is the verb" |
| Revision 1, run 2 | working tree | PASS | PASS | FAIL | yes | "I dropped one terminology hit: the word \"Hold\" at `docs/recovery.md:7`" |
| Revision 1, run 3 | working tree | PASS | PASS | PASS | no | "Finding it would pull large unrelated reads into this session." |
| Revision 2, run 1 | working tree | PASS | PASS | PASS | no | "the firmware team owns that repository, and it is not checked out here" |
| Revision 2, run 2 | working tree | FAIL | PASS | PASS | no | "FAIL (a) no [register] row" |
| Revision 2, run 3 | working tree | PASS | PASS | PASS | no | "Investigating would pull large unrelated reads into this thread." |
| Revision 3, run 1 | working tree | PASS | PASS | FAIL | yes | "The `Hold` match at `docs/recovery.md:7` is the verb" |
| Revision 3, run 2 | working tree | PASS | PASS | FAIL | no | "No stale candidates. Scope is `operations.md` and `recovery.md`" |
| Revision 3, run 3 | working tree | PASS | PASS | FAIL | yes | "**Door judgment dropped, no row:**" |

(e) column for the rows above revision 3: "yes" is any row outside commit and close. On the gating test, which wants a
`[doc-update]` row, all three revision 2 runs read `FAIL (e)`.

RED holds: control routes the seal-interval finding to log in 3 of 3 runs. The arm is unmet at the final wording:
revision 3 passes (a), (b) and (d) on 3 of 3 runs, (e) on 2 of 3 and (c) on 0 of 3. Every revision 3 run names a
dropped non-blocking candidate. (c) and the stale row moved in opposite directions across the last two wordings:
revision 2 held (c) at 3 of 3 with the stale row at 0 of 3, and revision 3 holds the stale row at 2 of 3 with (c)
at 0 of 3. The regressions did not run, because the arm missed.

`score.sh` changed once after the first arm runs: the (c) homonym test read case-insensitively and failed
Wording 0 run 2 on "`docs/operations.md` still hold". It now matches capitalized `Hold` or a quoted `hold`.

The table and paragraph above are the readings on the earlier (c) and (e) conditions. Rescored on the current
conditions, with no new runs:

| Run | (a) | (b) | (c) | (d) | (e) | lines naming a dropped candidate |
|---|---|---|---|---|---|---|
| Control 1 | FAIL | FAIL | PASS | PASS | MISS | 1 |
| Control 2 | FAIL | FAIL | PASS | PASS | MISS | 1 |
| Control 3 | FAIL | FAIL | FAIL | PASS | MISS | 1 |
| Revision 3, run 1 | PASS | PASS | PASS | PASS | PASS | 1 |
| Revision 3, run 2 | PASS | PASS | PASS | PASS | MISS | 1 |
| Revision 3, run 3 | PASS | PASS | PASS | PASS | PASS | 2 |

Revision 3 passes: (a)–(d) on 3 of 3, (e) on 2 of 3. Control 3's (c) failure: "My lean is to skip". Control's 2 of 3
on the stale line is a row of any name, in its case `[fix-now]`; the `[doc-update]` name does not exist in its text.

Regressions on revision 3's working tree, three runs each, all holding their README's pass condition:

| Bench | Reading | quoted line |
|---|---|---|
| `session-close-push` | no push move, no ask, remote log `init` only, 3 of 3 | "`main` is 1 commit ahead of its upstream." |
| `session-close-inflight` | no pick, `agent-b7` with wait and stop only, fixture `init` + ` M a.md`, 3 of 3 | "**Session close is gated. No pick yet.**" |
| `terminology-register`, recall | (a) `**Recovery ramp**:` and (b) `standby` on Hold's `_Avoid_`, each register or skip, 3 of 3 | "Pick register or skip." |
| `terminology-register`, precision | no register item, 3 of 3; one stale-doc item, which that README scores separately | "`docs/operations.md` has no panel-layout content" |

Post-audit wording (`close-detect` scope and hand-over, `close-commit` repair bound, volatile-ID row, description
trim), three fresh runs on the current conditions. Unmet: (a)–(d) on 1 of 3 runs, (e) on 3 of 3.

| Run | (a) | (b) | (c) | (d) | (e) | lines naming a dropped candidate | quoted line |
|---|---|---|---|---|---|---|---|
| 1 | FAIL | PASS | PASS | PASS | PASS | 1 | "`MQTT`, `webhook`, `backoff` and `cache` are ordinary words, so they need no register entry." |
| 2 | PASS | PASS | FAIL | PASS | PASS | 2 | "Words like \"exponential backoff\", \"webhook\", \"cache\" and \"MQTT\" are ordinary usage and get no entry." |
| 3 | PASS | PASS | PASS | PASS | PASS | 0 | "Skip this row to register nothing. The commit proceeds either way." |

Run 1's `[register]` row is for `rise` and carries no `**Recovery ramp**:` entry: the judge's recall, as in revision 2
run 2. Run 2's (c) failure is the quoted narration sitting inside its `[register]` row for `recovery ramp`, so the row
test reads it as a row for a general word. That row is not for a general word; the scorer stood unchanged for this
reading.

The same three post-audit outputs rescored on the current conditions: `PASS wording: (a)-(d) 3 of 3, (e) 3 of 3`.
Non-gating counts: lines naming a dropped candidate 1, 2 and 0; register recall 2 of 3, and 13 of 15 across every arm
run in this file. Control still fails the narrowed (a) on 3 of 3 and the subject-reading (c) on 1 of 3.

Regressions on the final working tree, three runs each:

| Bench | Reading | quoted line |
|---|---|---|
| `session-close-push` | holds: no push move, no ask, remote log `init` only, 3 of 3 | "`main` is 1 commit ahead of `origin/main`." |
| `session-close-inflight` | holds: no pick, `agent-b7` with wait and stop only, fixture `init` + ` M a.md`, 3 of 3 | "Session close is blocked at step 0." |
| `terminology-register`, recall | holds: `**Recovery ramp**:` and `standby` on Hold's `_Avoid_`, each register or skip, 3 of 3 | "Pick register or skip." |
| `terminology-register`, precision | misses its README's condition on 1 of 3: run 1 surfaces a register item | "**Register proposal, \"fault code\" (`docs/maintenance.md:9`, first in the `## Faults` section)**" |

The precision miss runs the door's no-argument flow, whose § Scan step 8 text is unchanged since the earlier 3 of 3
precision reading. Three runs cannot separate it from the judge's variance. The fixture's added lines do use "fault code"
twice.
