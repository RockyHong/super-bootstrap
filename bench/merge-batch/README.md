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
