#!/usr/bin/env bash
# GAP-085 — assemble the decontaminated fixture environment for the
# assertion-liveness RED.
#
# Builds two things under <target-dir>:
#   <target-dir>/repo     the pristine scratch repo handed to each run
#   <target-dir>/coldcfg  a CLAUDE_CONFIG_DIR holding credentials only
#
# The scratch repo is a BOOTSTRAPPED CONSUMER, not two bare skeleton files:
# the control arm has to be the condition the card's incident actually
# occurred under — a repo carrying the full harness runway. A two-file
# fixture can show a gap the full runway would have closed, and authoring an
# ambient clause off that is the `BUG-064` failure in docs/decisions.md.
#
# Every placement below is derived from
# plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md Phase 2, for a
# repo of this shape: small single-package Python repo, code present, no
# workspace manifest (single-package tier), scale module unarmed, drain infra
# declined. Nothing here is invented — see README.md § Fixture for the
# per-file SKILL.md citation.
#
# `coldcfg` is the device-layer half of the decontamination: a headless run
# inherits ~/.claude/CLAUDE.md, ~/.claude/rules, plugins and hooks unless the
# config dir is relocated. Blanking it costs nothing here — unlike the
# consult-hook bench, this fixture depends on no device plant
# (bench/consult-hook/bench-decontamination.md, channel 3).
#
# Usage: bash make-fixture.sh <target-dir> [arm]
#   arm defaults to `control` (shipped runway, no clause). A treatment arm
#   `X` appends arm-X-claude.md / arm-X-agents.md (when present) to the placed
#   CLAUDE.md / AGENTS.md — that is the only byte that differs between arms.
#
# Dialect (.claude/rules/asset-dialects.md): POSIX bash + portable awk for the
# placements; python3 for the two mechanical JSON composers (settings.json
# hook merge, runway receipt) — the bench already hard-depends on python3
# (run.sh, score.sh, run_tests.py), and hand-rolling JSON in shell to avoid a
# jq dependency is the worse trade. Degrade path: neither JSON file is read by
# the measurement — a python3-less host can drop both and still run the arms.
set -eu
FX="${1:?usage: make-fixture.sh <target-dir> [arm]}"
ARM="${2:-control}"
SRC="$(cd "$(dirname "$0")" && pwd)"
ASSETS="$(cd "$SRC/../../plugins/super-bootstrap/skills/harness-bootstrap/assets" && pwd)"
PLUGIN_JSON="$(cd "$SRC/../../plugins/super-bootstrap/.claude-plugin" && pwd)/plugin.json"

# --- Phase 1 detection facts, for a fixture of this shape --------------------
# Manifest: none. Code presence: source files present (.py) -> CODE PRESENT
# (SKILL.md § Code presence). Workspace manifest: none -> single-package tier
# (SKILL.md § Monorepo detection). Rule signals: no frontend component dir, no
# MV3 manifest, no migrations dir; the tests-dir signal only "flags
# rules/tests.md for body-fill via doc-sync" and ships no skeleton asset, so
# scaffold places no rule file (SKILL.md § Rule-signal detection).
PROJECT="decimate"
TECHLINE="Python 3 (stdlib only) + a framework-free assert test runner."
CMDLINE="python3 run_tests.py   # whole suite"
TS_RUNTIME="Python 3 (standard library only — no virtualenv, no third-party packages)."
TS_DEPS="None — standard library only, across runtime, dev, test and build."
TS_BUILD="\`python3 run_tests.py\` runs the whole suite. No build step, no packaging."

rm -rf "$FX/repo" "$FX/coldcfg"
mkdir -p "$FX/repo" "$FX/coldcfg"
REPO="$FX/repo"
mkdir -p "$REPO/docs/specs" "$REPO/docs/work" "$REPO/.claude/rules" "$REPO/.claude/hooks"

