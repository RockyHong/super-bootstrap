---
paths:
  - ".claude/rules/**"
description: "Rule-authoring guide — loads when editing files under .claude/rules/"
---

# Rules — Authoring Guide

> Active rules are catalogued in `CLAUDE.md` § Rules (the always-on discovery surface). This file is the authoring guide — it loads only when you edit a rule.
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
2. Body uses the same imperative, full-detail style as `CLAUDE.md` § Edit Discipline — rules are loaded with full ammo.
3. Add a one-line summary bullet to `CLAUDE.md` § Rules.
