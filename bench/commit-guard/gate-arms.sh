#!/usr/bin/env bash
# gate-arms.sh — deterministic arms that drive the REAL planted harness-audit gate, no model.
# Usage: bash bench/commit-guard/gate-arms.sh hunk|stale <dir> [--form current|target]
#
# Each arm builds its fixture at <dir> (outside any repo), runs the commit door's § 5 stamp
# procedure as shell, one fresh `bash -c` per tool call (the Bash tool's fresh shell per call,
# so a variable set in one step is unset in the next), runs the stamp for real
# (`bash <gate> --stamp <verdict> <paths>`), then pipes a synthesized PreToolUse payload holding
# the exact commit command § 5 would issue into the gate. The commit itself never runs.
# Assertion: the gate stays silent (no stdout, exit 0) on the audited state -> PASS; any gate
# output -> FAIL, printed verbatim. A procedure step exiting non-zero is a FAIL too.
#
#   hunk   make-fixture-gate.sh: .claude/rules/r.md holds this session's hunk and another
#          writer's; CLAUDE.md is the other writer's dirty harness file. Private index from
#          HEAD (§ 5 hunk steps 1-3), stamp, commit under the private index.
#   stale  make-fixture-stale.sh --on-list .claude/rules/shared.md: the session list holds a
#          harness path whose shared-index entry is stale. File grain: readback, stamp,
#          `git commit -o`.
#   --form current  the stamp / commit forms § 5 writes today (default).
#   --form target   the forms BUG-e9ef's verdict names.
#
# The gate path defaults to ~/.claude/hooks/harness-audit-pretool.sh; GATE=<path> overrides.
# Step transcripts and the gate output print to stdout; the patch files land in <dir>.patch/.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
arm="${1:?usage: gate-arms.sh hunk|stale <dir> [--form current|target]}"
dir="${2:?usage: gate-arms.sh hunk|stale <dir> [--form current|target]}"
form=current
if [ "${3:-}" = "--form" ]; then form="${4:?--form takes current|target}"; fi
case "$form" in current|target) ;; *) echo "unknown form: $form" >&2; exit 2 ;; esac
gate="${GATE:-$HOME/.claude/hooks/harness-audit-pretool.sh}"
[ -f "$gate" ] || { echo "gate not found: $gate" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || { echo "jq required (the gate exits silent without it)" >&2; exit 2; }

# Never build a fixture inside this repo: its index is a live shared index.
repo_root="$(git -C "$here" rev-parse --show-toplevel)"
parent="$(dirname "$dir")"; mkdir -p "$parent"
if [ "$(git -C "$parent" rev-parse --show-toplevel 2>/dev/null)" = "$repo_root" ]; then
  echo "refusing: $dir sits inside $repo_root" >&2; exit 2
fi

fail=0
say_fail() { echo "FAIL: $*"; fail=1; }

# One tool call: a fresh shell in the fixture, no inherited GIT_INDEX_FILE / project dir.
step() {
  echo "\$ $1"
  ( cd "$dir" && env -u GIT_INDEX_FILE -u CLAUDE_PROJECT_DIR -u priv -u base bash -c "$1" ) 2>&1
  local rc=$?
  echo "[rc=$rc]"
  return $rc
}

msg='-m "$(cat <<'"'"'EOF'"'"'
docs(rules): session edit
EOF
)"'
verdict='audit-harness-edits: clean'

