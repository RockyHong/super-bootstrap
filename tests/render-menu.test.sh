#!/usr/bin/env bash
# L1 unit tests for render-menu.py: output-stream encoding, skill discovery
# across plugin layouts, and the stderr source-diagnostic lines (`# sources:`
# plus the `# anomalies:` line that flags a source which came back short).
# Zero session dependency: builds throwaway home + project fixtures and runs the
# script in a child. Encoding cases force PYTHONIOENCODING=cp950 and assert the
# bytes on the wire are UTF-8 regardless. Discovery cases stand up a fake
# installed-plugin registry so the plugin branch is exercised, not just the
# project one. Targets the PLUGIN ASSET (source of truth).
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

nested_plugin() { # <install-dir> <skill-relpath>... ; writes a SKILL.md at each nested path
  local install="$1"; shift
  local rel leaf
  for rel in "$@"; do
    leaf="$(basename "$rel")"
    mkdir -p "$install/skills/$rel"
    cat > "$install/skills/$rel/SKILL.md" <<EOF
---
name: $leaf
description: Nested skill $leaf. Second sentence.
tags: dev
---

body
EOF
  done
}

plugin_home() { # <home-dir> <plugin-key> <install-dir> ; fake home whose registry lists+enables the plugin
  local home="$1" key="$2" install="$3"
  mkdir -p "$home/.claude/plugins"
  python3 -c "
import json, sys
json.dump({'version': 1, 'plugins': {sys.argv[1]: [{'scope': 'user', 'installPath': sys.argv[2]}]}},
          open(sys.argv[3], 'w', encoding='utf-8'))
" "$key" "$(winpath "$install")" "$(winpath "$home/.claude/plugins/installed_plugins.json")"
  cat > "$home/.claude/settings.json" <<EOF
{"enabledPlugins": {"$key": true}}
EOF
}

run_script() { # <project-root> <stdout-file> <stderr-file> [home-dir] ; returns the script's exit code
  local fake_home; fake_home="$(winpath "${4:-$TMP/fakehome}")"
  HOME="$fake_home" USERPROFILE="$fake_home" PYTHONIOENCODING=cp950 \
    python3 "$(winpath "$SCRIPT")" "$(winpath "$1")" >"$2" 2>"$3"
}

has_bytes() { # has_bytes <file> <python-bytes-literal>
  python3 -c "import sys; sys.exit(0 if $2 in open(sys.argv[1],'rb').read() else 1)" \
    "$(winpath "$1")"
}

no_bytes() { ! has_bytes "$@"; }

echo "== render-menu: em-dash emits as UTF-8 even when the child env forces cp950 =="
proj="$(fixture emdash "Test skill — em-dash inside the first sentence. Second sentence.")"
run_script "$proj" "$TMP/emdash.out" "$TMP/emdash.err"
check "row is emitted at all" has_bytes "$TMP/emdash.out" "b'/emdash'"
check "em-dash on the wire is UTF-8 (E2 80 94), not cp950" \
  has_bytes "$TMP/emdash.out" "b'\xe2\x80\x94'"
check "a fully-emitting project skills dir is on the sources line" \
  has_bytes "$TMP/emdash.err" "b'project .claude/skills (1 skills)'"
check "a fully-emitting project skills dir raises no anomaly" \
  no_bytes "$TMP/emdash.err" "b'# anomalies'"

echo "== render-menu: a character cp950 cannot encode does not abort the emit =="
proj="$(fixture unencodable "Rocket 🚀 outside the cp950 repertoire. Second sentence.")"
run_script "$proj" "$TMP/unenc.out" "$TMP/unenc.err"
rc=$?
check "exit code 0 (no UnicodeEncodeError mid-emit)" test "$rc" -eq 0
check "the unencodable character survives as UTF-8" \
  has_bytes "$TMP/unenc.out" "b'\xf0\x9f\x9a\x80'"

echo "== render-menu: nested-layout plugin with a manifest allowlist emits exactly the declared skills =="
nested_plugin "$TMP/allowplugin" engineering/nested-alpha productivity/nested-beta in-progress/nested-unlisted
mkdir -p "$TMP/allowplugin/.claude-plugin" "$TMP/allowproj"
cat > "$TMP/allowplugin/.claude-plugin/plugin.json" <<'EOF'
{"name": "allowplug", "version": "0.0.1",
 "skills": ["./skills/engineering/nested-alpha", "./skills/productivity/nested-beta"]}
EOF
plugin_home "$TMP/allowhome" "allowplug@fixture" "$TMP/allowplugin"
run_script "$TMP/allowproj" "$TMP/allow.out" "$TMP/allow.err" "$TMP/allowhome"
check "declared skill under a category subfolder is emitted" \
  has_bytes "$TMP/allow.out" "b'/allowplug:nested-alpha'"
check "second declared skill under another category subfolder is emitted" \
  has_bytes "$TMP/allow.out" "b'/allowplug:nested-beta'"
check "on-disk skill absent from the manifest stays out (allowlist, not a hint)" \
  no_bytes "$TMP/allow.out" "b'nested-unlisted'"
check "sources line counts the manifest, not the tree" \
  has_bytes "$TMP/allow.err" "b'allowplug@fixture (2 skills)'"
check "a manifest emitting fewer rows than the tree holds is NOT an anomaly" \
  no_bytes "$TMP/allow.err" "b'# anomalies'"

