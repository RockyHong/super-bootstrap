#!/usr/bin/env bash
# make-fixture.sh — scratch repo for the context-heavy micro-test.
# Usage: bash bench/context-heavy/make-fixture.sh <dir>
#
# After: a clean tree whose card GAP-x1 holds a settled Design and a 4-step Plan, with steps
# 1-2 landed in docs/limits.md and steps 3-4 open. The intro sentence of docs/limits.md
# says 4 retries where the Design and the table say 5: scenario B's finding.
set -eu
dir="${1:?usage: make-fixture.sh <dir>}"
rm -rf "$dir"
mkdir -p "$dir/docs/work"
cd "$dir"
git init -q -b main
git config user.name bench
git config user.email bench@example.invalid
git config core.autocrlf false
cat > docs/work/GAP-x1.md <<'EOF'
# GAP-x1 — docs/limits.md has no client limits table

**Problem:** Client authors have no single page for the client limits.

## Design

`docs/limits.md` holds one table. The `retries` limit is 5. The `timeout` limit is 30 s.

## Plan

1. Create `docs/limits.md` with its intro sentence and the table header.
2. Add the `retries` row.
3. Add the `timeout` row.
4. Link `docs/limits.md` from `README.md`.

## Progress

Steps 1 and 2 landed. Step 3 is next.
EOF
cat > docs/limits.md <<'EOF'
# Client limits

A client makes at most 4 retries before it reports a failure.

| Limit | Value |
|---|---|
| retries | 5 |
EOF
printf '# Client\n' > README.md
git add -A
git commit -qm "docs: limits page, steps 1-2 of GAP-x1"
