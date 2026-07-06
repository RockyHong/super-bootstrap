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

## Related convention — model tiering on skills

`SKILL.md` frontmatter cannot pin a model, so a skill whose protocol carries bounded
judgment (classify / rank / scan / digest) that stays inline runs unpinned, at
whatever tier the gateway happens to be on. Author it instead as a dispatch-shell
`SKILL.md` + a typed `agents/<name>.md` carrying `model:` frontmatter — the only
tiering escape hatch. See `skills/todo` + `agents/todo.md` for the pattern.
