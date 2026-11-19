#!/usr/bin/env python3
"""DEBT-ymdg — score a carrier-equivalence round.

Usage: python3 score.py <runs-dir> [--machine]
  <runs-dir>  holds <arm>-<context>-r<rep>.jsonl (+ .probe/ dir; compact = one stream with bench_turn markers)
  --machine   print only `name<TAB>valid<TAB>behavior<TAB>loaded` rows (selftest uses it)

Readings per run: valid, loaded (load evidence), behavior (route line names a cluster).
"""
import io
import json
import os
import re
import sys

# --- BEHAVIOR PATTERNS (one place) -------------------------------------------
# behavior = 1 when the scored text matches ANY of these, case-insensitive:
#   - "cluster N"                      (the doctrine's routing table is named;
#                                       markdown/punctuation between word and digit
#                                       allowed — smoke: "**Cluster:** 1, bug" was
#                                       a false miss under the strict `cluster\s*N`)
#   - "route ... root cause|reproduce" (the route line states the bug route,
#                                       within 80 chars of the word "route")
BEHAVIOR_PATTERNS = [
    r"\bcluster\b\W{0,6}[0-9]\b",
    r"\broute\b.{0,80}\b(root cause|reproduce)",
]

HERE = os.path.dirname(os.path.abspath(__file__))
CARRIER_SUFFIX = {            # arm -> normalized path tail of the carrier file
    "claudemd": "/CLAUDE.md",
    "rules": "/.claude/rules/harness.md",
    "import": "/.claude/harness.md",
}


def task_prompt():
    with io.open(os.path.join(HERE, "task-prompt.txt"), encoding="utf-8") as fh:
        return fh.read().strip()


def events(path):
    out = []
    if not os.path.isfile(path):
        return out
    for line in io.open(path, encoding="utf-8", errors="replace"):
        line = line.strip()
        if not line:
            continue
        try:
            out.append(json.loads(line))
        except ValueError:
            pass
    return out


def blocks(ev):
    m = ev.get("message")
    c = m.get("content") if isinstance(m, dict) else None
    if isinstance(c, str):
        return [{"type": "text", "text": c}]
    # a bare string inside the list must not reach .get()
    return [b for b in c if isinstance(b, dict)] if isinstance(c, list) else []


def text_of(ev):
    return "".join(b.get("text", "") for b in blocks(ev) if b.get("type") == "text")


def dispatch_prompt(tool_use):
    """The Agent tool_use's input.prompt; '' when input is not a dict / prompt not a str."""
    inp = tool_use.get("input") if isinstance(tool_use, dict) else None
    p = inp.get("prompt") if isinstance(inp, dict) else None
    return p if isinstance(p, str) else ""


def read_lines(path):
    if not os.path.isfile(path):
        return None
    return [l.rstrip("\n") for l in io.open(path, encoding="utf-8", errors="replace") if l.strip()]


