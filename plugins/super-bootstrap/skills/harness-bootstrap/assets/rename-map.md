# Skeleton Rename Map

Tracks pipeline-owned literal renames so Phase 3b can spot literals that
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

- `/commit` → `/super-bootstrap:commit` — plugin-namespace canonical; bare form is ambiguous when other plugins also ship `commit`
- `/sb-commit` → `/super-bootstrap:commit` — `sb-` prefix dropped
- `/sb-todo` → `/super-bootstrap:todo`
- `/sb-merge` → `/super-bootstrap:merge`
- `/sb-help` → `/super-bootstrap:help`
- `/sb-harness-bootstrap` → `/super-bootstrap:harness-bootstrap`
- `/sb-super-bootstrap` → `/super-bootstrap` — top-level skill keeps plugin name only
- `/sb-resolve-plugins` → `/super-bootstrap:resolve-plugins`
- `/sb-release-init` → `/super-bootstrap:release-init`
- `/todo` → `/super-bootstrap:todo` — same collision risk as `/commit`
- `/help` → `/super-bootstrap:help` — only when the literal appears inside a pipeline-owned section that names the bundled help skill (not Claude Code's built-in `/help`)

## Skeleton headings / structure

(none yet — append entries here when section names rename)

## Scan guidance

- Match the `old` form as a whole token (word boundaries) — avoid false hits inside URLs or unrelated identifiers.
- For each `/help` and `/todo` hit, confirm the surrounding paragraph references the super-bootstrap bundled skill (not the built-in Claude Code command of the same name) before proposing migration.
- One repo can carry hits across multiple `old` forms in the same file (e.g. `sb-` literal AND bare-namespace literal). Surface each independently.
