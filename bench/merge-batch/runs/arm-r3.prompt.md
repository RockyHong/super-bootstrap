You are running the merge skill below in this repository. Base branch: `main`.
Land the branches `f1` `f2` `f3` into `main`, in that order. I pre-confirm whatever strategy you recommend - execute it without waiting for a reply. Finish by printing your final report (the skill's step 7 summary) as your final output.

---

---
name: merge
description: 'Absorb one or more feature branches into the base branch. One branch: recommends merge vs rebase. Two or more (or `--batch` for any number): batch landing through one integration branch off base — a conflict on derived output only settles by the repo''s declared regenerate command, one verify on the integrated tree (red → bisect names the culprit), base fast-forwards once. On any other conflict, aborts that branch + surfaces the file list. Resolution out of scope; routes to the harness-named conflict-resolution agent (stages the resolution and reports; the gateway concludes it) or the user.'
tags: [merge, git, branch]
---

# merge — Branch Absorption

Absorb feature branches into the base branch; several branches land as one batch (§ 5b). **Conflict resolution is NOT this skill's job** — abort, surface, stop. Regenerating derived output (§ 5b step 2) is not resolution: it takes no judgment.

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

The gateway reads the staged resolution and concludes it in the main session with `GIT_EDITOR=true git merge --continue` or `GIT_EDITOR=true git rebase --continue` (non-interactive; a pathspec commit is refused mid-merge). A rebase that stops again on a later commit goes back out as a new resolver scope on the same branch, not through the Conflict Doctrine's abort.

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
- `--batch`: land through § 5b even for one branch

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

A shared or occupied branch takes Merge --no-ff whatever its commit count. In a batch landing (§ 5b) every branch takes Merge --no-ff — its per-branch merge commit is a bisect point.

Conflict probability is NOT a reason to pick merge over rebase — both surface and abort identically per the conflict doctrine.

Present recommendations as a table; name the holding worktree's path beside an occupied branch. Wait for user confirmation before executing. Two or more confirmed branches, or `--batch` with any number → § 5b; one → § 5.

### 5. Execute sequentially (one branch)

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

### 5b. Batch landing (two or more branches, or `--batch`)

The branches merge in confirmed order into one integration branch off `{base}`; the verify runs once on the integrated tree; `{base}` moves once, by fast-forward. Run every git command in the current worktree (cwd); never run git inside another worktree.

**Derived output** — a path the repo's docs (`docs/techstack.md` or CLAUDE.md Commands) name, beside a regenerate command, as a path that command writes. A regenerate command declared without the paths it writes settles no conflict: the conflict takes the Conflict Doctrine, and § 7 reports the missing declaration.

1. **Open the integration branch** — record `{base}`'s tip as `{base-tip}`, then `git checkout -b integrate/{base}-{YYYYMMDD-HHMMSS} {base}`.
2. **Merge each branch, in confirmed order** — `git merge {branch} --no-ff -m "merge: {branch}"`. On a stop with unmerged paths (`git diff --name-only --diff-filter=U`):
   - **Every unmerged path is derived output** → settle by regeneration: `git checkout --theirs -- <paths>` (either side serves — the command overwrites it), run the regenerate command(s) declared for those paths, `git add <paths>`, confirm the unmerged-path list is empty, then conclude with `GIT_EDITOR=true git merge --continue`. Record the branch as settled by regeneration, with the command run. A regenerate command that exits non-zero → handle the stop as the next bullet, with the command's error in the surface.
   - **Any unmerged path is not derived output** → the Conflict Doctrine: abort this branch's merge, surface it with the integration branch as its merge target, continue with the next branch.
   - A failed command with no unmerged paths → § 5's not-a-conflict line.

   The step ends when every confirmed branch is merged into the integration branch, surfaced, or skipped.
3. **Settle surfaced branches** — per surfaced branch, offer: dispatch the conflict-resolution agent (§ Resolver contract, merge target = the integration branch; the gateway concludes it there) or leave the branch out of this batch. The step ends when every surfaced branch is concluded on the integration branch or left out.
4. **Verify once, on the integrated tree** — run the provisioning commands the repo's docs declare (the install command when a merged branch changed a manifest or lockfile, then every regenerate command), then the repo's declared verify command (the `## Staged-Tree Verify` block in `docs/techstack.md`). No verify command declared → skip provisioning (the derived conflicts were already settled in step 2) and go to step 6, with § 7 reporting the verify as none declared. Green → step 6. Red → step 5.
5. **Red → name the culprit** — before every checkout in this step, `git checkout -- .` discards the tracked files provisioning changed. Run the same provisioning + verify on `{base-tip}` (`git checkout {base-tip}`). Red there → `{base}` itself is red: surface that with its output, no bisect. Green there → `git checkout integrate/…`, `git bisect start --first-parent integrate/… {base-tip}`, `git bisect run sh -c '<provisioning> && <verify>; rc=$?; git checkout -- .; exit $rc'`, then `git bisect reset`. The first bad commit is one branch's merge commit; its second parent names the culprit branch. Surface the culprit and the verify output. `{base}` stays at `{base-tip}`; the integration branch stays for inspection; no fast-forward, no push ask.
6. **Green → fast-forward once** — provisioning left tracked files changed → commit them on the integration branch first (`git commit -am "chore: regenerate derived output"`). Then `git checkout {base}`, `git merge --ff-only integrate/…`, then `git branch -d integrate/…`. A refused fast-forward (`{base}` moved during the batch) → surface git's error line, keep the integration branch, no push ask.

### 6. Per-branch post-absorption

For successfully absorbed branches:

- `git log --oneline -3` to confirm
- Note: do NOT delete the branch. Branch deletion is the user's call after testing.

### 7. Final summary

Report to user:

- Branches absorbed cleanly (with strategy used per branch)
- Batch landing: the integration branch, branches settled by regeneration (with the command run), any conflict that took the Conflict Doctrine because its regenerate command declares no written paths, the verify result (green, red with the culprit branch, or none declared), and whether `{base}` fast-forwarded
- Branches that hit conflicts (with file lists — the conflict scope a resolver takes under § Resolver contract)
- Branches skipped and why — a failed command that left no conflicting files appears here with git's error line verbatim
- Final `git log --oneline --graph -10`

### 8. Push (where a push surface exists)

Probe first, ask second — the probe is a fact the gateway reads itself. `git remote` prints nothing → no push surface: §7's report is the next and only output. A remote but no upstream for the base (`git rev-parse --abbrev-ref @{u}` errors) → say so in one line and ask once: **"Set upstream and push {base} (`git push -u <remote> {base}`)? (y / skip)"** — `<remote>` is the sole remote, or the one the user names when several exist. Remote + upstream → present base → remote, commits ahead of remote, which branches were folded in; ask **"Push {base} now? (y / skip)"**. Push on explicit yes only; skip on silence or decline. Never force. Branches that hit conflicts are not pushed. Same push-probe shape as the commit skill's § 6.

## Rules

- Run inline — no subagent dispatch.
- Push asks only where a push surface exists, and only on explicit confirmation — §8's probe decides whether the question fires; present what will push, never force, never unannounced.
- Never resolve conflicts inline. Surface and stop. (See Conflict Doctrine above.) A conflict on derived output only settles by its declared regenerate command (§ 5b step 2).
- Never force-merge.
- Never delete the absorbed branches. The batch's own integration branch goes with `git branch -d` once `{base}` holds it.
- Dirty working tree: surface to user; staging or stashing is the user's call.
- If on a detached HEAD: stop, surface to user.
- Process branches one at a time within a queue — independence not assumed across the queue.
