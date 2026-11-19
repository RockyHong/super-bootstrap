#!/usr/bin/env bash
# DEBT-ymdg — one headless run of the carrier-equivalence bench.
# Usage: bash run.sh <outdir> <arm> <context> <rep>     context: main|subagent|compact|resume-compact
# Writes <outdir>/runs/<arm>-<context>-r<rep>.jsonl (the TASK turn's stream),
#   .t1.jsonl/.t2.jsonl (resume-compact only: filler + /compact turns), .probe/ (copy of the
#   fixture's .probe logs), .err. The fixture is built fresh per run in
#   <outdir>/work/<name>/ — no state shared between runs.
# Permission posture: --permission-mode default (overrides the cold config's
#   acceptEdits) + --disallowedTools "Edit,Write,NotebookEdit,Bash" — read-only
#   by construction; Read/Glob/Grep/Agent stay. Model pinned: --model sonnet.
# Env: RUNS_SUBDIR (default runs) — smoke runs use `smoke`.
set -u
OUT="${1:?usage: run.sh <outdir> <arm> <context> <rep>}"; ARM="${2:?}"; CTX="${3:?}"; REP="${4:?}"
SRC="$(cd "$(dirname "$0")" && pwd)"
NAME="$ARM-$CTX-r$REP"
RD="$OUT/${RUNS_SUBDIR:-runs}"; WORK="$OUT/work/$NAME"
mkdir -p "$RD"
[ -s "$RD/$NAME.jsonl" ] && { echo "[skip] $NAME"; exit 0; }
rm -rf "$WORK"
bash "$SRC/make-fixture.sh" "$WORK" "$ARM" > "$RD/$NAME.fixture.txt" 2>&1 || { echo "fixture failed: $NAME" >&2; exit 1; }
CFG="$WORK/coldcfg"; command -v cygpath >/dev/null 2>&1 && CFG="$(cygpath -m "$CFG")"
mkdir -p "$WORK/home"; FAKEHOME="$WORK/home"; command -v cygpath >/dev/null 2>&1 && FAKEHOME="$(cygpath -m "$FAKEHOME")"
TASK="$(cat "$SRC/task-prompt.txt")"
COMMON=(--model sonnet --permission-mode default --disallowedTools "Edit,Write,NotebookEdit,Bash" --output-format stream-json --verbose
        --setting-sources project,local --strict-mcp-config)
# --setting-sources/--strict-mcp-config: try to cut the operator's user layer (~/.claude/CLAUDE.md
# still loaded under CLAUDE_CONFIG_DIR+HOME overrides) and the account-level claude.ai MCP connectors.

# one turn: claude_turn <outfile> [extra flags...] -- <prompt>
claude_turn() {
  local out="$1"; shift
  # QUIRK 1: CLAUDE_CONFIG_DIR alone does NOT cold the user layer on this build —
  # the first smoke run still loaded the operator's ~/.claude/CLAUDE.md
  # (InstructionsLoaded showed it). HOME/USERPROFILE point at an empty dir to cut it.
  # QUIRK 2: Git Bash (MSYS) rewrites a bare "/compact" argument into
  # "C:/Program Files/Git/compact"; MSYS_NO_PATHCONV=1 stops that.
  # QUIRK 3: `< /dev/null` — otherwise claude waits 3s for stdin.
  ( cd "$WORK/repo" && MSYS_NO_PATHCONV=1 HOME="$FAKEHOME" USERPROFILE="$FAKEHOME" \
      CLAUDE_CONFIG_DIR="$CFG" claude "${COMMON[@]}" "$@" ) < /dev/null > "$out" 2> "$out.err"
  echo "  [$NAME] $(basename "$out") exit=$? lines=$(wc -l < "$out")"
}
sid_of() { python3 -c '
import io,json,sys
for l in io.open(sys.argv[1],encoding="utf-8",errors="replace"):
    try: e=json.loads(l)
    except ValueError: continue
    if e.get("session_id"): print(e["session_id"]); break' "$1"; }

case "$CTX" in
  main)
    claude_turn "$RD/$NAME.jsonl" -p -- "$TASK" ;;
  subagent)
    # forwarded subagent text: flag first; QUIRK recorded in README if env form is needed
    claude_turn "$RD/$NAME.jsonl" --forward-subagent-text -p -- "$(cat "$SRC/subagent-prompt.txt")" ;;
  compact)
    # ONE claude process, three user turns over stream-json (drive-turns.py):
    # filler, "/compact", task. The process is never restarted, so any
    # instruction load logged after the compaction marker is an in-process
    # re-injection. Turn boundaries are bench_turn markers in the stream.
    # native python.exe needs Windows paths (cygpath -m), not /d/... or /tmp/...
    W() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else echo "$1"; fi; }
    ( cd "$WORK/repo" && MSYS_NO_PATHCONV=1 HOME="$FAKEHOME" USERPROFILE="$FAKEHOME" CLAUDE_CONFIG_DIR="$CFG" \
        python3 "$(W "$SRC")/drive-turns.py" "$(W "$RD")/$NAME.jsonl" "$(W "$WORK")/repo" \
          "$(W "$SRC")/filler-prompt.txt" "$(W "$SRC")/compact-prompt.txt" "$(W "$SRC")/task-prompt.txt" \
          -- claude "${COMMON[@]}" ) < /dev/null
    echo "  [$NAME] $(basename "$RD/$NAME.jsonl") lines=$(wc -l < "$RD/$NAME.jsonl")" ;;
  resume-compact)
    # OLD three-process form, NOT part of the round: measures --resume, not
    # compaction (turn 3 is a fresh process that reloads every file at start).
    claude_turn "$RD/$NAME.t1.jsonl" -p -- "$(cat "$SRC/filler-prompt.txt")"
    SID="$(sid_of "$RD/$NAME.t1.jsonl")"
    [ -n "$SID" ] || { echo "no session id from turn 1" >&2; exit 1; }
    claude_turn "$RD/$NAME.t2.jsonl" --resume "$SID" -p -- "/compact"
    claude_turn "$RD/$NAME.jsonl" --resume "$SID" -p -- "$TASK" ;;
  *) echo "bad context $CTX" >&2; exit 1 ;;
esac
rm -rf "$RD/$NAME.probe"; cp -r "$WORK/repo/.probe" "$RD/$NAME.probe" 2>/dev/null || mkdir -p "$RD/$NAME.probe"
