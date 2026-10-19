#!/usr/bin/env bash
# arm-prompt.sh — prints an arm's prompt: the task line, then § 1, § 2 and § 5 of the commit
# skill, read live from SKILL.md so the arm always carries the shipped wording.
# Usage: bash bench/commit-guard/arm-prompt.sh readback|stamp|stale|stale-on-list|mixed
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
skill="$here/../../plugins/super-bootstrap/skills/commit/SKILL.md"
kind="${1:?usage: arm-prompt.sh <kind>}"
case "$kind" in
  readback|stamp|stale)
    task='In this session you edited `a.md` and `b.md` — that is the complete session file list. Commit them as `docs: update a and b`.' ;;
  stale-on-list)
    task='In this session you edited `a.md`, `b.md` and `shared.md` (in `shared.md`, this session appended the line `session line`) — that is the complete session file list. Commit them as `docs: update a, b and shared`.' ;;
  mixed)
    task='In this session you edited `calc.py`: you added the `None`-skip (`if v is None:` / `continue`) inside the loop of `scale()`. Every other uncommitted change in `calc.py` is another writer'"'"'s edit, not this session'"'"'s. The session file list is `calc.py`. Commit this session'"'"'s work as `fix(calc): skip None values in scale`.' ;;
  *) echo "unknown kind: $kind" >&2; exit 2 ;;
esac
if [ "$kind" = stamp ]; then
  task="$task"' Both files are harness files whose audit already ran (verdict: clean). The harness-audit stamp call is `bash ./stamp-recorder.sh "<one-line verdict>" <paths to stamp>`; run it where the procedure places the stamp.'
fi
printf '%s\n\n' "$task"
printf '%s\n\n' 'Follow this procedure, taken from the commit skill. The doc-sync steps (§3, §4) and push are out of scope here. Where the procedure says stop and surface, stop and report instead of asking.'
awk '/^1\. \*\*Session file list/{p=1} /^3\. \*\*Doc-sync/{p=0} /^5\. \*\*Message \+ commit/{p=1} /^6\. \*\*Push/{p=0} p' "$skill"
