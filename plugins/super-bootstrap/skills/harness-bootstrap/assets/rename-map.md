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

**Canonical form:** every bundled skill is invoked as `/super-bootstrap:<skill>`; the entry `/super-bootstrap` is the one bare exception (plugin name == skill name). Per-skill table: [`plugins/super-bootstrap/README.md` § Naming convention](../../../README.md#naming-convention).

**Coverage rule:** a row exists for every bare form of a bundled skill that could plausibly sit in a downstream pipeline-owned file — whether or not this plugin ever shipped that form, since a repo can carry a bare literal it coined itself. A bundled skill with no row therefore reads as deliberate. The `sb-` prefix is retired, so only skills that existed under it carry an `/sb-*` row.

Bare-form migrations (when literal appears in pipeline-owned files):

- `/commit` → `/super-bootstrap:commit`
- `/todo` → `/super-bootstrap:todo`
- `/merge` → `/super-bootstrap:merge`
- `/help` → `/super-bootstrap:help`
- `/log` → `/super-bootstrap:log`
- `/drain` → `/super-bootstrap:drain`
- `/triage` → `/super-bootstrap:triage`
- `/triage-report` → `/super-bootstrap:triage-report`
- `/harness-bootstrap` → `/super-bootstrap:harness-bootstrap`
- `/resolve-plugins` → `/super-bootstrap:resolve-plugins`
- `/release-init` → `/super-bootstrap:release-init`
- `/check-docs-consistency` → `/super-bootstrap:check-docs-consistency`

Legacy `sb-*` prefix migrations:

- `/sb-commit` → `/super-bootstrap:commit`
- `/sb-todo` → `/super-bootstrap:todo`
- `/sb-merge` → `/super-bootstrap:merge`
- `/sb-help` → `/super-bootstrap:help`
- `/sb-harness-bootstrap` → `/super-bootstrap:harness-bootstrap`
- `/sb-super-bootstrap` → `/super-bootstrap` — entry keeps plugin name only
- `/sb-resolve-plugins` → `/super-bootstrap:resolve-plugins`
- `/sb-release-init` → `/super-bootstrap:release-init`

Pre-rename plugin-name migrations:

- `/sp-bootstrap` → `/super-bootstrap` — entry keeps plugin name only

## Plugin names

Bare plugin-name references in prose. Slash-command forms of the same rename live under [§ Slash commands](#slash-commands).

- `sp-bootstrap` → `super-bootstrap` — pre-rename plugin name

## Skeleton headings / structure

(none yet — append entries here when section names rename)

## Scan guidance

- Match the `old` form as a whole token (word boundaries) — avoid false hits inside URLs or unrelated identifiers.
- **Confirm the referent before proposing a bare-form hit.** A bare name can belong to something else the consumer runs — Claude Code's built-in `/help`, or another installed plugin's command (a paired skill set can ship its own `/triage`). Read the hit's line: propose migration when the surrounding prose means the bundled skill, and leave the line when it means the other tool. The scan already reads each hit's line to render its rot row, so this costs no extra pass. `sb-` prefixed forms are unambiguous — propose those on match.
- One repo can carry hits across multiple `old` forms in the same file (e.g. `sb-` literal AND bare-namespace literal). Surface each independently.
