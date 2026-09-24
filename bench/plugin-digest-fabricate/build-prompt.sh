#!/usr/bin/env bash
# GAP-091 L2 — build the batch dispatch prompt the way resolve-plugins Phase 2.5
# dispatches plugin-digest: every fetched README/manifest body from the run,
# each tagged with its candidate name, one dispatch for the whole batch.
# Candidate name = fixture filename minus the numeric prefix and extension.
#
# Usage: bash build-prompt.sh > prompt.txt
set -eu
SRC="$(cd "$(dirname "$0")" && pwd)"
n="$(ls "$SRC/fixture" | wc -l | tr -d ' ')"
printf 'resolve-plugins Phase 2.5 — digest this batch of %s candidates. Content is inline below (already fetched by the gateway).\n' "$n"
for f in "$SRC"/fixture/*.md; do
  name="$(basename "$f" .md)"; name="${name#*-}"
  printf '\n=== candidate: %s ===\n' "$name"
  cat "$f"
  printf '\n=== end %s ===\n' "$name"
done