echo "== render-menu: nested-layout plugin with no manifest allowlist falls back to a recursive walk =="
nested_plugin "$TMP/walkplugin" engineering/walk-alpha misc/deep/walk-beta
mkdir -p "$TMP/walkplugin/.claude-plugin" "$TMP/walkproj"
cat > "$TMP/walkplugin/.claude-plugin/plugin.json" <<'EOF'
{"name": "walkplug", "version": "0.0.1"}
EOF
plugin_home "$TMP/walkhome" "walkplug@fixture" "$TMP/walkplugin"
run_script "$TMP/walkproj" "$TMP/walk.out" "$TMP/walk.err" "$TMP/walkhome"
check "skill at depth 2 is discovered by the walk" has_bytes "$TMP/walk.out" "b'/walkplug:walk-alpha'"
check "skill at depth 3 is discovered by the walk" has_bytes "$TMP/walk.out" "b'/walkplug:walk-beta'"
check "sources line counts every walked skill" \
  has_bytes "$TMP/walk.err" "b'walkplug@fixture (2 skills)'"
check "a walk that emits everything it found is NOT an anomaly" \
  no_bytes "$TMP/walk.err" "b'# anomalies'"
check "a project with no .claude/skills dir stays off the sources line" \
  no_bytes "$TMP/walk.err" "b'project .claude/skills'"

echo "== render-menu: a manifest-declared path that fails to resolve is flagged =="
nested_plugin "$TMP/shortplugin" engineering/short-alpha
mkdir -p "$TMP/shortplugin/.claude-plugin" "$TMP/shortproj"
cat > "$TMP/shortplugin/.claude-plugin/plugin.json" <<'EOF'
{"name": "shortplug", "version": "0.0.1",
 "skills": ["./skills/engineering/short-alpha", "./skills/gone/short-missing"]}
EOF
plugin_home "$TMP/shorthome" "shortplug@fixture" "$TMP/shortplugin"
run_script "$TMP/shortproj" "$TMP/short.out" "$TMP/short.err" "$TMP/shorthome"
check "the resolvable declared skill still emits" has_bytes "$TMP/short.out" "b'/shortplug:short-alpha'"
check "sources line reports the emitted count" \
  has_bytes "$TMP/short.err" "b'shortplug@fixture (1 skills)'"
check "anomalies line names the source, the declared count and the emitted count" \
  has_bytes "$TMP/short.err" "b'# anomalies: shortplug@fixture \xe2\x80\x94 declared 2, emitted 1'"

echo "== render-menu: a walked SKILL.md with no description is flagged as a shortfall =="
nested_plugin "$TMP/partialplugin" engineering/partial-alpha
mkdir -p "$TMP/partialplugin/skills/engineering/partial-beta" "$TMP/partialproj"
cat > "$TMP/partialplugin/skills/engineering/partial-beta/SKILL.md" <<'EOF'
---
name: partial-beta
tags: dev
---

body with no description key
EOF
plugin_home "$TMP/partialhome" "partialplug@fixture" "$TMP/partialplugin"
run_script "$TMP/partialproj" "$TMP/partial.out" "$TMP/partial.err" "$TMP/partialhome"
check "the well-formed skill still emits" has_bytes "$TMP/partial.out" "b'/partialplug:partial-alpha'"
check "the description-less skill is not emitted" no_bytes "$TMP/partial.out" "b'partial-beta'"
check "anomalies line reports discovered vs emitted for the walk branch" \
  has_bytes "$TMP/partial.err" "b'# anomalies: partialplug@fixture \xe2\x80\x94 discovered 2, emitted 1'"

echo "== render-menu: a skills dir that exists and yields nothing is flagged; an absent one is not =="
mkdir -p "$TMP/emptyplugin/skills" "$TMP/emptyplugin/.claude-plugin" "$TMP/emptyproj"
cat > "$TMP/emptyplugin/.claude-plugin/plugin.json" <<'EOF'
{"name": "emptyplug", "version": "0.0.1"}
EOF
plugin_home "$TMP/emptyhome" "emptyplug@fixture" "$TMP/emptyplugin"
run_script "$TMP/emptyproj" "$TMP/empty.out" "$TMP/empty.err" "$TMP/emptyhome"
check "sources line still carries the zero" has_bytes "$TMP/empty.err" "b'emptyplug@fixture (0 skills)'"
check "an existing-but-empty skills tree is an anomaly" \
  has_bytes "$TMP/empty.err" "b'# anomalies: emptyplug@fixture \xe2\x80\x94 discovered 0, emitted 0'"

mkdir -p "$TMP/nodirplugin" "$TMP/nodirproj"
plugin_home "$TMP/nodirhome" "nodirplug@fixture" "$TMP/nodirplugin"
run_script "$TMP/nodirproj" "$TMP/nodir.out" "$TMP/nodir.err" "$TMP/nodirhome"
check "a plugin with no skills/ tree reports a truthful zero" \
  has_bytes "$TMP/nodir.err" "b'nodirplug@fixture (0 skills)'"
check "a plugin with no skills/ tree does NOT false-flag" \
  no_bytes "$TMP/nodir.err" "b'# anomalies'"

echo "== render-menu: an existing-but-empty project .claude/skills reaches the diagnostic lines =="
mkdir -p "$TMP/emptyskillsproj/.claude/skills"
run_script "$TMP/emptyskillsproj" "$TMP/projempty.out" "$TMP/projempty.err"
check "project source is listed even at zero" \
  has_bytes "$TMP/projempty.err" "b'project .claude/skills (0 skills)'"
check "and it is flagged as an anomaly" \
  has_bytes "$TMP/projempty.err" "b'# anomalies: project .claude/skills \xe2\x80\x94 discovered 0, emitted 0'"

echo
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
