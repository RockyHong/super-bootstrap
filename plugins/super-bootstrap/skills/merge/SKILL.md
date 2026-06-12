---
name: merge
description: 'Absorb one or more feature branches into the base branch. Recommends merge vs rebase per branch. On conflict, aborts that branch + surfaces the file list + stops. Resolution out of scope; user decides next.'
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

When `git merge` or `git rebase` produces conflicts:

1. **Abort immediately** — `git merge --abort` (for merge) or `git rebase --abort` (for rebase). Restore the working tree.
2. **Surface, don't resolve.** Output the branch name, the conflict file list (`git diff --name-only --diff-filter=U` captured BEFORE abort), and which strategy hit the conflict.
3. **Stop the run.** Do not attempt resolution. Do not offer "resolve now" as an option. Return control to the user. User decides next — resolve manually, route to a fitting reviewer/agent, or re-dispatch with a different strategy.

This rule applies to every branch in the queue. If branch A conflicts, abort A, surface, then continue with branches B, C — they're independent attempts. Don't skip them silently.

## Protocol

### 1. Gather state (parallel)

- `git branch --show-current` — identify current branch
- `git status` — ensure working tree is clean (if dirty, abort the run, tell user to commit or stash)
- `git branch -v` — list all local branches with last commit
- `git log --oneline --graph --all --decorate -20` — visual overview

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

Conflict probability is NOT a reason to pick merge over rebase — both surface and abort identically per the conflict doctrine.

Present recommendations as a table. Wait for user confirmation before executing.

### 5. Execute sequentially

Order matters — earlier merges can shift the base for later ones.

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

**On conflict (either strategy):** apply the Conflict Doctrine above. Capture conflict files, abort, surface, continue with the next branch.

### 6. Per-branch post-absorption

For successfully absorbed branches:

- `git log --oneline -3` to confirm
- Note: do NOT delete the branch. Branch deletion is the user's call after testing.

### 7. Final summary

Report to user:

- Branches absorbed cleanly (with strategy used per branch)
- Branches that hit conflicts (with file lists, ready for user to route resolution)
- Branches skipped and why
- Final `git log --oneline --graph -10`

### 8. Push (on confirmation)

After absorption, offer to push the updated base — never run it unannounced. Present:

- base branch → remote, commits ahead of remote
- which branches were folded in

Ask: **"Push {base} now? (y / skip)"** Push only on explicit yes. Skip by default if the user is silent. Never force push. Branches that hit conflicts are not pushed.

## Rules

- Run inline — no subagent dispatch.
- Working directory is already correct; `cd` is unnecessary.
- Push the base only on explicit confirmation — present what will push, never force, never unannounced. (See §8.)
- Never resolve conflicts inline. Surface and stop. (See Conflict Doctrine above.)
- Never force-merge.
- Never delete branches.
- Dirty working tree: surface to user; staging or stashing is the user's call.
- If on a detached HEAD: stop, surface to user.
- Process branches one at a time within a queue — independence not assumed across the queue.
