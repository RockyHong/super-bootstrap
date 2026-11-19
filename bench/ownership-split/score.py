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
                   meta/answer.txt          fork: `overwrite` | `keep`; legacy: `y` | `n` (the second turn's answer)
                   stream.t2.jsonl          also legacy, when answer.txt exists
                   meta/commits-ahead.txt   legacy + answer y: `git rev-list --count start..HEAD` after the run
                   meta/CLAUDE.before.md    legacy + answer y: the fixture's starting CLAUDE.md
                   meta/doc-links.before.txt, meta/doc-links.after.txt
                                            legacy + answer y: `doc-links.sh check` stdout before / after the walk
                   meta/own-lines.txt       legacy + answer y: the repo's own lines, one per line (absent: the single
                                            release bullet)
                   meta/receipt.before.json, meta/variant.txt
                                            legacy + answer y: the starting receipt (absent with variant.txt present =
                                            no receipt at start; both absent = a pre-variant tree, read as `covered`)
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
# legacy phase 1: the confirm prompt. The message's FINAL non-blank line must be
# this literal, after markdown emphasis / backticks are dropped and whitespace
# collapsed (so `CLAUDE.md` and **x** pass; other wording does not).
CONFIRM_RE = re.compile(r"^Migrate CLAUDE\.md onto \.claude/rules/harness\.md\? \(y / n\)$")
# legacy phase 2: the repo's release bullet, appended by make-fixture.sh to `## Git Notes` —
# the fallback own-lines set when a tree has no meta/own-lines.txt.
OWN_LINE = u"- Tag releases as vX.Y.Z from main only."
LINK_TARGET_RE = re.compile(r"\]\([^)]*\)")
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
# A prompt is about the owned file when the file is named inside the prompt's
# own block (prompt_block below), not merely near it: a run's summary a few
# lines above an unrelated prompt names the file too.
FENCE_RE = re.compile(r"^\s*(```|~~~)")
# a label line: a markdown heading, or a line that is one bold run (`**Question 1: ...**`)
LABEL_RE = re.compile(r"^\s{0,3}(#{1,6}\s+\S|\*\*[^*\n].*\*\*[:.]?\s*$)")


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


def prompt_block(t, a, b):
    """The block of text `t` that holds the prompt match t[a:b] -> str.

    Three shapes, read off the match's first line:
      fenced    inside a ``` / ~~~ fence -> that fence, nothing outside it.
      indented  the skill's own prompt format, unfenced: an unindented header
                line (`<file> sync — drift detected:`) over an indented body ->
                the header line and the indented/blank lines under it.
      prose     an unindented paragraph -> the paragraph; and, when a label line
                (heading or whole-line bold) stands above it, the labelled
                section: that label line down to the next label line. A model
                that words a multi-paragraph question names the file on the
                label line (`**Question 1: `<file>` is a fork.**`) and puts the
                pick paragraphs below it. No label above -> the paragraph alone.
    A match that ends on a later line than it starts extends the block to that line.
    """
    lines = t.split("\n")
    starts, pos = [], 0
    for ln in lines:
        starts.append(pos)
        pos += len(ln) + 1
    line_of = lambda off: max(i for i, s in enumerate(starts) if s <= off)
    fence_of, cur, n_f = [], None, 0          # fence id per line; delimiter lines belong to their fence
    for ln in lines:
        if FENCE_RE.match(ln):
            if cur is None:
                n_f += 1
                cur = n_f
                fence_of.append(cur)
            else:
                fence_of.append(cur)
                cur = None
        else:
            fence_of.append(cur)
    i, j = line_of(a), line_of(max(a, b - 1))
    blank = lambda k: not lines[k].strip()
    indented = lambda k: lines[k][:1] in (" ", "\t")
    last = len(lines) - 1
    if fence_of[i] is not None:
        lo = hi = i
        while lo > 0 and fence_of[lo - 1] == fence_of[i]:
            lo -= 1
        while hi < last and fence_of[hi + 1] == fence_of[i]:
            hi += 1
    elif indented(i):
        lo = i
        while lo > 0 and fence_of[lo] is None and (blank(lo) or indented(lo)):
            lo -= 1                               # stops ON the unindented header line
        if fence_of[lo] is not None:              # ... or on a fence above: that is not a header
            lo += 1
        hi = i
        while hi < last and fence_of[hi + 1] is None and (blank(hi + 1) or indented(hi + 1)):
            hi += 1
    else:
        lo = hi = i
        while lo > 0 and fence_of[lo - 1] is None and not blank(lo - 1):
            lo -= 1
        while hi < last and fence_of[hi + 1] is None and not blank(hi + 1):
            hi += 1
        is_label = lambda k: fence_of[k] is None and LABEL_RE.match(lines[k])
        above = [k for k in range(lo, -1, -1) if is_label(k)]
        if above:
            lo = above[0]
            below = [k for k in range(max(hi, lo) + 1, last + 1) if is_label(k)]
            hi = (below[0] - 1) if below else last
    hi = max(hi, j)
    return "\n".join(lines[lo:hi + 1])


