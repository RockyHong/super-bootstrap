#!/usr/bin/env python3
"""DEBT-ymdg — score ownership-split walks.

Usage: python3 score.py <results-dir> [--asset FILE] [--machine]
  <results-dir>  holds one directory per finished walk, named <walk> or
                 <walk>-<label> (walk: fresh | legacy | stale | fork), each as
                 run.sh leaves it:
                   repo/                    the fixture tree after the run
                   stream.jsonl             the run's stream-json transcript
                   stream.t2.jsonl          fork only, when a second turn answered the prompt
                   meta/start-head.txt      HEAD before the run
                   meta/end-head.txt        HEAD after the run
                   meta/git-status.txt      `git status --porcelain --untracked-files=all` after the run
                   meta/harness.before.md   stale / fork: the owned file before the run
                   meta/answer.txt          fork only: `overwrite` | `keep` (the second turn's answer)
                   meta/plugin-dir.txt      the --plugin-dir the run was given
  --asset FILE   the shipped owned-file asset to compare against. Default:
                 plugins/super-bootstrap/skills/harness-bootstrap/assets/harness.md;
                 with no default on disk and no --asset the scorer exits 2.
  --machine      print only `name<TAB>valid<TAB>pass<TAB>reason` rows.

One row per walk: walk, valid, pass, reason. `valid 0` = the run cannot be read
(no stream, no result event, errored, no assistant text, a missing meta file,
the dev plugin not loaded) — neither a pass nor a fail; `pass` is then `-`.
A fail's reason names every property that failed, joined by `; `.
"""
import io
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_ASSET = os.path.normpath(os.path.join(
    HERE, "..", "..", "plugins", "super-bootstrap", "skills", "harness-bootstrap", "assets", "harness.md"))
OWNED = ".claude/rules/harness.md"
RECEIPT = ".claude/super-bootstrap-runway.json"
PLUGIN_NAME = "super-bootstrap"

# --- the project set (one place) ----------------------------------------------
# A consumer CLAUDE.md `## ` heading is project-owned when it is one of these,
# or starts with `Monorepo` (the skeleton's conditional block carries a suffix).
PROJECT_HEADINGS = ("Tech Stack", "Commands", "Rules (auto-load on file match)", "Planning")
# Receipt `covered` rows name sections short (`CLAUDE.md § Rules`), so a row is
# project-owned when its section name STARTS with one of these.
PROJECT_ROW_PREFIXES = ("Tech Stack", "Commands", "Rules", "Planning", "Monorepo")
ROW_PRE = u"CLAUDE.md § "

# --- markers (one place) --------------------------------------------------------
# legacy stop message: names the owned file AND states the pre-split shape.
# The fixed message is authored with the split's placement contract; pin this
# list to its wording when it lands.
LEGACY_SHAPE_PATTERNS = [
    r"pre-split",
    r"\blegacy\b",
    r"\bnot (yet )?(been )?split\b",
    r"\bbefore the (ownership )?split\b",
    r"\bmigrat",
]
# an approval prompt, as the skill words them (SKILL.md § 2b Block 2, the
# `⊕ new` expansion, legacy migration; hooks-ensure-infra.md § fork pick)
OVERWRITE_KEEP = r"\boverwrite\b.{0,300}?\bkeep\b|\bkeep\b.{0,300}?\boverwrite\b"
PROMPT_PATTERNS = [
    r"\bUpdate\?\s*\(",
    r"Insert at the skeleton",
    r"Apply migrations\?",
    r"\(\s*y\s*/\s*n\b",
    OVERWRITE_KEEP,
]
LOOKBACK, LOOKAHEAD = 800, 200   # chars around a prompt that must name the owned file


def strip_cr(b):
    return b.replace(b"\r", b"")


def read_bytes(path):
    if not os.path.isfile(path):
        return None
    with io.open(path, "rb") as fh:
        return fh.read()


def read_text(path):
    b = read_bytes(path)
    return None if b is None else b.decode("utf-8", errors="replace")


def events(path):
    out = []
    t = read_text(path)
    for line in (t or "").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            e = json.loads(line)
        except ValueError:
            continue
        if isinstance(e, dict):
            out.append(e)
    return out


def blocks(ev):
    m = ev.get("message")
    c = m.get("content") if isinstance(m, dict) else None
    if isinstance(c, str):
        return [{"type": "text", "text": c}]
    return [b for b in c if isinstance(b, dict)] if isinstance(c, list) else []


def main_texts(evs):
    """Main-session assistant text, one string per assistant event, in order."""
    out = []
    for e in evs:
        if e.get("type") == "assistant" and not e.get("parent_tool_use_id"):
            t = "".join(b.get("text", "") for b in blocks(e) if b.get("type") == "text")
            if t.strip():
                out.append(t)
    return out


def asked_texts(evs):
    """Text that can carry a question to the user: assistant text + AskUserQuestion input."""
    out = main_texts(evs)
    for e in evs:
        if e.get("type") == "assistant" and not e.get("parent_tool_use_id"):
            for b in blocks(e):
                if b.get("type") == "tool_use" and b.get("name") == "AskUserQuestion":
                    out.append(json.dumps(b.get("input"), ensure_ascii=False))
    return out


