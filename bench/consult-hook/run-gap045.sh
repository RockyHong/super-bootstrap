#!/usr/bin/env bash
# GAP-045 Phase 3 runner — probes x arms through headless sonnet, stream-json out.
# Usage: bash bench/run-gap045.sh [arm ...]     default arms: baseline pointer forcedeval
# Env:   ID_FILTER=<regex>   subset probes by id (pilot: ID_FILTER='^(A1|A3|A4)')
#        REP=<n>             replicate number — appends __r<n> to output names
#                            (gate margins within one probe of threshold mandate
#                            repeats per the spec's pre-registered clause)
#        FIXTURE_DIR=<dir>   run with cwd inside the decontaminated fixture
#                            (bench/make-fixture.sh) — mandatory for scored runs;
#                            in-repo runs are contaminated by the recent-commits
#                            leak + taste-center self-description.
#                            Channels + checklist: bench/bench-decontamination.md
# Skips runs whose output file already exists (resumable).
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1
mkdir -p bench/runs-gap045
RUNCWD="${FIXTURE_DIR:-$ROOT}"

ARMS="${*:-baseline pointer forcedeval}"
FILTER="${ID_FILTER:-.}"
n=0
while IFS= read -r line; do
  [ -n "$line" ] || continue
  id="$(jq -r '.id' <<<"$line")"
  grep -qE "$FILTER" <<<"$id" || continue
  prompt="$(jq -r '.prompt' <<<"$line")"
  for arm in $ARMS; do
    out="$ROOT/bench/runs-gap045/${id}__${arm}${REP:+__r$REP}.jsonl"
    [ -s "$out" ] && { echo "[skip] $out"; continue; }
    n=$((n+1))
    echo "[$n] $id / $arm"
    # hermetic fixture: revert tracked files, remove leftovers a prior run wrote
    if [ -n "${FIXTURE_DIR:-}" ] && [ -d "$RUNCWD/.git" ]; then
      git -C "$RUNCWD" checkout -q -- . && git -C "$RUNCWD" clean -qfd
    fi
    ( cd "$RUNCWD" && claude --model sonnet --settings "$ROOT/bench/arm-${arm}.json" \
        --output-format stream-json --verbose -p -- "$prompt" ) \
      > "$out" 2> "$out.err"
    echo "      exit=$? lines=$(wc -l < "$out" 2>/dev/null)"
  done
done < bench/probes-gap045.jsonl
echo "DONE — $n new runs in bench/runs-gap045/"
