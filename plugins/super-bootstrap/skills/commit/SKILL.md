---
name: commit
description: "Stage and commit the current session's changes only. Session-isolated (never -A), doc-sync-gated, conventional message, commits directly without a confirm gate, offers push on explicit confirmation. Dispatches the `commit` subagent (agents/commit.md, model: sonnet) so classification, the doc-sync gate, and message-gen run off the gateway model. Bundled with super-bootstrap — encodes the harness commit rules."
tags: [commit, git, session, doc-sync, superpowers]
---

# Commit — Session-Isolated, Doc-Sync-Gated

Commits the changes this Claude session produced, leaving prior uncommitted work alone. The protocol runs in the `commit` subagent (`agents/commit.md`, `model: sonnet`); this skill is the dispatch shell plus the three gateway lanes that need the user: doc-sync resolution, push confirmation, cycle handoff.

## Execution

1. **Assemble the dispatch prompt** — the session's changed-file list (from this conversation: what this session edited/wrote), any user-supplied message context (e.g. `/super-bootstrap:commit — explain the auth refactor`), and today's date. The list is the agent's session-isolation ground truth — build it faithfully; a file you don't remember touching stays OFF the list (the agent returns it as a question if it matters).
2. **Dispatch**: `Agent` tool, `subagent_type: "commit"`. Relay the agent's return verbatim — no editorializing.
3. **Branch on the return shape** (`agents/commit.md` § Output contract):
   - **`stale-docs`** → resolve each candidate with the user (update / acknowledge-accurate / skip — never silently fix, never silently skip). Land approved doc edits (inline for bounded prose; dispatch by closure). Re-dispatch the agent — a **fresh `Agent` call**, never SendMessage-resume of the same instance — with the same prompt **plus** per-candidate resolutions (`updated: <path>` → stage it; `accurate` / `skip` → cleared).
   - **`questions`** → route to the user verbatim; act on the answer, then re-dispatch with the clarification.
   - **`committed`** → proceed to push offer.
4. **Push (on confirmation)** — from the return's `push` facts, present: branch → upstream, commits ahead. Ask: **"Push these now? (y / skip)"**. Push only on explicit yes (`git push <remote> <branch>`); skip by default on silence or decline. Never force, never unannounced.
5. **Cycle handoff** — one line from the return's `cycle` facts; don't expand into a status table (that's `/super-bootstrap:todo`'s job):

| `cycle` facts | Handoff one-liner |
|---|---|
| No open plans, no backlog items | `Cycle complete. Safe to /clear. Next session: /super-bootstrap:todo picks up next item.` |
| Open plan with unchecked boxes | `Cycle complete. <plan file> still has <n>/<m> unchecked — /clear then /super-bootstrap:todo to resume.` |
| Backlog open, no active plans | `Cycle complete. No active specs/plans; docs/backlog.md has open items — /clear then /super-bootstrap:todo to pick next.` |

## Rules

- **Route work to the subagent; keep user lanes here.** Classification, the doc-sync scan, message, stage, commit — all agent-side. Doc-sync resolution, push, handoff — gateway-side.
- **Session list is built here, honestly.** The gateway owns the transcript; the agent trusts the list. Uncertain files stay off it.
- **Doc-sync round-trip, never bypass** — a `stale-docs` return always goes through the user before re-dispatch.
- **Continuation is a fresh dispatch, never a resume** — every re-dispatch is a new `Agent` call carrying resolutions; a SendMessage-resume of the same instance stops at its mid-protocol STOP (staged, not committed).
- **Push on explicit yes only** — committed work is safe locally either way.