def prompts_naming_owned(texts, patterns):
    """Prompt matches whose surrounding text names the owned file -> [snippet]."""
    hits = []
    for t in texts:
        prev_end = 0
        spans = sorted(m.span() for p in patterns for m in re.finditer(p, t, re.I | re.S))
        for a, b in spans:
            ctx = t[max(prev_end, a - LOOKBACK):b + LOOKAHEAD]
            if "harness.md" in ctx:
                hits.append(" ".join(t[a:b].split())[:60])
            prev_end = max(prev_end, b)
    return hits


def stream_health(evs, label="stream"):
    """-> list of invalid reasons for one turn's stream."""
    if not evs:
        return ["no %s" % label]
    res = [e for e in evs if e.get("type") == "result"]
    if not res:
        return ["%s has no result event" % label]
    last = res[-1]
    if last.get("is_error") or str(last.get("subtype", "success")).startswith("error"):
        return ["run errored (%s)" % last.get("subtype")]
    if not main_texts(evs):
        return ["no assistant text"]
    return []


def plugin_health(evs, d):
    """The skill under test must be the dev copy: the init event lists the plugin,
    at the path run.sh passed. An init event without a `plugins` key is not judged."""
    init = next((e for e in evs if e.get("type") == "system" and e.get("subtype") == "init"), None)
    if init is None or not isinstance(init.get("plugins"), list):
        return []
    mine = [p for p in init["plugins"] if isinstance(p, dict) and p.get("name") == PLUGIN_NAME]
    if not mine:
        return ["dev plugin not loaded (init lists no `%s` plugin)" % PLUGIN_NAME]
    want = (read_text(os.path.join(d, "meta", "plugin-dir.txt")) or "").strip()
    if want:
        nz = lambda p: os.path.normcase(os.path.normpath(p.replace("\\", "/"))).rstrip("\\/")
        if not any(nz(str(p.get("path", ""))) == nz(want) for p in mine):
            return ["plugin loaded from %s, not the dev copy %s" % (mine[0].get("path"), want)]
    return []


def headings(text):
    out, fence = [], False
    for ln in text.replace("\r", "").split("\n"):
        if ln.startswith("```"):
            fence = not fence
        if not fence and ln.startswith("## "):
            out.append(ln[3:].strip())
    return out


def is_project_heading(h):
    return h in PROJECT_HEADINGS or h.startswith("Monorepo")


# --- per-walk property checks: each returns a list of fail reasons ---------------
def check_fresh(d, asset, evs):
    fails = []
    repo = os.path.join(d, "repo")
    owned = read_bytes(os.path.join(repo, OWNED))
    if owned is None:
        fails.append("owned file missing: no %s" % OWNED)
    elif strip_cr(owned) != strip_cr(asset):
        fails.append("owned file differs from the shipped asset")
    cm = read_text(os.path.join(repo, "CLAUDE.md"))
    if cm is None:
        fails.append("CLAUDE.md missing")
    else:
        extra = [h for h in headings(cm) if not is_project_heading(h)]
        if extra:
            fails.append("CLAUDE.md holds non-project heading(s): %s" % ", ".join(extra))
    rt = read_text(os.path.join(repo, RECEIPT))
    try:
        cov = json.loads(rt)["covered"] if rt is not None else None
    except (ValueError, KeyError, TypeError):
        cov = None
    if not isinstance(cov, list):
        fails.append("receipt missing or without a `covered` list")
    else:
        rows = [c for c in cov if isinstance(c, str)]
        doctrine = [c for c in rows if c.startswith(ROW_PRE)
                    and not c[len(ROW_PRE):].startswith(PROJECT_ROW_PREFIXES)]
        if doctrine:
            fails.append("receipt `covered` holds doctrine row(s): %s" % ", ".join(doctrine))
        if OWNED not in rows:
            fails.append("receipt `covered` lacks the %s row" % OWNED)
    return fails


def check_legacy(d, asset, evs):
    fails = []
    status = read_text(os.path.join(d, "meta", "git-status.txt"))
    dirty = [l for l in status.splitlines() if l.strip()]
    if dirty:
        fails.append("working tree not clean: %d path(s), first `%s`" % (len(dirty), dirty[0].strip()))
    start = read_text(os.path.join(d, "meta", "start-head.txt")).strip()
    end = read_text(os.path.join(d, "meta", "end-head.txt")).strip()
    if start != end:
        fails.append("HEAD moved (%s -> %s)" % (start[:8], end[:8]))
    final = main_texts(evs)[-1]
    if "harness.md" not in final or ".claude/rules" not in final:
        fails.append("stop message does not name %s" % OWNED)
    if not any(re.search(p, final, re.I) for p in LEGACY_SHAPE_PATTERNS):
        fails.append("stop message does not state the pre-split shape")
    return fails


