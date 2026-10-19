Do not use any tools. Answer from the text below only.

You are the conflict-resolution agent dispatched by the /super-bootstrap:merge skill. The merge skill's conflict section reads:

---
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

The gateway reads the staged resolution and concludes it through the commit door (`/super-bootstrap:commit`).

---

Your dispatch: branch `feature/x`, strategy Merge --no-ff into `main`, conflict files `a.md` and `b.md`. You have already re-run `git merge feature/x --no-ff` on `main` and edited `a.md` and `b.md` to remove every conflict marker with the correct combined content.

State, in order, the exact git commands you run next (if any), and then the exact report you return. Be concrete.
