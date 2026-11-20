#!/usr/bin/env bash
# One headless run of the session-close-compaction probe.
# Usage: bash run.sh <outdir> <compact|nocompact> <rep>
# Writes <outdir>/runs/<arm>-r<rep>.jsonl (whole stream, bench_turn markers) and
# <arm>-r<rep>.verdict.txt (validity). Fixture + cold config come from the
# carrier-equivalence bench (called, not copied); drive-turns.py is called too.
# <outdir> must sit outside the repo and outside Claude Code's temp tree (%TEMP%/claude/...),
# else project instruction files do not load (see ../carrier-equivalence/README.md).
set -u
OUT="${1:?usage: run.sh <outdir> <compact|nocompact> <rep>}"; ARM="${2:?}"; REP="${3:?}"
SRC="$(cd "$(dirname "$0")" && pwd)"; CE="$SRC/../carrier-equivalence"
NAME="$ARM-r$REP"; RD="$OUT/runs"; WORK="$OUT/work/$NAME"
mkdir -p "$RD"; rm -rf "$WORK"
W() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else echo "$1"; fi; }
bash "$CE/make-fixture.sh" "$WORK" rules > "$RD/$NAME.fixture.txt" 2>&1 || { echo "fixture failed" >&2; exit 1; }
mkdir -p "$WORK/home"
case "$ARM" in
  compact)   TURNS=("$CE/filler-prompt.txt" "$CE/compact-prompt.txt" "$SRC/probe-prompt.txt") ;;
  nocompact) TURNS=("$CE/filler-prompt.txt" "$SRC/probe-prompt.txt") ;;
  *) echo "bad arm $ARM" >&2; exit 1 ;;
esac
TW=(); for t in "${TURNS[@]}"; do TW+=("$(W "$t")"); done
# Read-only fixture: same disallowed tools as carrier-equivalence.
COMMON=(--model sonnet --permission-mode default --disallowedTools "Edit,Write,NotebookEdit,Bash"
        --output-format stream-json --verbose --setting-sources project,local --strict-mcp-config)
# MSYS_NO_PATHCONV: Git Bash rewrites a bare /compact; HOME/USERPROFILE/CLAUDE_CONFIG_DIR cold the user layer.
( cd "$WORK/repo" && MSYS_NO_PATHCONV=1 HOME="$(W "$WORK/home")" USERPROFILE="$(W "$WORK/home")" \
    CLAUDE_CONFIG_DIR="$(W "$WORK/coldcfg")" \
    python3 "$(W "$CE")/drive-turns.py" "$(W "$RD")/$NAME.jsonl" "$(W "$WORK")/repo" "${TW[@]}" \
      -- claude "${COMMON[@]}" ) < /dev/null
# validity: compact needs compact_boundary before the last bench_turn; nocompact needs none anywhere.
PYTHONIOENCODING=utf-8 python3 - "$(W "$RD")/$NAME.jsonl" "$ARM" > "$RD/$NAME.verdict.txt" <<'PY'
import json, sys
last_turn = 0; boundary_at = None; n = 0
for l in open(sys.argv[1], encoding="utf-8"):
    try: e = json.loads(l)
    except ValueError: continue
    if e.get("type") == "bench_turn": last_turn = e["turn"]
    if e.get("subtype") == "compact_boundary":
        boundary_at = last_turn if boundary_at is None else boundary_at
arm = sys.argv[2]; probe_turn = 3 if arm == "compact" else 2
if arm == "compact":
    ok = boundary_at is not None and boundary_at < probe_turn
else:
    ok = boundary_at is None and last_turn == probe_turn
print("valid=%s boundary_in_turn=%s probe_turn=%s last_turn=%s" % (ok, boundary_at, probe_turn, last_turn))
PY
cat "$RD/$NAME.verdict.txt"
