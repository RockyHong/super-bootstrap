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

- **Type:** {{project_type}}
- **Version files:**
{{version_files_list}}
- **Platforms:** {{platforms_or_none}}
- **Main branch:** {{main_branch}}

## Protocol

### 1. Qualify

Run in parallel:
- `git status` — working tree must be clean. If dirty, stop: "Commit or stash changes first."
- `git branch --show-current` — must be on `{{main_branch}}`. If not, warn and ask to continue.

### 2. Read state

```bash
# Latest version tag
git tag -l "v*" --sort=-v:refname | head -1

# Platform tags for that version (if multi-platform)
git tag -l "v<latest>-*"

# Commits since last version tag
git log <latest-tag>..HEAD --oneline

# Check if current commit == tagged commit
git rev-parse HEAD
git rev-parse <latest-tag>^{commit}  # (skip if no tags)
```

### 3. Decide

Based on the state, determine which flow to run:

**STATE A — No version tag exists:**
→ Go to "Full Release Flow"

**STATE B — Version tagged, same commit, not all platforms tagged:**
→ Go to "Platform Tag Flow"

**STATE C — Version tagged, different commit, not all platforms tagged:**
→ Ask: "New release, or tagging a platform upload for v{latest}?"
  - Platform tag → ask which commit to tag (current or the version tag's commit). Go to "Platform Tag Flow"
  - New release → Go to "Full Release Flow"

**STATE D — Version tagged, different commit, all platforms tagged (or single-platform project):**
→ Go to "Full Release Flow"

**STATE E — Version tagged, same commit, all platforms tagged:**
→ "v{latest} fully released. Nothing to do."

### Full Release Flow

**Step 1 — Detect bump level** from conventional commits since last tag:

| Signal | Bump |
|---|---|
| `BREAKING CHANGE:` in body, or `!:` suffix | major |
| `feat:` | minor |
| `fix:`, `refactor:`, `chore:`, `docs:`, `test:`, `perf:` | patch |
| No conventional prefixes | patch (default) |

Use the highest level found. If no previous tag exists, ask user for the version.

**Step 2 — Propose:**

> Current: {current_version} → New: {new_version} (auto: N feat, N fix since v{current})
> OK?

Wait for confirmation. User can override the version.

**Step 3 — Bump version files:**

{{bump_instructions}}

Use the Edit tool for each file. Only change version fields.

**Step 4 — Generate release notes** from commits since last tag:

```
## What's New
- description (from feat: commits)

## Fixes
- description (from fix: commits)

## Other
- description (from everything else)
```

Omit empty sections. Show to user for approval.

**Step 5 — Commit and tag:**

Doc-sync scan first when the gate is installed: if `.claude/hooks/docsync-scan.sh` exists, run `bash .claude/hooks/docsync-scan.sh` as its own Bash call and resolve any staleness it reports — the scan self-stamps the token the gate consumes. In un-gated repos the script is absent → skip, commit directly. Keep the scan a separate call from the commit below.

```bash
git add {{version_file_paths}}
git commit -m "chore: release v{version}"
git tag -a v{version} -m "<release notes>"
```

Use annotated tag. Pass message via HEREDOC.

**Step 6 — Report + offer push:**

> Release v{version} prepared (commit + tag v{version}).
> Push to publish? Runs `git push origin {{main_branch}} --tags`. (y / skip)

Push only on explicit yes. Skip by default if the user is silent. Never force push.

{{#if platforms}}

### Platform Tag Flow

**Step 1 — Check untagged platforms** for the current version.

If one remaining:
> v{version}-{platform} not yet tagged. Tagging this upload on current commit?

If multiple remaining:
> Untagged: {remaining_platforms}
> Which platform?

**Step 2 — Read build number** from version files for that platform.

{{platform_build_number_instructions}}

**Step 3 — Tag:**

```bash
git tag -a v{version}-{platform} -m "{Platform} upload — build {build_number}"
```

**Step 4 — Report + offer push:**

> Tagged v{version}-{platform} (build {build_number})
> Remaining: {remaining_platforms_or_none}
> Push to publish? Runs `git push origin --tags`. (y / skip)

Push only on explicit yes. Skip by default if silent.
{{/if}}

## Rules

- Push only on explicit confirmation — offer after commit/tag, run `git push ... --tags` on yes, never force, never unannounced.
- Working tree must be clean before proceeding — step 1 enforces this.
- Never delete or move existing tags.
- All tags are annotated (`git tag -a`).
- Run `/release` with no arguments — the skill auto-detects state.