def check_stale(d, asset, evs):
    fails = []
    owned = read_bytes(os.path.join(d, "repo", OWNED))
    before = read_bytes(os.path.join(d, "meta", "harness.before.md"))
    if owned is None:
        fails.append("owned file missing: no %s" % OWNED)
    elif strip_cr(owned) != strip_cr(asset):
        same = before is not None and strip_cr(owned) == strip_cr(before)
        fails.append("owned file differs from the shipped asset (%s)"
                     % ("still the older bytes" if same else "neither older nor shipped"))
    asked = prompts_naming_owned(asked_texts(evs), PROMPT_PATTERNS)
    if asked:
        fails.append("approval prompt for the owned file in the transcript: `%s`" % asked[0])
    return fails


def check_fork(d, asset, evs):
    fails = []
    owned = read_bytes(os.path.join(d, "repo", OWNED))
    before = read_bytes(os.path.join(d, "meta", "harness.before.md"))
    answer = (read_text(os.path.join(d, "meta", "answer.txt")) or "").strip()
    if not prompts_naming_owned(asked_texts(evs), [OVERWRITE_KEEP]):
        fails.append("no overwrite-or-keep choice naming %s" % OWNED)
    if owned is None:
        fails.append("owned file missing: no %s" % OWNED)
    elif answer == "overwrite":
        if strip_cr(owned) != strip_cr(asset):
            fails.append("told to overwrite, owned file differs from the shipped asset")
    elif strip_cr(owned) != strip_cr(before):
        fails.append("owned file changed without an overwrite answer (answer: %s)" % (answer or "none"))
    return fails


CHECKS = {"fresh": check_fresh, "legacy": check_legacy, "stale": check_stale, "fork": check_fork}
META_NEEDED = {
    "fresh": [],
    "legacy": ["git-status.txt", "start-head.txt", "end-head.txt"],
    "stale": ["harness.before.md"],
    "fork": ["harness.before.md"],
}
NAME_RE = re.compile(r"^(fresh|legacy|stale|fork)(-.+)?$")


def score_walk(results, name, asset):
    walk = NAME_RE.match(name).group(1)
    d = os.path.join(results, name)
    evs = events(os.path.join(d, "stream.jsonl"))
    invalid = stream_health(evs)
    if not invalid:
        invalid += plugin_health(evs, d)
    if not os.path.isdir(os.path.join(d, "repo")):
        invalid.append("no repo/ tree")
    for m in META_NEEDED[walk]:
        if not os.path.isfile(os.path.join(d, "meta", m)):
            invalid.append("meta/%s missing" % m)
    # fork with an answer: the second turn must be readable too
    if walk == "fork" and os.path.isfile(os.path.join(d, "meta", "answer.txt")):
        invalid += stream_health(events(os.path.join(d, "stream.t2.jsonl")), "stream.t2")
    if invalid:
        return {"name": name, "valid": "0", "pass": "-", "reason": "; ".join(invalid)}
    fails = CHECKS[walk](d, asset, evs)
    notes = []
    res = [e for e in evs if e.get("type") == "result"][-1]
    if res.get("permission_denials"):
        notes.append("note: %d permission denial(s) in the run" % len(res["permission_denials"]))
    return {"name": name, "valid": "1", "pass": "0" if fails else "1",
            "reason": "; ".join(fails + notes) if (fails or notes) else "ok"}


def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8")   # Windows console is a legacy codepage
    except AttributeError:
        pass
    argv, machine, asset_path, pos = sys.argv[1:], False, None, []
    i = 0
    while i < len(argv):
        if argv[i] == "--machine":
            machine = True
        elif argv[i] == "--asset":
            i += 1
            asset_path = argv[i] if i < len(argv) else None
        else:
            pos.append(argv[i])
        i += 1
    if len(pos) != 1:
        sys.stderr.write(__doc__)
        return 2
    asset_path = asset_path or DEFAULT_ASSET
    asset = read_bytes(asset_path)
    if asset is None:
        sys.stderr.write("FATAL: no shipped asset at %s — pass --asset FILE\n" % asset_path)
        return 2
    results = pos[0]
    names = sorted(n for n in os.listdir(results)
                   if NAME_RE.match(n) and os.path.isdir(os.path.join(results, n)))
    rows = [score_walk(results, n, asset) for n in names]
    if machine:
        for r in rows:
            print("%s\t%s\t%s\t%s" % (r["name"], r["valid"], r["pass"], r["reason"]))
        return 0
    table = [["walk", "valid", "pass", "reason"]] + [[r["name"], r["valid"], r["pass"], r["reason"]] for r in rows]
    w = [max(len(t[i]) for t in table) for i in range(3)]
    for t in table:
        print("  ".join(t[i].ljust(w[i]) for i in range(3)) + "  " + t[3])
    v = [r for r in rows if r["valid"] == "1"]
    print("\nasset: %s" % asset_path)
    print("valid %d / %d · pass %d · fail %d · invalid %d" % (
        len(v), len(rows), sum(r["pass"] == "1" for r in v), sum(r["pass"] == "0" for r in v), len(rows) - len(v)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
