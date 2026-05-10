---
name: sb-merge
description: 'Absorb one or more feature branches into the base branch. Recommends merge vs rebase per branch. On conflict, surfaces the file list and stops — resolution is out of scope; user/gateway decides next.'
tags: [sb, merge, git, branch]
---

# sb-merge — Branch Absorption

Absorb feature branches into the base branch. Mechanical merge + strategy recommendation. **Conflict resolution is NOT this skill's job** — surfaces and stops.

## Execution

The full protocol lives in the `sb-merge` agent (`agents/sb-merge.md`, `model: sonnet`). Strategy recommendation + clean-merge mechanics are bounded judgment — Sonnet sweet spot. Conflict resolution is intentionally out of scope (returns to user/gateway with full conflict scope).

When the user invokes `/sb-merge`:

1. Dispatch the `sb-merge` subagent (Agent tool, `subagent_type: "sb-merge"`).
2. Forward branch list (if user supplied) and any context as the prompt body. If no branches given, the agent will identify candidates and ask back.
3. The agent presents a strategy table per branch. Gateway relays to user for confirmation, then forwards confirmation back to the agent (or re-dispatches with confirmed list).
4. The agent executes clean merges. **On conflict, the agent aborts that branch's merge and surfaces the conflict file list.**
5. **Conflict handoff:** if any branch hit a conflict, gateway surfaces the conflict scope (branch + file list + which strategy hit it) to the user. Resolution is out of scope for sb-merge — user resolves manually or routes to a fitting reviewer/agent of their choosing. Do NOT route conflict resolution back to the merge agent.
6. Relay the agent's final summary verbatim to the user.

## Why this routes through an agent

- **Model fit.** Strategy table + clean merge mechanics = bounded judgment. Sonnet sufficient.
- **Hard SoC.** The merge agent owns absorption; resolution is somebody else's problem. Splitting along that line keeps the merge agent small and the post-conflict handoff surgical.
- **Context isolation.** Conflict diffs would explode the gateway's working memory if handled inline.
