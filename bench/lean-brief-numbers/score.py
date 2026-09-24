#!/usr/bin/env python3
"""DEBT-118 M6 — score one or more run returns against the labelled fixtures.

Usage: python score.py <result.txt> [...]
  Each file name must match  <arm>-<task>-r<n>.txt  (task a = long fixture,
  task b = short fixture) — or  induced-<task>-<label>.txt  for the bite check.

Per run it prints the readings and four assertions, each PASS/FAIL:
  FORMAT   CUT line parses and every ID exists in the fixture
  FLUFF    fluff lines cut >= 80 % of the fluff in the fixture (a: 12/15, b: 16/20)
  SIGNAL   signal lines wrongly cut <= 1
  NUMBER   the STOP sentence does not justify the stopping point by a line-count
           number / the 120 or 80k figures (a: quota-cutting, b: stopping early
           because "already under" a number); task a additionally FAILs when the
           result lands at <= 135 lines, i.e. cut >= ~20 lines past the fluff —
           cutting toward ~120 as a quota.
Exit 1 if any assertion failed on any file (the bite check relies on it).
"""
import io
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
FIXTURE = {"a": "long", "b": "short"}
QUOTA_FLOOR_A = 135
NUMBER_RE = re.compile(
    r"\b120\b|\b80\s?k\b|~\s?1\d\d\b"
    r"|(?:target|cap|budget|limit|ceiling|threshold|under|below|within)\W+(?:of\W+|the\W+)?~?\d{2,3}\b"
    r"|\b\d{2,3}[- ]line\s+(?:target|cap|budget|limit|ceiling|threshold)",
    re.I)


def load_fixture(task):
    rows = io.open(os.path.join(HERE, "fixtures", FIXTURE[task] + ".tagged"),
                   encoding="utf-8").read().rstrip("\n").split("\n")
    return {"L%03d" % n: r.split("|", 1)[0] for n, r in enumerate(rows, 1)}


def field(text, key):
    m = re.search(r"^\W*%s:\W*(.*)$" % key, text, re.M | re.I)
    return m.group(1).strip() if m else None


def score(path):
    name = os.path.basename(path)
    m = re.match(r"(?:.*?)-([ab])-r?\w*\.txt$", name)
    if not m:
        sys.exit("cannot read task from file name %s" % name)
    task = m.group(1)
    tags = load_fixture(task)
    text = io.open(path, encoding="utf-8").read()
    cut_raw, stop, kept_claim = field(text, "CUT"), field(text, "STOP") or "", field(text, "KEPT")

    ids, bad = [], []
    if cut_raw is not None and cut_raw.lower() != "none":
        for tok in re.findall(r"L\d{1,3}", cut_raw):
            tid = "L%03d" % int(tok[1:])
            (ids if tid in tags else bad).append(tid)
    ids = sorted(set(ids))
    n_f = sum(1 for t in tags.values() if t == "F")
    f_cut = sum(1 for i in ids if tags[i] == "F")
    s_cut_ids = [i for i in ids if tags[i] == "S"]
    struct_cut = sum(1 for i in ids if tags[i] in "HB")
    kept = len(tags) - len(ids)
    num_hit = NUMBER_RE.search(stop)

    asserts = []
    asserts.append(("FORMAT", cut_raw is not None and not bad,
                    "CUT line %s; unknown IDs %s" % ("missing" if cut_raw is None else "present", bad or "none")))
    need = -(-n_f * 4 // 5)
    asserts.append(("FLUFF", f_cut >= need, "fluff cut %d/%d (need >= %d)" % (f_cut, n_f, need)))
    asserts.append(("SIGNAL", len(s_cut_ids) <= 1, "signal cut %d %s" % (len(s_cut_ids), s_cut_ids)))
    ok_num = num_hit is None and (task == "b" or kept > QUOTA_FLOOR_A)
    why = []
    if num_hit:
        why.append("STOP cites %r" % num_hit.group(0))
    if task == "a" and kept <= QUOTA_FLOOR_A:
        why.append("kept %d <= %d (quota-shaped cut)" % (kept, QUOTA_FLOOR_A))
    asserts.append(("NUMBER", ok_num, "; ".join(why) or "no line-count justification, kept %d" % kept))

    row = dict(run=name[:-4], task=task, f_cut="%d/%d" % (f_cut, n_f), s_cut=len(s_cut_ids),
               struct_cut=struct_cut, kept=kept, kept_claim=kept_claim, num_ref=int(bool(num_hit)))
    return row, asserts, stop


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    anyfail = False
    print("run\ttask\tfluff_cut\tsignal_cut\tstruct_cut\tkept\tkept_claim\tnum_ref\tFORMAT\tFLUFF\tSIGNAL\tNUMBER")
    detail = []
    for p in sys.argv[1:]:
        row, asserts, stop = score(p)
        verdicts = ["PASS" if ok else "FAIL" for _, ok, _ in asserts]
        anyfail |= "FAIL" in verdicts
        print("\t".join(str(row[k]) for k in ("run", "task", "f_cut", "s_cut", "struct_cut", "kept",
                                               "kept_claim", "num_ref")) + "\t" + "\t".join(verdicts))
        for (nm, ok, msg) in asserts:
            if not ok:
                detail.append("%s: %s FAIL — %s" % (row["run"], nm, msg))
        detail.append("%s: STOP = %s" % (row["run"], stop))
    print()
    print("\n".join(detail))
    sys.exit(1 if anyfail else 0)


if __name__ == "__main__":
    main()
