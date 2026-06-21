# Rules Index

> **Cold-load caveat:** rule fires on file *read*, not on intent. Read the rule directly when planning: `Read .claude/rules/<name>.md`.
>
> Use `paths:` in frontmatter — not `globs:` (Cursor key, ignored by Claude Code).

## Active rules

- `dimension-discipline.md` — `docs/**/*.md`, `README.md` — classify state vs history before propagating (served; predicate in `work-discipline/doc-dimension-discipline.md`)
- `ssot-doc-link.md` — `docs/**/*.md`, `README.md` — author concepts born-linked to their SSOT home (served; predicate in `work-discipline/doc-link-discipline.md`)

## Adding a new rule

1. New file `<topic>.md` with frontmatter:
   ```yaml
   ---
   paths:
     - "src/<scope>/**/*.ts"
   description: "When this rule applies and why"
   ---
   ```
2. Body uses the same imperative, full-detail style as `CLAUDE.md` § Edit Discipline — rules are loaded with full ammo.
3. Add a one-line summary bullet to `CLAUDE.md` § Rules so the orchestrator knows it exists.
4. Add an entry to this index.