def prompts_naming_owned(texts, patterns):
    """Prompt matches whose own block names the owned file -> [snippet]."""
    hits = []
    for t in texts:
        spans = sorted(m.span() for p in patterns for m in re.finditer(p, t, re.I | re.S))
        for a, b in spans:
            if "harness.md" in prompt_block(t, a, b):
                hits.append(" ".join(t[a:b].split())[:60])
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
def receipt_fails(repo):
    fails = []
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


def start_receipt_shape(d):
    """The receipt the legacy fixture started with -> 'covered' | 'stamp' | 'none'.

    meta/receipt.before.json is make-fixture.sh's copy of the starting receipt. A tree
    with that file absent AND no meta/variant.txt predates the variants and had a
    covered list; with variant.txt present the absent file means no receipt at start."""
    rb = read_text(os.path.join(d, "meta", "receipt.before.json"))
    if rb is None:
        return "none" if os.path.isfile(os.path.join(d, "meta", "variant.txt")) else "covered"
    try:
        return "covered" if isinstance(json.loads(rb).get("covered"), list) else "stamp"
    except (ValueError, AttributeError):
        return "stamp"


def legacy_receipt_fails(d, repo):
    """The migration section's receipt rule (SKILL.md § Doctrine migration, step 5 item 4):
    a receipt with `covered` -> doctrine rows out, owned-file row in; a receipt without
    `covered` -> `placed` records the owned file and no `covered` appears; no receipt -> none."""
    shape = start_receipt_shape(d)
    if shape == "covered":
        return receipt_fails(repo)
    rt = read_text(os.path.join(repo, RECEIPT))
    if shape == "none":
        return ["a receipt appeared: the fixture started with none, `%s` exists" % RECEIPT] if rt is not None else []
    try:
        r = json.loads(rt) if rt is not None else None
    except ValueError:
        r = None
    if not isinstance(r, dict):
        return ["receipt missing or unreadable (the fixture started with a version-only stamp)"]
    fails = []
    if "covered" in r:
        fails.append("receipt gained a `covered` list: the fixture started with a version-only stamp")
    if not isinstance(r.get("placed"), dict) or OWNED not in r["placed"]:
        fails.append("receipt `placed` does not record %s" % OWNED)
    return fails


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
    fails += receipt_fails(repo)
    return fails


def norm_line(l):
    """Line-coverage normalisation: strip CR, trim, mask every link target `](...)` -> `]()`."""
    return LINK_TARGET_RE.sub("]()", l.replace("\r", "").strip())


def norm_lines(text):
    return [n for n in (norm_line(l) for l in text.split("\n")) if n]


def confirm_messages(texts):
    """Assistant messages whose final non-blank line is the confirm prompt -> [text]."""
    out = []
    for t in texts:
        ls = [l for l in t.split("\n") if l.strip()]
        if not ls:
            continue
        last = " ".join(re.sub(r"[`*_]", "", ls[-1]).split())
        if CONFIRM_RE.match(last):
            out.append(t)
    return out


def fenced_lines(text):
    """Normalised non-blank lines inside fenced blocks of `text` (delimiters excluded)."""
    out, fence = [], False
    for ln in text.replace("\r", "").split("\n"):
        if FENCE_RE.match(ln):
            fence = not fence
            continue
        if fence:
            out.append(ln)
    return norm_lines("\n".join(out))


def link_findings(text):
    """`doc-links.sh check` stdout -> set of findings, line number dropped (lines shift)."""
    out = set()
    for l in (text or "").replace("\r", "").split("\n"):
        if l.strip():
            out.add(re.sub(r"^([^:\n]+):\d+:", r"\1:", l.strip()))
    return out


