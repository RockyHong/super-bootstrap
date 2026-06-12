---
name: help
description: "Passive on-demand index of installed user-invoke skills, grouped by category. Bundled with super-bootstrap. Invoke as `/super-bootstrap:help` (namespaced to avoid colliding with Claude Code's built-in `/help`); `/super-bootstrap:help <category>` filters. Reads installed-plugin manifest + project skills + per-plugin bundled skills. No active reminders — discovery is pull-only, zero ambient cost."
tags: [help, discovery, menu, pipeline]
---

# Help — User-Invoke Skill Discovery Surface

Render an on-demand menu of slash commands the user can invoke in this project. Cold-by-nature user-invoke skills (slash commands the user must remember) need a discovery surface; passive `/super-bootstrap:help` is the right shape.

## When to Use

- User forgot which slash commands are available
- User just installed a new plugin and wants to see what it added
- User wants to filter by category (`/super-bootstrap:help git`, `/super-bootstrap:help docs`)

## Execution

Protocol lives in the `help` agent — dispatch via `subagent_type: "help"`.

When the user invokes `/super-bootstrap:help [category]`:

1. Dispatch the `help` subagent (Agent tool, `subagent_type: "help"`). Forward the project root path and any category argument as the prompt body.
2. Relay the agent's rendered menu verbatim to the user. Do not re-do the work.

## Rules

- **No active reminders.** Discovery is pull-only — the user invokes; nothing fires ambiently. Footer-hint convention on other surfaces (e.g. `/super-bootstrap:todo` ends with `more: /super-bootstrap:help`) is the only push.
- **Namespaced invocation.** Always `/super-bootstrap:help`, never bare `/help` — bare `/help` is Claude Code's built-in. Footer hints elsewhere in this plugin must use the namespaced form too.
