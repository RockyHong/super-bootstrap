---
name: sb-todo
description: "Scan docs/superpowers/ for active specs and plans. Show status table with cycle stage, progress, and blockers. Suggest what to tackle next. Bundled with super-bootstrap — works in any repo with the superpowers pipeline."
tags: [todo, scan, status, pipeline, superpowers]
---

# Todo — Pipeline Work Scanner

Scan the project's `docs/superpowers/` folder for active design specs and implementation plans. Show what's in flight, what's blocked, and what to do next.

Bundled with `/super-bootstrap`. The harness CLAUDE.md and bootstrap plan tell future sessions to "Run `/sb-todo`" — this is that command.

## Why dispatched (Sonnet)

Multi-file scan + bounded classification + table render. No session context needed; isolating reads from the gateway keeps working memory clean and saves Opus tokens. Sonnet handles all of it correctly in a single round-trip — no iterative back-and-forth needed.

## Execution

The full protocol lives in the `sb-todo` agent (`agents/sb-todo.md`, `model: sonnet`, read-only tools).

When the user invokes `/sb-todo`:

1. **Quick gate (gateway).** Glob `docs/superpowers/specs/*.md`, `docs/superpowers/plans/*.md`, and `docs/backlog.md`. If all empty/absent, print directly without dispatching:
   > "No active work. Start something with `/brainstorm` or give me a task."

2. **Otherwise dispatch** the `sb-todo` subagent (Agent tool, `subagent_type: "sb-todo"`). Forward the project root path and any filter argument as the prompt body.

3. **Relay the agent's table + "Next up" output verbatim** to the user. Do not re-do the work in main session.

## Skip dispatch if

- User explicitly asks to run inline.
- Quick-gate Glob returns zero files (no point spawning).

## Rules

- **Read-only.** Reports only — never modifies files.
- **Works in any repo** — only requires `docs/superpowers/` to exist (created by `/harness-bootstrap`).
- **No git operations.**
