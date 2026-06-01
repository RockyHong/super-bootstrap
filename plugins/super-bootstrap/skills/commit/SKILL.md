---
name: commit
description: "Stage and commit the current session's changes only. Session-isolated (never -A), doc-sync-gated, conventional message, commits directly without a confirm gate, offers push on explicit confirmation. Bundled with super-bootstrap — encodes the harness commit rules."
tags: [commit, git, session, doc-sync, superpowers]
---

# Commit — Session-Isolated, Doc-Sync-Gated

Stage and commit the changes this Claude session produced. Leaves prior uncommitted work alone. Runs the doc-sync gate first. Writes a conventional commit message and commits directly — no approval gate. Offers to push on explicit confirmation — never unannounced.

Bundled with `/super-bootstrap`. The harness CLAUDE.md and bootstrap plan route every flow through "doc sync → `/super-bootstrap:commit`" — this is that command.

## Protocol

### 1. Inspect Working Tree

Run in parallel:
- `git status` — full picture of modified, staged, untracked
- `git diff` — unstaged changes
- `git diff --staged` — already staged
- `git log --oneline -10` — recent commit style for message conventions

### 2. Classify Changes — Session vs Prior

Walk every changed file and classify:

| Touched by current session? | Action |
|---|---|
| Yes — Claude edited / wrote it this session | **stage** |
| No — pre-existing dirty state from prior work | **leave alone** |
| Ambiguous (mixed file, partial overlap) | **ask user** before staging |

Use the conversation transcript as source of truth for "what did this session touch." If unsure, list the file to the user with: "I don't remember touching this — stage or skip?"

**Stage by explicit path only.**

### 3. Doc-Sync Gate

Before staging, scan `docs/` for files that describe behavior touched by the diff. Per the harness CLAUDE.md rules, check:

- `docs/overview.md` — behavior/data-flow changes
- `docs/techstack.md` — dep / tooling / architecture changes
- `docs/specs/*.md` — feature behavior (if scaffolded)
- `docs/backlog.md` — items resolved or new items surfaced (if scaffolded)
- `docs/superpowers/specs+plans/*.md` — temporal cleanup if work completes

For each doc that looks stale relative to the diff:
1. Report path + what looks outdated + relevant diff context.
2. Resolve with user — update doc, or confirm still accurate.
3. Always surface the call to the user before staging.

**Backlog cleanup:** if the diff resolves a `BUG-###` / `DEBT-###` / `GAP-###` item in `docs/backlog.md`, propose deleting the item.

**Temporal cleanup:** if the diff completes a feature branch, propose deleting matching files from `docs/superpowers/specs/` and `docs/superpowers/plans/`.

Doc updates from this gate stage alongside the code changes.

### 4. Draft Commit Message

Conventional Commits format:

```
<type>(<scope>): <subject>

<body — only if "why" isn't obvious from the diff>
```

**Types:** `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `style`.

Rules:
- Subject ≤72 chars, imperative mood ("add", not "added").
- One logical change per commit. If diff spans two unrelated changes → split into two commits.
- Body only when reasoning isn't visible in the diff. Skip body for obvious fixes.
- Author message directly; co-author trailers (e.g. "🤖 Generated with Claude Code") only on explicit user request.
- Match the repo's existing commit style (scan `git log --oneline -10`).

### 5. Stage + Commit

No approval gate — stage and commit directly. The conventional message plus the explicit file list are the record. Genuine ambiguity already pauses upstream: §2 ambiguous-file classification and §3 doc-sync both surface to the user before reaching here.

Stage by explicit path:
```bash
git add path/to/file1 path/to/file2
```

Commit with HEREDOC for proper formatting:
```bash
git commit -m "$(cat <<'EOF'
<type>(<scope>): <subject>

<body if any>
EOF
)"
```

Then report what landed — files staged, files left alone (prior work), doc-sync updates, and the commit message — and run `git status` to confirm clean state.

### 6. Push (on confirmation)

After the commit confirms clean, offer to push — never run it unannounced. Present:

- branch → remote (e.g. `main` → `origin`)
- commits ahead of remote (`git log --oneline @{u}..` if upstream set, else note no upstream)

Ask: **"Push these now? (y / skip)"** Push only on explicit yes:

```bash
git push <remote> <branch>
```

Skip by default if the user is silent or declines — committed work is safe locally either way. No force push without an explicit request.

### 7. Cycle Handoff

After commit confirms clean, signal cycle exit so user knows it's safe to reset context:

> Cycle complete. Safe to `/clear`. Next session: `/super-bootstrap:todo` picks up next item.

If `docs/superpowers/specs/` or `docs/superpowers/plans/` still has unfinished work (one quick Glob — files exist, plans with unchecked boxes), name the top candidate inline:

> Cycle complete. `plans/2026-04-12-auth.md` still has 3/7 unchecked — `/clear` then `/super-bootstrap:todo` to resume.

If backlog has open items and no active superpowers work:

> Cycle complete. No active specs/plans; `docs/backlog.md` has open items — `/clear` then `/super-bootstrap:todo` to pick next.

One line. Don't expand into full status table — that's `/super-bootstrap:todo`'s job.

## Rules

- **Session-isolated** — only this session's changes. Prior dirty state is sacred.
- **Doc-sync first** — gate runs before staging. Stale docs block commit until resolved.
- **Conventional** — type, scope, subject. Body only when needed.
- **Commit directly** — no approval gate; the conventional message + explicit file list are the record. Conditional pauses still fire (ambiguous-file classification, doc-sync); routine approval doesn't.
- **Explicit paths always** — `git add <path>`, never `-A` / `.` (hard constraint — irreversible if it picks up secrets).
- **Push on confirm** — offers push after a clean commit; runs only on explicit yes, never force, never unannounced.
- **Cycle handoff** — post-commit one-liner signals cycle exit (`/clear` + `/super-bootstrap:todo` next session). Removes ambiguity at cache-reset moment.
- **No amend** — new commit on top, even after pre-commit hook failure. Amend only if user explicitly asks.
- **No `--no-verify`** — pre-commit hooks fire. If a hook fails, fix the cause, don't bypass.
- **One logical change per commit** — split if diff spans unrelated work.
