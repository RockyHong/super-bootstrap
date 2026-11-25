#!/usr/bin/env python3
"""DEBT-sxck — score run returns against each item's governed behavior.

Usage: python score.py <result.txt> [...]
  Each file name must match  <item>-<arm>-r<n>.txt  (item a | b | c | e) —
  or  induced-<item>-<label>.txt  for the bite check.

Assertions per item (Plan step 3), each PASS/FAIL:
  a  FORMAT     a `--- SECTION ---` … `--- END ---` block is present
     NODATE     the section holds no date / year / month name (no when-decided)
     NOWHY      no incident / outage / retro / INC-42 back-story (no why-decided)
     NODECIDED  no decision-narrative verb (decided / agreed / chose / opted …)
     CONSTRAINT the constraint itself survives (single-threaded)
  b  FORMAT     at least one `FILE:` line
     OWNFILE    a new rule file under .claude/rules/ other than the four existing ones
     NOHARNESS  no edit to .claude/rules/harness.md
     PATHS      the new rule's frontmatter keys on `paths:` (not `globs:`) and names migrations
  c  FORMAT     DOC, STATUS and the section block are present
     DOC        docs/architecture.md classified state
     STATUS     its `## Status` section classified state
     OVERWRITE  the Stripe line is overwritten in place: no "in progress", no date,
                no was/previously/formerly/no longer/used to/arrow note; other rows kept
  e  FORMAT     a `FILE:` line and a TEXT block are present
     WHERE      the edited file is CLAUDE.md, not .claude/rules/harness.md
     TAKEOVER   the added line is marked as taking over the doctrine line it overrides
An item's governed behavior passes when every assertion of that item passes.
Exit 1 if any assertion failed on any file (the bite check relies on it).
"""
import io
import os
import re
import sys

DATE_RE = re.compile(
    r"\b(19|20)\d\d\b|\b\d{1,2}/\d{1,2}\b"
    r"|\b(jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*\.?\s+\d"
    r"|\b(january|february|march|april|june|july|august|september|october|november|december)\b"
    r"|\b(yesterday|today|last (week|month|quarter)|recently)\b", re.I)
WHY_RE = re.compile(r"INC-?\d+|\bincident|\boutage|\bretro\b|retrospective|post-?mortem|took down|brought down", re.I)
DECIDED_RE = re.compile(r"\bdecided\b|\bdecision (was|made)\b|\bagreed\b|\bchose\b|\bopted\b|\bwe went\b|\bresolved to\b", re.I)
CHRON_RE = re.compile(r"\bwas\b|\bpreviously\b|\bformerly\b|\bno longer\b|\bused to\b|→|->|\bmigrated (on|from)\b", re.I)
TAKEOVER_RE = re.compile(r"takes? over|overrid|supersed|replac|instead of|wins over", re.I)
EXISTING = {"index.md", "harness.md", "dimension-discipline.md", "ssot-doc-link.md"}


def block(text, start, end="--- END ---"):
    m = re.search(r"^\W*%s\W*$(.*?)^\W*%s\W*$" % (re.escape(start), re.escape(end)), text, re.M | re.S)
    return m.group(1).strip("\n") if m else None


def field(text, key):
    m = re.search(r"^\W*%s:\W*(.*)$" % key, text, re.M | re.I)
    return m.group(1).strip() if m else None


def hit(rx, s):
    m = rx.search(s or "")
    return m.group(0) if m else None


def score_a(text):
    sec = block(text, "--- SECTION ---")
    s = sec or ""
    d, w, k = hit(DATE_RE, s), hit(WHY_RE, s), hit(DECIDED_RE, s)
    return [
        ("FORMAT", sec is not None, "section block %s" % ("present" if sec is not None else "missing")),
        ("NODATE", sec is not None and d is None, "date token %r" % d),
        ("NOWHY", sec is not None and w is None, "back-story token %r" % w),
        ("NODECIDED", sec is not None and k is None, "decision verb %r" % k),
        ("CONSTRAINT", bool(re.search(r"single[- ]thread", s, re.I)), "single-threaded constraint %s"
         % ("kept" if re.search(r"single[- ]thread", s, re.I) else "missing")),
    ]


def files_b(text):
    parts = re.split(r"^\W*FILE:\s*`?([^`\s]+)`?.*$", text, flags=re.M)
    return [(parts[i].strip(), parts[i + 1]) for i in range(1, len(parts) - 1, 2)]


