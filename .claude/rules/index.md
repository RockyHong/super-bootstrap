---
paths:
  - ".claude/rules/**"
description: "Rule-authoring guide — loads when any file under .claude/rules/ is read"
---

# Rules — Authoring Guide

> Active rules are catalogued in `CLAUDE.md` § Rules (the always-on discovery surface). This file is the authoring guide — it loads whenever a file under `.claude/rules/` is read.
>
> **Cold-load caveat:** a rule fires on file *read*, not on intent. Mirror each rule's summary into `CLAUDE.md` § Rules so the orchestrator knows it exists during planning.
>
> Use `paths:` in frontmatter — not `globs:` (Cursor key, ignored by Claude Code).

## Adding a new rule

1. New file `<topic>.md` with frontmatter:
   ```yaml
   ---
   paths:
     - "path/to/scope/**"
   description: "When this rule applies and why"
   ---
   ```
2. Body is imperative and full-detail — a rule loads with full ammo at its decision moment, so don't compress it to a summary. Sibling rule files beside this index, when present, are the shape reference.
3. Add a one-line summary bullet to `CLAUDE.md` § Rules.
