#!/usr/bin/env bash
# DEBT-ymdg — build one carrier-equivalence fixture: a consumer-shaped repo
# (shipped runway placed) whose plugin-owned CLAUDE.md sections sit in the
# carrier named by <arm>.
#
# Usage: bash make-fixture.sh <outdir> <arm>      arm: claudemd | rules | import | none
# Output: <outdir>/repo (the repo handed to `claude -p`), <outdir>/coldcfg
#         (credentials-only CLAUDE_CONFIG_DIR), <outdir>/split.txt (the split).
#
# Runway: CALLS bench/assertion-liveness/make-fixture.sh (control arm) and then
# layers on top — one placement logic, no copy to drift. Its `decimate` code
# stays in the repo as inert background; the card points only at cart.py.
#
# Scripts here are bench-only (not shipped assets): POSIX bash + python3.
set -eu
FX="${1:?usage: make-fixture.sh <outdir> <arm>}"
ARM="${2:?usage: make-fixture.sh <outdir> <arm>}"
case "$ARM" in claudemd|rules|import|none) ;; *) echo "FATAL: unknown arm '$ARM'" >&2; exit 1 ;; esac
SRC="$(cd "$(dirname "$0")" && pwd)"
LIVE="$SRC/../assertion-liveness/make-fixture.sh"

mkdir -p "$FX"
bash "$LIVE" "$FX" control >/dev/null
REPO="$FX/repo"

# --- the seeded card + the code it points at ---------------------------------
cat > "$REPO/docs/work/BUG-k3x9.md" <<'MD'
# BUG-k3x9 — Total is off by one for an empty cart

**Logged:** 2026-11-19 · **Source:** manual checkout test
**Problem:** `cart_total([])` returns 1 instead of 0, so an empty cart is charged a unit it never held.
**Area:** `cart.py`
MD
cat > "$REPO/cart.py" <<'PY'
"""Shopping-cart arithmetic."""


def cart_total(prices):
    """Return the sum of the item prices in the cart."""
    if len(prices) < 1:
        return 1
    return sum(prices)
PY

# --- carrier split -----------------------------------------------------------
# Plugin-owned = every `## ` section EXCEPT the project-content ones. Headings
# inside code fences are not section starts. A section runs from its heading to
# the line before the next `## ` heading (blank separator lines included), so
# concatenating sections reproduces the bytes exactly.
PYTHONIOENCODING=utf-8 python3 - "$REPO" "$ARM" "$FX/split.txt" <<'PY'
import io, os, sys
repo, arm, splitfile = sys.argv[1:4]
PROJECT = ("## Tech Stack", "## Commands", "## Rules (auto-load on file match)", "## Planning")
path = os.path.join(repo, "CLAUDE.md")
with io.open(path, encoding="utf-8", newline="") as fh:
    text = fh.read()
lines = text.splitlines(keepends=True)
chunks, cur, fence = [], None, False   # chunk = [heading_or_None, [lines]]
for ln in lines:
    if ln.startswith("```"):
        fence = not fence
    if not fence and ln.startswith("## "):
        cur = [ln.rstrip("\r\n"), [ln]]
        chunks.append(cur)
    elif cur is None:
        if not chunks or chunks[0][0] is not None:
            chunks.insert(0, [None, []])
        chunks[0][1].append(ln)
    else:
        cur[1].append(ln)
title = chunks[0][1] if chunks and chunks[0][0] is None else []
secs = [c for c in chunks if c[0] is not None]
plugin = [c for c in secs if c[0] not in PROJECT]
project = [c for c in secs if c[0] in PROJECT]
if len(project) != len(PROJECT):
    sys.exit("FATAL: project-content sections missing: %s" % (set(PROJECT) - {c[0] for c in project}))
report = ["TITLE lines: %d (%r)" % (len(title), "".join(title).strip()),
          "PLUGIN-OWNED (moved/removed):"] + ["  " + c[0] for c in plugin] + \
         ["PROJECT-CONTENT (stay in CLAUDE.md):"] + ["  " + c[0] for c in project]
moved = "".join("".join(c[1]) for c in plugin)
whole_sections = moved  # the claudemd arm's plugin-owned bytes