# --- CLAUDE.md: the skeleton as a bootstrapped consumer holds it -------------
# SKILL.md § 2b ("Missing -> fill placeholders, write") + § Placeholders:
#   {Project Name}                  -> repo name                      (:522)
#   Tech Stack one-liner + Commands -> Phase 1 detection facts        (:524)
#   {## Coding Principles} block    -> code present -> unbracket verbatim (:528)
#   {example scaffolding} + bullets -> no signal-seeded rule file landed ->
#                                      drop, label and bullets together (:529)
#   {scale module installed} block  -> module not installed -> drop    (:529)
#   {## Monorepo ...} block         -> single-package -> drop entirely (:527)
#   {- docs/parked.md ...} lines    -> scale module absent -> drop     (:526)
# Literal braces in shipped prose — `docs/work/{ID}.md`, the
# `/super-bootstrap:triage {ID}` routing row — are NOT placeholders and
# survive: the drop rule fires only on a line that is bracketed end to end.
awk -v project="$PROJECT" -v techline="$TECHLINE" -v cmdline="$CMDLINE" '
  {
    line = $0
    if (line == "# {Project Name}") { line = "# " project }
    else if (index(line, "{detected one-line summary") == 1) { line = techline }
    else if (index(line, "{detected from scripts/Makefile/Cargo") == 1) { line = cmdline }
    else if (line == "{## Coding Principles}") { line = "## Coding Principles" }
    else if (index(line, "{Before writing") == 1) { line = substr(line, 2, length(line) - 2) }
    else if (substr(line, 1, 1) == "{" && substr(line, length(line), 1) == "}") { next }
    if (line == "") { nb++; if (nb > 1) next } else { nb = 0 }
    print line
  }
' "$ASSETS/claude-md-skeleton.md" > "$REPO/CLAUDE.md"

# --- Copied with no substitutions (SKILL.md § 2a / § 2b asset table) ---------
# AGENTS.md          :231 "always scaffolded ... if missing (no substitutions)"
# CODING_STANDARDS.md:233 "code present ... (no substitutions)"
# decisions.md       :227 "always scaffolded ... (no substitutions)"
# work/README.md,
# work/TEMPLATE.md   :229 "(no substitutions)"
# rules/index.md     :235 "seeded from assets/rules-index-skeleton.md"
# overview.md        :525 Problem / User / Current State "left empty at
#                    install; filled at GAP-card pickup" -> unfilled skeleton
cp "$ASSETS/agents-md-skeleton.md"        "$REPO/AGENTS.md"
cp "$ASSETS/coding-standards-skeleton.md" "$REPO/CODING_STANDARDS.md"
cp "$ASSETS/decisions-skeleton.md"        "$REPO/docs/decisions.md"
cp "$ASSETS/work-readme-skeleton.md"      "$REPO/docs/work/README.md"
cp "$ASSETS/work-template-skeleton.md"    "$REPO/docs/work/TEMPLATE.md"
cp "$ASSETS/rules-index-skeleton.md"      "$REPO/.claude/rules/index.md"
cp "$ASSETS/overview-skeleton.md"         "$REPO/docs/overview.md"
: > "$REPO/docs/specs/.gitkeep"

# --- docs/techstack.md: seed-once sections filled from detection -------------
# SKILL.md § Pipeline-owned — Runtime / Framework / Key Dependencies /
# Build & Distribution are seed-once, filled at scaffold where code is present;
# § Edit Discipline is fixed prose. The skeleton's own § Framework line says
# "Drop the section if no framework" — there is none here. § Packages is
# monorepo-tier only and drops with the rest of the bracketed lines.
awk -v runtime="$TS_RUNTIME" -v deps="$TS_DEPS" -v build="$TS_BUILD" '
  {
    line = $0
    if (skip) {
      if (index(line, "## ") == 1) { skip = 0 } else { next }
    }
    if (line == "## Framework") { skip = 1; next }
    if (index(line, "{detected from primary manifest") == 1) { line = runtime }
    else if (index(line, "{top-level deps grouped by role") == 1) { line = deps }
    else if (index(line, "{commands as they exist") == 1) { line = build }
    else if (substr(line, 1, 1) == "{" && substr(line, length(line), 1) == "}") { next }
    if (line == "") { nb++; if (nb > 1) next } else { nb = 0 }
    print line
  }
