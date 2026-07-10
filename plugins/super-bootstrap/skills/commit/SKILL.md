---
name: commit
description: "Commit the current session's changes only, gateway-inline. Session-isolated (never -A), doc-sync-gated. The gateway runs the commit inline — it already holds the diff, session file list, and change intent; only the doc-sync scan dispatches, and only when a mechanical grep-gate shows the diff touches the doc surface. Conventional message, commits directly, offers push on explicit confirmation. Bundled with super-bootstrap — encodes the harness commit rules."
tags: [commit, git, session, doc-sync, superpowers]
---

# Commit — Session-Isolated, Doc-Sync-Gated (gateway-inline)

Commits the changes this Claude session produced, leaving prior uncommitted work alone. The gateway runs the flow inline — it holds the session's diff, file list, and change intent, so the mechanics carry no closure a fresh container would hold. Only the **doc-sync scan** dispatches, and only when the diff touches the doc surface: it is the one step that earns a cold, context-clean pass — cold-eyes catch staleness the author is blind to.

## Execution (gateway-inline)

1. **Session file list** — from this conversation, the files this session edited/wrote. This is the session-isolation ground truth; a file you don't remember touching stays off it. Stage by explicit path only.

2. **Gather state** — `git status`, `git diff`, `git diff --staged`, `git log --oneline -10` (recent style).

3. **Doc-sync grep-gate** — mechanical, no judgment:
   - Extract terms from the changed files: `*/skills/<X>/SKILL.md`, `*/agents/<X>.md`, `*/rules/<X>.md` → `<X>`; else basename sans extension. Drop generics (`SKILL`, `CLAUDE`, `README`, `backlog`, `marketplace`, `plugin`, `gitignore`).
   - Grep the doc surface (CLAUDE.md § Doc Sync owns it — `docs/**` + root `README` + manifest description fields) for any term, excluding the changed files themselves. This is a cheap **pre-filter** on dispatch, not the scan — the agent re-scans cold.
   - **Any hit → dispatch the doc-sync scan (§4).**
   - **No hit → the diff narrates nothing; go to §5.**
   - **Deferred mode** (drain-worktree isolated commit): doc-sync belongs to the merge boundary — skip the gate, go to §5.

4. **Doc-sync scan (dispatched on hit)** — `Agent`, `subagent_type: "doc-sync-scan"`; prompt = the diff (`git diff` + `git diff --staged`) + today's date. It runs its own cold scan of the doc surface and returns one shape:
   - **`stale-docs`** → resolve each candidate with the user (update / acknowledge-accurate / skip — never silently fix, never silently skip). Land approved doc edits (inline for bounded prose; dispatch by closure). Resolved docs join the stage list.
   - **`clean`** → proceed.

5. **Message + commit** — draft a Conventional Commit (`<type>(<scope>): <subject>`, imperative ≤72 chars, body only when the why isn't in the diff, match `git log` style; one logical change per commit — a diff spanning two unrelated changes splits). `git add <explicit paths>` — never `-A` / `.`, never secrets (`.env`, keys). Commit with HEREDOC formatting; `git status` after to verify clean. Pre-commit hooks run; on failure fix the cause, never bypass. Always a new commit — amend only if asked.

6. **Push (on confirmation)** — present branch → upstream, commits ahead. Ask **"Push these now? (y / skip)"**. Push on explicit yes only (`git push <remote> <branch>`); skip on silence or decline. Never force, never unannounced.

7. **Cycle handoff** — one line from cycle facts (any `docs/superpowers/plans/*.md` with unchecked `- [ ]` boxes; whether `docs/backlog.md` has open rows). Don't expand into a status table — that's `/super-bootstrap:todo`'s job:

| Cycle facts | Handoff one-liner |
|---|---|
| No open plans, no backlog items | `Cycle complete. Safe to /clear. Next session: /super-bootstrap:todo picks up next item.` |
| Open plan with unchecked boxes | `Cycle complete. <plan file> still has <n>/<m> unchecked — /clear then /super-bootstrap:todo to resume.` |
| Backlog open, no active plans | `Cycle complete. No active specs/plans; docs/backlog.md has open items — /clear then /super-bootstrap:todo to pick next.` |

## Rules

- **Gateway-inline; only doc-sync dispatches.** The gateway holds the diff, session list, and intent → mechanics stay inline (no closure a fresh container would hold). The cold doc-sync scan is the one step a clean context serves.
- **Grep-gate is mechanical.** Term extraction is path-structure only, never a judgment about which identifiers matter — a judgment gate gets omitted. Any hit dispatches; conservative by design. A pure asset/binary diff with no narrated path is the skippable class.
- **Session-isolated.** The session list decides; prior dirty state is sacred. Explicit paths, never `-A`.
- **Doc-sync round-trip, never bypass** — a `stale-docs` return goes through the user before commit.
- **Whole-diff-once.** Doc-sync runs at the integration boundary, on the whole diff, once. Drain-worktree defers it to merge; an implementer never owns doc-sync — a partial-slice view gives false confidence.
- **Push on explicit yes only** — committed work is safe locally either way.
