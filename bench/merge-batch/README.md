# bench/merge-batch — landing several branches that conflict only on derived output

Test surface for [`skills/merge/SKILL.md`](../../plugins/super-bootstrap/skills/merge/SKILL.md)'s § 5b batch
landing: two or more branches merge `--no-ff` in order into one integration branch off base; a conflict whose
unmerged paths are all derived output (a path the repo's docs name as written by a declared regenerate command)
settles by that command, with no judgment; one verify runs on the integrated tree; base fast-forwards once.
Behavior-shaping prose, so it ships behind the [`skill-authoring`](../../.claude/rules/skill-authoring.md) RED
floor, on the fixture + headless model-arm shape [`bench/merge-occupied`](../merge-occupied/README.md) uses.

- [`make-fixture.sh`](make-fixture.sh) `<dir>` — `<dir>/repo` (base `main`, no remote; `f1` `f2` `f3` one
  commit each off `init`, each adding `features/fN.txt` and re-running `tools/roster.sh`, so each bumps the
  generated `docs/roster.md`'s `count:` line and appends `- fN`). `CLAUDE.md` § Commands and
  `docs/techstack.md` declare `sh tools/roster.sh` as the command that writes `docs/roster.md`, and
  `sh tools/verify.sh` as the verify (a `## Staged-Tree Verify` block). Each script appends its name to the
  git-ignored `.bench-log`. `f1` lands cleanly; once it is in, `f2` and `f3` conflict on `docs/roster.md` only.
  `<dir>/coldcfg` is a credentials-only `CLAUDE_CONFIG_DIR`.
- [`run.sh`](run.sh) `<dir> <tag> [model]` — one model run on a fresh fixture; writes `runs/<tag>.prompt.md`,
  `.result.txt`, `.state.txt` (git graph, `main`'s first-parent chain with parents, each branch's ancestry in
  `main`, `main`'s roster and whether it equals a roster regenerated from `main`'s `features/`, `.bench-log`
  with `roster` / `verify` counts, `main`'s reflog). `SKILL_REF=HEAD` takes the skill text from a commit
  instead of the working tree.

Pass an absolute `<dir>` outside this repo.

## Protocol

Headless `claude -p --model haiku --allowedTools Bash`, cwd `<dir>/repo`, `timeout 600`. Prompt on stdin:
"Land the branches `f1` `f2` `f3` into `main`, in that order", a pre-confirmation of the recommended strategy
(headless cannot reply), "print your final report", then the whole SKILL.md verbatim, read at run time.

- **Control** — the pre-batch body (`SKILL_REF=HEAD`, the commit before § 5b landed).
- **Arm** — the working-tree body with § 5b.
- **Assertion** — all three branches are ancestors of `main`, each through its own two-parent merge commit on
  one integration branch; `main`'s reflog shows one move, a fast-forward from `init`; `.bench-log` holds one
  `roster` per derived conflict (plus the verify step's provisioning run) and exactly one `verify`; `main`'s
  roster equals the regenerated one; the report names no abort and no hand edit of `docs/roster.md`.

## Findings

Run 2026-10-20, haiku, one fresh fixture per run, the four runs in parallel.

| Run | landing | `docs/roster.md` conflict (f2, f3) | `.bench-log` | `main` moves | f2 / f3 in `main` |
|---|---|---|---|---|---|
| Control r1-r2 | Rebase + fast-forward per branch, serially onto `main` | aborted both (2/2); report suggests regenerating "outside this skill" as the user's next step | empty — no regenerate, no verify (2/2) | 1 (ff to `f1`) | no / no (2/2) |
| Arm r1-r2 | integration branch `integrate/main-<ts>`, `--no-ff` per branch | settled by `git checkout --theirs` → `sh tools/roster.sh` → `git add` (2/2), then concluded (r2 names `git merge --continue`; r1's report names no concluding command) | `roster` ×3, `verify` ×1 (2/2) | 1 (ff `init` → integrated tip, integration branch deleted) | yes / yes (2/2) |

RED: the pre-batch body lands each branch onto `main` in turn; every branch after the first meets the moved
base on the same generated line and is aborted under the Conflict Doctrine, so 1 of 3 lands and no verify runs.
Neither control hand-resolved the roster. GREEN: the § 5b body lands all three through one integration branch,
settles both derived conflicts by the declared command, runs verify once on the integrated tree, and moves
`main` once by fast-forward (2/2); the roster equals the regenerated one in both runs.

Arm r1-r2 ran an earlier § 5b wording whose step 2 named no merge subject: r2's merge commits carry git's
default `Merge branch 'fN' into integrate/main-<ts>`, putting the integration branch's name in `main`'s history,
and r2 first tried `git merge --continue --no-edit`, which git rejects. The shipped wording names
`-m "merge: {branch}"` and a non-interactive `git merge --continue` (arm r3's prompt named `GIT_EDITOR=true git merge --continue`; the shipped form is `git -c core.editor=true merge --continue`, and the red path is now a linear scan — r3 ran before both changes).

| Run | landing | conflict (f2, f3) | `.bench-log` | `main` moves | f2 / f3 in `main` |
|---|---|---|---|---|---|
| Arm r3 (step 2 subject + non-interactive conclude) | `integrate/main-<ts>`, subjects `merge: f1` … `merge: f3` | settled by regeneration, both | `roster` ×3, `verify` ×1 | 1 (ff, integration branch deleted) | yes / yes |
| Arm r4 (shipped text: linear red scan, `git -c core.editor=true` conclude) | `integrate/main-<ts>`, subjects `merge: f1` … `merge: f3` | settled by regeneration, both | `roster` ×3, `verify` ×1 | 1 (ff, integration branch deleted) | yes / yes |

Arm r3: "No tracked files changed, so no provisioning commit was needed"; the roster equals the regenerated one.
The red path (§ 5b step 5's linear scan for the first red merge) and a non-derived conflict inside a batch have no model run.

## Doc-sync case — a landed branch leaves a narrating doc stale

Test surface for § 5b step 6: the commit door's `range` entry
([`commit/SKILL.md` § Execution](../../plugins/super-bootstrap/skills/commit/SKILL.md#execution-gateway-inline)) run
over `{base-tip}..integrate/…` before base moves.

- [`make-fixture-docsync.sh`](make-fixture-docsync.sh) `<dir>` — `<dir>/repo` (base `main`, no remote).
  `docs/usage.md` narrates "`tools/greet.sh` prints `hello, world`"; `g1` changes the script to print `hi there` and
  leaves the doc; `g2` adds `notes/todo.txt`. No conflict, verify green on the integrated tree. The grep lane over
  the range reaches `docs/usage.md` (term `greet`, path segment).
- [`run-docsync.sh`](run-docsync.sh) `<dir> <tag> [model]` — snapshots the plugin's `skills/` + `agents/` into
  `<dir>/plugin` (working tree, or `SKILL_REF=<rev>`), prompts "land `g1` `g2` with `--batch`", pre-confirms the
  merge strategy only, says any other question is printed and the run stops there, names the plugin root so
  `/super-bootstrap:<name>` resolves to its `SKILL.md`, then the merge SKILL.md whole. `--allowedTools Bash,Read,Edit`.
- [`assert-docsync.sh`](assert-docsync.sh) `<repo> <result>` — PASS when the report names `docs/usage.md` and either
  `main` is still at `init` with an `integrate/*` branch holding `g1`, or `main:docs/usage.md` no longer says
  `hello, world`; FAIL names each failed leg. Its verdict is the last line of `<tag>.state.txt`.

Bite check (hand-built landings on one fixture): integrate + fast-forward with no doc-sync and a silent report →
`FAIL: report names no docs/usage.md; main moved past init with docs/usage.md still saying 'hello, world';`; the
same landing with a report naming the doc → `FAIL: main moved past init with docs/usage.md still saying 'hello, world';`;
`main` reset to `init` with no integration branch → `FAIL: main held at init but no integrate/* branch holds g1 (no landing ran);`.
`main` held with the integration branch kept, and a doc-fix commit on the integration branch fast-forwarded, both PASS.

### Findings

Run 2026-11-24, haiku, one fresh fixture per run.

| Run | text | landing | doc-sync | `main` | assert |
|---|---|---|---|---|---|
| Control r1-r2 | `SKILL_REF=HEAD` (§ 5b with no step 6, commit door with no `range` entry) | integration branch, `--no-ff` ×2, verify green | none; report never names `docs/usage.md` (2/2) | fast-forwarded with `hello, world` still in `docs/usage.md` (2/2) | FAIL (2/2) |
| Arm r1-r2 | working tree, first `range` wording | same | grep lane hit `docs/usage.md`, scope 1, judged warm; link + pin checks run; one ask drafting the line-3 edit (update / acknowledge) (2/2) | held at `init`, integration branch kept, waiting on the ask (2/2) | PASS (2/2) |
| Arm r3 | working tree, after the cold dry-run patches (`--no-renames`, per-call range prefix, one list with §3b rows, `held` / `declined` returns, integrity re-check before the commit) | same | same catch; the ask names the drafted commit subject and the hold option | held at `init`, integration branch kept | PASS |

RED: the pre-change text lands the batch and fast-forwards base with the narrating doc stale and unnamed — the
deferred mode's "doc-sync belongs to the merge boundary" has no receiver. GREEN: step 6 surfaces the stale doc with
its drafted edit and holds the fast-forward on the user's answer.

Lessons:

- A headless run cannot answer the doc-sync ask, so the prompt must say how a question ends the run ("print it and
  stop there"); the assertion then accepts either a held base or a base that moved only with the doc fixed. Without
  that line a run that treats the strategy pre-confirmation as approval of doc edits is indistinguishable from one
  that skipped the ask.
- The entry runs on a clean checkout of the integration tip, so `git diff HEAD` is empty there: every added-line lane
  needs the range. `doc-links.sh`'s `term-uses` and `volatile-ids` read `DOCLINK_DIFF_RANGE` for this
  ([`tests/doc-links.test.sh`](../../tests/doc-links.test.sh) locks it); before that they printed nothing on a clean tip.
- The pre-batch `run.sh` pastes the merge SKILL.md alone; a step that calls another skill needs that skill reachable,
  so `run-docsync.sh` snapshots the plugin and names its root in the prompt.
