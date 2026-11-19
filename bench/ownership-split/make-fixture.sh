#!/usr/bin/env bash
# DEBT-ymdg — build one ownership-split fixture: the starting state of one walk.
#
# Usage: bash make-fixture.sh <fxdir> <walk> [--shipped FILE] [--older FILE]
#   walk: fresh | legacy | stale | fork
#   --shipped FILE  the bytes the walk treats as the shipped owned-file asset.
#                   Default: plugins/super-bootstrap/skills/harness-bootstrap/assets/harness.md
#                   when it exists, else standin/harness-shipped.md (the asset
#                   does not exist until the split's placement contract lands).
#   --older FILE    the "older asset version" for stale / fork. Default: derived
#                   from the shipped bytes by dropping their last `## ` section.
#
# Output:
#   <fxdir>/repo                     the repo handed to `claude -p` (one commit)
#   <fxdir>/coldcfg                  credentials-only CLAUDE_CONFIG_DIR
#   <fxdir>/meta/walk.txt            the walk name
#   <fxdir>/meta/start-head.txt      HEAD before any run
#   <fxdir>/meta/shipped.md          the shipped bytes this fixture was built against
#   <fxdir>/meta/harness.before.md   stale / fork: the owned file as the run finds it
#   <fxdir>/meta/CLAUDE.before.md    legacy: CLAUDE.md as the run finds it (own line included)
#   <fxdir>/meta/doc-links.before.txt legacy: `doc-links.sh check` stdout on the fixture
#   <fxdir>/meta/variant.txt         legacy: the LEGACY_VARIANT value
#   <fxdir>/meta/own-lines.txt       legacy: the repo's own lines, one per line (the scorer's survival set)
#   <fxdir>/meta/receipt.before.json legacy: the starting receipt (absent file = no receipt at start)
#
# Env LEGACY_VARIANT (legacy walk only; default `current`; anything else is FATAL):
#   current   CLAUDE.md := legacy/CLAUDE.md (frozen) + the release bullet
#   v2.22.0 | v5.10.6 | v6.0.1
#             CLAUDE.md := that tag's assets/claude-md-skeleton.md (git show; tags are
#             immutable, nothing frozen here) with its placeholders filled the way a
#             single-package Python repo's scaffold step fills them, + the release bullet;
#             receipt in the shape that tag's skill wrote (v2.22.0: version-only stamp)
#   edited    the v6.0.1 variant + five hand edits to the doctrine sections (see README)
#
# Runway (legacy, stale, fork): CALLS ../assertion-liveness/make-fixture.sh and
# layers on top — one placement logic. That builder follows the shipped
# assets (the split shape, since the split's placement contract landed); this
# script still forces the shape each walk needs instead of trusting what it gets:
#   legacy      CLAUDE.md := legacy/CLAUDE.md (frozen pre-split copy) + one repo-own
#               bullet at the end of `## Git Notes` (the frozen file stays untouched),
#               no owned file, receipt `covered` := legacy/covered.txt
#   stale, fork CLAUDE.md := title + project sections only, owned file written here,
#               receipt `covered` / `placed` rewritten to the split shape
#
# Bench-only script: POSIX bash + python3.
set -eu
FX="${1:?usage: make-fixture.sh <fxdir> <walk> [--shipped FILE] [--older FILE]}"
WALK="${2:?usage: make-fixture.sh <fxdir> <walk> [--shipped FILE] [--older FILE]}"
shift 2
SHIPPED=""; OLDER=""
while [ $# -gt 0 ]; do
  case "$1" in
    --shipped) SHIPPED="${2:?--shipped needs a file}"; shift 2 ;;
    --older)   OLDER="${2:?--older needs a file}"; shift 2 ;;
    *) echo "FATAL: unknown argument '$1'" >&2; exit 1 ;;
  esac
