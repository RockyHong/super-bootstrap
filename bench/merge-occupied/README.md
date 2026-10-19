# bench/merge-occupied — merge on a branch another worktree holds

Test surface for [`skills/merge/SKILL.md`](../../plugins/super-bootstrap/skills/merge/SKILL.md)'s handling of
a branch checked out in another worktree: § 1's `git worktree list --porcelain` read, § 4's occupied-branch
→ Merge --no-ff row, and § 5's failed-command split (unmerged paths → Conflict Doctrine; none → abort any merge/rebase still in
progress, then § 7's skipped line with git's error verbatim). Behavior-shaping prose, so it ships behind the
[`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor, on the protocol shape
[`bench/merge-push`](../merge-push/README.md) uses.

- [`make-fixture.sh`](make-fixture.sh) `<dir>` — `<dir>/repo` (base `main`, no remote; `feature/x` one
  commit off `init`, one commit behind `main`, disjoint files), `<dir>/wt-x` (a second worktree holding
  `feature/x`), `<dir>/coldcfg` (credentials-only `CLAUDE_CONFIG_DIR`, `git` allow-listed).
- [`git-check.sh`](git-check.sh) `<dir>` — mechanism pin, no model: porcelain names `feature/x` occupied;
  § 5's `git rebase main feature/x` exits non-zero with `already used by worktree` (older git: `is already
  checked out at`) and leaves no unmerged
  paths, no rebase in progress, a clean tree on `main`; `git merge feature/x --no-ff` lands it as a
  two-parent commit and `wt-x` still holds `feature/x`.
- [`run.sh`](run.sh) `<dir> <tag> [model]` — one model run on a fresh fixture; writes
  `runs/<tag>.prompt.md`, `.result.txt`, `.state.txt` (git graph, `main`'s parents, worktree list, `wt-x`'s
  `feature/x` reflog after). `SKILL_REF=HEAD` takes the skill text from a commit instead of the working
  tree; `FORCE=rebase` pre-confirms Rebase + fast-forward so the run meets the failing command.

Pass an absolute `<dir>` outside this repo.

## Protocol

Headless `claude -p --model haiku --allowedTools Bash`, cwd `<dir>/repo`, `timeout 300`. Prompt on stdin:
"Land the branch `feature/x` into `main`", a pre-confirmation of the § 4 recommendation (headless cannot
reply), "print the step 7 report", then the skill body from `## Conflict Doctrine` through § 7 verbatim,
extracted from the shipped SKILL.md at run time.

- **Control** — the pre-fix body (no worktree read, no occupied row, every failure routed to the Conflict
  Doctrine). Prompt kept as [`runs/control-r1.prompt.md`](runs/control-r1.prompt.md).
- **Arm** — the shipped body.
- **Forced** (`FORCE=rebase`) — same two bodies, prompt pre-confirms the rebase form, so the run executes
  the command that fails on an occupied branch.
- **Assertion, default prompt** — `feature/x` lands in `main` as a two-parent merge commit whose second
  parent equals `wt-x`'s `feature/x` (its reflog shows no rebase), and the report names no conflict.
- **Assertion, forced prompt** — `feature/x` is listed under § 7's skipped line with git's error line, the
  report names no conflict, and `wt-x`'s `feature/x` reflog shows no rebase.

## Findings

Run 2026-10-20, haiku, one fresh fixture per run. Arm r1-r2 ran an earlier wording of the same fix; arm r3
and forced arm r1 ran the shipped body.

| Run | prompt | strategy taken | report | `wt-x`'s `feature/x` |
|---|---|---|---|---|
| Control r1 | default | `git rebase main feature/x` → refused (`already used by worktree`); then rebased **inside `wt-x`**, then ff | "Rebase + fast-forward … no conflicts"; "I ran the rebase inside `wt-x`" | rewritten (`251cb53` → `f2442ce`) |
| Arm r1-r3 | default | Merge --no-ff from `main` | "Merge --no-ff. Reason: the branch is checked out in another worktree (`wt-x`), so it was not rewritten" (r3) | untouched; equals `main`'s second parent (3/3) |
| Forced control r1 | forced | rebased **inside `wt-x`**, then ff | "Rebased onto `main` in the worktree `wt-x`, because `feature/x` is checked out there"; skipped: none | rewritten (`f7e29a5` → `998dbe5`) |
| Forced arm r1 | forced | `git rebase main feature/x` → refused; stopped there | "Conflicts: none. No unmerged paths." Skipped: `feature/x` with `fatal: 'feature/x' is already used by worktree at '…/wt-x'`; offers Merge --no-ff as the next step | untouched |

RED: the pre-fix body gives no route for an occupied branch. On both prompts haiku meets the checkout
refusal and works around it by rebasing inside the other worktree — rewriting a branch the skill does not
own. Neither control run reported a phantom conflict; both took the rebase path the field failure took.
GREEN: with the default prompt the shipped body reads occupancy at § 1 and takes Merge --no-ff from the
current worktree (3/3). With the rebase forced it runs no git in `wt-x`, reports the refusal verbatim under
§ 7's skipped line with no conflict wording, and leaves `main` and `feature/x` unchanged (1/1).

The in-progress-abort branch of § 5's split (a failed command that leaves a merge or rebase in progress but
no unmerged paths) has no model run; `git-check.sh` pins that the occupied-branch refusal leaves neither.
