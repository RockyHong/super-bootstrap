# Hooks ensure-infra — content-aware default-on hook install

harness-bootstrap ships three hook assets. Unlike drain's worktree infra
(`../drain/assets/ensure-infra.md`), install runs **unconditionally** — no opt-in
confirm. All are safe-by-default: `commit-channel` fires only on git commit and denies
raw commits from worker subagents — the main session is never blocked; the
`consult-check` pair only injects a doc catalog (read activation, no gating). Each
ships as a **frozen asset** beside this file; ensure-infra places it by mechanical
copy / merge — never regeneration, so there is no drift between repos. Run as
`SKILL.md §2a-hooks`, part of Phase 2a.

## The assets

| # | Frozen script asset | Destination | Frozen settings snippet | Merge target |
| - | - | - | - | - |
| 1 | `hooks/commit-channel.sh` | `.claude/hooks/commit-channel.sh` | `hooks/commit-channel.hook.json` | `.claude/settings.json` → `hooks.PreToolUse[]` |
| 2 | `hooks/consult-check-sessionstart.sh` | `.claude/hooks/consult-check-sessionstart.sh` | `hooks/consult-check-sessionstart.hook.json` | `.claude/settings.json` → `hooks.SessionStart[]` |
| 3 | `hooks/consult-check-check.sh` | `.claude/hooks/consult-check-check.sh` | `hooks/consult-check-check.hook.json` | `.claude/settings.json` → `hooks.UserPromptSubmit[]` |

Copy each script with Bash `cp` (plain file copy — invoked via `bash "$CLAUDE_PROJECT_DIR/.claude/hooks/<name>.sh"`, so no executable bit is required). Merge each `.hook.json` entry into `.claude/settings.json`'s target array via a guarded read-modify-write that touches only that array — the same merge mechanism as drain's `read-hook.json` (`../drain/assets/ensure-infra.md` step 3), reused rather than re-derived.

The consult pair installs together — the SessionStart deriver writes the
`.claude/.consult-catalog` cache the UserPromptSubmit injector reads; one without the
other is either a dead write or a silent no-op. Its install also appends
`.claude/.consult-catalog` to the repo's `.gitignore` when absent (per-session
regenerated cache, local-only). A repo that already carries the pair from another
manager (a prior device-level plant) is drift-checked by the same version-marker
mechanism below — the frozen asset here is the SSOT.

## Retired hooks — remove on re-sync

Five hooks are retired — delete them from any already-bootstrapped repo on re-sync:

- `entry-nudge` (formerly a UserPromptSubmit injector — one card-grounded-entry
  pointer per prompt) — retired as an unearned redundant push: the entry-discipline
  lives in full in CLAUDE.md § Development Workflow (ambient, reaches every turn and
  every dispatched subagent); the every-prompt pointer added only anti-decay
  repetition.
- `harness-grounding` (formerly a PreToolUse `Edit|Write` nudge on harness-path
  edits) — retired as out of scope: harness-bootstrap scaffolds a repo's harness;
  ongoing harness-editing discipline belongs to the actor's own device config, not
  to a repo scaffold.
- `docsync-gate` (formerly a PreToolUse commit gate) and `docsync-scan` (its
  self-stamping scan script) — doc-sync now runs gateway-inline in the commit door
  (`/super-bootstrap:commit`), so the token gate and its scan are gone.
- `docsync-stamp` (formerly a PostToolUse hook) — retired earlier when its
  token-write folded into `docsync-scan`.

On any re-sync of an already-bootstrapped repo:

1. For each of `entry-nudge.sh`, `harness-grounding.sh`, `docsync-gate.sh`, `docsync-scan.sh`, `docsync-stamp.sh` — if the
   file exists at `.claude/hooks/<name>.sh`, delete it.
2. Remove any `.claude/settings.json` hook entry whose `command` references one of
   those scripts (match by script filename) — a surgical array-element removal,
   touching no other entry.

Idempotent: a repo with none of the retired scripts and no matching settings entry is
already clean, nothing to do.

## Idempotency — content-aware (copy-on-drift)

Existence alone is not enough: an upstream fix to a frozen script must reach repos
that already have an older copy. Each frozen script carries a version marker on its
second line — `# FROZEN <name> vN` (e.g. `# FROZEN commit-channel v4`). The
present-check compares the **installed** copy's marker against the **asset's** marker
and re-copies on any mismatch (missing, older, or byte-differing):

```
scriptCurrent(name):
  installed = .claude/hooks/<name>.sh
  exists(installed)   AND
  marker-line of installed == marker-line of asset hooks/<name>.sh
  # mismatch (absent | different version | edited) → re-copy the asset verbatim

hooksInfraPresent():
  scriptCurrent(commit-channel)              AND
  scriptCurrent(consult-check-sessionstart)  AND
  scriptCurrent(consult-check-check)         AND
  settings.json hooks.PreToolUse       has an entry whose command references commit-channel.sh          AND
  settings.json hooks.SessionStart     has an entry whose command references consult-check-sessionstart.sh AND
  settings.json hooks.UserPromptSubmit has an entry whose command references consult-check-check.sh     AND
  .gitignore contains .claude/.consult-catalog
```

All current → skip silently (`✓ current`), no message. Any drift → re-copy the drifted
script (verbatim, overwriting the stale copy), and/or merge the missing settings entry,
and/or re-append `.claude/.consult-catalog` to `.gitignore`,
report what changed, stage with the Phase 2c commit. This is copy-on-drift, not a
migration engine — the asset is always the source of truth, the installed copy is
replaceable. **No confirm gate** — default-on, unlike drain's `infraPresent()`
install-confirm.

## Hook activation

`settings.json` hook edits are picked up mid-session by the file-watcher (no restart
— `hook-agent-type.md`), so the guards go live shortly after the merge.

## Roles

Durable harness config, not a temporal pipeline artifact — so no cleaner:

- **Creator** — harness-bootstrap Phase 2a-hooks (first run, and every sync re-run —
  idempotent, so a re-run only fills what's missing).
- **Consumer** — the consumer repo's own `git commit` calls (`commit-channel`); every
  session boundary + prompt in the repo (`consult-check` pair).
- **Cleaner** — none; the infra lives until the user removes the harness.

## Self-containment (hard constraint)

The scripts and their settings snippets are copied verbatim — no template
substitution, no reference to any super-bootstrap-specific state beyond what
harness-bootstrap itself stamps (`CLAUDE.md`, `.claude/rules/`, `docs/`).
`commit-channel.sh`'s deny text names only `/super-bootstrap:commit` (a bundled
plugin skill every consumer has) — no device-only skill names, no super-bootstrap state.
The `consult-check` pair reads only the consumer's own `docs/**` and
`.claude/consult-exclude`; its bench provenance lives at the plugin-source repo
(`bench/consult-hook/`), never referenced at runtime.