def score_b(text):
    fs = files_b(text)
    rules = [(p, c) for p, c in fs if re.search(r"(^|/)\.claude/rules/[^/]+\.md$", p)]
    new = [(p, c) for p, c in rules if os.path.basename(p) not in EXISTING]
    harness = [p for p, _ in fs if os.path.basename(p) == "harness.md"]
    ok_paths, why = False, "no new rule file"
    if new:
        c = new[0][1]
        fm = re.search(r"^\s*---\s*$(.*?)^\s*---\s*$", c, re.M | re.S)
        fmt = fm.group(1) if fm else ""
        has_paths = re.search(r"^\s*paths\s*:", fmt, re.M) is not None
        has_globs = re.search(r"^\s*globs\s*:", fmt, re.M) is not None
        names_mig = "migrations" in fmt
        ok_paths = bool(fm) and has_paths and not has_globs and names_mig
        why = "frontmatter %s; paths: %s; globs: %s; names migrations: %s" % (
            "present" if fm else "missing", has_paths, has_globs, names_mig)
    return [
        ("FORMAT", bool(fs), "FILE lines %d" % len(fs)),
        ("OWNFILE", bool(new), "new rule files %s (all files %s)" % ([p for p, _ in new], [p for p, _ in fs])),
        ("NOHARNESS", not harness, "harness.md edited: %s" % (harness or "no")),
        ("PATHS", ok_paths, why),
    ]


def score_c(text):
    doc, status = field(text, "DOC"), field(text, "STATUS")
    sec = block(text, "--- SECTION ---")
    s = sec or ""
    lines = [l for l in s.split("\n") if l.strip()]
    stripe = [l for l in lines if re.search(r"stripe|payment", l, re.I)]
    probs = []
    if not stripe:
        probs.append("no payments row")
    for l in stripe:
        if re.search(r"in progress", l, re.I):
            probs.append("still 'in progress'")
        if hit(DATE_RE, l):
            probs.append("date %r" % hit(DATE_RE, l))
        if hit(CHRON_RE, l):
            probs.append("chronicle %r" % hit(CHRON_RE, l))
    if not re.search(r"elasticsearch", s, re.I):
        probs.append("search row dropped")
    if not re.search(r"mobile push", s, re.I):
        probs.append("mobile row dropped")
    isstate = lambda v: bool(v) and re.match(r"\W*state\b", v, re.I) is not None
    return [
        ("FORMAT", doc is not None and status is not None and sec is not None,
         "DOC %s, STATUS %s, section %s" % (doc is not None, status is not None, sec is not None)),
        ("DOC", isstate(doc), "DOC = %r" % doc),
        ("STATUS", isstate(status), "STATUS = %r" % status),
        ("OVERWRITE", sec is not None and not probs, "; ".join(probs) or "overwritten in place"),
    ]


def score_e(text):
    f = field(text, "FILE")
    body = block(text, "--- TEXT ---")
    base = os.path.basename((f or "").strip("`* ")) if f else ""
    t = hit(TAKEOVER_RE, body or "")
    return [
        ("FORMAT", f is not None and body is not None, "FILE %s, TEXT %s" % (f is not None, body is not None)),
        ("WHERE", base == "CLAUDE.md", "FILE = %r" % f),
        ("TAKEOVER", t is not None, "takeover marker %r" % t),
    ]


SCORERS = {"a": score_a, "b": score_b, "c": score_c, "e": score_e}


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    anyfail = False
    rows, detail = [], []
    for p in sys.argv[1:]:
        name = os.path.basename(p)[:-4]
        m = re.match(r"(?:induced-)?([abce])-", name)
        if not m:
            sys.exit("cannot read item from file name %s" % name)
        item = m.group(1)
        asserts = SCORERS[item](io.open(p, encoding="utf-8").read())
        fails = [nm for nm, ok, _ in asserts if not ok]
        anyfail |= bool(fails)
        rows.append("%s\t%s\t%s\t%s" % (name, item, "PASS" if not fails else "FAIL",
                                        " ".join("%s=%s" % (nm, "PASS" if ok else "FAIL") for nm, ok, _ in asserts)))
        for nm, ok, msg in asserts:
            if not ok:
                detail.append("%s: %s FAIL — %s" % (name, nm, msg))
    print("run\titem\tgoverned\tassertions")
    print("\n".join(rows))
    if detail:
        print()
        print("\n".join(detail))
    sys.exit(1 if anyfail else 0)


if __name__ == "__main__":
    main()
