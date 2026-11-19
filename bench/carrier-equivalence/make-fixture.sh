#!/usr/bin/env bash
# DEBT-ymdg — build one carrier-equivalence fixture: a consumer-shaped repo
# (shipped runway placed) whose workflow doctrine — the shipped asset
# assets/harness.md — sits in the carrier named by <arm>.
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
ASSET="$(cd "$SRC/../../plugins/super-bootstrap/skills/harness-bootstrap/assets" && pwd)/harness.md"

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
# Source of the doctrine: the shipped asset (assets/harness.md), which the
# runway placer has already put at .claude/rules/harness.md — the `rules` arm
# IS that placement, untouched. The other arms move the asset's BODY (its first
# `## ` line to its end; the H1 and the "plugin-owned, re-placed whole" line
# above it describe the rules-file placement and stay behind) into another
# carrier, or nowhere. The asset's relative link targets are written for
# .claude/rules/; a moved body has each one re-based for its carrier's
# directory, and that is the only byte that may differ from the asset body.
# CLAUDE.md's pointer line (under the H1, naming .claude/rules/harness.md) is
# true only in the `rules` arm: dropped in `claudemd` and `none`, replaced by
# the `@.claude/harness.md` import line in `import`.
PYTHONIOENCODING=utf-8 python3 - "$REPO" "$ARM" "$FX/split.txt" "$ASSET" <<'PY'
import io, os, posixpath, re, sys
repo, arm, splitfile, asset_path = sys.argv[1:5]
PROJECT = ("## Tech Stack", "## Commands", "## Rules (auto-load on file match)", "## Planning")
RULES = ".claude/rules/harness.md"
IMPORTED = ".claude/harness.md"
IMPORT_LINE = "@.claude/harness.md"
CARRIER = {"claudemd": "CLAUDE.md", "rules": RULES, "import": IMPORTED, "none": None}
# A markdown link target: `](target)`. Absolute URLs, in-page anchors and
# root-absolute paths are not re-based.
LINK = re.compile(r"\]\(([^)\s]+)\)")


def rd(p):
    """File text with CR removed — the asset is compared CR-blind, as the skill does."""
    with io.open(p, "rb") as fh:
        return fh.read().replace(b"\r", b"").decode("utf-8")


def wr(p, s):
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with io.open(p, "w", encoding="utf-8", newline="") as fh:
        fh.write(s)


def die(msg):
    sys.exit("FATAL (%s): %s" % (arm, msg))


def rebase(text, src_dir, dst_dir):
    """Re-base every relative link target from src_dir to dst_dir -> (text, [(old, new)])."""
    pairs = []

    def one(m):
        t = m.group(1)
        if "://" in t or t.startswith(("#", "/", "mailto:")):
            return m.group(0)
        path, sep, frag = t.partition("#")
        new = posixpath.relpath(posixpath.normpath(posixpath.join(src_dir, path)), dst_dir or ".")
        if path.endswith("/"):
            new += "/"
        new += sep + frag
        if new != t:
            pairs.append((t, new))
        return "](" + new + ")"

    return LINK.sub(one, text), pairs


def split_sections(text):
    """-> (title_text, [(heading, section_text)]); `## ` inside a code fence is no heading."""
    title, secs, fence = [], [], False
    for ln in text.splitlines(keepends=True):
        if ln.startswith("```"):
            fence = not fence
        if not fence and ln.startswith("## "):
            secs.append([ln.rstrip("\n"), [ln]])
        elif not secs:
            title.append(ln)
        else:
            secs[-1][1].append(ln)
    return "".join(title), [(h, "".join(b)) for h, b in secs]


# --- the asset: preamble (stays behind) + body (the doctrine that moves) ------
asset = rd(asset_path)
cut = asset.find("\n## ")
if cut < 0:
    die("the asset has no `## ` section: %s" % asset_path)
body = asset[cut + 1:]
if not body.endswith("\n"):
    die("the asset body does not end with a newline")
_, asset_secs = split_sections(asset)
owned = [h for h, _ in asset_secs]

# --- the placement as the runway placer left it -------------------------------
cm_path = os.path.join(repo, "CLAUDE.md")
rules_path = os.path.join(repo, RULES)
imported_path = os.path.join(repo, IMPORTED)
if not os.path.isfile(rules_path) or rd(rules_path) != asset:
    die("the runway placer did not place %s equal to the asset" % RULES)
title, cm_secs = split_sections(rd(cm_path))
if [h for h, _ in cm_secs if h in owned]:
    die("the placed CLAUDE.md already holds doctrine sections — the placer is not in the split shape")
project = "".join(b for h, b in cm_secs if h in PROJECT)
missing = set(PROJECT) - {h for h, _ in cm_secs}
if missing:
    die("project-content sections missing from CLAUDE.md: %s" % sorted(missing))
