Do not use any tools. Answer from the text below only.

You are the gateway session of /super-bootstrap:autorun, working in the main checkout on `main`. The autorun skill text you run under reads:

---
## Rules

- **Gateway holds destructive git.** Merge, push, worktree removal, branch deletion — gateway only, each behind a user prompt. Sessions hand off through the status line.
- **State = file presence.** Worktree dir + `OWNED_BY` + card thread + branch. Every invocation re-reads; nothing is remembered across turns.
- **Read-around, never Read-in.** `git show autorun/{id-lower}:<path>`, `cat` the status file, `Grep` / `Glob` markers — mechanically backed by the `PreToolUse(Read)` hook ensure-infra installs.
- **Verification that depends on module resolution runs at the merge, on the base tree** — a nested worktree can resolve phantom deps from the parent (`assets/parallel-worktrees.md` § Nested-worktree false-greens).

From `assets/parallel-worktrees.md`:

## Dependency provisioning (subprocess-side, stack-agnostic)

A cold worktree from `git worktree add` carries source only — no installed dependencies. The subprocess's first action is the repo's install command (from `docs/techstack.md` / CLAUDE.md Commands — e.g. `npm ci`, `pnpm install`, `pip install -e .`, `cargo fetch`, `go mod download`), run **foreground with an explicit long timeout** (`Bash(timeout: 300000)`) so a slow install completes within the turn instead of being backgrounded and cutting the `-p` turn short. Do **not** symlink the main checkout's installed deps — workspace package links resolve back to the main tree's source and silently break isolation.

## Nested-worktree false-greens

A worktree is physically nested inside the parent repo, and module resolution walks **up** past the worktree boundary into the parent's installed dependencies when the worktree's own resolution fails — so a build can PASS in a worktree by resolving phantom deps from the parent, masking breaks a real checkout would surface. This is a property of physical nesting + the resolver's walk-up, independent of package-manager config.

**Rule:** install-dependent or native-build verification (anything exercising module resolution) must run on a **real, non-nested checkout**, never the nested worktree. Worktrees are sound for code-edit isolation; they are unsound as the verification surface for resolution. If a card's verification is resolution-sensitive, run that verification gateway-side at the merge gate (on the merged, non-nested base), not in the worktree.
---

The repository's CLAUDE.md `## Commands` block reads:

```bash
npm ci              # install dependencies
npm run codegen     # regenerate src/generated/ (git-ignored) from schemas/*.graphql
npm test            # verify: typecheck + unit tests
```

Situation: `/super-bootstrap:merge autorun/gap-12` just landed `autorun/gap-12` on `main` (Merge --no-ff, no conflicts). 6 commits, 11 files changed. Card GAP-12 marks its verification as module-resolution sensitive, so it was deferred to the merge gate. This checkout has `node_modules/` and `src/generated/` from earlier work on `main`.

State, in order, the exact shell commands you run from now up to and including the verify command, each with a one-line reason. Be concrete.
