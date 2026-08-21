# Ensure infra — idempotent worktree-infra install

drain needs three pieces of infra committed in the consumer repo. (A fourth — the subprocess boundary anchor — rides the scoped brief, not the repo: `phase-loop.md §Dispatch`.) They ship as **frozen assets** beside this file; ensure-infra places them by mechanical copy / merge — never by regeneration, so there is no drift between repos. Run as `SKILL.md §Pre-flight` step 0.

## The three pieces

| # | Frozen asset | Destination | Operation |
| - | ------------ | ----------- | --------- |
| 1 | — | `.gitignore` | Ensure both a `.claude/worktrees/` line and a `.drain-status` line exist (append if absent). The `.drain-status` line keeps the per-worktree live status off the branch under `git add -A` (`phase-loop.md §Status contract`). |
| 2 | `worktree-settings.local.json` | `.claude/templates/worktree-settings.local.json` | Copy verbatim if absent **or byte-differing** from the asset. The warm step copies this into each worktree's `.claude/settings.local.json`. |
| 3 | `read-hook.json` | `.claude/settings.json` → `hooks.PreToolUse[]` | **Merge** the single entry if absent; **replace that one entry in place** if it differs from the asset — never overwrite the file or other hooks. |

Copy the template with Bash `cp` (a plain file copy); the hook entry merges into `settings.json` via a guarded read-modify-write that touches only the `PreToolUse` array.

## Idempotency — content-aware (copy-on-drift)

Existence alone is not enough: an upstream change to a frozen asset must reach repos that already carry an older copy. Each step is checked for **presence**, and the two frozen assets additionally for **currency** against the asset shipped beside this file (same copy-on-drift pattern as `../../harness-bootstrap/assets/hooks-ensure-infra.md §Idempotency`):

```
templateCurrent():
  installed = .claude/templates/worktree-settings.local.json
  exists(installed)   AND   bytes(installed) == bytes(asset worktree-settings.local.json)
  # absent → install lane (confirm below); differing → re-copy the asset verbatim, silently

readHookCurrent():
  entry = the settings.json hooks.PreToolUse entry whose command greps ".claude/worktrees/"
  exists(entry)   AND   entry deep-equals asset read-hook.json's entry (matcher + hooks)
  # absent → install lane (confirm below); differing → replace that one entry in place, silently

infraPresent():
  gitignore has ".claude/worktrees/"   AND
  gitignore has ".drain-status"   AND
  templateCurrent()   AND
  readHookCurrent()
```

All present and current → pass silently, proceed to Pre-flight step 1. Present but drifted → re-place the drifted piece from the asset (no confirm — the infra is already installed; this is the asset refresh), report what changed, stage it with the session's next commit. Any piece **absent** → surface the one-time install confirm:

```
/super-bootstrap:drain needs worktree infra installed (first run):
  + .gitignore       .claude/worktrees/ , .drain-status  (two ignore lines)
  + .claude/templates/worktree-settings.local.json  (worktree permission template)
  + .claude/settings.json  PreToolUse(Read) guard (merged, your other hooks untouched)
Install? [y/N]
```

Decline → HALT (drain can't run without isolation infra). Accept → place the three, then stage + commit them (`/super-bootstrap:commit`).

## Hook activation

`settings.json` hook edits are picked up mid-session by the file-watcher (no restart — `hook-agent-type.md`), so the `PreToolUse(Read)` guard goes live shortly after the merge. Regardless of timing, the gateway's behavioral Read-discipline (`SKILL.md §Read discipline` — read-around paths, never `Read` inside a worktree) is the primary contract; the hook is the mechanical backstop.

## Roles

Durable harness config, not a temporal pipeline artifact — so no cleaner:

- **Creator** — ensure-infra (first run).
- **Consumer** — the warm step (template → worktree), the gateway (Read-hook + boundary-anchor embed at dispatch).
- **Cleaner** — none; the infra lives until the user removes drain. (Contrast worktrees, which are temporal and *do* have a teardown cleaner — `parallel-worktrees.md §Cleanup`.)

## Optional delegated seed

`harness-bootstrap` may call this same procedure during install when the user opts in (most dev repos drain; skill/plugin repos decline). That path delegates here — one home for the install logic, no second copy. See `harness-bootstrap/SKILL.md §Phase 2a-drain (drain infra opt-in)`.
