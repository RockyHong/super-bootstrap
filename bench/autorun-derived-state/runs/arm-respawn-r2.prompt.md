You are a subprocess Claude re-spawned by /super-bootstrap:autorun. Your brief begins with this anchor, verbatim:

---
# Worktree Boundary — dispatch anchor

> Embedded verbatim by the gateway at the head of every autorun brief (`SKILL.md` § Run). It rides the prompt so it is always present in the subprocess context — no reliance on a path-glob rule firing inside the worktree (the subprocess's project root **is** the worktree, so a `.claude/worktrees/**` glob never matches its own reads).

You are running as a subprocess Claude inside an isolated autorun worktree. This is your attention anchor. Read `OWNED_BY` at the worktree root for your dispatch contract — purpose, branch, item-id, dispatch session.

## Two zones

| Zone | Your authority |
| ---- | -------------- |
| **Inside your worktree** | Edit, Write, Create, local `git add` + `git commit`, build + test. Freely. |
| **Outside your worktree** | Gateway's tree — none. Route any cross-tree need back to the gateway by surfacing; do not reach across to fetch or write it yourself. |

Every edit, every commit, every build command stays inside this tree.

Run git commands, file operations (the status-file rename, a card delete) and `/super-bootstrap:commit` through the Bash tool — the commit door's commands are POSIX shell.

## Destructive git is the gateway's lane

Hand these off via a `DONE` status — the gateway runs them behind a user prompt:

- `git push` (any flavor)
- `git merge`, `git rebase`
- `git worktree add`, `git worktree remove`
- `git branch -D`, `git branch -d`
- `git reset --hard`, `git clean`, `git tag`

## Missing data — surface, don't reach

If the data you need lives outside the worktree, stop and surface to the gateway. A self-sufficient worktree is the contract; if it isn't self-sufficient, that's a dispatch gap to surface — the gateway re-dispatches with the missing context inside the tree. A permission denial reaching outside `./` means the gate is working — re-read `OWNED_BY` and stay inside; do not retry through another surface.

## When in doubt

If the work you're about to do crosses the two-zone boundary or contradicts `OWNED_BY`, stop and surface — do not proceed.
---

From the autorun mechanism reference `assets/parallel-worktrees.md`:

---
## Provisioning — dependencies and derived state (stack-agnostic)

A tree's verify reads more than its tracked sources: installed dependencies, and git-ignored derived state built from those sources (codegen output, an engine's import cache, a generated registry). Two commands provision it, both read from the repo's docs (`docs/techstack.md` / CLAUDE.md Commands): the install command (e.g. `npm ci`, `pnpm install`, `pip install -e .`, `cargo fetch`, `go mod download`) and every command those docs name for regenerating derived state.

- **Cold tree** — a worktree from `git worktree add` carries source only. The subprocess's first action is the install command, then the regenerate commands.
- **Before every verify** — whenever tracked sources changed through something other than the verifying session's own edits, run the regenerate commands first, and the install command too when a manifest or lockfile changed. Such changes include a base sync into the branch before a re-spawn and a branch landing on the base tree before the merge-gate verify. A verify on stale derived state reports a break the sources do not have.

Run each **foreground with an explicit long timeout** (`Bash(timeout: 300000)`) so a slow step completes within the turn instead of being backgrounded and cutting the `-p` turn short. Do **not** symlink the main checkout's installed deps — workspace package links resolve back to the main tree's source and silently break isolation.

---

Situation: you work card GAP-12 in this worktree on branch `autorun/gap-12`. Your earlier spawn here provisioned the tree and committed `feat(orders): add total`, then stopped at a WALL. The user answered it, and before this re-spawn the gateway merged `main` into your branch.

Work order: make the one remaining edit the answer asked for - add the line `currency: usd` to `src/orders.src`. Then verify, commit on this branch with plain git (stage the file, then commit; the commit door is not installed in this repo), and write `.autorun-status` at the worktree root: `DONE` when verify passes, else `BLOCKED - {what is wrong}`. End with the status line.
