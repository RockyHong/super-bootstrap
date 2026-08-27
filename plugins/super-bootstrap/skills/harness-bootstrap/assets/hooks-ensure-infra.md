# Hooks ensure-infra — content-aware default-on hook install

harness-bootstrap ships three hook assets. Unlike drain's worktree infra
(`../drain/assets/ensure-infra.md`), install runs **unconditionally** — no opt-in
confirm. All are safe-by-default: `commit-channel`'s hook process spawns on any `git`
call (its `if` anchors on the bare command) and denies only raw `git commit` from
worker subagents — everything else exits 0 silently, and the main session is never
blocked; the
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
manager (a prior device-level plant) is drift-checked by the same copy-on-drift
mechanism below and lands in its fork prompt — the frozen asset here is the SSOT,
and the swap is an explicit pick.

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
3. Remove any `placed[".claude/hooks/<name>.sh"]` key for those scripts from
   `.claude/super-bootstrap-runway.json` — a guarded read-modify-write touching only
   the `placed` map.

Idempotent: a repo with none of the retired scripts and no matching settings entry is
already clean, nothing to do.

## Idempotency — content-aware (copy-on-drift, fork-aware)

Existence alone is not enough: an upstream fix to a frozen asset — script **or**
settings snippet — must reach repos that already have an older copy. Currency compares
**installed** against **asset** whole: a script by sha256 of its bytes, a snippet by
deep-equal against the asset entry. Each frozen script also carries a version marker on
its second line — `# FROZEN <name> vN` (e.g. `# FROZEN commit-channel v5`) — which
names the version in reports and prompts; it is not the currency test, so an edit
anywhere in the file counts as drift. A second script predicate reads the runway
receipt's `placed` map to tell a copy that merely lags the asset (**stale**) from one
carrying consumer edits (**fork**):

```
scriptCurrent(name):
  installed = .claude/hooks/<name>.sh
  exists(installed)   AND   sha256(installed) == sha256(asset hooks/<name>.sh)
  # mismatch (absent | older version | edited anywhere) → resolve via scriptUntouched

scriptUntouched(name):
  installed = .claude/hooks/<name>.sh
  placed    = .claude/super-bootstrap-runway.json → placed[".claude/hooks/<name>.sh"]
  exists(placed)   AND   sha256(installed) == placed
  # true  → the file sits exactly as this pipeline placed it → stale
  # false → the file carries edits this pipeline did not place → fork
  # no placed entry (receipt predates the field, or another manager placed the
  #   file) → unknown, resolved as fork

snippetCurrent(name):
  entry = the settings.json target-array entry whose command references <name>.sh
  exists(entry)   AND
  entry deep-equals asset hooks/<name>.hook.json's entry
                   (matcher + hooks; the asset's top-level _comment is ignored)
  # mismatch (absent | differing) → absent: merge the asset entry;
  #   differing: replace that one entry in place — surgical, touching no other entry

hooksInfraPresent():
  scriptCurrent(commit-channel)              AND
  scriptCurrent(consult-check-sessionstart)  AND
  scriptCurrent(consult-check-check)         AND
  snippetCurrent(commit-channel)             AND
  snippetCurrent(consult-check-sessionstart) AND
  snippetCurrent(consult-check-check)        AND
  .gitignore contains .claude/.consult-catalog
```

All current → skip silently (`✓ current`), no message — the `placed` record below
still runs. A missing script installs from the asset. Script drift resolves by which
side moved:

- **Stale** (`scriptCurrent` false, `scriptUntouched` true) — the placed copy is intact
  and only lags the asset. Re-copy the asset verbatim, silently; report
  `⚠ drifted → updated (stale)`.
- **Fork** (`scriptCurrent` false, and `scriptUntouched` false or no `placed` entry) —
  the installed file carries content this pipeline did not place. Stop and ask, three
  parts:
  1. **Found** — the installed path, its marker line (or `no FROZEN marker`) and its
     sha256, beside the asset's marker line.
  2. **Expected** — that file exactly as the last sync placed it: the `placed` hash, or
     `no placed entry — this copy came from outside this pipeline`.
  3. **Pick** — `overwrite` re-places the asset verbatim (report `⚠ drifted → updated
     (fork, overwritten)`); `keep` leaves the file as it stands (report
     `⚠ drifted → kept (fork)`). Say with the pick that `keep` holds for this sync only
     — the next sync meets the same fork and asks again; a consumer variant of a frozen
     asset is not a supported state. The pick resolves this one script; continue with
     the next check in `hooksInfraPresent()`.

Settings snippets keep replace-in-place, silently — a `.hook.json` entry is a JSON
registration this pipeline owns, not a consumer-editable script — and a missing
`.claude/.consult-catalog` line re-appends to `.gitignore`. Report what changed, stage
with the Phase 2c commit. This is copy-on-drift, not a migration engine — the asset is
the source of truth for every copy this pipeline placed, and the fork prompt is what
keeps an unrecognized copy from being replaced blind. Install stays default-on — no
install confirm, unlike drain's `infraPresent()`; the fork pick is the only prompt.

Whenever a script resolves current — copied this run, or already sha-equal to the asset
— record `placed[".claude/hooks/<name>.sh"] = sha256(asset hooks/<name>.sh)` in
`.claude/super-bootstrap-runway.json` unless the entry already holds that hash: a guarded
read-modify-write touching only that one `placed` key, leaving `version` / `covered` /
`declined` as found; file absent → create it carrying `placed` alone. A sha-equal copy
is byte-identical to the asset whatever placed it, so recording it changes nothing today
and lets the next asset bump resolve as stale instead of fork. Phase 2c's receipt write
(`SKILL.md` § 2c) reads the file back and carries every `placed` entry forward.

One migration this reaches by design: an installed `consult-check` pair predating
the frozen assets — header line `# SessionStart hook — consult-check catalog
derivation (GAP-045 build …`, no `# FROZEN … v1` marker, planted by a device-level
manager, so no `placed` entry — arrives at the fork prompt as unknown. Carry this as
that prompt's context: the frozen v1 pair is the intended successor, and its scan
covers the consumer's own `docs/**` alone — the guidelines trees are split out
deliberately (their rows resolve two ways and cost most of the render budget), so an
`overwrite` dropping those roots is the migration landing as designed.

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
