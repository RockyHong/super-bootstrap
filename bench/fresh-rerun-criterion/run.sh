#!/usr/bin/env bash
# bench/fresh-rerun-criterion — reading-only RED for the fresh-install / re-run criterion.
#
#   run.sh <outdir> [trials]      build both prompts, run <trials> headless trials per arm
#   run.sh --build <outdir>       build both prompts only (no model call)
#
# control = SKILL.md at $CONTROL_REF (default: the parent of the commit that changed the
# criterion); arm = the working-tree SKILL.md. Excerpts are cut by line pattern, so each
# arm reads the bytes that ship.
set -u

here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
skill="plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md"
ref="${CONTROL_REF:-HEAD}"

build_only=0
if [ "${1:-}" = "--build" ]; then build_only=1; shift; fi
out="${1:?usage: run.sh [--build] <outdir> [trials]}"
trials="${2:-3}"
mkdir -p "$out"

# The state read (through the paragraph before the skeleton-block note), then § 2b's
# bootstrap-shaped-commit paragraph and the rot scan paragraph.
excerpt() {
  awk '
    /^Read the repo.s \*\*state\*\* off the files present/ { on = 1 }
    /^On fresh and split, with a `CLAUDE.md` present/      { on = 0 }
    on                                                     { print }
    /^\*\*Bootstrap-shaped commit/                         { print; print "" }
    /^\*\*Rot scan \(mandatory pre-step/                   { print }
  '
}

git -C "$repo" show "$ref:$skill" | tr -d '\r' | excerpt > "$out/excerpt-control.md"
tr -d '\r' < "$repo/$skill" | excerpt > "$out/excerpt-arm.md"

for arm in control arm; do
  [ -s "$out/excerpt-$arm.md" ] || { echo "empty excerpt: $arm" >&2; exit 1; }
  awk -v f="$out/excerpt-$arm.md" '
    $0 == "{EXCERPT}" { while ((getline l < f) > 0) print l; close(f); next }
    { print }
  ' "$here/scenario.md" > "$out/prompt-$arm.txt"
done

if cmp -s "$out/excerpt-control.md" "$out/excerpt-arm.md"; then
  echo "excerpts are identical — the arms do not differ" >&2
  exit 1
fi
[ "$build_only" = 1 ] && { echo "built: $out/prompt-{control,arm}.txt"; exit 0; }

cd "$out" || exit 1
for arm in control arm; do
  i=1
  while [ "$i" -le "$trials" ]; do
    claude -p --model haiku --tools "" --strict-mcp-config --setting-sources "" \
      < "prompt-$arm.txt" > "$arm-$i.txt" 2> "$arm-$i.err"
    printf '%s %s: %s\n' "$arm" "$i" "$(grep -m1 -oE '\b(RUN|SKIP)\b' "$arm-$i.txt" || echo '?')"
    i=$((i + 1))
  done
done
