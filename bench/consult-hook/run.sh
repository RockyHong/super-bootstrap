#!/usr/bin/env bash
# Phase 2 runner — fire each probe x arm through headless opus, capture stream-json.
# 3 probes x 3 arms = 9 runs. Raw streams land in bench/runs/<id>__<arm>.jsonl
# (stderr to .err). Scoring (Phase 3) reads these. Sequential; ~minutes per run.
# In-repo cwd — these runs are contaminated, archive unscored: see
# bench/bench-decontamination.md (channels + fixture checklist).
set -uo pipefail
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$ROOT" || exit 1
mkdir -p bench/runs

ARMS="baseline v1 v2-oracle"
n=0
while IFS= read -r line; do
  [ -n "$line" ] || continue
  id="$(jq -r '.id' <<<"$line")"
  prompt="$(jq -r '.prompt' <<<"$line")"
  for arm in $ARMS; do
    n=$((n+1))
    out="bench/runs/${id}__${arm}.jsonl"
    echo "[$n/9] $id / $arm  ->  $out"
    claude -p "$prompt" \
      --model opus \
      --settings "$ROOT/bench/arm-${arm}.json" \
      --output-format stream-json --verbose \
      > "$out" 2> "$out.err"
    echo "      exit=$? lines=$(wc -l < "$out" 2>/dev/null)"
  done
done < bench/probes.jsonl
echo "DONE — $n runs in bench/runs/"
