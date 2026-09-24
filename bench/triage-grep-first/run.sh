#!/usr/bin/env bash
# DEBT-118 M4 — fire N cold headless triage runs of one arm on one card.
#
# Each rep gets a pristine copy of the fixture repo. The run is `claude -p`
# cwd'd inside that copy, briefed the way skills/triage/SKILL.md step 2
# dispatches the `triage` subagent:
#   system prompt = the arm body (agents/triage.md body, frontmatter stripped,
#                   ${CLAUDE_PLUGIN_ROOT} resolved to <fixture-root>/plugin)
#   prompt        = card ID + today's date + the gateway-aligned problem-aim
#                   (prompt-<card>.txt; no cause theory, no fix preference)
#   tools         = the agent's frontmatter set: Read, Grep, Glob, Bash, Edit
#   model         = opus (the agent is `model: inherit`; downstream sessions
#                   run the top tier)
# CLAUDE_CONFIG_DIR is the credentials-only cold dir make-fixture.sh built.
#
# Usage: bash run.sh <fixture-root> <arm> <card> [N]
#   arm   current | removed | floor
#   card  BUG-001 | BUG-002
#   N     default 3
# Env:
#   MODEL  default opus
#   PERM   permission mode, default acceptEdits. Any other mode tags the run
#          <card>-<arm>-<perm>-r<n> (e.g. PERM=auto -> BUG-001-floor-auto-r1),
#          so a mode set scores beside the default set without colliding.
#
# Outputs, per rep:
#   <fixture-root>/runs/<card>-<arm>-r<n>/        the run's repo, as left
#   <fixture-root>/runs/<card>-<arm>-r<n>.jsonl   full stream-json transcript
#   bench/triage-grep-first/runs/<card>-<arm>-r<n>.card.md    the card as left
#   bench/triage-grep-first/runs/<card>-<arm>-r<n>.result.txt the final report
#   bench/triage-grep-first/runs/<card>-<arm>-r<n>.tools.tsv  tool-call log
set -u
FXROOT="${1:?usage: run.sh <fixture-root> <arm> <card> [N]}"
ARM="${2:?arm}"
CARD="${3:?card}"
N="${4:-3}"
MODEL="${MODEL:-opus}"
PERM="${PERM:-acceptEdits}"
LABEL="$ARM"
[ "$PERM" = "acceptEdits" ] || LABEL="$ARM-$PERM"
SRC="$(cd "$(dirname "$0")" && pwd)"

[ -d "$FXROOT/repo" ] || { echo "no fixture at $FXROOT/repo — run make-fixture.sh first" >&2; exit 1; }
[ -f "$SRC/arm-$ARM.md" ] || { echo "no arm body $SRC/arm-$ARM.md — run make-arms.sh" >&2; exit 1; }
[ -f "$SRC/prompt-$CARD.txt" ] || { echo "no prompt for $CARD" >&2; exit 1; }

CFG="$FXROOT/coldcfg"
PLUGIN="$FXROOT/plugin"
if command -v cygpath >/dev/null 2>&1; then
  CFG="$(cygpath -m "$CFG")"
  PLUGIN="$(cygpath -m "$PLUGIN")"
fi
SYSTEM="$(sed "s#\${CLAUDE_PLUGIN_ROOT}#$PLUGIN#g" "$SRC/arm-$ARM.md")"
PROMPT="$(cat "$SRC/prompt-$CARD.txt")"

mkdir -p "$FXROOT/runs" "$SRC/runs"

n=1
while [ "$n" -le "$N" ]; do
  tag="$CARD-$LABEL-r$n"
  rundir="$FXROOT/runs/$tag"
  out="$FXROOT/runs/$tag.jsonl"
  if [ -s "$out" ]; then
    echo "[skip] $tag"
    n=$((n + 1))
    continue
  fi
  rm -rf "$rundir"
  cp -r "$FXROOT/repo" "$rundir"
  echo "[$tag] model=$MODEL perm=$PERM"
  (
    cd "$rundir" || exit 1
    CLAUDE_CONFIG_DIR="$CFG" claude \
      --model "$MODEL" \
      --system-prompt "$SYSTEM" \
      --tools "Read,Grep,Glob,Bash,Edit" \
      --permission-mode "$PERM" \
      --add-dir "$PLUGIN" \
      --no-session-persistence \
      --output-format stream-json --verbose \
      -p -- "$PROMPT"
  ) > "$out" 2> "$out.err"
  echo "      exit=$? lines=$(wc -l < "$out" 2>/dev/null)"

  cp "$rundir/docs/work/$CARD.md" "$SRC/runs/$tag.card.md" 2>/dev/null || true
  PYTHONIOENCODING=utf-8 python3 "$SRC/extract.py" "$out" "$SRC/runs/$tag"
  n=$((n + 1))
done
echo "DONE — $N runs of $CARD / $LABEL"
