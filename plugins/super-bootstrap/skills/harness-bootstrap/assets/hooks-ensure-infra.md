# Hooks ensure-infra — idempotent default-on hook install

harness-bootstrap ships two `PreToolUse` hooks as frozen assets. Unlike drain's
worktree infra (`../drain/assets/ensure-infra.md`), install runs **unconditionally**
— no opt-in confirm. Both hooks are safe-by-default: A2 (`docsync-gate`) fires at
most once per commit and carries a mechanical escape hatch; A1 (`harness-grounding`)
never blocks — `additionalContext` only. They ship as **frozen assets** beside this
file; ensure-infra places them by mechanical copy / merge — never regeneration, so
there is no drift between repos. Run as `SKILL.md §2a-hooks`, part of Phase 2a.

## The two hooks

| # | Frozen script asset | Destination | Frozen settings snippet | Merge target |
| - | - | - | - | - |
| 1 | `hooks/docsync-gate.sh` | `.claude/hooks/docsync-gate.sh` | `hooks/docsync-gate.hook.json` | `.claude/settings.json` → `hooks.PreToolUse[]` |
| 2 | `hooks/harness-grounding.sh` | `.claude/hooks/harness-grounding.sh` | `hooks/harness-grounding.hook.json` | `.claude/settings.json` → `hooks.PreToolUse[]` |

Copy each script with Bash `cp` (plain file copy — invoked via `bash "$CLAUDE_PROJECT_DIR/.claude/hooks/<name>.sh"`, so no executable bit is required). Merge each `.hook.json` entry into `.claude/settings.json`'s `hooks.PreToolUse` array via a guarded read-modify-write that touches only that array — the same merge mechanism as drain's `read-hook.json` (`../drain/assets/ensure-infra.md` step 3), reused rather than re-derived.

## Idempotency

Each step is present-checked first:

```
hooksInfraPresent():
  .claude/hooks/docsync-gate.sh exists   AND
  .claude/hooks/harness-grounding.sh exists   AND
  .claude/settings.json hooks.PreToolUse contains an entry whose command references docsync-gate.sh   AND
  .claude/settings.json hooks.PreToolUse contains an entry whose command references harness-grounding.sh
```

All present → skip silently (`✓ current`), no message. Any missing → place the
missing pieces, report what was added, stage with the Phase 2c commit. **No confirm
gate** — default-on, unlike drain's `infraPresent()` install-confirm.

## Hook activation

`settings.json` hook edits are picked up mid-session by the file-watcher (no restart
— `hook-agent-type.md`), so both guards go live shortly after the merge.

## Roles

Durable harness config, not a temporal pipeline artifact — so no cleaner:

- **Creator** — harness-bootstrap Phase 2a-hooks (first run, and every sync re-run —
  idempotent, so a re-run only fills what's missing).
- **Consumer** — the consumer repo's own `git commit` calls (A2) and `Edit`/`Write`
  calls (A1).
- **Cleaner** — none; the infra lives until the user removes the harness.

## Self-containment (hard constraint)

Both scripts and both settings snippets are copied verbatim — no template
substitution, no reference to any super-bootstrap-specific state beyond what
harness-bootstrap itself stamps (`CLAUDE.md`, `.claude/rules/`, `docs/`).
`harness-grounding.sh`'s injected `additionalContext` text names only git log,
`.claude/rules/index.md` (or the rule file matching the edited path), and the
verify pass — never `/load-harness-principles` or any other device-only skill,
since those do not exist on a bare consumer repo.
