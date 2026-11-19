#!/usr/bin/env bash
# DEBT-ymdg — one headless walk of the ownership-split bench.
#
# Usage: bash run.sh <outdir> <walk> [label]        walk: fresh | legacy | stale | fork
# Builds the fixture fresh in <outdir>/<walk>[-<label>]/ (make-fixture.sh), runs the
# IN-REPO harness-bootstrap skill against it with the fixture repo as cwd, then
# records what the scorer reads:
#   stream.jsonl (+ .err)   the turn's stream-json transcript
#   meta/end-head.txt       HEAD after the run
#   meta/git-status.txt     `git status --porcelain --untracked-files=all` after the run
#   meta/plugin-dir.txt     the --plugin-dir passed
#   meta/command.txt        the claude argv, one argument per line
#   stream.t2.jsonl, meta/answer.txt   fork + ANSWER only: the second turn
# A walk whose stream.jsonl already exists is skipped.
#
# Env:
#   MODEL      default sonnet
#   PERM_MODE  default acceptEdits (see README § Approval prompts)
#   ANSWER     fork only: `overwrite` | `keep` — a second turn (`--continue`) gives that answer
#   SHIPPED, OLDER   passed to make-fixture.sh as --shipped / --older
#   DRY=1      build the fixture and print the command; start no claude process
set -u
OUT="${1:?usage: run.sh <outdir> <walk> [label]}"; WALK="${2:?usage: run.sh <outdir> <walk> [label]}"; LABEL="${3:-}"
case "$WALK" in fresh|legacy|stale|fork) ;; *) echo "FATAL: unknown walk '$WALK'" >&2; exit 1 ;; esac
SRC="$(cd "$(dirname "$0")" && pwd)"
# native programs (claude, python.exe) need Windows paths, not /d/... or /tmp/...
W() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s\n' "$1"; fi; }

mkdir -p "$OUT"; OUT="$(cd "$OUT" && pwd)"
# QUIRK (bench/carrier-equivalence, unexplained): with the fixture under Claude
# Code's own temp tree (%TEMP%/claude/…, a session scratchpad included) no run
# loaded a project instruction file. Refuse that location.
case "$(W "$OUT" | tr 'A-Z' 'a-z')" in
  */temp/claude|*/temp/claude/*) echo "FATAL: <outdir> sits under Claude Code's temp tree ($OUT) — pick another, e.g. \$TEMP/os-round1" >&2; exit 1 ;;
esac

NAME="$WALK${LABEL:+-$LABEL}"; WD="$OUT/$NAME"
[ -s "$WD/stream.jsonl" ] && { echo "[skip] $NAME"; exit 0; }
rm -rf "$WD"; mkdir -p "$WD"
bash "$SRC/make-fixture.sh" "$WD" "$WALK" ${SHIPPED:+--shipped "$SHIPPED"} ${OLDER:+--older "$OLDER"} > "$WD/fixture.txt" 2>&1 \
  || { echo "fixture failed: $NAME (see $WD/fixture.txt)" >&2; exit 1; }

# The skill under test is the in-repo dev copy, not the installed plugin cache.
PLUGIN="$(W "$(cd "$SRC/../../plugins/super-bootstrap" && pwd)")"
printf '%s\n' "$PLUGIN" > "$WD/meta/plugin-dir.txt"
CFG="$(W "$WD/coldcfg")"; mkdir -p "$WD/home"; FAKEHOME="$(W "$WD/home")"
PROMPT="$(cat "$SRC/walk-prompt.txt")"
# Permission posture — nobody is there to approve a tool call:
#   --permission-prompts none   anything that would prompt is denied, never left waiting
#   --permission-mode + --allowedTools   what runs without a prompt
# --setting-sources project,local + the cold config dir: the operator's user layer stays out.
COMMON=(--model "${MODEL:-sonnet}" --plugin-dir "$PLUGIN"
        --permission-mode "${PERM_MODE:-acceptEdits}" --permission-prompts none
        --allowedTools "Bash,Read,Edit,Write,Glob,Grep,Skill"
        --output-format stream-json --verbose --setting-sources project,local --strict-mcp-config)

# one turn: claude_turn <outfile> [extra flags...] -- <prompt>
claude_turn() {
  local out="$1"; shift
  # MSYS_NO_PATHCONV=1: Git Bash rewrites an argument that starts with "/" into a
  #   Windows path — the prompt starts with "/super-bootstrap:harness-bootstrap".
  #   With it set, every path argument above must already be a Windows path (W).
  # HOME/USERPROFILE -> an empty dir: CLAUDE_CONFIG_DIR alone does not cut the
  #   operator's ~/.claude/CLAUDE.md on this build (carrier-equivalence QUIRK 1).
  # GIT_* identity: with HOME moved, git finds no user.name/user.email, and the
  #   walk's own commit (fresh, stale) would fail on "Please tell me who you are".
  # < /dev/null: otherwise claude waits 3 s for stdin.
  ( cd "$WD/repo" && MSYS_NO_PATHCONV=1 HOME="$FAKEHOME" USERPROFILE="$FAKEHOME" CLAUDE_CONFIG_DIR="$CFG" \
      GIT_AUTHOR_NAME=fx GIT_AUTHOR_EMAIL=fx@fx GIT_COMMITTER_NAME=fx GIT_COMMITTER_EMAIL=fx@fx \
      claude -p "${COMMON[@]}" "$@" ) < /dev/null > "$out" 2> "$out.err"
  echo "  [$NAME] $(basename "$out") exit=$? lines=$(wc -l < "$out")"
}

printf '%s\n' claude -p "${COMMON[@]}" -- "$PROMPT" > "$WD/meta/command.txt"
if [ "${DRY:-}" = 1 ]; then
  echo "[dry] $NAME — fixture at $WD/repo, no claude process started. Command (cwd = the fixture repo):"
  sed 's/^/    /' "$WD/meta/command.txt"
  exit 0
fi

claude_turn "$WD/stream.jsonl" -- "$PROMPT"
if [ "$WALK" = fork ] && [ -n "${ANSWER:-}" ]; then
  case "$ANSWER" in overwrite|keep) ;; *) echo "FATAL: ANSWER must be overwrite or keep" >&2; exit 1 ;; esac
  printf '%s\n' "$ANSWER" > "$WD/meta/answer.txt"
  claude_turn "$WD/stream.t2.jsonl" --continue -- "$ANSWER"
fi
( cd "$WD/repo" && git rev-parse HEAD ) > "$WD/meta/end-head.txt" 2>/dev/null
( cd "$WD/repo" && git status --porcelain --untracked-files=all ) > "$WD/meta/git-status.txt" 2>/dev/null
echo "  [$NAME] head $(cut -c1-8 "$WD/meta/start-head.txt") -> $(cut -c1-8 "$WD/meta/end-head.txt"), $(grep -c . "$WD/meta/git-status.txt") dirty path(s)"
