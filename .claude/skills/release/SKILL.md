---
name: release
description: Prepare a version release — bump version files, commit, and tag. Just run /release with no arguments.
---

# Release

## Project Config

- **Type:** generic (Claude Code plugin / marketplace)
- **Version file (single source of truth):**
  - `plugins/super-bootstrap/.claude-plugin/plugin.json` → `version` (`marketplace.json` carries no `version`)
- **Derived manifest mirror:**
  - `.claude-plugin/marketplace.json` → `plugins[0].description` (synced from `plugin.json` at release; direct edits get overwritten)
- **Platforms:** none (single artifact)
- **Main branch:** main

## Protocol

### 1. Qualify

Run in parallel:
- `git status` — working tree must be clean. If dirty, stop: "Commit or stash changes first."
- `git branch --show-current` — must be on `main`. If not, warn and ask to continue.

### 2. Read state

```bash
# Latest version tag
git tag -l "v*" --sort=-v:refname | head -1

# Commits since last version tag
git log <latest-tag>..HEAD --oneline

# Check if current commit == tagged commit
git rev-parse HEAD
git rev-parse <latest-tag>^{commit}
```

### 3. Decide

**STATE A — No version tag exists:**
→ Go to "Full Release Flow"

**STATE D — Version tagged, different commit:**
→ Go to "Full Release Flow"

**STATE E — Version tagged, same commit:**
→ "v{latest} already released. Nothing to do."

### Full Release Flow

**Step 1 — Detect bump level** from conventional commits since last tag:

| Signal | Bump |
|---|---|
| `BREAKING CHANGE:` in body, or `!:` suffix | major |
| `feat:` | minor |
| `fix:`, `refactor:`, `chore:`, `docs:`, `test:`, `perf:` | patch |
| No conventional prefixes | patch (default) |

Use the highest level found.

**Step 2 — Propose:**

> Current: {current_version} → New: {new_version} (auto: N feat, N fix since v{current})
> OK?

Wait for confirmation. User can override.

**Step 3 — Bump version + sync manifest mirror:**

1. **Version** — edit `plugins/super-bootstrap/.claude-plugin/plugin.json`, change the top-level `"version"` field to the new version string. `marketplace.json` carries no `version` — do not add one.
2. **Description mirror** — copy `plugin.json` `description` verbatim into `.claude-plugin/marketplace.json` `plugins[0].description`. No-op if already identical.

Verify `plugin.json` shows the new version and the marketplace `plugins[0].description` matches `plugin.json` `description`.

**Step 4 — Generate release notes** from commits since last tag:

```
## What's New
- description (from feat: commits)

## Fixes
- description (from fix: commits)

## Other
- description (from everything else — refactor/chore/docs)
```

Omit empty sections. Show to user for approval.

**Step 5 — Commit and tag:**

```bash
git add plugins/super-bootstrap/.claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "chore: release v{version}"
git tag -a v{version} -m "<release notes>"
```

Use annotated tag. Pass message via HEREDOC.

**Step 6 — Report + offer push:**

> Release v{version} prepared (commit + tag v{version}).
> Push to publish? Runs `git push origin main --tags`. (y / skip)
>
> After push, Claude Code plugin manager will see the new version on next `/plugin update super-bootstrap` and refresh the cache.

Push only on explicit yes. Skip by default if the user is silent. Never force push.

## Rules

- Push only on explicit confirmation — offer after commit/tag, run `git push origin main --tags` on yes, never force, never unannounced.
- Working tree must be clean before proceeding — step 1 enforces this.
- Never delete or move existing tags.
- All tags are annotated (`git tag -a`).
- Run `/release` with no arguments — the skill auto-detects state.
- `plugin.json` is the single version source — bump it only. Do not add a `version` field to `marketplace.json`.
- `marketplace.json` `plugins[0].description` is a derived mirror of `plugin.json` `description` — this skill syncs it at release; direct edits get overwritten.
