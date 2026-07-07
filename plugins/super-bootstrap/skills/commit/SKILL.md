---
name: commit
description: "Stage and commit the current session's changes only. Session-isolated (never -A), doc-sync-gated, conventional message, commits directly without a confirm gate, offers push on explicit confirmation. Bundled with super-bootstrap — encodes the harness commit rules."
tags: [commit, git, session, doc-sync, superpowers]
---

# Commit — Session-Isolated, Doc-Sync-Gated

Stage and commit the changes this Claude session produced. Leaves prior uncommitted work alone. Runs the doc-sync gate first. Writes a conventional commit message and commits directly — no approval gate. Offers to push on explicit confirmation — never unannounced.

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

Run the doc-sync gate per the project's **CLAUDE.md § Doc Sync** — it owns the scan surface (`docs/` plus behavior-narrating prose outside it) and the write boundary (what doc-sync may update vs flag-and-defer). This skill runs that gate; it does not re-declare its scope.

Commit-specific: surface every call **before** staging, not after. Doc updates from this gate stage alongside the code changes.

Once every call resolves (updated / acknowledged-accurate / explicit skip), branch on the installed hook set. Two `test -f` probes under `$CLAUDE_PROJECT_DIR/.claude/hooks/` decide the branch — `docsync-gate.sh` (the `PreToolUse` artifact that actually blocks the commit) and `docsync-scan.sh` (the only legitimate producer of `.git/docsync-token`):

**Gate absent** — `! -f "$CLAUDE_PROJECT_DIR/.claude/hooks/docsync-gate.sh"`. No hook blocks the commit. The doc-sync staleness judgment above (against CLAUDE.md § Doc Sync's scan surface) still runs and still gates the commit; once it resolves, commit directly.

**Gate live, scan present** — `-f docsync-gate.sh` **and** `-f docsync-scan.sh`. `git commit` is denied until `.git/docsync-token` exists, and that token is produced only by running the scan. Run the scan as its own Bash call: `bash "$CLAUDE_PROJECT_DIR/.claude/hooks/docsync-scan.sh"` (installed alongside the gate by harness-bootstrap `assets/hooks-ensure-infra.md`). The scan prints the changed-files surface (the grounding for your staleness judgment) and — as a side-effect — the `docsync-stamp` `PostToolUse` hook writes `.git/docsync-token`, which the `docsync-gate` hook consumes on the next commit attempt — one-shot. **Never `touch` the token by hand — the stamp is produced by running the scan, not forged.** Run the scan and `git commit` as SEPARATE tool calls: never chain `docsync-scan.sh && git commit` in one Bash call — PreToolUse reads the whole command string *before* the scan runs, sees `git commit`, checks the not-yet-written token, and denies. Scan first (its own call, which writes the token), then commit in a later call.

**Gate live, scan absent** — `-f docsync-gate.sh` but `! -f docsync-scan.sh`. The gate will deny the commit for a missing `.git/docsync-token`, and its producer `docsync-scan.sh` isn't installed. Do **not** `bash` the missing script, do **not** forge the token. Surface the state and halt: tell the user the doc-sync gate is installed but its scan script (`docsync-scan.sh`) is missing — the hook set is stale/partial; run `/super-bootstrap` to re-sync it, then commit. The commit can't legitimately proceed until the install is repaired.

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

After commit confirms clean, signal cycle exit. One line — don't expand into full status table (that's `/super-bootstrap:todo`'s job).

| Condition | Handoff one-liner |
|---|---|
| No unfinished specs/plans, no backlog items | `Cycle complete. Safe to /clear. Next session: /super-bootstrap:todo picks up next item.` |
| Unfinished work in specs/plans (unchecked boxes) | `Cycle complete. plans/2026-04-12-auth.md still has 3/7 unchecked — /clear then /super-bootstrap:todo to resume.` |
| Backlog has open items, no active superpowers work | `Cycle complete. No active specs/plans; docs/backlog.md has open items — /clear then /super-bootstrap:todo to pick next.` |

## Rules

- **Session-isolated** — only this session's changes. Prior dirty state is sacred.
- **Doc-sync first** — the staleness judgment gates before staging; stale docs block commit until resolved. When the `docsync-gate` hook is live, clearing it needs the scan's token — and if `docsync-scan.sh` is missing, halt and re-sync rather than forge it — see §3.
- **Scan and commit are separate calls** — when the gate is live, never chain `docsync-scan.sh && git commit` in one Bash call — see §3.
- **Conventional** — type, scope, subject. Body only when needed.
- **Commit directly** — no approval gate; the conventional message + explicit file list are the record. Conditional pauses still fire (ambiguous-file classification, doc-sync); routine approval doesn't.
- **Explicit paths always** — `git add <path>`, never `-A` / `.`.
- **Push on confirm** — offers push after a clean commit; runs only on explicit yes, never force, never unannounced.
- **Cycle handoff** — post-commit one-liner signals cycle exit (`/clear` + `/super-bootstrap:todo` next session). Removes ambiguity at cache-reset moment.
- **Always new commit** — even after pre-commit hook failure. Amend only if user explicitly asks.
- **Hooks always fire** — pre-commit hooks run. If a hook fails, fix the cause, don't bypass.
- **One logical change per commit** — split if diff spans unrelated work.
