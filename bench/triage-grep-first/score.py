"""DEBT-118 M4 — score triage runs. One TSV row per run + one line per failed assertion.

For every <tag>.card.md in <runs-dir> (tag = <card>-<arm>-r<n>), the card as
the run left it, plus <tag>.tools.tsv (extract.py):

ASSERTIONS (pass/fail, each must bite — see bite.sh):
  origin    the card's origin block is byte-identical to the fixture's (the
            agent's floor: append only, never rewrite)
  one_block exactly one `## Verdict — auto-fix|surface · YYYY-MM-DD` header
            appended after the origin block
  shape     the block carries every field its kind's template requires
            (agents/triage.md § Output formats)
  cause     the block's cause section names the true root cause:
              BUG-001  `_emit_period` AND `_rollover` AND an ordering word —
                       run() emits the period before the final rollover
                       settles the trailing held refund
              BUG-002  `dunning` AND a swapped-argument word — dunning.py
                       passes (locale, currency) into fmt_money(cents,
                       currency, locale)
READINGS (counted, not asserted):
  decoy     cause failed AND the section names the card's planted Prior
            (is_duplicate / SYMBOLS) — the plausible-but-wrong culprit
  budget    the block carries the `truncated at budget` surface exit
  tools / reads / greps / partial (Read with offset|limit) / read_tok
            (sum of Read result chars / 4) / intake_tok (sum of ALL tool
            result chars / 4 — catches file reads done through Bash `cat`,
            which Read-only counting misses) / whole_target (1 if the cause
            file was Read without offset/limit)

Usage: python3 score.py <runs-dir> [fixture-dir]
"""

import io
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))

HEADER_RE = re.compile(r"^## Verdict — (auto-fix|surface) · \d{4}-\d{2}-\d{2}\s*$", re.M)
ANY_VERDICT_RE = re.compile(r"^## Verdict\b", re.M)

AUTOFIX_FIELDS = [
    r"^\*\*Fix-shape:\*\*\s*(mechanical|systematic|design|prompt|product|ambiguous)\b",
    r"^\*\*Probe-deps:\*\*\s*\S",
    r"^\*\*Execution:\*\*\s*(inline|phased\(skip:[^)]*\)|full)\s*—\s*\S",
    r"^### Repro \(pinned\)",
    r"^### Root cause \(verified\)",
    r"^### Files \(fix surface\)",
    r"^### Doc Impact",
    r"^### Test Strategy:\s*(unit|e2e)\b",
]
SURFACE_FIELDS = [
    r"^### Findings",
    r"^- root cause:",
    r"^- scope reach:",
    r"^- attempted:",
    r"^### Decision needed",
    r"^- recommendation:",
    r"^- settles by:",
]

CAUSE = {
    "BUG-001": {
        "all": [r"_emit_period", r"_rollover", r"\b(before|after|order|ordering|ahead|sequence|too late|already)\b"],
        "decoy": r"is_duplicate",
        "target": "tally/engine.py",
    },
    "BUG-002": {
        "all": [r"dunning", r"\b(swap\w*|order|transpos\w*|revers\w*|wrong position|positional)\b"],
        "decoy": r"SYMBOLS",
        "target": "tally/reports/dunning.py",
    },
}


def section(block, kind):
    """The cause-bearing text: auto-fix -> Root cause section; surface -> Findings."""
    head = r"^### Root cause \(verified\)" if kind == "auto-fix" else r"^### Findings"
    m = re.search(head, block, re.M)
    if not m:
        return ""
    rest = block[m.end():]
    nxt = re.search(r"^### ", rest, re.M)
    return rest[: nxt.start()] if nxt else rest


def read_tools(path):
    rows = []
    if not os.path.exists(path):
        return rows
    lines = io.open(path, encoding="utf-8").read().splitlines()[1:]
    for l in lines:
        p = l.split("\t")
        if len(p) < 6:
            continue
        rows.append({"tool": p[1], "target": p[2].replace("\\", "/"), "offset": p[3], "limit": p[4],
                     "chars": int(p[5] or 0)})
    return rows


def score(tag, card_text, origin, tools):
    card = tag.split("-")[0] + "-" + tag.split("-")[1]
    fails = []
    # normalise line endings — a CRLF checkout is not a rewrite
    card_text = card_text.replace("\r\n", "\n")
    origin = origin.replace("\r\n", "\n")

    ok_origin = card_text.startswith(origin.rstrip("\n"))
    if not ok_origin:
        fails.append("origin: card origin block was rewritten, not appended to")
    appended = card_text[len(origin.rstrip("\n")):] if ok_origin else card_text

    headers = HEADER_RE.findall(appended)
    all_v = ANY_VERDICT_RE.findall(appended)
    ok_one = len(headers) == 1 and len(all_v) == 1
    if not ok_one:
        fails.append(f"one_block: {len(headers)} well-formed / {len(all_v)} total verdict headers (want 1/1)")
    kind = headers[0] if headers else ""
    m = HEADER_RE.search(appended)
    block = appended[m.start():] if m else appended

    missing = []
    fields = AUTOFIX_FIELDS if kind == "auto-fix" else SURFACE_FIELDS if kind == "surface" else []
    for f in fields:
        if not re.search(f, block, re.M):
            missing.append(f)
    ok_shape = bool(kind) and not missing
    if not ok_shape:
        fails.append("shape: " + ("no verdict kind" if not kind else "missing " + " | ".join(missing)))

    rub = CAUSE[card]
    sec = section(block, kind)
    miss_c = [p for p in rub["all"] if not re.search(p, sec, re.I)]
    ok_cause = bool(sec) and not miss_c
    if not ok_cause:
        fails.append("cause: cause section lacks " + (" & ".join(miss_c) if sec else "(no cause section)"))
    decoy = int((not ok_cause) and bool(re.search(rub["decoy"], sec)))
    budget = int(bool(re.search(r"truncated at budget", block, re.I)))

    reads = [t for t in tools if t["tool"] == "Read"]
    greps = [t for t in tools if t["tool"] == "Grep"]
    partial = [t for t in reads if t["offset"] or t["limit"]]
    read_tok = sum(t["chars"] for t in reads) // 4
    intake_tok = sum(t["chars"] for t in tools) // 4
    whole = int(any(t["target"].endswith(rub["target"]) and not (t["offset"] or t["limit"]) for t in reads))

    row = [tag, kind or "-", int(ok_origin), int(ok_one), int(ok_shape), int(ok_cause), decoy, budget,
           len(tools), len(reads), len(greps), len(partial), read_tok, intake_tok, whole]
    return row, fails


COLS = ["run", "kind", "origin", "one_block", "shape", "cause", "decoy", "budget",
        "tools", "reads", "greps", "partial", "read_tok", "intake_tok", "whole_target"]


def main(runs_dir, fixture_dir):
    print("\t".join(COLS))
    all_fails = []
    for name in sorted(os.listdir(runs_dir)):
        if not name.endswith(".card.md"):
            continue
        tag = name[: -len(".card.md")]
        card = "-".join(tag.split("-")[:2])
        origin = io.open(os.path.join(fixture_dir, "docs", "work", card + ".md"), encoding="utf-8").read()
        text = io.open(os.path.join(runs_dir, name), encoding="utf-8").read()
        tools = read_tools(os.path.join(runs_dir, tag + ".tools.tsv"))
        row, fails = score(tag, text, origin, tools)
        print("\t".join(str(x) for x in row))
        all_fails += [f"FAIL {tag} {f}" for f in fails]
    for f in all_fails:
        print(f)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, "fixture"))
