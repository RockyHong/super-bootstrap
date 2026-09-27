#!/usr/bin/env python3
# DEBT-122 multi-turn runner — scripted sessions x arms through ONE headless
# claude process per session (stream-json in/out), so UserPromptSubmit fires
# per turn and SessionStart fires once: the injection-frequency variable the
# single-prompt run-gap045.sh cannot separate.
# Usage: python bench/consult-hook/run-multiturn.py [arm ...]
#                             default arms: forcedeval-v2 forcedeval-v2-once
# Env:   SCRIPT_FILTER=<regex>  subset sessions by script id (smoke: '^S1$')
#        REP=<n>             replicate number — appends __r<n> to output names
#        FIXTURE_DIR=<dir>   run with cwd inside the decontaminated fixture
#                            (make-fixture.sh) — mandatory for scored runs;
#                            reset hermetically before every session.
#                            Channels + checklist: bench-decontamination.md
#        MODEL=<alias|id>    session model (default sonnet) — runs land in
#                            $RUNS_DIR/<model>/ so tiers never collide
#        RUNS_DIR=<dir>      raw-run root (default runs-multiturn/ beside this script)
#        TURN_TIMEOUT=<s>    kill a session whose turn yields no result (default 600)
# Scripts: scripts-multiturn.jsonl — {"script","turns":[probe-id,...]}, prompts
# resolved from probes-gap045.jsonl. Each user line is fed only after the prior
# turn's "result" event (batch-feeding drops turns); before each turn the driver
# writes {"type":"bench_turn","turn":k,"id":...} into the raw file — -p stream
# output has no user echo, so these markers are the scorer's turn boundaries.
# Output: $RUNS_DIR/<model>/<script>__<arm>[__r<rep>].jsonl (+ .err); written
# via .part and renamed only when every turn produced a result, so a present
# file means a complete session. Skips sessions whose output exists (resumable).
# Injection check: stream output carries SessionStart hook_response events but
# no UserPromptSubmit ones — per-turn UPS injection is visible only in the CLI
# session transcript (~/.claude/projects/<cwd-slug>/<session_id>.jsonl).
# Degrade path if Python is unavailable: bash coproc with the same loop.
import json, os, re, shutil, subprocess, sys, threading

try:
    sys.stdout.reconfigure(encoding="utf-8")  # Windows console codepage
except (AttributeError, ValueError):
    pass

ROOT = os.path.dirname(os.path.abspath(__file__))
MODEL = os.environ.get("MODEL", "sonnet")
RUNS = os.path.join(os.environ.get("RUNS_DIR") or os.path.join(ROOT, "runs-multiturn"), MODEL)
FIXTURE = os.environ.get("FIXTURE_DIR", "")
RUNCWD = FIXTURE or ROOT
REP = os.environ.get("REP", "")
FILTER = re.compile(os.environ.get("SCRIPT_FILTER", "."))
TURN_TIMEOUT = float(os.environ.get("TURN_TIMEOUT", "600"))
ARMS = sys.argv[1:] or ["forcedeval-v2", "forcedeval-v2-once"]

CLAUDE = shutil.which("claude")
if not CLAUDE:
    sys.exit("claude not on PATH")

def load_jsonl(path):
    with open(path, encoding="utf-8") as fh:
        return [json.loads(l) for l in fh if l.strip()]

prompts = {p["id"]: p["prompt"] for p in load_jsonl(os.path.join(ROOT, "probes-gap045.jsonl"))}
scripts = load_jsonl(os.path.join(ROOT, "scripts-multiturn.jsonl"))
os.makedirs(RUNS, exist_ok=True)

def reset_fixture():
    # hermetic fixture: revert tracked files, remove leftovers a prior session wrote
    if FIXTURE and os.path.isdir(os.path.join(RUNCWD, ".git")):
        subprocess.run(["git", "-C", RUNCWD, "checkout", "-q", "--", "."], check=False)
        subprocess.run(["git", "-C", RUNCWD, "clean", "-qfd"], check=False)

def run_session(script, arm, out):
    part = out + ".part"
    cmd = [CLAUDE, "--model", MODEL, "--settings", os.path.join(ROOT, f"arm-{arm}.json"),
           "-p", "--input-format", "stream-json", "--output-format", "stream-json", "--verbose"]
    reset_fixture()
    done = 0
    with open(part, "w", encoding="utf-8", newline="\n") as fo, \
         open(out + ".err", "w", encoding="utf-8") as fe:
        p = subprocess.Popen(cmd, cwd=RUNCWD, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                             stderr=fe, text=True, encoding="utf-8", errors="replace")
        for k, pid in enumerate(script["turns"], 1):
            fo.write(json.dumps({"type": "bench_turn", "turn": k, "id": pid}) + "\n")
            fo.flush()
            p.stdin.write(json.dumps({"type": "user", "message": {"role": "user", "content": prompts[pid]}}) + "\n")
            p.stdin.flush()
            timer = threading.Timer(TURN_TIMEOUT, p.kill)
            timer.start()
            got = False
            try:
                while True:
                    line = p.stdout.readline()
                    if not line:
                        break
                    fo.write(line if line.endswith("\n") else line + "\n")
                    try:
                        ev = json.loads(line)
                    except ValueError:
                        continue
                    if ev.get("type") == "result":
                        got = True
                        break
            finally:
                timer.cancel()
            if not got:
                print(f"      turn {k} ({pid}): no result — session aborted")
                break
            done = k
        try:
            p.stdin.close()
        except OSError:
            pass
        try:
            p.wait(timeout=60)
        except subprocess.TimeoutExpired:
            p.kill()
            p.wait()
    ok = done == len(script["turns"])
    if ok:
        os.replace(part, out)
    print(f"      exit={p.returncode} turns={done}/{len(script['turns'])}" + ("" if ok else f" (kept {part})"))

n = 0
for script in scripts:
    sid = script["script"]
    if not FILTER.search(sid):
        continue
    for arm in ARMS:
        out = os.path.join(RUNS, f"{sid}__{arm}" + (f"__r{REP}" if REP else "") + ".jsonl")
        if os.path.exists(out) and os.path.getsize(out) > 0:
            print(f"[skip] {out}")
            continue
        n += 1
        print(f"[{n}] {sid} / {arm}", flush=True)
        run_session(script, arm, out)
print(f"DONE — {n} new sessions in {RUNS}/")
