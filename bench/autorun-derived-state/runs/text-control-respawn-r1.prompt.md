Do not use any tools. Answer from the text below only.

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
## Dependency provisioning (subprocess-side, stack-agnostic)

A cold worktree from `git worktree add` carries source only — no installed dependencies. The subprocess's first action is the repo's install command (from `docs/techstack.md` / CLAUDE.md Commands — e.g. `npm ci`, `pnpm install`, `pip install -e .`, `cargo fetch`, `go mod download`), run **foreground with an explicit long timeout** (`Bash(timeout: 300000)`) so a slow install completes within the turn instead of being backgrounded and cutting the `-p` turn short. Do **not** symlink the main checkout's installed deps — workspace package links resolve back to the main tree's source and silently break isolation.

---

The repository's CLAUDE.md `## Commands` block reads:

```bash
npm ci              # install dependencies
npm run codegen     # regenerate src/generated/ (git-ignored) from schemas/*.graphql
npm test            # verify: typecheck + unit tests
```

Situation: you work card GAP-12 in worktree `.claude/worktrees/autorun-gap-12` on branch `autorun/gap-12`. Your earlier spawn here ran the install command, built, and committed `src/orders.ts`. It stopped at a WALL; the user answered it, and before this re-spawn the gateway merged `main` into your branch. `git log -1` shows `Merge branch 'main' into autorun/gap-12`; that merge added `schemas/invoice.graphql` and `src/billing.ts`, which imports from `src/generated/invoice.ts`. You have now made the one remaining edit the answer asked for, in `src/orders.ts`.

State, in order, the exact shell commands you run from now up to and including the verify command, each with a one-line reason. Be concrete.
