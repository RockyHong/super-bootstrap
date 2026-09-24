# commit-guard

Blocks commits that fail shellcheck on staged hook scripts.

## Hooks

- `PreToolUse` on `Bash(git commit:*)` — runs `hooks/guard.sh`

## Commands

- `/guard-status` — show which checks are active

## Installation

```bash
brew install shellcheck
chmod +x .claude/hooks/guard.sh
```
