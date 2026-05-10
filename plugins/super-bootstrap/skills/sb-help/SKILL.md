---
name: sb-help
description: "Passive on-demand index of installed user-invoke skills, grouped by category. Bundled with super-bootstrap. /sb-help renders the full menu; /sb-help <category> filters. Reads installed-plugin manifest + project skills + per-plugin bundled skills. No active reminders — discovery is pull-only, zero ambient cost."
tags: [help, discovery, menu, pipeline]
---

# Help — User-Invoke Skill Discovery Surface

Render an on-demand menu of slash commands the user can invoke in this project. Cold-by-nature user-invoke skills (slash commands the user must remember) need a discovery surface; passive `/sb-help` is the right shape.

## When to Use

- User forgot which slash commands are available
- User just installed a new plugin and wants to see what it added
- User wants to filter by category (`/sb-help git`, `/sb-help docs`)

## Why dispatched (Haiku)

Pure manifest lookup + filter + render. Mechanical; Haiku is the right model fit. Skills can't pin a model in frontmatter today — only agents can — so escaping Opus requires dispatch. Haiku output is ~15× cheaper than Opus per token; dispatch overhead is negligible at this volume. Bonus: keeps the gateway's working memory clean of manifest dumps.

## Execution

The full protocol lives in the `sb-help` agent (`agents/sb-help.md`, `model: haiku`, read-only tools).

When the user invokes `/sb-help [category]`:

1. Dispatch the `sb-help` subagent (Agent tool, `subagent_type: "sb-help"`). Forward the project root path and any category argument as the prompt body.
2. Relay the agent's rendered menu verbatim to the user. Do not re-do the work.

## Rules

- **No active reminders.** Discovery is pull-only; user invokes `/sb-help` when they want it. Footer-hint convention on other surfaces (e.g. `/sb-todo` ends with `more: /sb-help`) is the only push.

## Out of Scope

- **Active context-aware suggestion** — description-match autopilot territory; same failure mode as the orphaned-plugins problem.
- **Time-based "you haven't used X in N days" reminders** — see § No active reminders.
- **Auto-execute via `!command` syntax** — not a Claude Code feature today; menu renders names, user types the command.