case "$arm" in
  hunk)
    bash "$here/make-fixture-gate.sh" "$dir" >/dev/null
    dir="$(cd "$dir" && pwd)"
    p="$dir.patch"; rm -rf "$p"; mkdir -p "$p"
    path=.claude/rules/r.md
    if [ "$form" = current ]; then
      idx='"$priv"'
      step 'priv="$(git rev-parse --git-dir)/index-s1"; base="$(git rev-parse HEAD)"; GIT_INDEX_FILE="$priv" git read-tree HEAD' \
        || say_fail "step 1 (private index build) exited non-zero"
      base_word='"$base"'
    else
      idx='"$(git rev-parse --git-dir)/index-s1"'
      base_sha="$(git -C "$dir" rev-parse HEAD)"
      base_word="\"$base_sha\""
      step "GIT_INDEX_FILE=$idx git read-tree $base_sha" || say_fail "step 1 (private index build) exited non-zero"
    fi
    # Step 2: the full diff, then keep its header + this session's git hunk (the editing a
    # session does by hand), then apply the kept patch to the private index.
    step "git diff HEAD -- $path > '$p/r.full.patch'" || say_fail "step 2 (diff) exited non-zero"
    awk '/^@@/ { if (h != "" && keep) printf "%s", h; h = $0 ORS; keep = 0; inh = 1; next }
         inh   { h = h $0 ORS; if ($0 == "+session line") keep = 1; next }
               { print }
         END   { if (h != "" && keep) printf "%s", h }' "$p/r.full.patch" > "$p/r.patch"
    step "GIT_INDEX_FILE=$idx git apply --cached '$p/r.patch'" || say_fail "step 2 (apply --cached to the private index) exited non-zero"
    step "GIT_INDEX_FILE=$idx git diff --cached HEAD --name-only" || say_fail "step 3 (readback) exited non-zero"
    # Step 4, staged-tree verify: none declared in this fixture -> skipped.
    if [ "$form" = current ]; then
      # § 5 seam today: the hunk lane names no stamp form; the one command form it writes is
      # "the session's harness paths, named explicitly" — run as a plain call.
      stamp_cmd="bash '$gate' --stamp '$verdict' $path"
    else
      stamp_cmd="GIT_INDEX_FILE=$idx bash '$gate' --stamp '$verdict' \$(GIT_INDEX_FILE=$idx git diff --cached --name-only)"
    fi
    commit_cmd="[ \"\$(git rev-parse HEAD)\" = $base_word ] && GIT_INDEX_FILE=$idx git commit $msg"
    ;;
  stale)
    bash "$here/make-fixture-stale.sh" "$dir" --on-list .claude/rules/shared.md >/dev/null
    dir="$(cd "$dir" && pwd)"
    list="a.md b.md .claude/rules/shared.md"
    step "git diff HEAD --name-only -- $list" || say_fail "readback exited non-zero"
    if [ "$form" = current ]; then
      # § 5 seam today: "the session's harness paths, named explicitly, never read from the
      # shared index" — a plain call, so the stamp reads the shared index for the blob.
      stamp_cmd="bash '$gate' --stamp '$verdict' $list"
    else
      t='"$(git rev-parse --git-dir)/index-stamp-s1"'
      stamp_cmd="GIT_INDEX_FILE=$t git read-tree HEAD && GIT_INDEX_FILE=$t bash '$gate' --stamp '$verdict' \$(git diff HEAD --name-only -- $list); rc=\$?; rm -f $t; exit \$rc"
    fi
    commit_cmd="git commit -o $msg -- $list"
    ;;
  *) echo "unknown arm: $arm" >&2; exit 2 ;;
esac

step "$stamp_cmd" || say_fail "stamp exited non-zero"
echo "stamp store: $(ls "$dir/.git/harness-audit-stamps" 2>/dev/null | tr '\n' ' ')"

# The PreToolUse payload Claude Code hands the gate for the commit call (Bash lane).
wdir="$dir"; command -v cygpath >/dev/null 2>&1 && wdir="$(cygpath -w "$dir")"
payload="$(jq -n --arg c "$commit_cmd" --arg d "$wdir" \
  '{hook_event_name: "PreToolUse", tool_name: "Bash", tool_input: {command: $c}, cwd: $d}')"
echo "--- commit command handed to the gate:"
printf '%s\n' "$commit_cmd"
out="$(cd "$dir" && printf '%s' "$payload" | env -u GIT_INDEX_FILE CLAUDE_PROJECT_DIR="$wdir" bash "$gate")"
rc=$?
echo "--- gate output (exit $rc):"
printf '%s\n' "${out:-<none>}"
if [ "$rc" -ne 0 ] || [ -n "$out" ]; then
  say_fail "gate nudged on the audited state ($arm, --form $form)"
fi
echo "--- shared index staged: $(git -C "$dir" diff --cached --name-only | tr '\n' ' ')"
[ "$fail" -eq 0 ] && echo PASS
exit "$fail"
