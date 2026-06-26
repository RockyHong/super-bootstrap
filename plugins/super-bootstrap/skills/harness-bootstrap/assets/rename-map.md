# Skeleton Rename Map

Tracks pipeline-owned literal renames so Phase 2b can spot literals that
per-section diff misses. When a slash command (or other inline literal)
renames, the surrounding template may stay shaped the same — only the
literal inside changed — and per-section diff returns `✓ matches`. This
file is the bridge: grep each `old` form in pipeline-owned files; surface
migration proposals.

Format per entry: `` `old` `` → `` `new` `` — brief reason.

When a literal renames, **add a row here** and **update the relevant
skeleton** in the same commit. Drop rows only when no realistic chance
remains that any installed project still carries the `old` form.

## Slash commands

**Policy (canonical invocation form):** all bundled skills use the namespaced form `/super-bootstrap:<skill>`; only the entry `/super-bootstrap` stays bare (plugin-name == skill-name special case). Dropdown autocomplete already shows the namespaced form, so docs that match it avoid mental drift; namespace is also forward-proof against future bare-name collisions.

Bare-form migrations (when literal appears in pipeline-owned files):

- `/commit` → `/super-bootstrap:commit`
- `/todo` → `/super-bootstrap:todo`
- `/merge` → `/super-bootstrap:merge`
- `/help` → `/super-bootstrap:help` — only when the literal references the bundled help skill (not Claude Code's built-in `/help`)
- `/harness-bootstrap` → `/super-bootstrap:harness-bootstrap`
- `/resolve-plugins` → `/super-bootstrap:resolve-plugins`
- `/release-init` → `/super-bootstrap:release-init`

Legacy `sb-*` prefix migrations:

- `/sb-commit` → `/super-bootstrap:commit`
- `/sb-todo` → `/super-bootstrap:todo`
- `/sb-merge` → `/super-bootstrap:merge`
- `/sb-help` → `/super-bootstrap:help`
- `/sb-harness-bootstrap` → `/super-bootstrap:harness-bootstrap`
- `/sb-super-bootstrap` → `/super-bootstrap` — entry keeps plugin name only
- `/sb-resolve-plugins` → `/super-bootstrap:resolve-plugins`
- `/sb-release-init` → `/super-bootstrap:release-init`

## Skeleton headings / structure

(none yet — append entries here when section names rename)

## Scan guidance

- Match the `old` form as a whole token (word boundaries) — avoid false hits inside URLs or unrelated identifiers.
- For `/help` hits only: confirm the surrounding paragraph references the super-bootstrap bundled skill (not Claude Code's built-in `/help`) before proposing migration. All other bare-form bundled-skill hits migrate unconditionally per policy above.
- One repo can carry hits across multiple `old` forms in the same file (e.g. `sb-` literal AND bare-namespace literal). Surface each independently.
