---
name: release-init
description: Detect project type and generate a tailored project-level /release skill. Run once per project to set up releasing.
tags: [release, init, scaffold, meta]
---

# Release Init

Detect project type, version files, and platform targets. Generate a project-level `/release` skill tailored to this repo.

## Usage

```
/super-bootstrap:release-init
```

## Protocol

### 1. Check for existing project skill

Look for `.claude/skills/release/SKILL.md` in the repo root.

If it exists, ask:
> Project release skill already exists. Overwrite with fresh detection? (y/n)

Stop if user declines.

### 2. Detect project type

Scan the working directory. First match wins:

| Marker | Type |
|---|---|
| `ProjectSettings/ProjectSettings.asset` (search recursively) | `unity` |
| `package.json` + `src-tauri/` directory | `tauri` |
| `package.json` | `node` |
| `*.xcodeproj` or `*.xcworkspace` (in root) | `ios-native` |
| `build.gradle` or `build.gradle.kts` (in root) | `android-native` |
| None of the above | `generic` |

### 3. Discover version files and current values

Read current version values from the detected files:

**unity:**
- Find `ProjectSettings/ProjectSettings.asset` (may be nested, e.g. `ProjectName/ProjectSettings/`)
- Read: `bundleVersion` (display version), `AndroidBundleVersionCode`, `buildNumber.iPhone`
- Report all three values

**tauri:**
- `package.json` → `version`
- `src-tauri/tauri.conf.json` → `version`
- `src-tauri/Cargo.toml` → `version`

**node:**
- `package.json` → `version`

**ios-native:**
- Find `Info.plist` → `CFBundleShortVersionString`, `CFBundleVersion`

**android-native:**
- `build.gradle` or `build.gradle.kts` → `versionName`, `versionCode`

**generic:**
- Ask user: "Where does your version live? (file path and field name)"

### 4. Detect platforms and recommend tagging approach

Determine if multi-platform based on project type and evidence:

| Type | Signal | Recommendation |
|---|---|---|
| `unity` | Has both Android + iOS build settings in ProjectSettings | Multi-platform: `android`, `ios` |
| `unity` | Only one platform target | Single platform, no platform tags |
| `tauri` | Desktop app | Single artifact, no platform tags |
| `node` | Web app / server | Single deploy, no platform tags |
| `ios-native` | iOS only | Single platform, no platform tags |
| `android-native` | Android only | Single platform, no platform tags |

Present the recommendation WITH reasoning:

> Detected: Unity project with Android + iOS build targets in `PuzzleSnake/ProjectSettings/ProjectSettings.asset`
> - bundleVersion: 4.0.5
> - AndroidBundleVersionCode: 40
> - iOS buildNumber: 1
>
> Recommending platform tags (`v4.1.0-android`, `v4.1.0-ios`) — you ship to two stores independently, so each upload gets its own tag.
>
> Look right?

Wait for confirmation. User may correct platforms (e.g., "also shipping to Steam") or remove some.

### 5. Handle greenfield / untracked repos

Check `git tag -l "v*"`:

- **Tags exist** — note the latest tag, continue.
- **No tags exist** — ask:
  > No version tags found in git. Is this a first release, or has this project shipped before without tags?

  - **First release** — suggest starting at `1.0.0` (user can override).
  - **Previously shipped** — ask for current live versions:
    > What are the current live versions? (e.g., "Android 4.0.5 build 41, iOS 1.2.9 build 12")

    Create a baseline tag on the current commit so future releases have a reference point. For multi-platform, also create platform baseline tags.

### 6. Present full summary for confirmation

Show everything in one block:

```
Project type: unity
Version files:
  - PuzzleSnake/ProjectSettings/ProjectSettings.asset
    - bundleVersion (display version): 4.0.5
    - AndroidBundleVersionCode: 40
    - buildNumber.iPhone: 1

Platforms: android, ios
Tagging: v{version} + v{version}-android, v{version}-ios

Qualification: clean git, on master

Git baseline: v4.0.5 (to be created)

Generate .claude/skills/release/SKILL.md with these settings?
```

Wait for user approval.

### 7. Generate the project-level skill

Create `.claude/skills/release/SKILL.md` using the template below, filling in the detected values.

The generated skill content follows this template — substitute all `{{placeholders}}`:

````markdown
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

> Current: {{current_version}} → New: {new_version} (auto: N feat, N fix since v{current})
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
> v{version}-{{platform}} not yet tagged. Tagging this upload on current commit?

If multiple remaining:
> Untagged: {{remaining_platforms}}
> Which platform?

**Step 2 — Read build number** from version files for that platform.

{{platform_build_number_instructions}}

**Step 3 — Tag:**

```bash
git tag -a v{version}-{platform} -m "{Platform} upload — build {build_number}"
```

**Step 4 — Report + offer push:**

> Tagged v{version}-{platform} (build {build_number})
> Remaining: {{remaining_platforms_or_none}}
> Push to publish? Runs `git push origin --tags`. (y / skip)

Push only on explicit yes. Skip by default if silent.
{{/if}}

## Rules

- Push only on explicit confirmation — offer after commit/tag, run `git push ... --tags` on yes, never force, never unannounced.
- Never proceed if working tree is dirty.
- Never delete or move existing tags.
- All tags are annotated (`git tag -a`).
- No arguments to `/release` — always auto-detect.
````

### 8. Fill the template

Replace all `{{placeholders}}` with detected values:

- `{{project_type}}` — detected type
- `{{version_files_list}}` — bullet list of file paths and field names with current values
- `{{platforms_or_none}}` — comma-separated platform list, or `none (single-platform)`
- `{{main_branch}}` — from `git branch --show-current` or detect default
- `{{bump_instructions}}` — project-specific Edit instructions for each version file
- `{{version_file_paths}}` — space-separated paths for `git add`
- `{{platform_build_number_instructions}}` — how to read each platform's build number
- Remove the `{{#if platforms}}...{{/if}}` block entirely if single-platform

The generated skill should be clean markdown with no template syntax remaining.

### 9. Commit

```bash
git add .claude/skills/release/SKILL.md
git commit -m "chore: add project release skill"
```

### 10. Report

> Project release skill generated at `.claude/skills/release/SKILL.md`.
> From now on, just run `/release`.

Then offer to push this commit: **"Push now? (y / skip)"** — push only on yes, skip by default if silent.

## Rules

- Push only on explicit confirmation — offer after the commit, never force, never unannounced.
- Always confirm detection results before generating.
- If detection is ambiguous, ask — don't guess.
- The generated skill must have zero placeholders — all values filled in.
