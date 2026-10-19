You are running the merge procedure below in this repository. Base branch: `main`.
Land the branch `feature/x` into `main`. I pre-confirm whatever strategy you recommend in step 4 - execute it without waiting for a reply. Finish by printing the step 7 report as your final output.

## Conflict Doctrine (load-bearing)

When `git merge` or `git rebase` produces conflicts:

1. **Abort immediately** — `git merge --abort` (for merge) or `git rebase --abort` (for rebase). Restore the working tree.
2. **Surface, don't resolve.** Output the branch name, the conflict file list (`git diff --name-only --diff-filter=U` captured BEFORE abort), and which strategy hit the conflict.
3. **Stop the run.** Do not attempt resolution — resolution never runs inside this skill. The step-2 surface is the conflict scope. Route it: if the consuming repo's harness names a conflict-resolution agent (its CLAUDE.md or agent roster — e.g. a builder/implementer agent), offer dispatching that agent with the conflict scope as the recommended next step; otherwise the user resolves manually or re-dispatches with a different strategy.

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
- Branches that hit conflicts (with file lists — the conflict scope for resolution)
- Branches skipped and why
- Final `git log --oneline --graph -10`