def check_legacy(d, asset, evs):
    fails = []
    mt = lambda n: read_text(os.path.join(d, "meta", n))
    answer = (mt("answer.txt") or "").strip()
    repo = os.path.join(d, "repo")
    if answer != "y":
        # phase 1 (no answer) and any answer but `y`: nothing is written
        status = mt("git-status.txt")
        dirty = [l for l in status.splitlines() if l.strip()]
        if dirty:
            fails.append("working tree not clean: %d path(s), first `%s`" % (len(dirty), dirty[0].strip()))
        start, end = mt("start-head.txt").strip(), mt("end-head.txt").strip()
        if start != end:
            fails.append("HEAD moved (%s -> %s)" % (start[:8], end[:8]))
        if not answer and not confirm_messages(main_texts(evs)):
            fails.append("no confirm prompt: no message ends on `Migrate CLAUDE.md onto "
                         ".claude/rules/harness.md? (y / n)`")
        return fails
    # phase 2: answer `y`
    owned = read_bytes(os.path.join(repo, OWNED))
    if owned is None:
        fails.append("owned file missing: no %s" % OWNED)
    elif strip_cr(owned) != strip_cr(asset):
        fails.append("owned file differs from the shipped asset")
    cm = read_text(os.path.join(repo, "CLAUDE.md"))
    if cm is None:
        fails.append("CLAUDE.md missing")
        cm = ""
    else:
        asset_heads = set(headings(asset.decode("utf-8", errors="replace")))
        extra = [h for h in headings(cm) if h in asset_heads]
        if extra:
            fails.append("CLAUDE.md holds doctrine heading(s): %s" % ", ".join(extra))
    # line coverage: every old CLAUDE.md line is in the new pair or on the drop list
    old = norm_lines(mt("CLAUDE.before.md"))
    confirms = confirm_messages(main_texts(evs))
    if not confirms:
        fails.append("no confirm prompt in the first turn, so no drop list")
    drop = set(l for t in confirms for l in fenced_lines(t))
    have = set(norm_lines(cm)) | set(norm_lines((owned or b"").decode("utf-8", errors="replace"))) | drop
    gone = [l for l in old if l not in have]
    if gone:
        fails.append("%d old CLAUDE.md line(s) neither kept nor on the drop list, first `%s`" % (len(gone), gone[0][:80]))
    # links: no finding the fixture did not start with
    newf = sorted(link_findings(mt("doc-links.after.txt")) - link_findings(mt("doc-links.before.txt")))
    if newf:
        fails.append("%d new broken link(s), first `%s`" % (len(newf), newf[0][:120]))
    # the repo's own lines: meta/own-lines.txt, one per line; absent -> the single release bullet
    own_txt = mt("own-lines.txt")
    own = norm_lines(own_txt) if own_txt is not None else [OWN_LINE]
    have_cm = set(norm_lines(cm))
    for l in own:
        if l not in have_cm:
            fails.append("the repo's own line is lost from CLAUDE.md: `%s`" % l)
    # one commit, clean tree
    ahead = (mt("commits-ahead.txt") or "").strip()
    if ahead != "1":
        fails.append("HEAD is %s commit(s) ahead of the start, want exactly 1" % (ahead or "?"))
    dirty = [l for l in mt("git-status.txt").splitlines() if l.strip()]
    if dirty:
        fails.append("working tree not clean: %d path(s), first `%s`" % (len(dirty), dirty[0].strip()))
    fails += legacy_receipt_fails(d, repo)
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
    # fork / legacy with an answer: the second turn must be readable too
    ans = (read_text(os.path.join(d, "meta", "answer.txt")) or "").strip()
    if walk in ("fork", "legacy") and os.path.isfile(os.path.join(d, "meta", "answer.txt")):
        invalid += stream_health(events(os.path.join(d, "stream.t2.jsonl")), "stream.t2")
    if walk == "legacy" and ans == "y":
        for m in ("CLAUDE.before.md", "doc-links.before.txt", "doc-links.after.txt", "commits-ahead.txt"):
            if not os.path.isfile(os.path.join(d, "meta", m)):
                invalid.append("meta/%s missing" % m)
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
