#!/usr/bin/env bash
# skill.sh — the headless run's stand-in for slash-command skills, which `claude -p` with no settings
# source cannot load. Usage (from the fixture as cwd): bash skill.sh <skill-name> [args…]
#
# Every call is logged to <fixture>.door.log. `super-bootstrap:commit -m '<message>' -- <paths…>` commits
# those paths; GIT_TRACE is unset first, so <fixture>.trace holds only the git calls the agent ran itself.
# Any other skill name is logged and answered "unknown skill".
set -u
fx="$(pwd)"
printf '%s\n' "$*" >> "$fx.door.log"
name="${1:-}"; shift || true
case "$name" in
  super-bootstrap:commit|/super-bootstrap:commit)
    unset GIT_TRACE
    msg=""
    while [ $# -gt 0 ]; do
      case "$1" in
        -m) msg="${2:-}"; shift 2 ;;
        --) shift; break ;;
        *) shift ;;
      esac
    done
    if [ -z "$msg" ] || [ $# -eq 0 ]; then echo "commit door: need -m '<message>' -- <paths…>" >&2; exit 2; fi
    git add -N -- "$@" && git commit -q -o -m "$msg" -- "$@" || exit 1
    echo "Committed $(git log -1 --format='%h %s')."
    ;;
  *) echo "unknown skill: $name" >&2; exit 2 ;;
esac
