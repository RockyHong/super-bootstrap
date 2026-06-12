# Rules Index

> **Cold-load caveat:** rule fires on file *read*, not on intent. Read the rule directly when planning: `Read .claude/rules/<name>.md`.
>
> Use `paths:` in frontmatter — not `globs:` (Cursor key, ignored by Claude Code).

## Active rules

{seeded by sp-bootstrap from Phase 1 signals — examples:}

{- `<framework>.md` — `{glob}` — {one-line purpose}}
{- `mv3.md` — `src/background/**`, `src/content/**` — service-worker safety}

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