done
case "$WALK" in fresh|legacy|stale|fork) ;; *) echo "FATAL: unknown walk '$WALK'" >&2; exit 1 ;; esac
VARIANT="${LEGACY_VARIANT:-current}"
case "$VARIANT" in current|v2.22.0|v5.10.6|v6.0.1|edited) ;; *) echo "FATAL: unknown LEGACY_VARIANT '$VARIANT' (current|v2.22.0|v5.10.6|v6.0.1|edited)" >&2; exit 1 ;; esac
[ "$VARIANT" = current ] || [ "$WALK" = legacy ] || { echo "FATAL: LEGACY_VARIANT=$VARIANT only applies to the legacy walk" >&2; exit 1; }

SRC="$(cd "$(dirname "$0")" && pwd)"
LIVE="$SRC/../assertion-liveness/make-fixture.sh"
CODE="$SRC/../assertion-liveness/fixture"
ASSET="$SRC/../../plugins/super-bootstrap/skills/harness-bootstrap/assets/harness.md"
if [ -z "$SHIPPED" ]; then
  if [ -f "$ASSET" ]; then SHIPPED="$ASSET"; else SHIPPED="$SRC/standin/harness-shipped.md"; fi
fi
[ -f "$SHIPPED" ] || { echo "FATAL: shipped file not found: $SHIPPED" >&2; exit 1; }
[ -z "$OLDER" ] || [ -f "$OLDER" ] || { echo "FATAL: older file not found: $OLDER" >&2; exit 1; }

# native python.exe needs Windows paths, not /d/... or /tmp/...
W() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s\n' "$1"; fi; }

rm -rf "$FX/repo" "$FX/coldcfg" "$FX/meta"
mkdir -p "$FX/meta"
REPO="$FX/repo"

if [ "$WALK" = fresh ]; then
  # a code-present repo that no bootstrap has touched: source + tests, nothing else
  mkdir -p "$REPO"
  cp -r "$CODE/src" "$CODE/tests" "$REPO/"
  cp "$CODE/run_tests.py" "$CODE/.gitignore" "$REPO/"
  find "$REPO" -name __pycache__ -type d -exec rm -rf {} + 2>/dev/null || true
  ( cd "$REPO" && git init -q )
else
  bash "$LIVE" "$FX" control >/dev/null 2>&1 \
    || { echo "FATAL: the runway placer failed: $LIVE" >&2; exit 1; }
fi

# --- cold config, one shape for all four walks (overwrites the placer's) -----
# credentials only: no CLAUDE.md, no plugins, no hooks. The run's permission
# posture comes from run.sh's flags, not from here.
rm -rf "$FX/coldcfg"; mkdir -p "$FX/coldcfg"
[ -f "$HOME/.claude/.credentials.json" ] && cp "$HOME/.claude/.credentials.json" "$FX/coldcfg/"
cat > "$FX/coldcfg/settings.json" <<'JSON'
{
  "hooks": {},
  "enabledPlugins": {},
  "includeCoAuthoredBy": false
}
JSON

# --- force the walk's shape ---------------------------------------------------
PYTHONIOENCODING=utf-8 python3 - "$WALK" "$(W "$REPO")" "$(W "$FX/meta")" "$(W "$SRC")" \
    "$(W "$SHIPPED")" "${OLDER:+$(W "$OLDER")}" "$VARIANT" "$(W "$SRC/../..")" <<'PY'
import hashlib, io, json, os, re, subprocess, sys
walk, repo, meta, src, shipped_path = sys.argv[1:6]
older_path = sys.argv[6] if len(sys.argv) > 6 and sys.argv[6] else ""
variant, repo_root = sys.argv[7], sys.argv[8]
PROJECT = ("Tech Stack", "Commands", "Rules (auto-load on file match)", "Planning")
OWNED = ".claude/rules/harness.md"
OWN_LINE = "- Tag releases as vX.Y.Z from main only."


def rd(p):
    with io.open(p, "rb") as fh:
        return fh.read()


def wr(p, b):
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with io.open(p, "wb") as fh:
        fh.write(b)


def is_project(h):
    return h in PROJECT or h.startswith("Monorepo")


