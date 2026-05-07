---
name: sb-help
description: "Passive on-demand index of installed user-invoke skills, grouped by category. Bundled with super-bootstrap. /sb-help renders the full menu; /sb-help <category> filters. Reads installed-plugin manifest + project skills + per-plugin bundled skills. No active reminders — discovery is gateway-side, zero ambient cost."
tags: [help, discovery, menu, pipeline]
---

# Help — User-Invoke Skill Discovery Surface

Render an on-demand menu of slash commands the user can invoke in this project. Cold-by-nature user-invoke skills (slash commands the user must remember) need a discovery surface; passive `/sb-help` is the right shape.

## When to Use

- User forgot which slash commands are available
- User just installed a new plugin and wants to see what it added
- User wants to filter by category (`/sb-help git`, `/sb-help docs`)

## Protocol

### Step 1: Read sources

Walk these inputs in order, accumulating slash-invocable skills:

- `~/.claude/plugins/installed_plugins.json` — global installed plugin manifest. Skip silently if absent.
- `<project>/.claude/settings.json` `enabledPlugins` — project-pinned plugins (intent that travels with repo).
- `<project>/.claude/skills/*/SKILL.md` — project-local skills (frontmatter `name:`, `description:`, `tags:`). Skip silently if folder absent.
- Per-plugin bundled skills — for each enabled plugin, scan its `skills/*/SKILL.md` and `plugin.json` for declared commands.

### Step 2: Filter to user-invoke

A skill counts as user-invoke if any one is true:

- Frontmatter `name:` begins with `/`, OR
- Description includes a user-trigger phrasing (e.g. "user types", "run `/...` to ...", "invoke when ..."), OR
- Registered as a slash command in the plugin manifest (`commands:` field or equivalent).

Drop delegation-only skills (called by other skills via `Skill(name=...)`) and hook-only skills (fired by Claude Code runtime, not the user).

### Step 3: Group by category

Parse each skill's `tags:` frontmatter and map to coarse categories:

- `git` — commit, push, PR, branch, merge, rebase
- `docs` — overview, techstack, spec, plan, sync, scaffold
- `pipeline` — brainstorm, write-plan, execute-plan, todo, help
- `meta` — bootstrap, harness, resolve, audit
- `dev` — debug, test, refactor, lint
- `utils` — format, search, lookup

If a skill's tags span multiple categories, list it under the leftmost match. Ambiguous → primary group only.

### Step 4: Render menu

Table-style, one line per skill: command + one-line summary + when-to-use trigger.

```
Available slash commands ({N} total):

[meta]
  /super-bootstrap        Bootstrap or sync the superpowers pipeline.
                          When: starting a fresh repo or syncing harness.
  /harness-bootstrap      Install harness in a repo with code already present.
                          When: existing repo, want pipeline + skeleton docs.
  /resolve-plugins        Curate skill / MCP / hook picks against live sources.
                          When: refresh picks; called from harness Phase 3c.

[pipeline]
  /sb-todo                Scan docs/superpowers/ for active specs and plans.
                          When: "what was I doing?" / start of session.
  /sb-help                This menu.
                          When: forgot what's installed.

[git]
  /sb-commit              Session-isolated, doc-sync-gated commit.
                          When: ready to commit work this session produced.
```

### Step 5: Filtered mode

If invoked with an argument (`/sb-help git`), render only that category. Unknown category → list available categories and exit.

## Why no active reminder

Time-based reminders ("you haven't used /X in N days") are umbrella-shouting on sunny days — empirically unreliable, costly per session, ignored under load. Footer-hint convention (existing render surfaces append `more: /sb-help`) is zero ambient cost; user pulls discovery when they actually want it.

## Why gateway-side, not subagent-dispatched

Token cost is minimal — read a few small JSON / SKILL.md files, render a table. Subagent dispatch would ship parent context as overhead with no meaningful gain. Gateway-side keeps the menu instant.

## Out of Scope

- **Active context-aware suggestion** — description-match autopilot territory; same failure mode as the orphaned-plugins problem.
- **Time-based "you haven't used X in N days" reminders** — see § Why no active reminder.
- **Auto-execute via `!command` syntax** — not a Claude Code feature today; menu renders names, user types the command.
