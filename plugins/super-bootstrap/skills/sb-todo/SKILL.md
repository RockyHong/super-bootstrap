---
name: sb-todo
description: "Scan docs/superpowers/ for active specs and plans. Show status table with cycle stage, progress, and blockers. Suggest what to tackle next. Bundled with super-bootstrap — works in any repo with the superpowers pipeline."
tags: [todo, scan, status, pipeline, superpowers]
---

# Todo — Pipeline Work Scanner

Scan the project's `docs/superpowers/` folder for active design specs and implementation plans. Show what's in flight, what's blocked, and what to do next.

Bundled with `/super-bootstrap`. The harness CLAUDE.md and bootstrap plan tell future sessions to "Run `/sb-todo`" — this is that command.

## Protocol

### 0. Dispatch to Subagent

This skill is mechanical scan + classify + render. No session context needed. Save main-session tokens by dispatching the whole protocol to a Sonnet subagent:

```
Agent(
  subagent_type: "general-purpose",
  model: "sonnet",
  description: "Scan superpowers pipeline for active work",
  prompt: <steps 1-5 below, verbatim, with repo root path>
)
```

Relay the agent's table + "Next up" output to the user as-is. Do not re-do the work in main session.

Skip dispatch only if: user explicitly asks to run inline, or repo has zero `docs/superpowers/` files (one Glob check, no point spawning).

### 1. Find Active Work

Scan for files in these locations (check both, either may not exist):
- `docs/superpowers/specs/*.md` — design specs from brainstorming
- `docs/superpowers/plans/*.md` — implementation plans

If neither directory exists or both are empty:
> "No active work. Start something with `/brainstorm` or give me a task."

If `docs/backlog.md` exists, also report a one-line count of open BUG/DEBT/GAP items below the active-work section (don't expand the items — that's a separate read).

Stop after reporting if no active specs/plans.

### 2. Read Each File and Classify

For each file found, read it and determine:

**Cycle stage** — infer from content:

| Signal | Stage |
|---|---|
| No checkboxes, discussion-style content, "approaches", "options" | `brainstorming` |
| Spec file exists but no matching plan file | `spec-ready` (needs `/write-plan`) |
| Plan file with all `- [ ]` unchecked | `planning` (ready to execute) |
| Plan file with mix of `- [ ]` and `- [x]` | `executing` |
| Plan file with all `- [x]` checked | `review` (needs verification) |
| File contains "DONE" or "COMPLETED" marker | `done` (should be cleaned up) |

**Progress** — count checkboxes:
- If file has checkboxes: `{checked}/{total}` (e.g., `3/7`)
- If no checkboxes: `—`

**Blocker** — scan for signals:
- Contains "waiting on", "needs approval", "user decision", unclosed question to user → `user`
- Contains "blocked by", references another spec/plan as dependency → `blocked ({dependency})`
- Otherwise → `none`

### 3. Present Summary Table

```
File                                    | Stage       | Progress | Blocker
specs/2026-03-15-auth-design.md         | spec-ready  | —        | none
plans/2026-03-15-auth.md                | executing   | 3/7      | none
specs/2026-04-01-dashboard-design.md    | brainstorming| —       | user (needs decision on layout)
```

If `docs/backlog.md` exists, append below the table:

```
Backlog: 3 BUG, 2 DEBT, 1 GAP open (see docs/backlog.md)
```

### 4. Suggest Next Action

Below the table, recommend what to tackle next. Priority order:

1. **Unblocked executing work** — finish what's in progress (`/execute-plan`)
2. **Review-ready work** — verify completed plans (`/review`)
3. **Spec-ready items** — write plans for approved specs (`/write-plan`)
4. **Planning items** — start executing ready plans (`/execute-plan`)
5. **Done items** — clean up temporal files (delete spec + plan, they served their purpose)
6. **Blocked items** — list what the user needs to unblock

Format as a short prioritized list:

```
Next up:
1. Continue executing plans/2026-03-15-auth.md (3/7 done, unblocked)
2. Write plan for specs/2026-04-01-dashboard-design.md (spec approved, no plan yet)
3. Clean up plans/2026-02-20-old-feature.md (all tasks done)
```

If backlog.md exists and active work is empty: "No active work — pick from `docs/backlog.md` to start something."

### 5. Cross-Reference (Optional)

If specs and plans exist for the same feature (matched by date prefix or name):
- Show them as linked: `auth-design.md → auth.md`
- Flag orphaned plans (plan exists but spec was deleted — probably fine, just note it)
- Flag orphaned specs with no plan that are older than 7 days — they may be forgotten

## Rules

- **Read-only** — this skill only reports. It never modifies files.
- **Dispatched by default** — Sonnet subagent runs scan + classify + render. Main session relays output.
- **Works in any repo** — only requires `docs/superpowers/` to exist (created by `/harness-bootstrap`).
- **No git operations** — purely file-based scan.
