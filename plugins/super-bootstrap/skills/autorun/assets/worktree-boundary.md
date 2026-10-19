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

## Provisioning

Read the commands from the repo's docs (`docs/techstack.md` / CLAUDE.md Commands): the install command, and every command they name for regenerating derived state (codegen output, an import cache). Run each foreground with an explicit long timeout (`Bash(timeout: 300000)`).

- **Cold tree** — your first action is the install command, then the regenerate commands.
- **Before every verify** — run `git log` on your branch. If it shows commits this session did not make (a merge commit, or an earlier session's commits when you are re-spawned into a tree it left), the sources moved since the tree was provisioned: run the regenerate commands first, and the install command too when one of those commits changed a manifest or lockfile.

## Harness edits go on the card

Harness files — `CLAUDE.md`, `.claude/**`, and the repo's skill / agent / rule files — stay as they are in this tree; the gateway applies harness edits on the base branch after the merge, where the harness audit runs. When your card's work includes one:

1. Append a `## Harness edits — {date}` block to the card. Per harness edit: the file path, the exact old string copied from the file, and the new string, each in its own fenced block. Confirm with `grep -c -F` that each old string occurs once in its file; lengthen it until it does.
2. A harness edit that is not a replacement of existing text — a new file, a file deletion — has no form here: stop with `WALL — harness edit is not a text replacement: {path}`.
3. Keep the card file — the gateway deletes it once every edit is applied.
4. Commit the rest of the work and the Harness edits block as usual, then write the status `DONE — harness pending`.

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
