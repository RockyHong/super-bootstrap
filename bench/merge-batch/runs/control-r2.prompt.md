You are running the merge skill below in this repository. Base branch: `main`.
Land the branches `f1` `f2` `f3` into `main`, in that order. I pre-confirm whatever strategy you recommend - execute it without waiting for a reply. Finish by printing your final report (the skill's step 7 summary) as your final output.

---

---
name: merge
description: 'Absorb one or more feature branches into the base branch. Recommends merge vs rebase per branch. On conflict, aborts that branch + surfaces the file list + stops. Resolution out of scope; routes to the harness-named conflict-resolution agent (stages the resolution and reports; the gateway concludes it) or the user.'
tags: [merge, git, branch]
---

# merge — Branch Absorption

Absorb feature branches into the base branch. Per-branch rebase-vs-merge recommendation, mechanical execution. **Conflict resolution is NOT this skill's job** — abort, surface, stop.

## Branch Absorption Lane (load-bearing)

Branch integration is a topology operation on the commit graph. Route through the merge tool — `git merge`, this skill, or worker-direct-merge. File extension is not a routing signal; a docs-only branch is still branch integration.

### Pre-flight when integration is in scope

Triggers: branch named for absorption, current branch behind base, worker returned with branch unmerged.

1. `git branch --no-merged <base>` — list unmerged tips.
2. For any file slated for edit: `git log <base>..<branch> -- <path>`. Non-empty → merge lane.
3. To inspect merge state, materialize it: `git merge --no-commit --no-ff <branch>`, then `git merge --abort`. Read `git diff <base>..<branch>` for review only, never as input to a hand-applied edit across base.

## Conflict Doctrine (load-bearing)

When `git merge` or `git rebase` stops with unmerged paths (`git diff --name-only --diff-filter=U` lists files):

1. **Abort immediately** — `git merge --abort` (for merge) or `git rebase --abort` (for rebase). Restore the working tree.
2. **Surface, don't resolve.** Output the branch name, the conflict file list (the unmerged-path list above, captured BEFORE abort), and which strategy hit the conflict.
3. **Stop the run.** Do not attempt resolution — resolution never runs inside this skill. The step-2 surface is the conflict scope. Route it: if the consuming repo's harness names a conflict-resolution agent (its CLAUDE.md or agent roster — e.g. a builder/implementer agent), offer dispatching that agent with the conflict scope and the § Resolver contract below as the recommended next step; otherwise the user resolves manually or re-dispatches with a different strategy.

This rule applies to every branch in the queue. If branch A conflicts, abort A, surface, then continue with branches B, C — they're independent attempts. Don't skip them silently.

### Resolver contract

A dispatched conflict-resolution agent works one branch's conflict scope:

1. Re-run that branch's merge or rebase with the strategy named in the surface.
2. Resolve each conflicting file, then stage it — `git add <file>`.
3. Leave the merge or rebase in progress: the agent's last git command is `git add`. Concluding it — `git commit`, `git merge --continue`, `git rebase --continue` — is the gateway's step.
4. Report to the gateway: branch, strategy, files resolved, and how each conflict was settled.

The gateway reads the staged resolution and concludes it in the main session with `git merge --continue` or `git rebase --continue` (a pathspec commit is refused mid-merge). A rebase that stops again on a later commit goes back out as a new resolver scope on the same branch, not through the Conflict Doctrine's abort.

## Protocol

### 1. Gather state (parallel)

- `git branch --show-current` — identify current branch
- `git status` — ensure working tree is clean (if dirty, abort the run, tell user to commit or stash)
- `git branch -v` — list all local branches with last commit
- `git log --oneline --graph --all --decorate -20` — visual overview
- `git worktree list --porcelain` — branches checked out in another worktree: a `branch refs/heads/{branch}` line under a `worktree` entry other than the current checkout marks `{branch}` occupied

### 2. Identify target branches

- If user specified branches: use those
- If on a feature branch with no args: absorb current branch into base
- If on base branch with no args: list all feature branches with divergence info; ask user to clarify which to absorb

### 3. For each candidate branch, gather intel (parallel per branch)

- `git log --oneline {base}..{branch}` — commits ahead
- `git log --oneline {branch}..{base}` — commits behind (base moved since branch)
- `git diff --stat {base}...{branch}` — files changed
- Commit count

### 4. Recommend strategy per branch

| Condition                                | Strategy                                                    |
| ---------------------------------------- | ----------------------------------------------------------- |
| 1 commit, clean apply                    | **Rebase + fast-forward**                                   |
| 2-3 commits, single logical change       | **Rebase + fast-forward**                                   |
| Multi-commit, preserving context matters | **Merge --no-ff**                                           |
| Branch has been pushed/shared            | **Merge --no-ff** — don't rewrite shared history            |
| Branch checked out in another worktree   | **Merge --no-ff** — don't rewrite another worktree's branch |

A shared or occupied branch takes Merge --no-ff whatever its commit count.

Conflict probability is NOT a reason to pick merge over rebase — both surface and abort identically per the conflict doctrine.

Present recommendations as a table; name the holding worktree's path beside an occupied branch. Wait for user confirmation before executing.

### 5. Execute sequentially

Order matters — earlier merges can shift the base for later ones. Run every git command in the current worktree (cwd); never run git inside another worktree.

For each branch in confirmed order:

**Rebase strategy:**

```
git rebase {base} {branch}
git checkout {base}
git merge {branch} --ff-only
```

**Merge strategy:**

```
git checkout {base}
git merge {branch} --no-ff
```

**On a failed command (either strategy):** unmerged paths listed → apply the Conflict Doctrine above. None listed → not a conflict: when a merge or rebase is still in progress (`git status` names one), abort it (`git merge --abort` / `git rebase --abort`); then record the branch under § 7's skipped line with git's error line verbatim and continue with the next branch.

### 6. Per-branch post-absorption

For successfully absorbed branches:

- `git log --oneline -3` to confirm
- Note: do NOT delete the branch. Branch deletion is the user's call after testing.

### 7. Final summary

Report to user:

- Branches absorbed cleanly (with strategy used per branch)
- Branches that hit conflicts (with file lists — the conflict scope a resolver takes under § Resolver contract)
- Branches skipped and why — a failed command that left no conflicting files appears here with git's error line verbatim
- Final `git log --oneline --graph -10`

### 8. Push (where a push surface exists)

Probe first, ask second — the probe is a fact the gateway reads itself. `git remote` prints nothing → no push surface: §7's report is the next and only output. A remote but no upstream for the base (`git rev-parse --abbrev-ref @{u}` errors) → say so in one line and ask once: **"Set upstream and push {base} (`git push -u <remote> {base}`)? (y / skip)"** — `<remote>` is the sole remote, or the one the user names when several exist. Remote + upstream → present base → remote, commits ahead of remote, which branches were folded in; ask **"Push {base} now? (y / skip)"**. Push on explicit yes only; skip on silence or decline. Never force. Branches that hit conflicts are not pushed. Same push-probe shape as the commit skill's § 6.

## Rules

- Run inline — no subagent dispatch.
- Push asks only where a push surface exists, and only on explicit confirmation — §8's probe decides whether the question fires; present what will push, never force, never unannounced.
- Never resolve conflicts inline. Surface and stop. (See Conflict Doctrine above.)
- Never force-merge.
- Never delete branches.
- Dirty working tree: surface to user; staging or stashing is the user's call.
- If on a detached HEAD: stop, surface to user.
- Process branches one at a time within a queue — independence not assumed across the queue.
