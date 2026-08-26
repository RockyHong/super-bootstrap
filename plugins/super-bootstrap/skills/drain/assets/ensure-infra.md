# Ensure infra — idempotent worktree-infra install

drain needs three pieces of infra committed in the consumer repo. (A fourth — the subprocess boundary anchor — rides the scoped brief, not the repo: `phase-loop.md §Dispatch`.) They ship as **frozen assets** beside this file; ensure-infra places them by mechanical copy / merge — never by regeneration, so there is no drift between repos. Run as `SKILL.md §Pre-flight` step 0.

## The three pieces

| # | Frozen asset | Destination | Operation |
| - | ------------ | ----------- | --------- |
| 1 | — | `.gitignore` | Ensure both a `.claude/worktrees/` line and a `.drain-status` line exist (append if absent). The `.drain-status` line keeps the per-worktree live status off the branch under `git add -A` (`phase-loop.md §Status contract`). |
| 2 | `worktree-settings.local.json` | `.claude/templates/worktree-settings.local.json` | Copy verbatim if absent, or byte-differing from the asset while still matching the hash this pipeline placed (§ Idempotency splits the byte-differing case). The warm step copies this into each worktree's `.claude/settings.local.json`. |
| 3 | `read-hook.json` | `.claude/settings.json` → `hooks.PreToolUse[]` | **Merge** the single entry if absent; **replace that one entry in place** if it differs from the asset — never overwrite the file or other hooks. |

Copy the template with Bash `cp` (a plain file copy); the hook entry merges into `settings.json` via a guarded read-modify-write that touches only the `PreToolUse` array.

## Idempotency — content-aware (copy-on-drift, fork-aware)

Existence alone is not enough: an upstream change to a frozen asset must reach repos that already carry an older copy. Each step is checked for **presence**, and the two frozen assets additionally for **currency** against the asset shipped beside this file (same copy-on-drift pattern as `../../harness-bootstrap/assets/hooks-ensure-infra.md §Idempotency` — that section is the pattern source, fork split included):

```
templateCurrent():
  installed = .claude/templates/worktree-settings.local.json
  exists(installed)   AND   bytes(installed) == bytes(asset worktree-settings.local.json)
  # absent → install lane (confirm below); differing → resolve via templateUntouched

templateUntouched():
  installed = .claude/templates/worktree-settings.local.json
  placed    = .claude/super-bootstrap-runway.json
              → placed[".claude/templates/worktree-settings.local.json"]
  exists(placed)   AND   sha256(installed) == placed
  # true  → the file sits exactly as this pipeline placed it → stale
  # false → the file carries edits this pipeline did not place → fork
  # no placed entry (receipt absent or predating the field) → unknown, resolved as fork

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

All present and current → pass silently, proceed to Pre-flight step 1.

A drifted **settings entry** (`readHookCurrent()` false, present) replaces in place, silently — a JSON registration this pipeline owns, not a consumer-editable file. A drifted **template** resolves by which side moved:

- **Stale** (`templateCurrent()` false, `templateUntouched()` true) — the placed copy is intact and only lags the asset. Re-copy the asset verbatim, silently; report `⚠ drifted → updated (stale)`.
- **Fork** (`templateCurrent()` false, and `templateUntouched()` false or no `placed` entry) — the installed file carries content this pipeline did not place. Stop and ask, three parts:
  1. **Found** — the installed path and its sha256, beside the asset's.
  2. **Expected** — that file exactly as the last run placed it: the `placed` hash, or `no placed entry — this copy came from outside this pipeline`.
  3. **Pick** — `overwrite` re-places the asset verbatim (report `⚠ drifted → updated (fork, overwritten)`); `keep` leaves the file as it stands (report `⚠ drifted → kept (fork)`). Say with the pick that `keep` holds for this run only — the next run meets the same fork and asks again; a consumer variant of a frozen asset is not a supported state. The pick resolves the template alone; continue with the remaining `infraPresent()` checks.

Report what changed, stage it with the session's next commit. After copying the template, record `placed[".claude/templates/worktree-settings.local.json"] = sha256(asset worktree-settings.local.json)` in `.claude/super-bootstrap-runway.json` — a guarded read-modify-write touching only that one `placed` key, leaving `version` / `covered` / `declined` as found; file absent → create it carrying `placed` alone.

Any piece **absent** → surface the one-time install confirm:

```
/super-bootstrap:drain needs worktree infra installed (first run):
  + .gitignore       .claude/worktrees/ , .drain-status  (two ignore lines)
  + .claude/templates/worktree-settings.local.json  (worktree permission template)
  + .claude/settings.json  PreToolUse(Read) guard (merged, your other hooks untouched)
Install? [y/N]
```

Decline → HALT (drain can't run without isolation infra). Accept → place the three, record the template's `placed` hash the same way, then stage + commit them (`/super-bootstrap:commit`).

## Hook activation

`settings.json` hook edits are picked up mid-session by the file-watcher (no restart — `hook-agent-type.md`), so the `PreToolUse(Read)` guard goes live shortly after the merge. Regardless of timing, the gateway's behavioral Read-discipline (`SKILL.md §Read discipline` — read-around paths, never `Read` inside a worktree) is the primary contract; the hook is the mechanical backstop.

## Roles

Durable harness config, not a temporal pipeline artifact — so no cleaner:

- **Creator** — ensure-infra (first run).
- **Consumer** — the warm step (template → worktree), the gateway (Read-hook + boundary-anchor embed at dispatch).
- **Cleaner** — none; the infra lives until the user removes drain. (Contrast worktrees, which are temporal and *do* have a teardown cleaner — `parallel-worktrees.md §Cleanup`.)

## Optional delegated seed

`harness-bootstrap` may call this same procedure during install when the user opts in (most dev repos drain; skill/plugin repos decline). That path delegates here — one home for the install logic, no second copy. See `harness-bootstrap/SKILL.md §Phase 2a-drain (drain infra opt-in)`.
