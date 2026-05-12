---
name: release
description: Prepare a version release — bump version files, commit, and tag. Just run /release with no arguments.
---

# Release

Prepare a version release. No arguments — reads git state and decides what to do.

## Usage

```
/release
```

## Project Config

- **Type:** generic (Claude Code plugin / marketplace)
- **Version files:**
  - `plugins/super-bootstrap/.claude-plugin/plugin.json` → `version`
  - `.claude-plugin/marketplace.json` → `plugins[0].version`
- **Platforms:** none (single artifact)
- **Main branch:** main

Both version files must stay in sync — they declare the same plugin version to two different consumers (plugin manifest + marketplace registry).

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

**Step 3 — Bump version files:**

Use the Edit tool on both files. The two files MUST end up with the same version string.

- `plugins/super-bootstrap/.claude-plugin/plugin.json` — change the top-level `"version"` field.
- `.claude-plugin/marketplace.json` — change `plugins[0].version`. Leave `plugins[0].name` and other fields alone.

Verify both files contain the new version after edit.

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

**Step 6 — Report:**

> Release v{version} prepared.
> To publish: `git push origin main --tags`
>
> After push, Claude Code plugin manager will see the new version on next `/plugin update super-bootstrap` and refresh the cache.

## Rules

- Never push. User pushes manually.
- Never proceed if working tree is dirty.
- Never delete or move existing tags.
- All tags are annotated (`git tag -a`).
- No arguments to `/release` — always auto-detect.
- Both version files must stay in sync — bump both, or bump neither.
