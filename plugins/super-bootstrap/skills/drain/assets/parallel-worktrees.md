# Parallel Worktrees — mechanism reference

The hard-FS-isolation primitive `/super-bootstrap:drain` consumes. The gateway owns the full lifecycle; each subprocess Claude works inside one assigned worktree only. This is a look-up reference — the firing rules live in `SKILL.md` and `phase-loop.md`; this file carries the mechanism and the platform pitfalls.

## Naming namespace

Worktrees live at `.claude/worktrees/drain-{id}/` inside the repo, gitignored at `.claude/worktrees/`. The directory's existence **is** the claim. Branch: `drain/{id-lower}`.

## Ownership marker (`OWNED_BY`)

Each worktree carries `.claude/worktrees/drain-{id}/OWNED_BY` at its root — first-class, so the gateway scans it in one shot without cracking open work files:

```yaml
session-id: <gateway session id>
spawn-ts: <ISO-8601>
purpose: drain
branch: drain/{id-lower}
item-id: <BUG-12 | DEBT-7 | GAP-3>
stage: <raw | spec | plan | review>
```

Writer = gateway, at warm step. Readers = gateway (scan/orphan tick) + the subprocess (anchor only, never writes).

## Warm step (gateway lane)

```bash
git worktree add .claude/worktrees/drain-{id} -b drain/{id-lower} {base}
mkdir -p .claude/worktrees/drain-{id}/.claude
cp .claude/templates/worktree-settings.local.json .claude/worktrees/drain-{id}/.claude/settings.local.json
# write OWNED_BY per schema above
```

## Dispatch step

```bash
cd .claude/worktrees/drain-{id}
claude -p "<phase prompt>" \
  --model sonnet \
  --setting-sources local,project \
  --permission-mode acceptEdits \
  --allowedTools "Skill"
```

### Required flags (miss one → silent degrade or hard failure, not a loud error)

Canonical spot for this table — cross-referenced, not restated, from `SKILL.md` and `phase-loop.md`.

| Flag / ordering | If missing |
| ---------------- | ---------- |
| Prompt-first ordering | `--allowedTools` (variadic) swallows a trailing prompt as tool-rule values → `Error: Input must be provided`. |
| `--allowedTools "Skill"` | Bundled skills (`/code-review`) are permission-denied in `-p` mode — review phase silently degrades to a no-op. |
| `--model sonnet` | Subprocess inherits the invoking (gateway) model instead — drain is the widest fan-out surface in the system, so an unspecified tier multiplies cost per item across the whole wave. |
| `--setting-sources local,project` | Worktree's own `settings.local.json` + committed `.claude/` (rules, skills) never register — subprocess runs against the wrong config. |
| `--permission-mode acceptEdits` | Edit/Write inside the worktree prompt for confirmation instead of auto-applying — breaks headless (`-p`) execution. |

Mechanism detail the table doesn't carry (consequences live in the table only):

- Prompt-first: keep the prompt as the first positional, matching the official-docs example `claude -p "<prompt>" --allowedTools ...`; never trail it after `--allowedTools`.
- `--model sonnet` — one subprocess-level pin shared by every phase (triage/execute/review); split per-phase only if a phase proves to need a different tier.
- `--setting-sources local,project` — because cwd = worktree, `project` resolves to the worktree tree (registering its rules + skills); user sources stay excluded. The FS wall is cwd-default + no `--add-dir <gateway>`, independent of source selection.
- `--permission-mode acceptEdits` — auto-accepts Edit/Write within the allow set only; Bash stays deny-by-default unless allowed.

_These `claude -p` flags + the prompt-first ordering are confirmed against the official Claude Code CLI reference and a live end-to-end drain smoke (CC 2.1.183): `--setting-sources` accepts `user,project,local`; `acceptEdits` is a valid `--permission-mode` value; `--allowedTools` is valid (alias `--allowed-tools`) and variadic; `--model` accepts an alias (`sonnet`/`opus`/`haiku`) or a full model id. Re-confirm if the CLI surface moves._

Dispatch via `Bash(run_in_background: true)` so multiple subprocesses run concurrently; the gateway is notified on each completion (push, not poll).

## Dependency provisioning (subprocess-side, stack-agnostic)

A cold worktree from `git worktree add` carries source only — no installed dependencies. The subprocess's first action is the repo's install command (from `docs/techstack.md` / CLAUDE.md Commands — e.g. `npm ci`, `pnpm install`, `pip install -e .`, `cargo fetch`, `go mod download`), run **foreground with an explicit long timeout** (`Bash(timeout: 300000)`) so a slow install completes within the turn instead of being backgrounded and cutting the `-p` turn short. Do **not** symlink the main checkout's installed deps — workspace package links resolve back to the main tree's source and silently break isolation.

## Hard FS boundary mechanism

The boundary is layered, and one layer is missing on native Windows.