def sections(text):
    """-> (title_lines, [(heading, [lines])]); `## ` inside a code fence is no heading."""
    title, secs, cur, fence = [], [], None, False
    for ln in text.splitlines(keepends=True):
        if ln.startswith("```"):
            fence = not fence
        if not fence and ln.startswith("## "):
            cur = (ln[3:].strip(), [ln])
            secs.append(cur)
        elif cur is None:
            title.append(ln)
        else:
            cur[1].append(ln)
    return title, secs


shipped = rd(shipped_path).replace(b"\r", b"")
wr(os.path.join(meta, "shipped.md"), shipped)
io.open(os.path.join(meta, "walk.txt"), "w", encoding="utf-8", newline="\n").write(walk + "\n")
claude_md = os.path.join(repo, "CLAUDE.md")
owned = os.path.join(repo, OWNED)
receipt_path = os.path.join(repo, ".claude", "super-bootstrap-runway.json")

if walk == "fresh":
    sys.exit(0)

receipt = json.load(io.open(receipt_path, encoding="utf-8"))

if walk == "legacy":
    SKEL = "plugins/super-bootstrap/skills/harness-bootstrap/assets/claude-md-skeleton.md"
    PROJ_NAME = "decimate"
    TECH = "Python 3 (stdlib only) + a framework-free assert test runner."
    CMD = "python3 run_tests.py   # whole suite"
    # whole-line `{...}` placeholders of a skeleton, by what a single-package Python
    # repo's scaffold step does with them (each tag's SKILL.md § Placeholders):
    DROP = ("{## Monorepo", "{Workspace repo", "{Run the workspace-aware",   # single-package: block dropped
            "{example scaffolding", "{- **`rules/", "{  • ",              # no signal-seeded rule: examples dropped
            "{seeded by sp-bootstrap", "{If rule body")                       # v2.22.0: "keep only the explanatory paragraph"
    DROP_ANY = ("docs/parked.md", "docs/test-queue.md", "docs/outward/")     # scale module not installed
    UNBRACKET = ("{## Coding Principles}", "{Before writing", "{**Backlog cleanup",   # code present / backlog always
                 "{- [`docs/specs/`", "{- [`docs/backlog.md`")                     # specs: code present; backlog: always

    def tag_skeleton(tag):
        r = subprocess.run(["git", "-C", repo_root, "show", "%s:%s" % (tag, SKEL)], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if r.returncode != 0:
            sys.exit("FATAL: git show %s:%s failed: %s" % (tag, SKEL, r.stderr.decode("utf-8", "replace").strip()))
        return r.stdout.replace(b"\r", b"").decode("utf-8")

    def fill_skeleton(text):
        out = []
        for ln in text.split("\n"):
            s_ = ln.rstrip()
            if s_ == "# {Project Name}":
                out.append("# " + PROJ_NAME)
            elif s_.startswith("{") and s_.endswith("}"):
                if s_.startswith(DROP) or any(k in s_ for k in DROP_ANY):
                    continue
                if s_.startswith("{detected one-line summary"):
                    out.append(TECH)
                elif s_.startswith("{detected from scripts"):
                    out.append(CMD)
                elif s_.startswith(UNBRACKET):
                    out.append(s_[1:-1])
                else:
                    sys.exit("FATAL: unclassified placeholder line in the skeleton: %s" % s_[:100])
            else:
                out.append(ln)
        t = re.sub(r"\n{3,}", "\n\n", "\n".join(out)).rstrip("\n") + "\n"
        left = [l for l in t.split("\n") if l.startswith("{") or "{Project Name}" in l]
        if left:
            sys.exit("FATAL: placeholder left unfilled: %s" % left[0][:100])
        return t

    def sub_once(text, old, new, what):
        if text.count(old) != 1:
            sys.exit("FATAL: edited variant, %s: anchor found %d times at v6.0.1: %s" % (what, text.count(old), old[:80]))
        return text.replace(old, new)

    def hand_edit(text):
        """The `edited` variant's five hand edits on the v6.0.1 CLAUDE.md -> (text, forked + own lines)."""
        forked = "- Every change lands through a PR with one reviewer. Main + feature branches. No force push."
        deploy = ["Deploys run from the `release` branch only.", "- Staging first; production after a green smoke run."]
        api = "- API docs under `docs/api/` regenerate from source; never hand-edit them."
        # 2 forked doctrine line
        ls = text.split("\n")
        hit = [i for i, l in enumerate(ls) if l.startswith("- No PR self-review")]
        if len(hit) != 1:
            sys.exit("FATAL: edited variant, item 2: `- No PR self-review` found %d times" % len(hit))
        ls[hit[0]] = forked
        text = "\n".join(ls)
        # 3 own section between two doctrine sections
        text = sub_once(text, "## Context Hygiene\n", "## Deploy\n\n" + "\n".join(deploy) + "\n\n## Context Hygiene\n", "item 3")
        # 5 last sentence of the single-paragraph `## Context Hygiene` (v6.0.1 holds one paragraph there)
        cut = (" Volatile state no card owns rides the session-carry ledger, owned by `/super-bootstrap:session-close` "
               "(write/clear) and `/super-bootstrap:session-continue` (read/claim).")
        text = sub_once(text, cut, "", "item 5")
        # 4 own bullet at the end of `## Doc Sync (non-negotiable)` = before the next `## ` heading
        ls = text.split("\n")
        di = [i for i, l in enumerate(ls) if l == "## Doc Sync (non-negotiable)"]
        if len(di) != 1:
            sys.exit("FATAL: edited variant, item 4: `## Doc Sync (non-negotiable)` found %d times" % len(di))
        nx = next(i for i in range(di[0] + 1, len(ls)) if ls[i].startswith("## "))
        last = max(i for i in range(di[0], nx) if ls[i].strip())
        ls[last + 1:last + 1] = ["", api]
        return "\n".join(ls), [forked] + deploy + [api]

    cov = [l.strip() for l in io.open(os.path.join(src, "legacy", "covered.txt"), encoding="utf-8") if l.strip()]
    own_extra = []
    if variant == "current":
        old = rd(os.path.join(src, "legacy", "CLAUDE.md")).replace(b"\r", b"").decode("utf-8")
    elif variant == "v2.22.0":
        old = fill_skeleton(tag_skeleton("v2.22.0"))
    else:
        old = fill_skeleton(tag_skeleton("v6.0.1" if variant == "edited" else variant))
        if variant == "edited":
            old, own_extra = hand_edit(old)
    # the repo's own line: last bullet of the `## Git Notes` section (before the next `## `)
    lines = old.split("\n")
    gi = next(i for i, l in enumerate(lines) if l == "## Git Notes")
    nxt = next((i for i in range(gi + 1, len(lines)) if lines[i].startswith("## ")), len(lines))
    last = max(i for i in range(gi, nxt) if lines[i].strip())
    lines.insert(last + 1, OWN_LINE)
    old = "\n".join(lines)
    wr(claude_md, old.encode("utf-8"))
    wr(os.path.join(meta, "CLAUDE.before.md"), old.encode("utf-8"))
    own_lines = own_extra + [OWN_LINE]
    wr(os.path.join(meta, "own-lines.txt"), ("\n".join(own_lines) + "\n").encode("utf-8"))
    io.open(os.path.join(meta, "variant.txt"), "w", encoding="utf-8", newline="\n").write(variant + "\n")
    if os.path.exists(owned):
        os.remove(owned)
    if variant == "v2.22.0":
        # that tag's SKILL.md § 2c Stamp write: `{ "version": "{current plugin version}" }`, nothing else
        receipt = {"version": "2.22.0"}
    else:
        # v5.10.6 / v6.0.1 § 2c Receipt write: version + covered + declined + placed
        receipt["covered"] = cov
        receipt["version"] = "6.0.1" if variant == "edited" else (variant[1:] if variant != "current" else receipt.get("version"))
        receipt.get("placed", {}).pop(OWNED, None)
    wr(os.path.join(meta, "receipt.before.json"),
       (json.dumps(receipt, indent=2, ensure_ascii=False) + "\n").encode("utf-8"))
else:
    # split shape: CLAUDE.md keeps its title + project sections, whatever the placer wrote
    title, secs = sections(rd(claude_md).decode("utf-8"))
    kept = [s for s in secs if is_project(s[0])]
    if len(kept) < len(PROJECT):
        sys.exit("FATAL: placed CLAUDE.md lacks a project section (has %s)" % [s[0] for s in kept])
    wr(claude_md, ("".join(title) + "".join("".join(b) for _, b in kept)).encode("utf-8"))

    if older_path:
        older = rd(older_path).replace(b"\r", b"")
    else:
        # derived "older version": the shipped text minus its last `## ` section
        _t, ssecs = sections(shipped.decode("utf-8"))
        if len(ssecs) >= 2:
            older = ("".join(_t) + "".join("".join(b) for _, b in ssecs[:-1])).encode("utf-8")
        else:
            lines = shipped.decode("utf-8").rstrip("\n").split("\n")
            older = ("\n".join(lines[:-1]) + "\n").encode("utf-8")
    if older == shipped:
        sys.exit("FATAL: the older bytes equal the shipped bytes — no stale state to build")
    placed_file = older
    if walk == "fork":
        placed_file = older + (u"\n## Local Additions\n\n- Hand edit by the consumer: "
                               u"run `make lint` before every commit.\n").encode("utf-8")
        if placed_file == shipped:
            sys.exit("FATAL: the fork bytes equal the shipped bytes")
    wr(owned, placed_file)
    wr(os.path.join(meta, "harness.before.md"), placed_file)

    # receipt in the split shape: no CLAUDE.md row for a moved section, one
    # whole-file row for the owned file, `placed` = the OLDER bytes' hash (what
    # the last sync placed). stale: file == that record; fork: file != it.
    pre = u"CLAUDE.md § "
    short = ("Tech Stack", "Commands", "Rules", "Planning", "Monorepo")   # receipt rows use short names
    cov = [r for r in receipt.get("covered", [])
           if not r.startswith(pre) or r[len(pre):].startswith(short)]
    if OWNED not in cov:
        cov.append(OWNED)
    receipt["covered"] = cov
    receipt.setdefault("placed", {})[OWNED] = hashlib.sha256(older).hexdigest()

# LF-only receipt (the skill's own contract for this file)
with io.open(receipt_path, "w", encoding="utf-8", newline="\n") as fh:
    fh.write(json.dumps(receipt, indent=2, ensure_ascii=False) + "\n")
PY

# --- seal one neutral commit --------------------------------------------------
# core.autocrlf=false: a Windows default of `true` makes git report "LF will be
# replaced by CRLF" on every placed file and can turn a byte-identical copy
# into a status line; the fixture pins it so `git status` reads bytes.
(
  cd "$REPO"
  git config core.autocrlf false
  git add -A
  if git rev-parse -q --verify HEAD >/dev/null 2>&1; then
    git -c user.email=fx@fx -c user.name=fx commit -q --amend -m init --no-verify
  else
    git -c user.email=fx@fx -c user.name=fx commit -q -m init --no-verify
  fi
) >/dev/null 2>&1
( cd "$REPO" && git rev-parse HEAD ) > "$FX/meta/start-head.txt"

# --- guards: the starting state is what the walk's row says -------------------
PYTHONIOENCODING=utf-8 python3 - "$WALK" "$(W "$REPO")" "$(W "$FX/meta")" <<'PY'
import hashlib, io, json, os, subprocess, sys
walk, repo, meta = sys.argv[1:4]
PROJECT = ("Tech Stack", "Commands", "Rules (auto-load on file match)", "Planning")
OWNED = ".claude/rules/harness.md"
OWN_LINE = "- Tag releases as vX.Y.Z from main only."


def rd(p):
    with io.open(p, "rb") as fh:
        return fh.read().replace(b"\r", b"")


def heads(p):
    out, fence = [], False
    for ln in rd(p).decode("utf-8").split("\n"):
        if ln.startswith("```"):
            fence = not fence
        if not fence and ln.startswith("## "):
            out.append(ln[3:].strip())
    return out


def need(cond, msg):
    if not cond:
        sys.exit("FATAL guard (%s): %s" % (walk, msg))
    print("GUARD ok: " + msg)


cm, owned = os.path.join(repo, "CLAUDE.md"), os.path.join(repo, OWNED)
rc = os.path.join(repo, ".claude", "super-bootstrap-runway.json")
shipped = rd(os.path.join(meta, "shipped.md"))
status = subprocess.check_output(["git", "status", "--porcelain", "--untracked-files=all"], cwd=repo)
need(status.strip() == b"", "working tree clean on one commit")
doctrine = lambda hs: [h for h in hs if h not in PROJECT and not h.startswith("Monorepo")]
if walk == "fresh":
    need(not os.path.exists(cm), "no CLAUDE.md")
    need(not os.path.exists(owned), "no %s" % OWNED)
    need(not os.path.exists(os.path.join(repo, ".claude")), "no .claude/ at all")
elif walk == "legacy":
    need(len(doctrine(heads(cm))) > 0, "CLAUDE.md holds doctrine sections: %s" % doctrine(heads(cm)))
    need(not os.path.exists(owned), "no %s" % OWNED)
    sheads = set(heads(os.path.join(meta, "shipped.md")))
    owned_n = [h for h in heads(cm) if h in sheads]
    need(len(owned_n) >= 2, "CLAUDE.md holds %d `## ` line(s) equal to the shipped asset's (legacy detection needs 2+): %s" % (len(owned_n), owned_n))
    own = [l for l in rd(os.path.join(meta, "own-lines.txt")).decode("utf-8").split("\n") if l]
    cml = rd(cm).decode("utf-8").split("\n")
    need(own and all(l in cml for l in own), "CLAUDE.md holds all %d own line(s) of meta/own-lines.txt" % len(own))
    need(os.path.isfile(os.path.join(meta, "CLAUDE.before.md")), "meta/CLAUDE.before.md saved")
    need(os.path.isfile(os.path.join(meta, "receipt.before.json")), "meta/receipt.before.json saved")
    r = json.load(io.open(rc, encoding="utf-8"))
    need(OWNED not in r.get("placed", {}) and OWNED not in r.get("covered", []), "receipt names no owned file (starting shape: %s)" % ("covered list" if "covered" in r else "version-only stamp"))
    need(True, "variant: %s" % rd(os.path.join(meta, "variant.txt")).decode("utf-8").strip())
else:
    need(doctrine(heads(cm)) == [], "CLAUDE.md holds project sections only: %s" % heads(cm))
    r = json.load(io.open(rc, encoding="utf-8"))
    rec = r.get("placed", {}).get(OWNED)
    got = hashlib.sha256(rd(owned)).hexdigest()
    need(rd(owned) != shipped, "%s differs from the shipped bytes" % OWNED)
    need(OWNED in r["covered"], "receipt `covered` holds the whole-file row")
    short = ("Tech Stack", "Commands", "Rules", "Planning", "Monorepo")
    bad = [c for c in r["covered"] if c.startswith(u"CLAUDE.md § ") and not c[len(u"CLAUDE.md § "):].startswith(short)]
    need(not bad, "receipt `covered` holds no doctrine row")
    if walk == "stale":
        need(rec == got, "owned file sha == receipt `placed` record (%s…)" % got[:12])
    else:
        need(rec is not None and rec != got, "owned file sha (%s…) != receipt `placed` record (%s…)" % (got[:12], rec[:12]))
PY

# legacy: the broken-link baseline the scorer compares the walk's end state against.
# doc-links.sh reads the doc surface of its cwd; findings go to stdout (the count line to stderr).
if [ "$WALK" = legacy ]; then
  DL="$SRC/../../plugins/super-bootstrap/skills/commit/assets/doc-links.sh"
  ( cd "$REPO" && bash "$DL" check 2>/dev/null ) > "$FX/meta/doc-links.before.txt" || true
  echo "GUARD ok: doc-links baseline saved ($(grep -c . "$FX/meta/doc-links.before.txt") finding(s))"
fi

echo "fixture ready: $REPO (walk=$WALK, shipped=$SHIPPED)"
