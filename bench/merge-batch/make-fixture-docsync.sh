#!/usr/bin/env bash
# BUG-wnav — build the batch-landing doc-sync fixture + a cold config dir.
#
#   <dir>/repo/     git repo, base `main`, no remote:
#                     main: init — tools/greet.sh (prints `hello, world`),
#                           tools/verify.sh, docs/usage.md narrating
#                           "`tools/greet.sh` prints `hello, world`", docs/techstack.md
#                           declaring `sh tools/verify.sh` (## Staged-Tree Verify),
#                           CLAUDE.md naming both
#                     g1   one commit off init: tools/greet.sh now prints
#                          `hi there` — docs/usage.md left as it was (the stale doc)
#                     g2   one commit off init: adds notes/todo.txt (narrates nothing)
#                   No conflict; verify stays green on the integrated tree.
#                   Working tree clean, on main.
#   <dir>/coldcfg/  CLAUDE_CONFIG_DIR: credentials + settings only.
#
# Usage: bash make-fixture-docsync.sh <dir>   (outside this repo's tree; absolute path)
set -eu
FX="${1:?usage: make-fixture-docsync.sh <dir>}"
rm -rf "$FX/repo" "$FX/coldcfg"
mkdir -p "$FX/repo/tools" "$FX/repo/docs" "$FX/repo/notes" "$FX/coldcfg"
R="$FX/repo"
git -C "$R" init -q -b main
git -C "$R" config user.name bench
git -C "$R" config user.email bench@example.invalid
git -C "$R" config commit.gpgsign false
git -C "$R" config core.autocrlf false
g() { git -C "$R" "$@"; }

cat > "$R/CLAUDE.md" <<'MD'
# greetdemo

A one-script greeter. Usage is documented in [`docs/usage.md`](docs/usage.md).

## Commands

```bash
sh tools/greet.sh     # print the greeting
sh tools/verify.sh    # verify: the greeter runs and prints one line
```
MD
cat > "$R/docs/techstack.md" <<'MD'
# Tech stack

POSIX sh. No build step. Usage: [`docs/usage.md`](usage.md).

## Staged-Tree Verify

```sh
sh tools/verify.sh
```
MD
cat > "$R/docs/usage.md" <<'MD'
# Usage

Run `tools/greet.sh`. It prints `hello, world` on one line and exits 0.

## Verify

`sh tools/verify.sh` checks that `tools/greet.sh` prints exactly one line.
MD
cat > "$R/tools/greet.sh" <<'SH'
#!/bin/sh
echo "hello, world"
SH
cat > "$R/tools/verify.sh" <<'SH'
#!/bin/sh
n=$(sh tools/greet.sh | wc -l | tr -d ' ')
[ "$n" -eq 1 ] && { echo "verify OK"; exit 0; }
echo "verify FAILED: $n lines"; exit 1
SH
printf '# notes\n' > "$R/notes/README.txt"
g add -A && g commit -qm "init"

g checkout -q -b g1 main
cat > "$R/tools/greet.sh" <<'SH'
#!/bin/sh
echo "hi there"
SH
g add -A && g commit -qm "feat(greet): greet with hi there"
g checkout -q -b g2 main
printf 'tidy the notes folder\n' > "$R/notes/todo.txt"
g add -A && g commit -qm "chore(notes): add a todo"
g checkout -q main
(cd "$R" && sh tools/verify.sh >/dev/null) || { echo "fixture verify red" >&2; exit 1; }
[ -z "$(g status --porcelain)" ] || { echo "fixture dirty" >&2; exit 1; }

[ -f "$HOME/.claude/.credentials.json" ] && cp "$HOME/.claude/.credentials.json" "$FX/coldcfg/"
cat > "$FX/coldcfg/settings.json" <<'JSON'
{
  "hooks": {},
  "enabledPlugins": {},
  "includeCoAuthoredBy": false,
  "permissions": { "defaultMode": "acceptEdits" }
}
JSON
echo "fixture at $R; cold config at $FX/coldcfg"
