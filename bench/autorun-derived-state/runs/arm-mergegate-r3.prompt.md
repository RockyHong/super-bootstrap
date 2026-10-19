You are the gateway session of /super-bootstrap:autorun, working in the main checkout (this directory) on `main`. The autorun skill text you run under reads:

---
## Rules

- **Gateway holds destructive git.** Merge, push, worktree removal, branch deletion — gateway only, each behind a user prompt. Sessions hand off through the status line.
- **State = file presence.** Worktree dir + `OWNED_BY` + card thread + branch. Every invocation re-reads; nothing is remembered across turns.
- **Read-around, never Read-in.** `git show autorun/{id-lower}:<path>`, `cat` the status file, `Grep` / `Glob` markers — mechanically backed by the `PreToolUse(Read)` hook ensure-infra installs.
- **Verification that depends on module resolution runs at the merge, on the base tree** — a nested worktree can resolve phantom deps from the parent (`assets/parallel-worktrees.md` § Nested-worktree false-greens). The landing changed the base tree's sources, so the gateway first runs the repo's regenerate commands there (`assets/parallel-worktrees.md` § Provisioning).

From `assets/parallel-worktrees.md`:

## Provisioning — dependencies and derived state (stack-agnostic)

A tree's verify reads more than its tracked sources: installed dependencies, and git-ignored derived state built from those sources (codegen output, an engine's import cache, a generated registry). Two commands provision it, both read from the repo's docs (`docs/techstack.md` / CLAUDE.md Commands): the install command (e.g. `npm ci`, `pnpm install`, `pip install -e .`, `cargo fetch`, `go mod download`) and every command those docs name for regenerating derived state.

- **Cold tree** — a worktree from `git worktree add` carries source only. The subprocess's first action is the install command, then the regenerate commands.
- **Before every verify** — whenever tracked sources changed through something other than the verifying session's own edits, run the regenerate commands first, and the install command too when a manifest or lockfile changed. Such changes include a base sync into the branch before a re-spawn and a branch landing on the base tree before the merge-gate verify. A verify on stale derived state reports a break the sources do not have.

Run each **foreground with an explicit long timeout** (`Bash(timeout: 300000)`) so a slow step completes within the turn instead of being backgrounded and cutting the `-p` turn short. Do **not** symlink the main checkout's installed deps — workspace package links resolve back to the main tree's source and silently break isolation.

## Nested-worktree false-greens

A worktree is physically nested inside the parent repo, and module resolution walks **up** past the worktree boundary into the parent's installed dependencies when the worktree's own resolution fails — so a build can PASS in a worktree by resolving phantom deps from the parent, masking breaks a real checkout would surface. This is a property of physical nesting + the resolver's walk-up, independent of package-manager config.

**Rule:** install-dependent or native-build verification (anything exercising module resolution) must run on a **real, non-nested checkout**, never the nested worktree. Worktrees are sound for code-edit isolation; they are unsound as the verification surface for resolution. If a card's verification is resolution-sensitive, run that verification gateway-side at the merge gate (on the merged, non-nested base), not in the worktree.
---

Situation: `/super-bootstrap:merge autorun/gap-12` just landed `autorun/gap-12` on `main` (Merge --no-ff, no conflicts). Card GAP-12 marks its verification as module-resolution sensitive, so it was deferred to the merge gate.

Run the merge-gate verification now. Do not edit any tracked file. End with one line: `PASS` or `FAIL - {reason}`.