' "$ASSETS/techstack-skeleton.md" > "$REPO/docs/techstack.md"

# --- 2a-hooks: the three default-on harness hooks (unconditional) ------------
# SKILL.md § 2a-hooks + assets/hooks-ensure-infra.md — frozen scripts copied
# verbatim to .claude/hooks/, each .hook.json entry merged into
# .claude/settings.json, plus the .consult-catalog gitignore line.
for h in commit-channel consult-check-sessionstart consult-check-check; do
  cp "$ASSETS/hooks/$h.sh" "$REPO/.claude/hooks/$h.sh"
done

cp "$SRC/fixture/.gitignore" "$REPO/.gitignore"
printf '.claude/.consult-catalog\n' >> "$REPO/.gitignore"

# --- .claude/settings.json: core plugin pin (§ 2a) + the three hook entries --
# The pin is a core dep, not an adaptive pick (SKILL.md § 2a "Core plugin pin").
# Hook entries are read back out of the frozen .hook.json assets — minus their
# asset-only `_comment` — so an upstream hook bump reaches the fixture.
PYTHONIOENCODING=utf-8 python3 - "$ASSETS/hooks" "$REPO/.claude/settings.json" <<'PY'
import io, json, os, sys
hooks_dir, dst = sys.argv[1], sys.argv[2]


def entry(name):
    with io.open(os.path.join(hooks_dir, name + ".hook.json"), encoding="utf-8") as fh:
        e = json.load(fh)
    e.pop("_comment", None)
    return e


settings = {
    "enabledPlugins": {"super-bootstrap@super-bootstrap": True},
    "extraKnownMarketplaces": {
        "super-bootstrap": {
            "source": {"source": "github", "repo": "RockyHong/super-bootstrap"}
        }
    },
    "hooks": {
        "PreToolUse": [entry("commit-channel")],
        "SessionStart": [entry("consult-check-sessionstart")],
        "UserPromptSubmit": [entry("consult-check-check")],
    },
}
with io.open(dst, "w", encoding="utf-8") as fh:
    fh.write(json.dumps(settings, indent=2) + "\n")
PY

# --- .claude/super-bootstrap-runway.json: the coverage receipt (§ 2c) --------
# Durable marker, no cleaner. `covered` = the pipeline-owned sections
# applicable to this repo's tier (SKILL.md § Pipeline-owned, honoring code
# present / single-package / scale module off). `placed` = sha256 of each hook
# script as this pipeline placed it (assets/hooks-ensure-infra.md).
PYTHONIOENCODING=utf-8 python3 - "$PLUGIN_JSON" "$ASSETS/hooks" \
    "$REPO/.claude/super-bootstrap-runway.json" <<'PY'
import hashlib, io, json, os, sys
plugin_json, hooks_dir, dst = sys.argv[1], sys.argv[2], sys.argv[3]

with io.open(plugin_json, encoding="utf-8") as fh:
    version = json.load(fh)["version"]

covered = [
    "CLAUDE.md § Development Workflow",
    "CLAUDE.md § Dispatch",
    "CLAUDE.md § Doc Sync",
    "CLAUDE.md § Coding Principles",
    "CLAUDE.md § Edit Discipline",
    "CLAUDE.md § Context Hygiene",
    "CLAUDE.md § Finding Triage",
    "CLAUDE.md § Rules",
    "CLAUDE.md § Git Notes",
    "CLAUDE.md § Planning",
    "docs/techstack.md § Runtime",
    "docs/techstack.md § Key Dependencies",
    "docs/techstack.md § Build & Distribution",
    "docs/techstack.md § Edit Discipline",
    "docs/overview.md § Problem",
    "docs/overview.md § User",
    "docs/overview.md § Current State",
    "docs/decisions.md scope header",
    "CODING_STANDARDS.md preamble + headings",
    "docs/work/README.md",
    "docs/work/TEMPLATE.md",
    "AGENTS.md",
    ".claude/rules/index.md",
    ".claude/settings.json core plugin pin",
]