def w(p, s):
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with io.open(p, "w", encoding="utf-8", newline="") as fh:
        fh.write(s)

keep = "".join(title) + "".join("".join(c[1]) for c in project)
if arm == "rules":
    w(os.path.join(repo, ".claude/rules/harness.md"), moved)
    w(path, keep)
elif arm == "import":
    w(os.path.join(repo, ".claude/harness.md"), moved)
    t = "".join(title)
    w(path, t.rstrip("\r\n") + "\n\n@.claude/harness.md\n\n" + "".join("".join(c[1]) for c in project))
elif arm == "none":
    w(path, keep)
# byte-equality assertion: the moved text must equal the claudemd arm's sections
if arm in ("rules", "import"):
    f = ".claude/rules/harness.md" if arm == "rules" else ".claude/harness.md"
    with io.open(os.path.join(repo, f), encoding="utf-8", newline="") as fh:
        got = fh.read()
    if got != whole_sections:
        sys.exit("FATAL: %s differs from the claudemd arm's plugin-owned sections" % f)
    report.append("BYTE-EQUAL OK: %s == claudemd plugin-owned sections (%d bytes)" % (f, len(got.encode("utf-8"))))
w(splitfile, "\n".join(report) + "\n")
print("arm=%s\n%s" % (arm, "\n".join(report)))
PY

# --- probe hooks -------------------------------------------------------------
mkdir -p "$REPO/.probe"
cat > "$REPO/.claude/hooks/probe-log.py" <<'PY'
#!/usr/bin/env python3
"""Bench probe hook (DEBT-ymdg): log the hook event's stdin JSON.
kind 'instructions' -> .probe/instructions.log + .probe/instructions.raw.jsonl
kind 'compact'      -> .probe/compact.log
Smoke-verified fields: session_id, file_path, memory_type, load_reason (no
agent_type seen yet — kept tolerant). Line format: session	file	reason	agent	ts_ms.
The raw JSON is kept too."""
import io, json, os, sys, time
kind = sys.argv[1]
ts = int(time.time() * 1000)   # ms epoch: orders instructions.log against compact.log
raw = sys.stdin.read()
try:
    ev = json.loads(raw)
except ValueError:
    ev = {"_unparsed": raw}
root = os.environ.get("CLAUDE_PROJECT_DIR") or ev.get("cwd") or os.getcwd()
pdir = os.path.join(root, ".probe")
os.makedirs(pdir, exist_ok=True)
def put(name, line):
    with io.open(os.path.join(pdir, name), "a", encoding="utf-8") as fh:
        fh.write(line + "\n")
sid = ev.get("session_id", "?")
if kind == "instructions":
    put("instructions.log", "%s\t%s\t%s\t%s\t%d" % (
        sid, ev.get("file_path", "?"), ev.get("load_reason", "?"), ev.get("agent_type", ""), ts))
    put("instructions.raw.jsonl", json.dumps(ev, ensure_ascii=False))
else:
    name = ev.get("hook_event_name", "?")
    put("compact.log", "%s %s %s %d" % (name, ev.get("source") or ev.get("trigger") or "?", sid, ts))
    put("compact.raw.jsonl", json.dumps(ev, ensure_ascii=False))
PY
printf '.probe/\n' >> "$REPO/.gitignore"

PYTHONIOENCODING=utf-8 python3 - "$REPO/.claude/settings.json" <<'PY'
import io, json, sys
p = sys.argv[1]
s = json.load(io.open(p, encoding="utf-8"))
def hk(kind):
    return {"hooks": [{"type": "command",
            "command": 'python3 "$CLAUDE_PROJECT_DIR/.claude/hooks/probe-log.py" ' + kind}]}
h = s.setdefault("hooks", {})
h["InstructionsLoaded"] = [hk("instructions")]
h["PostCompact"] = [hk("compact")]
h.setdefault("SessionStart", []).append(hk("compact"))
io.open(p, "w", encoding="utf-8").write(json.dumps(s, indent=2) + "\n")
PY

# --- re-seal the neutral one-commit history ---------------------------------
( cd "$REPO" && git add -A && git -c user.email=fx@fx -c user.name=fx commit -q --amend -m init --no-verify ) 2>/dev/null
echo "fixture ready: $REPO (arm=$ARM)"