| Layer | Mechanism | Role |
| ----- | --------- | ---- |
| **Gate** | Subprocess `claude -p` cwd-default-allow + no `--add-dir <gateway>` → outbound Edit/Write blocked at the tool surface. Template's targeted denies cover the destructive-git lane. | Tool-surface wall. Holds on all platforms. |
| **OS sandbox** | macOS Seatbelt / Linux-WSL2 bubblewrap wrap the process. **Native Windows: none shipped.** | Contains indirect subprocess writes (`node -e`, build scripts) the gate can't see. |
| **Anchor** | `worktree-boundary.md` embedded at the head of each dispatch prompt (`phase-loop.md §Dispatch`). | Attention anchor — defense against drift, not FS enforcement. |
| **Ownership** | Gateway holds the destructive-git lane; user-as-gate fires at gateway prompts. | Hand-off contract. |

### Windows residual gap

`permissions.deny` does not introspect indirect subprocess writes, and native Windows ships no OS sandbox — so a deliberately-misbehaving subprocess could route a write through `node -e` or a build script past the gate. Likelihood low (requires deliberate misbehavior, not drift); severity high. The defense on Windows is **behavioral**: the worktree-boundary anchor (embedded at dispatch) + dispatch-contract clarity in `OWNED_BY`. For a hard security boundary, run drain under WSL2 / a dev container / macOS. (`isolation:"worktree"` on the Agent tool does **not** help — it is collision-prevention, runs in-process, and inherits the parent's permission config; real per-worktree isolation needs separate `claude -p` processes.)

## Read discipline

The gateway reads worktree state **without** ever `Read`-ing a path under `.claude/worktrees/{id}/` — a worktree-internal Read re-injects that worktree's nested CLAUDE.md + path rules as system-reminders, once per file, compounding across a wave until the context budget blows. `Bash`-`git`, `Grep`, `Glob` do not trigger it.

| Target | Read-around |
| ------ | ----------- |
| Committed files (scope) | `git show {branch}:<path>` / `git log` from the gateway tree |
| Live status (`.drain-status`, uncommitted) | `cat .claude/worktrees/drain-{id}/.drain-status` |
| Gitignored markers (`OWNED_BY`, presence) | `Grep` / `Glob` / `git status` / `git worktree list` |
| Subprocess return | background task-output capture |
| Crashed-worktree diagnosis | `git -C .claude/worktrees/{id} status / diff / log`; `git show {branch}:<path>` for committed content |

Backed by the `PreToolUse(Read)` hook (`read-hook.json`, installed by ensure-infra): blocks Read of `.claude/worktrees/` paths (exit 2), with a `CLAUDE_PROJECT_DIR` guard clause so a subprocess reading its own tree is exempt. Tool-scoped to Read only — a permission deny on the path would also block `cd` into the subtree and break dispatch.

## Concurrent dispatch

The gateway holds no in-head state — it re-reads `OWNED_BY` (via `Grep`/`Glob`) + committed status (via `git show`) per tick. Tick triggers: subprocess-completion notification (primary), or `/super-bootstrap:drain status` (on-demand re-orient).

## Cleanup authority

**Gateway only.** Subprocesses never run `git worktree remove`, recursive deletes, or `git branch -D`. Teardown flow: orphan scan surfaces a stale worktree → gateway proposes removal with age + stage → user approves → gateway tears down via the platform-safe path below, then `git branch -D drain/{id-lower}`.

### Windows-safe teardown

```
cmd.exe //c "rmdir /s /q .claude\worktrees\drain-{id}"
```

- **`rmdir /s /q` from native `cmd`** deletes the tree directly — keeping teardown out of `git worktree remove`'s internal recursive-delete path, which can destroy the host `.git/` when run from an ambiguous cwd. If `git worktree remove` is needed for git bookkeeping, run it **after** the directory is already gone, and always `cd <repo-root>` first.
- **MSYS flag-rewrite:** when shelling through Git-Bash, the bare `cmd /c "..."` form has its single-slash `/c` rewritten as a path and opens an interactive banner that silently no-ops. Use the escaped `cmd.exe //c` form.
- **Forbidden:** `Remove-Item -Recurse` / `rm -rf` on the worktree (Windows file-handle locks leave it partial + flaky); bare `git worktree remove --force` from an ambiguous cwd (the host-`.git/`-destroying recursive-delete hazard above). The friction (no recursive-delete shortcut) is the defense — never pre-allow `git worktree remove` in settings; let the user-prompt fire every time.

## Nested-worktree false-greens

A worktree is physically nested inside the parent repo, and module resolution walks **up** past the worktree boundary into the parent's installed dependencies when the worktree's own resolution fails — so a build can PASS in a worktree by resolving phantom deps from the parent, masking breaks a real checkout would surface. This is a property of physical nesting + the resolver's walk-up, independent of package-manager config.

**Rule:** install-dependent or native-build verification (anything exercising module resolution) must run on a **real, non-nested checkout**, never the nested worktree. Worktrees are sound for code-edit isolation; they are unsound as the verification surface for resolution. If a drained item's verification is resolution-sensitive, run that verification gateway-side at the merge gate (on the merged, non-nested base), not in the worktree.