placed = {}
for name in ("commit-channel", "consult-check-sessionstart", "consult-check-check"):
    with io.open(os.path.join(hooks_dir, name + ".sh"), "rb") as fh:
        placed[".claude/hooks/%s.sh" % name] = hashlib.sha256(fh.read()).hexdigest()

receipt = {"version": version, "covered": covered, "declined": [], "placed": placed}
with io.open(dst, "w", encoding="utf-8") as fh:
    fh.write(json.dumps(receipt, indent=2, ensure_ascii=False) + "\n")
PY

# --- placement guards: the shipped surface, before any arm text is appended --
# AGENTS.md is placed with no substitutions (SKILL.md:231) — assert it, so a
# future edit to this script cannot quietly make the foreign-executor surface a
# filled variant. Checked pre-append: a treatment arm's clause lands below the
# shipped body, which is the arm delta, not a substitution.
diff -q "$ASSETS/agents-md-skeleton.md" "$REPO/AGENTS.md" >/dev/null \
  || { echo "FATAL: AGENTS.md is not byte-verbatim against the shipped asset" >&2; exit 1; }

# no unfired conditional may survive into the consumer-shaped CLAUDE.md
if grep -nE '^[{].*[}]$' "$REPO/CLAUDE.md" >/dev/null 2>&1; then
  echo "FATAL: unfilled skeleton braces left in CLAUDE.md:" >&2
  grep -nE '^[{].*[}]$' "$REPO/CLAUDE.md" >&2
  exit 1
fi

# --- the arm delta: the only byte that differs between arms ------------------
[ -f "$SRC/arm-$ARM-claude.md" ] && cat "$SRC/arm-$ARM-claude.md" >> "$REPO/CLAUDE.md"
[ -f "$SRC/arm-$ARM-agents.md" ] && cat "$SRC/arm-$ARM-agents.md" >> "$REPO/AGENTS.md"

# --- the code under test -----------------------------------------------------
cp -r "$SRC/fixture/src" "$SRC/fixture/tests" "$REPO/"
cp "$SRC/fixture/run_tests.py" "$REPO/"
find "$REPO" -name __pycache__ -type d -exec rm -rf {} + 2>/dev/null || true

# device-layer decontamination: credentials only — no CLAUDE.md, no plugins,
# no hooks, no skills, no rules.
[ -f "$HOME/.claude/.credentials.json" ] && cp "$HOME/.claude/.credentials.json" "$FX/coldcfg/"
cat > "$FX/coldcfg/settings.json" <<'JSON'
{
  "hooks": {},
  "enabledPlugins": {},
  "includeCoAuthoredBy": false,
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": ["Bash(python3:*)", "Bash(python:*)", "Bash(cd:*)"]
  }
}
JSON

# neutral one-commit history — kills the recent-commits leak the headless
# system prompt otherwise embeds (bench-decontamination.md, channel 1).
(
  cd "$REPO"
  git init -q
  git add -A
  git -c user.email=fx@fx -c user.name=fx \
      commit -qm "init" --no-verify >/dev/null 2>&1 || true
)

# the fixture is only a fixture if it starts green
# (PYTHONDONTWRITEBYTECODE so the check leaves no __pycache__ behind it)
( cd "$REPO" && PYTHONIOENCODING=utf-8 PYTHONDONTWRITEBYTECODE=1 \
    python3 run_tests.py >/dev/null ) \
  || { echo "FATAL: fixture suite is not green before any run" >&2; exit 1; }

echo "fixture repo at $REPO (arm=$ARM, runway placed, suite green)"
echo "cold config  at $FX/coldcfg"
