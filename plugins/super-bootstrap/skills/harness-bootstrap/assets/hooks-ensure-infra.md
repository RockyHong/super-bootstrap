# Hooks ensure-infra — content-aware default-on hook install

harness-bootstrap ships three hook assets. Unlike drain's worktree infra
(`../drain/assets/ensure-infra.md`), install runs **unconditionally** — no opt-in
confirm. All are safe-by-default: A2 (`docsync-gate`) fires at most once per commit;
A1 (`harness-grounding`) never blocks — `additionalContext` only; A3 (`docsync-scan`)
is a plain script the commit skill invokes when the gate is live, and self-stamps
the doc-sync token as a side-effect of running (no separate stamp hook — the skill
produces the artifact, the gate only checks). They ship as **frozen assets** beside
this file; ensure-infra places them by mechanical copy / merge — never regeneration,
so there is no drift between repos. Run as `SKILL.md §2a-hooks`, part of Phase 2a.

## The three assets

| # | Frozen script asset | Destination | Frozen settings snippet | Merge target |
| - | - | - | - | - |
| A2 | `hooks/docsync-gate.sh` | `.claude/hooks/docsync-gate.sh` | `hooks/docsync-gate.hook.json` | `.claude/settings.json` → `hooks.PreToolUse[]` |
| A1 | `hooks/harness-grounding.sh` | `.claude/hooks/harness-grounding.sh` | `hooks/harness-grounding.hook.json` | `.claude/settings.json` → `hooks.PreToolUse[]` |
| A3 | `hooks/docsync-scan.sh` | `.claude/hooks/docsync-scan.sh` | *(none — script only)* | *(no settings entry; invoked by /super-bootstrap:commit when the gate is live)* |

`docsync-scan.sh` (A3) is a plain script with **no settings entry** — the commit
skill calls it as `bash "$CLAUDE_PROJECT_DIR/.claude/hooks/docsync-scan.sh"` (its
own, separate Bash call) when the `docsync-gate` hook is live. Running it writes
`.git/docsync-token` itself — no PostToolUse stamp hook exists.

Copy each script with Bash `cp` (plain file copy — invoked via `bash "$CLAUDE_PROJECT_DIR/.claude/hooks/<name>.sh"`, so no executable bit is required). Merge each `.hook.json` entry into `.claude/settings.json`'s target array via a guarded read-modify-write that touches only that array — the same merge mechanism as drain's `read-hook.json` (`../drain/assets/ensure-infra.md` step 3), reused rather than re-derived.

## Retired hooks — remove on re-sync

`docsync-stamp` (formerly A4, a PostToolUse hook) is retired: its job (writing
`.git/docsync-token`) is now `docsync-scan.sh`'s own side-effect. On any re-sync
of an already-bootstrapped repo:

1. If `.claude/hooks/docsync-stamp.sh` exists, delete it.
2. Remove the `hooks.PostToolUse[]` entry in `.claude/settings.json` whose
   `command` references `docsync-stamp.sh` (match by script filename) — a
   surgical array-element removal, touching no other entry.

Idempotent: a repo with no `docsync-stamp.sh` and no matching settings entry is
already clean, nothing to do.

## Idempotency — content-aware (copy-on-drift)

Existence alone is not enough: an upstream fix to a frozen script must reach repos
that already have an older copy. Each frozen script carries a version marker on its
second line — `# FROZEN <name> vN` (e.g. `# FROZEN docsync-scan v1`). The
present-check compares the **installed** copy's marker against the **asset's** marker
and re-copies on any mismatch (missing, older, or byte-differing):

```
scriptCurrent(name):
  installed = .claude/hooks/<name>.sh
  exists(installed)   AND
  marker-line of installed == marker-line of asset hooks/<name>.sh
  # mismatch (absent | different version | edited) → re-copy the asset verbatim

hooksInfraPresent():
  scriptCurrent(docsync-gate)        AND
  scriptCurrent(harness-grounding)   AND
  scriptCurrent(docsync-scan)        AND
  settings.json hooks.PreToolUse  has an entry whose command references docsync-gate.sh   AND
  settings.json hooks.PreToolUse  has an entry whose command references harness-grounding.sh
```

All current → skip silently (`✓ current`), no message. Any drift → re-copy the drifted
script (verbatim, overwriting the stale copy) and/or merge the missing settings entry,
report what changed, stage with the Phase 2c commit. This is copy-on-drift, not a
migration engine — the asset is always the source of truth, the installed copy is
replaceable. **No confirm gate** — default-on, unlike drain's `infraPresent()`
install-confirm.

## Hook activation

`settings.json` hook edits are picked up mid-session by the file-watcher (no restart
— `hook-agent-type.md`), so both guards go live shortly after the merge.

## Roles

Durable harness config, not a temporal pipeline artifact — so no cleaner:

- **Creator** — harness-bootstrap Phase 2a-hooks (first run, and every sync re-run —
  idempotent, so a re-run only fills what's missing).
- **Consumer** — the consumer repo's own `git commit` calls (A2), `Edit`/`Write`
  calls (A1), and /super-bootstrap:commit's doc-sync scan (A3 script, which
  self-stamps the token).
- **Cleaner** — none; the infra lives until the user removes the harness.

## Self-containment (hard constraint)

All three scripts and their settings snippets are copied verbatim — no template
substitution, no reference to any super-bootstrap-specific state beyond what
harness-bootstrap itself stamps (`CLAUDE.md`, `.claude/rules/`, `docs/`).
`harness-grounding.sh`'s injected `additionalContext` text names only git log,
`.claude/rules/index.md` (or the rule file matching the edited path), and the
verify pass — never `/load-harness-principles` or any other device-only skill,
since those do not exist on a bare consumer repo. `docsync-scan.sh` references
only git and `$CLAUDE_PROJECT_DIR`; `docsync-gate.sh` additionally names the
`/super-bootstrap:commit` route in its deny message (a bundled plugin skill every
consumer has) — no device-only skill names, no super-bootstrap state.