tl = title.splitlines(keepends=True)
ptr = [i for i, ln in enumerate(tl) if RULES in ln]
if len(ptr) != 1:
    die("expected one pointer line naming %s under the H1, found %d" % (RULES, len(ptr)))
head = "".join(tl[:ptr[0]])                    # H1 + blank line
tail = "".join(tl[ptr[0] + 1:]).lstrip("\n")   # nothing, on the shipped skeleton
if tail:
    die("unexpected text between the pointer line and the first section: %r" % tail[:60])

# --- move the carrier ----------------------------------------------------------
pairs = []
# The folded doctrine needs one blank line before the next `## ` heading. The
# asset ends with a blank line of its own today, so nothing is added; `sep` is
# non-empty only if a later asset drops that line, and is not doctrine text.
sep = "" if body.endswith("\n\n") else "\n"
if arm == "rules":
    pass                                        # the shipped placement, as-is
elif arm == "claudemd":
    folded, pairs = rebase(body, posixpath.dirname(RULES), "")
    wr(cm_path, head + folded + sep + project)
    os.remove(rules_path)
elif arm == "import":
    folded, pairs = rebase(body, posixpath.dirname(RULES), posixpath.dirname(IMPORTED))
    wr(imported_path, folded)
    wr(cm_path, head + IMPORT_LINE + "\n\n" + project)
    os.remove(rules_path)
else:
    wr(cm_path, head + project)
    os.remove(rules_path)

# --- assertions, read back from disk -------------------------------------------
report = ["ARM: %s" % arm, "CARRIER: %s" % (CARRIER[arm] or "(none)"),
          "DOCTRINE sections (asset body, %d bytes):" % len(body.encode("utf-8"))] + ["  " + h for h in owned]
cm = rd(cm_path)
cm_title, cm_secs = split_sections(cm)
cm_heads = [h for h, _ in cm_secs]
report += ["CLAUDE.md sections:"] + ["  " + h for h in cm_heads]
if "".join(b for h, b in cm_secs if h in PROJECT) != project:
    die("the project sections of CLAUDE.md changed")
report.append("PROJECT sections unchanged: OK")

carried = None
if arm == "rules":
    if rd(rules_path) != asset:
        die("%s differs from the asset" % RULES)
    report.append("BYTE-EQUAL OK: %s == asset, whole file (%d bytes)" % (RULES, len(asset.encode("utf-8"))))
elif arm == "claudemd":
    got = "".join(b for h, b in cm_secs if h in owned)
    if not got.endswith("\n\n"):
        die("no blank line between the folded doctrine and the project sections")
    carried = got[:len(got) - len(sep)]
    if [h for h in cm_heads if h in owned] != owned or cm_heads[:len(owned)] != owned:
        die("CLAUDE.md does not hold the doctrine sections, in asset order, ahead of the project sections")
elif arm == "import":
    carried = rd(imported_path)
    if cm.splitlines().count(IMPORT_LINE) != 1:
        die("CLAUDE.md does not hold exactly one `%s` line" % IMPORT_LINE)
if carried is not None:
    cdir = posixpath.dirname(CARRIER[arm])
    back, _ = rebase(carried, cdir, posixpath.dirname(RULES))
    if back != body:
        die("the doctrine in %s, with link targets re-based back, differs from the asset body" % CARRIER[arm])
    report.append("BYTE-EQUAL OK: doctrine in %s == asset body, link targets aside (%d bytes carried)"
                  % (CARRIER[arm], len(carried.encode("utf-8"))))
    report += ["LINK TARGETS re-based for %s (%d):" % (CARRIER[arm], len(pairs))] + \
              ["  %s -> %s" % p for p in pairs]

# one carrier, and no other trace of the doctrine
for a, rel in (("rules", RULES), ("import", IMPORTED)):
    if os.path.exists(os.path.join(repo, rel)) != (arm == a):
        die("%s %s" % (rel, "is missing" if arm == a else "exists outside its arm"))
if arm != "claudemd" and [h for h in cm_heads if h in owned]:
    die("CLAUDE.md holds a doctrine heading outside the claudemd arm")
if (IMPORT_LINE in cm) != (arm == "import"):
    die("the `%s` line is %s" % (IMPORT_LINE, "missing" if arm == "import" else "present outside the import arm"))
if (RULES in cm_title) != (arm == "rules"):
    die("the pointer line naming %s is %s" % (RULES, "missing" if arm == "rules" else "present outside the rules arm"))
report.append("ONE CARRIER OK: %s; pointer line %s; import line %s" % (
    CARRIER[arm] or "none", "kept" if arm == "rules" else "dropped", "present" if arm == "import" else "absent"))

wr(splitfile, "\n".join(report) + "\n")
print("\n".join(report))
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
