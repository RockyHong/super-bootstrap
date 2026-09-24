#!/usr/bin/env bash
# DEBT-118 M1+M2 — build the scratch tree both arms run against.
#
# Usage: bash make-fixture.sh <target-dir>
#
# Produces:
#   <target-dir>/repo                 bench/todo-board/fixture (13 cards + test queue),
#                                     one neutral commit — the fallback agent's cwd
#   <target-dir>/plugin/shared/classify-actionable.md
#                                     the shipped spec (identical for both arms; the card
#                                     edits the briefing, never the spec)
#   <target-dir>/coldcfg              CLAUDE_CONFIG_DIR: credentials + empty settings only
#   <target-dir>/arm-<arm>/           agents.json + prompt-<mode>.txt per arm (build-dispatch.py)
#   <target-dir>/arm-live/            the same, built from the working-tree SKILL.md + agents/todo.md
#                                     (the shipped dispatch — the regression arm; BUG-074)
#   <target-dir>/golden/<mode>.md     render-board.py's board for the same fixture + mode,
#                                     re-rendered at the run's date (the goldens in
#                                     bench/todo-board/expected/ are pinned to 2026-08-14;
#                                     the check below proves the re-render differs only in
#                                     the title date)
set -eu
FX="${1:?usage: make-fixture.sh <target-dir>}"
SRC="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SRC/../.." && pwd)"
PLUG="$ROOT/plugins/super-bootstrap"
PY=$(command -v python3 || command -v python)
MODES="needme full"
DATE="${DATE:-$(date +%Y-%m-%d)}"

win() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s' "$1"; fi; }

rm -rf "$FX/repo" "$FX/plugin" "$FX/coldcfg" "$FX/golden" "$FX"/arm-* "$FX/src-live"
mkdir -p "$FX/repo" "$FX/plugin/shared" "$FX/coldcfg" "$FX/golden"

cp -r "$ROOT/bench/todo-board/fixture/." "$FX/repo/"
cp "$PLUG/shared/classify-actionable.md" "$FX/plugin/shared/"

# arm copies: current = shipped (HEAD) text, proposed = make-arms.py over it
"$PY" "$SRC/make-arms.py" >/dev/null
SPEC="$(win "$FX/plugin/shared/classify-actionable.md")"
for arm in current proposed; do
  "$PY" "$SRC/build-dispatch.py" "$SRC/arms/$arm" "$PLUG/skills/todo/assets/scaffolds.md" \
    "$SPEC" "$FX/arm-$arm" $MODES
done
# the two arms' prompts may differ only on the M1 lines
for m in $MODES; do
  d="$(diff "$FX/arm-current/prompt-$m.txt" "$FX/arm-proposed/prompt-$m.txt" | grep -c '^[<>]' || true)"
  [ "$d" = 6 ] || { echo "FATAL: $m prompts differ on $d lines, expected 6 (3 M1 lines per side)" >&2; exit 1; }
done
# live arm: the working-tree text as shipped, no A/B pairing
mkdir -p "$FX/src-live"
cp "$PLUG/skills/todo/SKILL.md" "$FX/src-live/SKILL.md"
cp "$PLUG/agents/todo.md" "$FX/src-live/agent-todo.md"
"$PY" "$SRC/build-dispatch.py" "$FX/src-live" "$PLUG/skills/todo/assets/scaffolds.md" \
  "$SPEC" "$FX/arm-live" $MODES

# goldens: the script lane's board for the same fixture, at the run's date
for m in $MODES; do
  "$PY" "$PLUG/skills/todo/assets/render-board.py" "$FX/repo" "$m" --date "$DATE" \
    > "$FX/golden/$m.md" 2>/dev/null
  sed "s/— $DATE\$/— 2026-08-14/" "$FX/golden/$m.md" \
    | diff -q "$ROOT/bench/todo-board/expected/$m.md" - >/dev/null \
    || { echo "FATAL: re-rendered $m golden drifts from bench/todo-board/expected/$m.md" >&2; exit 1; }
done

# device-layer decontamination: credentials only — no CLAUDE.md, no plugins, no hooks
[ -f "$HOME/.claude/.credentials.json" ] && cp "$HOME/.claude/.credentials.json" "$FX/coldcfg/"
cat > "$FX/coldcfg/settings.json" <<'JSON'
{
  "hooks": {},
  "enabledPlugins": {},
  "permissions": { "allow": ["Read", "Grep", "Glob"] }
}
JSON

# neutral one-commit history (bench-decontamination.md channel 1)
(
  cd "$FX/repo"
  git init -q
  git -c core.autocrlf=false add -A
  git -c user.email=fx@fx -c user.name=fx commit -qm "init" --no-verify >/dev/null 2>&1 || true
)
echo "fixture at $FX (date $DATE, modes: $MODES)"
