#!/usr/bin/env bash
# make-fixture.sh — scratch repo for the runway-receipt line-ending micro-test.
# Usage: bash bench/receipt-eol/make-fixture.sh <dir>
#
# After: a consumer-shaped repo — core.autocrlf=true, `* text=auto eol=lf` — with one
# commit holding an LF `.claude/super-bootstrap-runway.json` whose `placed` map carries a
# stale hash for `.claude/hooks/commit-channel.sh`, plus that hook file. The step under
# test must rewrite that one `placed` key.
set -eu
dir="${1:?usage: make-fixture.sh <dir>}"
rm -rf "$dir"
mkdir -p "$dir/.claude/hooks"
cd "$dir"
git init -q -b main
git config user.name bench
git config user.email bench@example.invalid
git config core.autocrlf true
printf '* text=auto eol=lf\n' > .gitattributes
printf '#!/usr/bin/env bash\n# commit-channel hook (fixture copy)\nexit 0\n' > .claude/hooks/commit-channel.sh
cat > .claude/super-bootstrap-runway.json <<'EOF'
{
  "version": "5.5.0",
  "covered": [
    "CLAUDE.md § Doc Sync",
    "CLAUDE.md § Dispatch",
    ".claude/hooks/commit-channel.sh"
  ],
  "declined": [],
  "placed": {
    ".claude/hooks/commit-channel.sh": "0000000000000000000000000000000000000000000000000000000000000000"
  }
}
EOF
git add -A
git commit -qm "init"
printf 'receipt CR bytes before run: %s\n' "$(tr -cd '\r' < .claude/super-bootstrap-runway.json | wc -c | tr -d ' ')"