def score_run(runs_dir, name):
    m = re.match(r"^(claudemd|rules|import|none)-(main|subagent|compact|resume-compact)-r(\d+)$", name)
    if m is None:
        raise ValueError("unparseable run name: %s" % name)
    arm, ctx, _rep = m.group(1), m.group(2), "r" + m.group(3)
    notes, invalid = [], []
    evs = events(os.path.join(runs_dir, name + ".jsonl"))
    probe = os.path.join(runs_dir, name + ".probe")

    # compact = ONE process, three turns (drive-turns.py): bench_turn markers split
    # the stream. Everything scored below is the task turn (turn 3) only.
    pre_task, sid_main = evs, None
    if ctx == "compact":
        mk = [i for i, e in enumerate(evs) if e.get("type") == "bench_turn" and e.get("turn") == 3]
        if mk:
            pre_task, evs = evs[:mk[0]], evs[mk[0]:]
        else:
            pre_task, evs = evs, []
            notes.append("no bench_turn 3 marker")
        sid_main = next((e["session_id"] for e in pre_task if e.get("session_id")), None)

    # --- run health ------------------------------------------------------------
    result = [e for e in evs if e.get("type") == "result"]
    if not evs:
        invalid.append("no stream")
    elif not result:
        invalid.append("no result event")
    elif result[-1].get("is_error") or str(result[-1].get("subtype", "success")).startswith("error"):
        invalid.append("run errored (%s)" % result[-1].get("subtype"))

    # --- scored text -----------------------------------------------------------
    main_texts = [text_of(e) for e in evs if e.get("type") == "assistant"
                  and not e.get("parent_tool_use_id") and text_of(e).strip()]
    scored = ""
    if ctx == "subagent":
        sub = [text_of(e) for e in evs if e.get("type") == "assistant"
               and e.get("parent_tool_use_id") and text_of(e).strip()]
        if sub:
            scored = "\n".join(sub)
        else:
            # fallback: the Agent tool_result content handed back to the main turn
            for e in evs:
                if e.get("type") == "user" and not e.get("parent_tool_use_id"):
                    for b in blocks(e):
                        if b.get("type") == "tool_result":
                            c = b.get("content")
                            scored += c if isinstance(c, str) else "".join(
                                x.get("text", "") for x in c or [] if isinstance(x, dict))
            if scored:
                notes.append("FALLBACK: no forwarded subagent text; scored the Agent tool_result")
        # dispatch-prompt verbatim check
        tus = [b for e in evs if e.get("type") == "assistant" and not e.get("parent_tool_use_id")
               for b in blocks(e) if b.get("type") == "tool_use" and b.get("name") in ("Agent", "Task")]
        if len(tus) != 1:
            invalid.append("%d Agent dispatches (want 1)" % len(tus))
        elif dispatch_prompt(tus[0]).strip() != task_prompt():
            invalid.append("dispatch prompt is not the task verbatim")
    else:
        scored = main_texts[-1] if main_texts else ""
    if not scored.strip():
        invalid.append("no assistant text")

    # --- compaction marker --------------------------------------------------
    # compact: a compact_boundary BEFORE the task turn (stream order), or, when
    # the stream lacks one, a PostCompact line in compact.log (order unverified).
    # resume-compact (old three-process form): marker anywhere.
    clog = read_lines(os.path.join(probe, "compact.log")) or []
    marker_ts = None
    if ctx in ("compact", "resume-compact"):
        for l in clog:
            f = l.split()
            if f and (f[0] == "PostCompact" or (f[0] == "SessionStart" and len(f) > 1 and f[1] == "compact")):
                if len(f) > 3 and f[3].isdigit():
                    marker_ts = int(f[3]) if marker_ts is None else min(marker_ts, int(f[3]))
                elif marker_ts is None:
                    marker_ts = 0
        has_post = any(l.split()[:1] == ["PostCompact"] for l in clog)
        if ctx == "compact":
            before = any(e.get("subtype") == "compact_boundary" for e in pre_task)
            after = any(e.get("subtype") == "compact_boundary" for e in evs)
            if after:
                invalid.append("compact_boundary sits after the task turn started")
            elif not before and not has_post:
                invalid.append("no compaction marker before the task turn (compact_boundary / PostCompact)")
            elif not before:
                notes.append("PostCompact line only; order vs the task turn unverified")
        else:
            boundary = any(e.get("subtype") == "compact_boundary"
                           for p in (name + ".jsonl", name + ".t2.jsonl")
                           for e in events(os.path.join(runs_dir, p)))
            if marker_ts is None and not boundary:
                invalid.append("no compaction marker (compact.log / compact_boundary)")

    # --- load evidence ----------------------------------------------------------
    if arm == "none":
        loaded = "n/a"
    else:
        ilog = read_lines(os.path.join(probe, "instructions.log"))
        if not ilog:
            loaded = "unknown"
        else:
            rows = []
            for l in ilog:
                f = l.split("\t")
                if len(f) >= 3:
                    p = f[1].replace("\\", "/")
                    # the operator's own ~/.claude/CLAUDE.md is not the carrier
                    if p.endswith(CARRIER_SUFFIX[arm]) and "/.claude/CLAUDE.md" not in p:
                        ts = int(f[4]) if len(f) > 4 and f[4].isdigit() else None
                        rows.append((f[2], ts))
            if ctx not in ("compact", "resume-compact"):
                loaded = "1" if rows else "0"
                if ctx == "subagent" and rows:
                    notes.append("subagent shares the main session's load (hook logs no per-subagent line)")
            elif ctx == "compact":
                # one process, never restarted: a post-marker line IS a re-injection.
                # Only the main session's lines count (the compaction summariser logs
                # its own session id).
                allrows = []
                for l in ilog:
                    f = l.split("\t")
                    if len(f) > 4 and f[4].isdigit() and (sid_main is None or f[0] == sid_main):
                        allrows.append((f[1].replace("\\", "/"), f[2], int(f[4])))
                post_all = [r for r in allrows if marker_ts is not None and r[2] > marker_ts]
                post_car = [r for r in post_all if r[0].endswith(CARRIER_SUFFIX[arm]) and "/.claude/CLAUDE.md" not in r[0]]
                if not post_all:
                    loaded = "unknown"
                elif post_car:
                    loaded = "1"
                    notes.append("post-marker carrier load_reason=%s" % sorted({r[1] for r in post_car}))
                else:
                    loaded = "0"
                    notes.append("post-marker loads exist for other files only (reasons %s)" % sorted({r[1] for r in post_all}))
            else:
                post = [(r, ts) for r, ts in rows if marker_ts is not None and ts is not None and ts > marker_ts]
                if marker_ts is None:
                    loaded = "unknown"
                elif any("compact" in r for r, _ in post):
                    loaded = "1"
                elif post:
                    loaded = "resume-only"
                    notes.append("post-compaction load is the --resume process start (reason %s), not an in-process re-injection"
                                 % sorted({r for r, _ in post}))
                else:
                    loaded = "0"

    # --- behavior ---------------------------------------------------------------
    behavior = "-"
    if not invalid:
        hit = any(re.search(p, scored, re.I | re.S) for p in BEHAVIOR_PATTERNS)
        behavior = "1" if hit else "0"
    return {"name": name, "arm": arm, "ctx": ctx, "rep": _rep, "valid": "0" if invalid else "1",
            "loaded": loaded, "behavior": behavior, "note": "; ".join(invalid + notes)}


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    machine = "--machine" in sys.argv
    runs_dir = args[0]
    names = sorted(f[:-6] for f in os.listdir(runs_dir)
                   if re.match(r"^(claudemd|rules|import|none)-(main|subagent|compact|resume-compact)-r\d+\.jsonl$", f))
    rows = [score_run(runs_dir, n) for n in names]
    if machine:
        for r in rows:
            print("%s\t%s\t%s\t%s" % (r["name"], r["valid"], r["behavior"], r["loaded"]))
        return 0
    hdr = ["arm", "context", "rep", "valid", "loaded", "behavior", "note"]
    table = [hdr] + [[r["arm"], r["ctx"], r["rep"], r["valid"], r["loaded"], r["behavior"], r["note"]] for r in rows]
    w = [max(len(str(t[i])) for t in table) for i in range(6)]
    for t in table:
        print("  ".join(str(t[i]).ljust(w[i]) for i in range(6)) + "  " + t[6])
    io.open(os.path.join(runs_dir, "scores.tsv"), "w", encoding="utf-8").write(
        "\n".join("\t".join(map(str, t)) for t in table) + "\n")

    # --- summary ----------------------------------------------------------------
    print("\nMISSES PER CARRIER (valid runs only; behavior 0 = miss)")
    miss, nvalid = {}, {}
    for a in ("claudemd", "rules", "import", "none"):
        v = [r for r in rows if r["arm"] == a and r["valid"] == "1"]
        nvalid[a] = len(v)
        miss[a] = sum(1 for r in v if r["behavior"] == "0")
        print("  %-9s misses %d / %d valid (%d total runs)" % (a, miss[a], len(v), sum(1 for r in rows if r["arm"] == a)))
    base = miss["claudemd"]
    verdicts = []
    for a in ("rules", "import"):
        ok = miss[a] <= base + 1
        verdicts.append(ok)
        print("  PASS-RULE %-7s within one miss of claudemd (%d <= %d+1): %s" % (a, miss[a], base, "yes" if ok else "NO"))
    none_runs = [r for r in rows if r["arm"] == "none" and r["ctx"] == "main"]
    none_ok = len(none_runs) >= 2 and all(r["valid"] == "1" and r["behavior"] == "0" for r in none_runs)
    print("  PASS-RULE none      both control runs miss: %s (%d none/main runs)" % ("yes" if none_ok else "NO", len(none_runs)))
    bad = [r for r in rows if r["valid"] != "1" or r["loaded"] in ("unknown", "resume-only")]
    print("\nINVALID / UNKNOWN / RESUME-ONLY RUNS (%d)" % len(bad))
    for r in bad:
        print("  %s  valid=%s loaded=%s  %s" % (r["name"], r["valid"], r["loaded"], r["note"]))
    unexplained = [r for r in rows if r["valid"] != "1"]
    print("\nOVERALL: %s" % ("PASS" if all(verdicts) and none_ok and not unexplained else
                              "NOT PASS (see rows above; invalid runs need an explanation)"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
