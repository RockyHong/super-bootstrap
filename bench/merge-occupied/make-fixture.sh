#!/usr/bin/env bash
# BUG-g6at — build the occupied-branch merge fixture + a cold config dir.
#
#   <dir>/repo/     git repo, base `main`, no remote:
#                     main: init (README.md, app.txt) -> "main: bump version"
#                     feature/x  1 commit off init (adds docs/x.md)
#                   feature/x is behind main by one commit and absorbs
#                   cleanly (disjoint files). Working tree clean, on main.
#   <dir>/wt-x/     a second worktree with feature/x checked out — the
#                   branch is occupied, as a finished worktree session leaves it.
#   <dir>/coldcfg/  CLAUDE_CONFIG_DIR: credentials + settings only — no
#                   device CLAUDE.md / rules / plugins / hooks reach the run.
#
# Usage: bash make-fixture.sh <dir>   (outside this repo's tree; absolute path)
set -eu
FX="${1:?usage: make-fixture.sh <dir>}"
rm -rf "$FX/repo" "$FX/wt-x" "$FX/coldcfg"
mkdir -p "$FX/repo" "$FX/coldcfg"
R="$FX/repo"
git -C "$R" init -q -b main
git -C "$R" config user.name bench
git -C "$R" config user.email bench@example.invalid
git -C "$R" config commit.gpgsign false
g() { git -C "$R" "$@"; }

printf '# demo\n' > "$R/README.md"
printf 'version=1\n' > "$R/app.txt"
g add -A && g commit -qm "init"
g checkout -qb feature/x
mkdir -p "$R/docs"; printf 'feature x\n' > "$R/docs/x.md"
g add -A && g commit -qm "feat(x): add docs/x.md"
g checkout -q main
printf 'version=2\n' > "$R/app.txt"
g add -A && g commit -qm "main: bump version"
g worktree add -q "$FX/wt-x" feature/x
[ -z "$(g status --porcelain)" ] || { echo "fixture dirty" >&2; exit 1; }
[ "$(git -C "$FX/wt-x" branch --show-current)" = "feature/x" ] || { echo "wt-x not on feature/x" >&2; exit 1; }

[ -f "$HOME/.claude/.credentials.json" ] && cp "$HOME/.claude/.credentials.json" "$FX/coldcfg/"
cat > "$FX/coldcfg/settings.json" <<'JSON'
{
  "hooks": {},
  "enabledPlugins": {},
  "includeCoAuthoredBy": false,
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": [
      "Bash(git:*)", "Bash(pwd)", "Bash(ls:*)", "Bash(echo:*)", "Bash(cat:*)", "Bash(test:*)",
      "PowerShell(git:*)", "PowerShell(Get-Location)"
    ]
  }
}
JSON
g log --oneline --graph --all
g worktree list
echo "fixture at $R; occupying worktree at $FX/wt-x; cold config at $FX/coldcfg"
