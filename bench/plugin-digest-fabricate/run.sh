#!/usr/bin/env bash
# GAP-091 L2 — fire N cold headless plugin-digest runs of one arm.
#
#   system prompt = arm body (arm-A.md | arm-B.md | arm-C.md)
#   prompt        = prompt.txt (build-prompt.sh — the 7-candidate batch, inline)
#   tools         = the agent's set: Read, Grep, Glob (content is inline; no
#                   file paths are supplied, so tools should go unused)
#   model         = claude-haiku-4-5 (the agent pins `model: haiku`)
# cwd = an empty scratch dir; CLAUDE_CONFIG_DIR = a credentials-only cold dir
# (no device CLAUDE.md, rules, plugins, hooks reach the run).
#
# Usage: bash run.sh <scratch-root> <A|B|C> [N]
# Outputs: runs/<arm>-r<n>.txt (final result text), <scratch>/<arm>-r<n>.json
set -u
SCR="${1:?usage: run.sh <scratch-root> <A|B> [N]}"
ARM="${2:?arm}"
N="${3:-3}"
MODEL="${MODEL:-claude-haiku-4-5}"
SRC="$(cd "$(dirname "$0")" && pwd)"
[ -f "$SRC/arm-$ARM.md" ] || { echo "run make-arms.sh first" >&2; exit 1; }
[ -f "$SRC/prompt.txt" ] || { echo "run build-prompt.sh > prompt.txt first" >&2; exit 1; }

mkdir -p "$SCR/cwd" "$SCR/coldcfg" "$SRC/runs"
[ -f "$SCR/coldcfg/.credentials.json" ] || cp "$HOME/.claude/.credentials.json" "$SCR/coldcfg/"
[ -f "$SCR/coldcfg/settings.json" ] || printf '{"hooks":{},"enabledPlugins":{},"permissions":{"defaultMode":"default"}}\n' > "$SCR/coldcfg/settings.json"
CFG="$SCR/coldcfg"
command -v cygpath >/dev/null 2>&1 && CFG="$(cygpath -m "$CFG")"
SYSTEM="$(cat "$SRC/arm-$ARM.md")"
PROMPT="$(cat "$SRC/prompt.txt")"

n=1
while [ "$n" -le "$N" ]; do
  tag="$ARM-r$n"
  if [ -s "$SRC/runs/$tag.txt" ]; then echo "[skip] $tag"; n=$((n+1)); continue; fi
  (
    cd "$SCR/cwd" || exit 1
    CLAUDE_CONFIG_DIR="$CFG" claude \
      --model "$MODEL" \
      --system-prompt "$SYSTEM" \
      --tools "Read,Grep,Glob" \
      --no-session-persistence \
      --output-format json \
      -p -- "$PROMPT"
  ) > "$SCR/$tag.json" 2> "$SCR/$tag.err"
  rc=$?
  PYTHONIOENCODING=utf-8 python3 -c '
import json,sys
d=json.load(open(sys.argv[1],encoding="utf-8"))
open(sys.argv[2],"w",encoding="utf-8").write(d.get("result",""))
print("      model:", ",".join((d.get("modelUsage") or {}).keys()), "turns:", d.get("num_turns"))
' "$SCR/$tag.json" "$SRC/runs/$tag.txt"
  echo "[$tag] exit=$rc"
  n=$((n+1))
done
