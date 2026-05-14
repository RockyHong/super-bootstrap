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

## Why dispatched (Haiku)

Pure manifest lookup + filter + render. Mechanical; Haiku is the right model fit. Skills can't pin a model in frontmatter today — only agents can — so escaping Opus requires dispatch. Haiku output is ~15× cheaper than Opus per token; dispatch overhead is negligible at this volume. Bonus: keeps the gateway's working memory clean of manifest dumps.

## Execution

The full protocol lives in the `help` agent (`agents/help.md`, `model: haiku`, read-only tools).

When the user invokes `/super-bootstrap:help [category]` (namespaced to avoid colliding with Claude Code's built-in `/help`):

1. Dispatch the `help` subagent (Agent tool, `subagent_type: "help"`). Forward the project root path and any category argument as the prompt body.
2. Relay the agent's rendered menu verbatim to the user. Do not re-do the work.

## Rules

- **No active reminders.** Discovery is pull-only; user invokes `/super-bootstrap:help` when they want it. Footer-hint convention on other surfaces (e.g. `/super-bootstrap:todo` ends with `more: /super-bootstrap:help`) is the only push.
- **Namespaced invocation.** Always `/super-bootstrap:help`, never bare `/help` — bare `/help` is Claude Code's built-in. Footer hints elsewhere in this plugin must use the namespaced form too.

## Out of Scope

- **Active context-aware suggestion** — description-match autopilot territory; same failure mode as the orphaned-plugins problem.
- **Time-based "you haven't used X in N days" reminders** — see § No active reminders.
- **Auto-execute via `!command` syntax** — not a Claude Code feature today; menu renders names, user types the command.
