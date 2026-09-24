#!/usr/bin/env bash
# GAP-091 L6 — build the throwaway merge fixture + a cold config dir.
#
#   <dir>/repo/     git repo, base `main`, no remote:
#                     main: init (README.md, app.txt) -> "main: bump version"
#                     feature/a  1 commit off init  (adds docs/a.md)
#                     feature/b  3 commits off init (adds lib/b.txt, grows it)
#                   Both branches are behind main by one commit and absorb
#                   cleanly (disjoint files). Working tree clean, on main.
#   <dir>/coldcfg/  CLAUDE_CONFIG_DIR: credentials + settings only — no
#                   device CLAUDE.md / rules / plugins / hooks reach the run.
#                   Allow-list covers git and cd forms in both shells so a
#                   cd attempt runs instead of being denied (a denial would
#                   perturb the rest of the run).
#
# Usage: bash make-fixture.sh <dir>   (outside this repo's tree)
set -eu
FX="${1:?usage: make-fixture.sh <dir>}"
rm -rf "$FX/repo" "$FX/coldcfg"
mkdir -p "$FX/repo" "$FX/coldcfg"
R="$FX/repo"
g() { git -C "$R" -c user.name=bench -c user.email=bench@example.invalid -c commit.gpgsign=false "$@"; }

git -C "$R" init -q -b main
printf '# demo\n' > "$R/README.md"
printf 'version=1\n' > "$R/app.txt"
g add -A && g commit -qm "init"
g checkout -qb feature/a
mkdir -p "$R/docs"; printf 'feature a\n' > "$R/docs/a.md"
g add -A && g commit -qm "feat(a): add docs/a.md"
g checkout -q main
g checkout -qb feature/b
mkdir -p "$R/lib"
for i in 1 2 3; do printf 'b step %s\n' "$i" >> "$R/lib/b.txt"; g add -A; g commit -qm "feat(b): step $i"; done
g checkout -q main
printf 'version=2\n' > "$R/app.txt"
g add -A && g commit -qm "main: bump version"
git -C "$R" config user.name bench
git -C "$R" config user.email bench@example.invalid
git -C "$R" config commit.gpgsign false
[ -z "$(git -C "$R" status --porcelain)" ] || { echo "fixture dirty" >&2; exit 1; }

[ -f "$HOME/.claude/.credentials.json" ] && cp "$HOME/.claude/.credentials.json" "$FX/coldcfg/"
cat > "$FX/coldcfg/settings.json" <<'JSON'
{
  "hooks": {},
  "enabledPlugins": {},
  "includeCoAuthoredBy": false,
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": [
      "Bash(git:*)", "Bash(cd:*)", "Bash(pwd)", "Bash(ls:*)",
      "PowerShell(git:*)", "PowerShell(cd:*)", "PowerShell(Set-Location:*)", "PowerShell(Get-Location)"
    ]
  }
}
JSON
git -C "$R" log --oneline --graph --all
echo "fixture at $R; cold config at $FX/coldcfg"
