#!/usr/bin/env bash
# L1 unit tests for render-menu.py: output-stream encoding (BUG-023).
# Zero session dependency: builds a throwaway home + project fixture, runs the
# script in a child with PYTHONIOENCODING=cp950, and asserts the bytes on the
# wire are UTF-8 regardless. Targets the PLUGIN ASSET (source of truth).
#
# Usage: bash tests/render-menu.test.sh
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$REPO/plugins/super-bootstrap/skills/help/assets/render-menu.py"

# python3 here may be a native Windows interpreter; hand it Windows-form paths.
winpath() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s' "$1"; fi
}

pass=0; fail=0
ok()   { pass=$((pass+1)); echo "  ok: $1"; }
bad()  { fail=$((fail+1)); echo "  FAIL: $1"; }
check() { # check <desc> <expr...>
  local desc="$1"; shift
  if "$@"; then ok "$desc"; else bad "$desc"; fi
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/fakehome"

fixture() { # <name> <description-value> ; echoes the fixture project root
  local name="$1" desc="$2" proj="$TMP/$1"
  mkdir -p "$proj/.claude/skills/$name"
  cat > "$proj/.claude/skills/$name/SKILL.md" <<EOF
---
name: $name
description: $desc
tags: dev
---

body
EOF
  printf '%s' "$proj"
}

run_script() { # <project-root> <stdout-file> <stderr-file> ; returns the script's exit code
  local fake_home; fake_home="$(winpath "$TMP/fakehome")"
  HOME="$fake_home" USERPROFILE="$fake_home" PYTHONIOENCODING=cp950 \
    python3 "$(winpath "$SCRIPT")" "$(winpath "$1")" >"$2" 2>"$3"
}

has_bytes() { # has_bytes <file> <python-bytes-literal>
  python3 -c "import sys; sys.exit(0 if $2 in open(sys.argv[1],'rb').read() else 1)" \
    "$(winpath "$1")"
}

echo "== render-menu: em-dash emits as UTF-8 even when the child env forces cp950 =="
proj="$(fixture emdash "Test skill — em-dash inside the first sentence. Second sentence.")"
run_script "$proj" "$TMP/emdash.out" "$TMP/emdash.err"
check "row is emitted at all" has_bytes "$TMP/emdash.out" "b'/emdash'"
check "em-dash on the wire is UTF-8 (E2 80 94), not cp950" \
  has_bytes "$TMP/emdash.out" "b'\xe2\x80\x94'"

echo "== render-menu: a character cp950 cannot encode does not abort the emit =="
proj="$(fixture unencodable "Rocket 🚀 outside the cp950 repertoire. Second sentence.")"
run_script "$proj" "$TMP/unenc.out" "$TMP/unenc.err"
rc=$?
check "exit code 0 (no UnicodeEncodeError mid-emit)" test "$rc" -eq 0
check "the unencodable character survives as UTF-8" \
  has_bytes "$TMP/unenc.out" "b'\xf0\x9f\x9a\x80'"

echo
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
