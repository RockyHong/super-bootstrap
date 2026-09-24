#!/usr/bin/env bash
# DEBT-118 M1+M2 — fire N cold headless runs of one arm x mode.
#
# The fallback `todo` agent is run as the session agent (`--agents` + `--agent todo`):
# its system prompt is the arm's `agents/todo.md` body, its tools Read/Grep/Glob, its
# user turn the dispatch prompt SKILL.md builds. cwd = the fixture repo; the spec sits
# outside it and is reached through `--add-dir`, the way the installed plugin's spec
# sits outside a consumer repo.
#
# Usage: bash run.sh <fixture-root> <arm> <mode> [N]
# Env:   MODEL (default sonnet — the agent's pinned tier)
#
# Outputs, per rep:
#   <fixture-root>/runs/<arm>-<mode>-r<n>.jsonl        full stream-json transcript
#   bench/todo-fallback-register/runs/<tag>.board.md   the run's final reply (the board)
#   bench/todo-fallback-register/runs/<tag>.reads.txt  every Read/Grep/Glob call, in order
set -u
FX="${1:?usage: run.sh <fixture-root> <arm> <mode> [N]}"
ARM="${2:?arm}"
MODE="${3:?mode}"
N="${4:-3}"
MODEL="${MODEL:-sonnet}"
SRC="$(cd "$(dirname "$0")" && pwd)"
PY=$(command -v python3 || command -v python)
win() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s' "$1"; fi; }

[ -d "$FX/repo" ] || { echo "no fixture at $FX — run make-fixture.sh first" >&2; exit 1; }
PROMPT="$(cat "$FX/arm-$ARM/prompt-$MODE.txt")"
mkdir -p "$FX/runs" "$SRC/runs"

n=1
while [ "$n" -le "$N" ]; do
  tag="$ARM-$MODE-r$n"
  out="$FX/runs/$tag.jsonl"
  if [ -s "$out" ]; then echo "[skip] $tag"; n=$((n + 1)); continue; fi
  echo "[$tag] model=$MODEL"
  (
    cd "$FX/repo" || exit 1
    CLAUDE_CONFIG_DIR="$(win "$FX/coldcfg")" claude \
      --model "$MODEL" \
      --agents "$(win "$FX/arm-$ARM/agents.json")" --agent todo \
      --tools Read,Grep,Glob \
      --add-dir "$(win "$FX/plugin")" \
      --output-format stream-json --verbose \
      -p -- "$PROMPT"
  ) > "$out" 2> "$out.err"
  echo "      exit=$? lines=$(wc -l < "$out" 2>/dev/null)"
  "$PY" - "$out" "$SRC/runs/$tag.board.md" "$SRC/runs/$tag.reads.txt" <<'PY'
import io, json, sys
src, board, reads = sys.argv[1:4]
text, calls, model = "", [], ""
for line in io.open(src, encoding="utf-8", errors="replace"):
    try:
        ev = json.loads(line)
    except ValueError:
        continue
    if ev.get("type") == "system" and ev.get("subtype") == "init":
        model = ev.get("model", "")
    if ev.get("type") == "assistant":
        for c in ev.get("message", {}).get("content", []):
            if c.get("type") == "tool_use":
                i = c.get("input", {})
                calls.append("%s\t%s" % (c.get("name"), i.get("file_path") or i.get("pattern") or ""))
    if ev.get("type") == "result":
        text = ev.get("result") or ""
io.open(board, "w", encoding="utf-8").write(text)
io.open(reads, "w", encoding="utf-8").write("# model: %s\n" % model + "\n".join(calls) + "\n")
PY
  n=$((n + 1))
done
echo "DONE — $N runs of $ARM/$MODE"
