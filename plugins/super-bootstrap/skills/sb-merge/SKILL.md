---
name: sb-merge
description: 'Absorb one or more feature branches into the base branch. Recommends merge vs rebase per branch. On conflict, aborts that branch + surfaces the file list + stops. Resolution out of scope; user decides next.'
tags: [sb, merge, git, branch]
---

# sb-merge — Branch Absorption

Absorb feature branches into the base branch. Per-branch rebase-vs-merge recommendation, mechanical execution. **Conflict resolution is NOT this skill's job** — abort, surface, stop.

## Why inline (not dispatched)

Same logic as `sb-commit`: branch state + conflict context belong in the gateway, not relayed through an agent. Conflict resolution (when it comes) is context-aware — needs full session memory of what was being absorbed and why. Detour through Sonnet would force re-relaying the conflict scope back to the gateway anyway. Frequency is lower than `sb-commit` so token-savings argument doesn't pay for the relay overhead either.

## Conflict Doctrine (load-bearing)

When `git merge` or `git rebase` produces conflicts:

1. **Abort immediately** — `git merge --abort` (for merge) or `git rebase --abort` (for rebase). Restore the working tree.
2. **Surface, don't resolve.** Output the branch name, the conflict file list (`git diff --name-only --diff-filter=U` captured BEFORE abort), and which strategy hit the conflict.
3. **Stop the run.** Do not attempt resolution. Do not offer "resolve now" as an option. Return control to the user. User decides next — resolve manually, route to a fitting reviewer/agent, or re-dispatch with a different strategy. Burning gateway context on three-way merge logic is the wrong shape; resolution is its own pass.

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

| Condition                                | Strategy                  | Why                           |
| ---------------------------------------- | ------------------------- | ----------------------------- |
| 1 commit, clean apply                    | **Rebase + fast-forward** | Clean linear history          |
| 2-3 commits, single logical change       | **Rebase + fast-forward** | Still clean enough            |
| Multi-commit, preserving context matters | **Merge --no-ff**         | Keeps branch grouping visible |
| Branch has been pushed/shared            | **Merge --no-ff**         | Don't rewrite shared history  |

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

## Rules

- Never `cd` — working directory is already correct.
- Never push. Pushing is the user's responsibility.
- Never resolve conflicts inline. Surface and stop. (See Conflict Doctrine above.)
- Never force-merge.
- Never delete branches.
- If working tree is dirty: stop, surface to user, do not attempt to stash automatically.
- If on a detached HEAD: stop, surface to user.
- Process branches one at a time within a queue — independence not assumed across the queue.
