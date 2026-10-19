#!/usr/bin/env bash
# Build one derived-state fixture + a cold config dir.
#
# The fixture repo declares three commands in its CLAUDE.md `## Commands`:
# install (tools/install.sh -> deps/), regenerate (tools/codegen.sh ->
# gen/registry.txt, git-ignored, one line per src/*.src), verify
# (tools/verify.sh: every `uses: X` in src/*.src must name a type the
# registry lists). Each script appends its name to the git-ignored
# .bench-log, so the run's command order is read back after it ends.
#
#   respawn    <dir>/repo on main; worktree .claude/worktrees/autorun-gap-12
#              on autorun/gap-12, provisioned (install + codegen) on its first
#              spawn, one commit of its own; then main gains src/invoice.src +
#              src/billing.src (uses: invoice) and the gateway merges main
#              into the branch. The worktree's registry predates invoice.
#   mergegate  <dir>/repo on main, provisioned earlier; autorun/gap-12 adds
#              src/invoice.src + src/billing.src and lands on main by
#              Merge --no-ff. The main checkout's registry predates invoice.
#   nocue      <dir>/repo on main; worktree autorun-gap-12 provisioned by an
#              earlier session, which then committed src/invoice.src +
#              src/billing.src on the branch and stopped without regenerating.
#              No merge; the prompt names none of it.
#
# .bench-log is emptied at the end, so it records the run's commands only.
# <dir>/coldcfg = CLAUDE_CONFIG_DIR with credentials + settings only.
#
# Usage: bash make-fixture.sh <dir> respawn|mergegate|nocue   (absolute, outside this repo)
set -eu
FX="${1:?usage: make-fixture.sh <dir> respawn|mergegate|nocue}"
SCEN="${2:?scenario}"
rm -rf "$FX/repo" "$FX/coldcfg"
mkdir -p "$FX/repo/tools" "$FX/repo/src" "$FX/coldcfg"
R="$FX/repo"
git -C "$R" init -q -b main
git -C "$R" config user.name bench
git -C "$R" config user.email bench@example.invalid
git -C "$R" config commit.gpgsign false
git -C "$R" config core.autocrlf false
g() { git -C "$R" "$@"; }

cat > "$R/CLAUDE.md" <<'MD'
# shopdemo

Order and billing records as `src/*.src` files. A record may reference another record type with a `uses: <name>` line.

## Commands

```bash
sh tools/install.sh    # install dependencies into deps/
sh tools/codegen.sh    # regenerate gen/registry.txt (git-ignored) from src/*.src
sh tools/verify.sh     # verify: type-check every record
```
MD
printf 'gen/\ndeps/\n.bench-log\n.autorun-status\nOWNED_BY\n.claude/worktrees/\n' > "$R/.gitignore"
cat > "$R/tools/install.sh" <<'SH'
#!/bin/sh
echo install >> .bench-log
mkdir -p deps && echo ok > deps/ok
SH
cat > "$R/tools/codegen.sh" <<'SH'
#!/bin/sh
echo codegen >> .bench-log
mkdir -p gen
for f in src/*.src; do basename "$f" .src; done > gen/registry.txt
SH
cat > "$R/tools/verify.sh" <<'SH'
#!/bin/sh
echo verify >> .bench-log
[ -f deps/ok ] || { echo "error: deps/ not found"; echo "verify FAILED"; exit 1; }
rc=0
for f in src/*.src; do
  for t in $(sed -n 's/^uses: *//p' "$f"); do
    grep -qx "$t" gen/registry.txt 2>/dev/null || { echo "$f: error: unknown type '$t'"; rc=1; }
  done
done
[ $rc -eq 0 ] && echo "verify OK" || echo "verify FAILED"
exit $rc
SH
printf 'name: orders\n' > "$R/src/orders.src"
g add -A && g commit -qm "init"

add_billing() { # add_billing <tree>
  printf 'name: invoice\n' > "$1/src/invoice.src"
  printf 'name: billing\nuses: invoice\n' > "$1/src/billing.src"
}

if [ "$SCEN" = respawn ]; then
  W="$R/.claude/worktrees/autorun-gap-12"
  g worktree add -q "$W" -b autorun/gap-12 main
  printf 'session-id: bench\nspawn-ts: 2026-10-20T00:00:00Z\npurpose: autorun\nbranch: autorun/gap-12\nitem-id: GAP-12\n' > "$W/OWNED_BY"
  (cd "$W" && sh tools/install.sh && sh tools/codegen.sh)
  printf 'name: orders\nuses: orders\ntotal: 1\n' > "$W/src/orders.src"
  git -C "$W" add -A && git -C "$W" commit -qm "feat(orders): add total"
  add_billing "$R"
  g add -A && g commit -qm "feat(billing): add invoice and billing records"
  git -C "$W" merge -q --no-edit main
  : > "$W/.bench-log"
  [ -z "$(git -C "$W" status --porcelain)" ] || { echo "worktree dirty" >&2; exit 1; }
  echo "worktree at $W"
elif [ "$SCEN" = nocue ]; then
  W="$R/.claude/worktrees/autorun-gap-12"
  g worktree add -q "$W" -b autorun/gap-12 main
  printf 'session-id: bench\nspawn-ts: 2026-10-20T00:00:00Z\npurpose: autorun\nbranch: autorun/gap-12\nitem-id: GAP-12\n' > "$W/OWNED_BY"
  (cd "$W" && sh tools/install.sh && sh tools/codegen.sh)
  add_billing "$W"
  git -C "$W" add -A && git -C "$W" commit -qm "feat(billing): add invoice and billing records"
  : > "$W/.bench-log"
  [ -z "$(git -C "$W" status --porcelain)" ] || { echo "worktree dirty" >&2; exit 1; }
  echo "worktree at $W"
else
  (cd "$R" && sh tools/install.sh && sh tools/codegen.sh)
  g checkout -qb autorun/gap-12
  add_billing "$R"
  g add -A && g commit -qm "feat(billing): add invoice and billing records"
  g checkout -q main
  g merge -q --no-ff --no-edit autorun/gap-12
  : > "$R/.bench-log"
  [ -z "$(g status --porcelain)" ] || { echo "repo dirty" >&2; exit 1; }
fi

[ -f "$HOME/.claude/.credentials.json" ] && cp "$HOME/.claude/.credentials.json" "$FX/coldcfg/"
cat > "$FX/coldcfg/settings.json" <<'JSON'
{ "hooks": {}, "enabledPlugins": {}, "includeCoAuthoredBy": false,
  "permissions": { "defaultMode": "acceptEdits", "allow": [] } }
JSON
g log --oneline --graph --all
