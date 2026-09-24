#!/usr/bin/env python3
"""DEBT-118 M1+M2 — score one fallback-lane board against the script lane's board.

Usage: python score.py <mode> <golden.md> <board.md> [<reads.txt>] [--header]
Prints one TSV row (with --header, the header line first).

Oracle = render-board.py's board for the same fixture + mode (make-fixture.sh re-renders
it at the run's date; it equals bench/todo-board/expected/<mode>.md bar the title date).

CLASSIFICATION (per golden row, action / intent / stage bucket):
  A golden row "agrees" when the board holds a row for the same item and
    needme — it sits under the same `## ` group (the intent bucket) with the same
             action verb (text before the first `:`);
    full   — same action verb, same Stage cell, same Blocker cell (Blocker is the
             flat board's only intent signal: `user` <=> a Discuss row).
  Item identity: the ID cell; for a `—` row (test queue) the first distinctive word of
  the golden action's title; for an Uncategorized row the file's basename.
  rows      = k/n golden rows that agree
  drain     = 1 when the `Drainable: N` count equals the golden's (needme; drained rows
              are classified Cloud and collapse to this count — their only trace)
  pending   = 1 when the `pending unblock: n` line equals the golden's (hard-block gate)

SHAPE (each 0/1):
  title     first non-blank line is `# To-Do — YYYY-MM-DD`
  heads     the ordered `## ` heading list equals the golden's
  cols      every table's header cells equal the golden table's under the same heading
  invented  0 when any board table row matches no golden row, or two rows match one item
  reco      0 when a line reads as a recommendation (recommend / best next / suggest /
            start with / next up / I'd / you should)
  footer    the lines after the last table equal the golden's
  shape     = sum of the six

WIDTH (outside shape, so shape stays comparable with the DEBT-118 runs):
  cut       k/n board Action cells at most 60 characters (scaffolds.md § Sheet columns:
            hard-cut to 60, the 60th being `…`); BUG-074 — the rule rides the preamble

SPEC READ:
  spec      1 when reads.txt shows a Read of classify-actionable.md
  spec_n    how many times it was Read (the agent says once)
"""
import io
import os
import re
import sys

args = [a for a in sys.argv[1:] if a != "--header"]
header = "--header" in sys.argv
mode, golden_p, board_p = args[:3]
reads_p = args[3] if len(args) > 3 else None

COLS = ["rows", "drain", "pending", "title", "heads", "cols", "invented", "reco",
        "footer", "shape", "cut", "spec", "spec_n", "misses"]


def load(p):
    return io.open(p, encoding="utf-8").read().replace("\r\n", "\n")


def cells(line):
    return [c.strip() for c in line.strip().strip("|").split("|")]


def parse(text):
    """-> (headings, tables{heading: (header_cells, [row_cells])}, tail_lines, lines)"""
    lines = text.split("\n")
    heads, tables, cur = [], {}, None
    last_table_line = -1
    i = 0
    while i < len(lines):
        l = lines[i]
        if l.startswith("## "):
            cur = l[3:].strip()
            heads.append(cur)
        elif l.lstrip().startswith("|"):
            hdr = cells(l)
            rows = []
            i += 1
            while i < len(lines) and lines[i].lstrip().startswith("|"):
                c = cells(lines[i])
                if not all(re.fullmatch(r":?-+:?", x) for x in c if x):
                    rows.append(c)
                i += 1
            last_table_line = i - 1
            tables[cur] = (hdr, rows)
            continue
        i += 1
    tail = [l.strip() for l in lines[last_table_line + 1:] if l.strip()]
    return heads, tables, tail, lines


def col(hdr, row, name):
    try:
        return row[hdr.index(name)]
    except (ValueError, IndexError):
        return ""


def verb(action):
    return action.split(":", 1)[0].strip()


