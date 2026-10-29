#!/usr/bin/env bash
# run.sh — one headless arm of the runway-receipt line-ending micro-test.
# Usage: bash bench/receipt-eol/run.sh <control|arm> <fixture-dir> <out-file>
#
#   control — the hooks-ensure-infra.md `placed` write paragraph as of c033fa9 (pre-fix)
#   arm     — the same paragraph from the working tree (copy under test: this repo's dev copy)
#
# Builds a fresh fixture, embeds the step text verbatim in the prompt, runs the agent with
# the fixture as cwd, writes stdout to <out-file>, then prints the oracle: the count of
# `\r` bytes in the receipt (0 = pass) and its `git ls-files --eol` row.
set -eu
mode="${1:?usage: run.sh <control|arm> <fixture-dir> <out-file>}"
fx="${2:?fixture dir}"
out="${3:?out file}"
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
asset_rel=plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks-ensure-infra.md
case "$mode" in
  control) src="$(git -C "$repo" show c033fa9:"$asset_rel")" ;;
  arm)     src="$(cat "$repo/$asset_rel")" ;;
  *) echo "unknown mode: $mode" >&2; exit 2 ;;
esac
# The step paragraph: from "Whenever a script resolves current" to the next blank line.
step="$(printf '%s\n' "$src" | awk '/^Whenever a script resolves current/{on=1} on&&/^$/{exit} on{print}')"
[ -n "$step" ] || { echo "step paragraph not found" >&2; exit 3; }
bash "$here/make-fixture.sh" "$fx" >/dev/null
hash="$(sha256sum < "$fx/.claude/hooks/commit-channel.sh" | cut -d' ' -f1)"
prompt="$(sed "s/@HASH@/$hash/" "$here/prompt.txt")

----- step text -----
$step"
( cd "$fx" && printf '%s\n' "$prompt" | claude -p --model haiku --tools Bash,Read --allowedTools Bash,Read \
    --setting-sources project,local --permission-prompts none ) \
    > "$out" 2>&1 || true
rcpt="$fx/.claude/super-bootstrap-runway.json"
echo "--- oracle ($mode): $fx"
# Count CR bytes with tr: under Git Bash, `grep -c $'\r'` misreports (all lines inside
# $(...), 0 on a CRLF file when piped), so it is not used as the oracle.
printf 'cr_bytes=%s\n' "$(tr -cd '\r' < "$rcpt" | wc -c | tr -d ' ')"
git -C "$fx" ls-files --eol .claude/super-bootstrap-runway.json
grep -n 'commit-channel.sh"' "$rcpt" | tr -d '\r'
