#!/usr/bin/env bash
# BUG-084 — build one pristine consumer repo per agent-arm run.
#
# The repo is `harbor`, a narrative-game content tree:
#   content/ambient.json        13 ambient lines keyed ambient.{time}.{noun}
#   src/ambient.py              schedules the keys by time of day (blast)
#   docs/specs/ambient-voice.md ratified spec; rule 3 and the exemplar list
#                               both cite ambient.dusk.lamp as a positive case
#   docs/work/GAP-001.md        the taste card: four flagged lines, one of them
#                               the spec exemplar; claims "dusk set (5 rows)"
#                               (real dusk family = 6) and files a night line
#                               (ambient.night.nets) under dusk
# plus docs/work/README.md + TEMPLATE.md + docs/decisions.md placed from the
# harness-bootstrap assets as they stand when this runs — so a fixture built
# before the prose edit carries the control thread contract, one built after
# carries the treatment one. One commit dated before the card's observation.
#
# Usage: bash make-fixture.sh <target-dir>
set -eu
FX="${1:?usage: make-fixture.sh <target-dir>}"
SRC="$(cd "$(dirname "$0")" && pwd)"
ASSETS="$SRC/../../plugins/super-bootstrap/skills/harness-bootstrap/assets"

rm -rf "$FX"
mkdir -p "$FX"
cp -r "$SRC/fixture/." "$FX/"
cp "$ASSETS/work-readme-skeleton.md"   "$FX/docs/work/README.md"
cp "$ASSETS/work-template-skeleton.md" "$FX/docs/work/TEMPLATE.md"
cp "$ASSETS/decisions-skeleton.md"     "$FX/docs/decisions.md"
(
  cd "$FX"
  git init -q
  git config core.autocrlf false
  git add -A
  GIT_AUTHOR_DATE="2026-09-01T10:00:00" GIT_COMMITTER_DATE="2026-09-01T10:00:00" \
    git -c user.name=bench -c user.email=bench@example.invalid commit -q -m "harbor: ambient content + voice spec"
)
echo "fixture at $FX"
