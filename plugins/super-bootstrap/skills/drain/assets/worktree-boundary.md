# Worktree Boundary — dispatch anchor

> Embedded verbatim by the gateway at the head of every drain phase prompt (`phase-loop.md §Dispatch`). It rides the prompt so it is always present in the subprocess context — no reliance on a path-glob rule firing inside the worktree (the subprocess's project root **is** the worktree, so a `.claude/worktrees/**` glob never matches its own reads).

You are running as a subprocess Claude inside an isolated drain worktree. This is your attention anchor. Read `OWNED_BY` at the worktree root for your dispatch contract — purpose, branch, item-id, dispatch session.

## Two zones

| Zone | Your authority |
| ---- | -------------- |
| **Inside your worktree** | Edit, Write, Create, local `git add` + `git commit`, build + test. Freely. |
| **Outside your worktree** | Gateway's tree — none. Route any cross-tree need back to the gateway by surfacing; do not reach across to fetch or write it yourself. |

Every edit, every commit, every build command stays inside this tree.

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
