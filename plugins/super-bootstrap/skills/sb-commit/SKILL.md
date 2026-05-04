---
name: sb-commit
description: "Stage and commit the current session's changes only. Session-isolated (never -A), doc-sync-gated, conventional message, no push. Bundled with super-bootstrap — encodes the harness commit rules."
tags: [commit, git, session, doc-sync, superpowers]
---

# Commit — Session-Isolated, Doc-Sync-Gated

Stage and commit the changes this Claude session produced. Leaves prior uncommitted work alone. Runs the doc-sync gate first. Writes a conventional commit message. Does not push.

Bundled with `/super-bootstrap`. The harness CLAUDE.md and bootstrap plan route every flow through "doc sync → `/sb-commit`" — this is that command.

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

**Never `git add -A`. Never `git add .`** Stage by explicit path only.

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
3. Never silently fix. Never silently skip.

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
- Never include "🤖 Generated with Claude Code" or co-author trailers unless user requests.
- Match the repo's existing commit style (scan `git log --oneline -10`).

### 5. Present + Confirm

Show user:
- Files to stage (explicit list, not `-A`)
- Files left alone (prior work)
- Doc-sync resolutions (what got updated)
- Drafted commit message

Wait for approval. User may edit message, drop files, or split.

### 6. Stage + Commit

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

Run `git status` after to confirm clean state.

### 7. Do Not Push

`/sb-commit` does not push. User pushes manually or via separate skill (`/commit-push-pr` from external plugins, or plain `git push`).

## Rules

- **Session-isolated** — only this session's changes. Prior dirty state is sacred.
- **Doc-sync first** — gate runs before staging. Stale docs block commit until resolved.
- **Conventional** — type, scope, subject. Body only when needed.
- **No `-A`** — explicit paths always.
- **No push** — separate concern.
- **No amend** — new commit on top, even after pre-commit hook failure. Amend only if user explicitly asks.
- **No `--no-verify`** — pre-commit hooks fire. If a hook fails, fix the cause, don't bypass.
- **One logical change per commit** — split if diff spans unrelated work.