def item_key(group, hdr, row, golden_keys=None):
    """Identity of a row. Golden keys are computed first; board rows resolve against them."""
    if group == "Uncategorized":
        return ("U", os.path.basename(col(hdr, row, "Action").strip("` ")))
    rid = col(hdr, row, "ID")
    if rid and rid not in ("—", "-"):
        return ("ID", rid)
    act = col(hdr, row, "Action").lower()
    if golden_keys is None:  # golden side: first distinctive title word
        title = act.split(":", 1)[-1]
        word = next(w for w in re.findall(r"[a-z][a-z-]{3,}", title))
        return ("Q", word)
    for k in golden_keys:  # board side: resolve against the golden words
        if k[0] == "Q" and k[1] in act:
            return k
    return ("Q?", act)


def rows_of(tables, golden_keys=None):
    out = []
    for g, (hdr, rows) in tables.items():
        for r in rows:
            out.append((item_key(g, hdr, r, golden_keys), g, hdr, r))
    return out


def count(lines, pat):
    for l in lines:
        m = re.match(pat, l.strip())
        if m:
            return m.group(1)
    return None


g_heads, g_tables, g_tail, g_lines = parse(load(golden_p))
b_text = load(board_p)
b_heads, b_tables, b_tail, b_lines = parse(b_text)

g_rows = rows_of(g_tables)
g_keys = [k for k, _, _, _ in g_rows]
b_rows = rows_of(b_tables, g_keys)
b_by_key = {}
for k, g, h, r in b_rows:
    b_by_key.setdefault(k, []).append((g, h, r))

agree, misses = 0, []
for k, g, h, r in g_rows:
    hits = b_by_key.get(k, [])
    ok = False
    if hits:
        bg, bh, br = hits[0]
        if g == "Uncategorized":
            ok = bg == "Uncategorized"
        elif mode == "needme":
            ok = bg == g and verb(col(bh, br, "Action")) == verb(col(h, r, "Action"))
        else:
            ok = (verb(col(bh, br, "Action")) == verb(col(h, r, "Action"))
                  and col(bh, br, "Stage") == col(h, r, "Stage")
                  and col(bh, br, "Blocker") == col(h, r, "Blocker"))
    if ok:
        agree += 1
    else:
        misses.append(k[1])

drain_pat = r"Drainable:\s*(\d+)"
pend_pat = r"pending unblock:\s*(\d+)"
drain = 1 if mode != "needme" or count(b_lines, drain_pat) == count(g_lines, drain_pat) else 0
pending = 1 if count(b_lines, pend_pat) == count(g_lines, pend_pat) else 0

first = next((l for l in b_lines if l.strip()), "")
title = 1 if re.fullmatch(r"# To-Do — \d{4}-\d{2}-\d{2}", first.strip()) else 0
heads = 1 if b_heads == g_heads else 0
cols = 1
for gname, (ghdr, _) in g_tables.items():
    if gname not in b_tables or b_tables[gname][0] != ghdr:
        cols = 0
invented = 1
if any(k not in g_keys for k, _, _, _ in b_rows) or any(len(v) > 1 for v in b_by_key.values()):
    invented = 0
reco = 0 if re.search(r"(?im)recommend|best next|suggest|start with|next up|\bI'd\b|you should",
                      b_text) else 1
footer = 1 if b_tail == g_tail else 0
shape = title + heads + cols + invented + reco + footer
acts = [col(h, r, "Action") for _, _, h, r in b_rows]
cut = "%d/%d" % (sum(1 for a in acts if len(a) <= 60), len(acts))

spec = spec_n = 0
if reads_p and os.path.exists(reads_p):
    spec_n = sum(1 for l in load(reads_p).split("\n")
                 if l.startswith("Read\t") and "classify-actionable.md" in l)
    spec = 1 if spec_n else 0

vals = ["%d/%d" % (agree, len(g_rows)), drain, pending, title, heads, cols, invented, reco,
        footer, "%d/6" % shape, cut, spec, spec_n, ",".join(misses) or "-"]
if header:
    print("\t".join(COLS))
print("\t".join(str(v) for v in vals))
