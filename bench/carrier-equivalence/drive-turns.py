#!/usr/bin/env python3
"""DEBT-ymdg — feed several user turns to ONE headless claude process.

Usage: drive-turns.py <out.jsonl> <cwd> <prompt-file>... -- <claude args...>
Shape reused from bench/consult-hook/run-multiturn.py: `-p --input-format
stream-json`, each user line sent only after the previous turn's `result` event
(batch-feeding drops turns), and a {"type":"bench_turn","turn":k} marker written
into the output before each turn — -p stream output has no user echo, so the
markers are the scorer's turn boundaries. The prompt files hold the turns
verbatim (a file keeps "/compact" away from MSYS path rewriting). Output is
written whole; exit status 0 only if every turn produced a result.
"""
import json
import subprocess
import sys
import threading

args = sys.argv[1:]
sep = args.index("--")
out, cwd, prompt_files, claude_cmd = args[0], args[1], args[2:sep], args[sep + 1:]
prompts = [open(f, encoding="utf-8").read().strip() for f in prompt_files]
TURN_TIMEOUT = 600

import shutil
claude_cmd[0] = shutil.which(claude_cmd[0]) or claude_cmd[0]
cmd = claude_cmd + ["-p", "--input-format", "stream-json"]
done = 0
with open(out, "w", encoding="utf-8", newline="\n") as fo, \
        open(out + ".err", "w", encoding="utf-8") as fe:
    p = subprocess.Popen(cmd, cwd=cwd, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                         stderr=fe, text=True, encoding="utf-8", errors="replace")
    assert p.stdin is not None and p.stdout is not None
    for k, text in enumerate(prompts, 1):
        fo.write(json.dumps({"type": "bench_turn", "turn": k, "prompt": text}) + "\n")
        fo.flush()
        p.stdin.write(json.dumps({"type": "user", "message": {"role": "user", "content": text}}) + "\n")
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
            print("turn %d: no result — session aborted" % k)
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
print("exit=%s turns=%d/%d" % (p.returncode, done, len(prompts)))
sys.exit(0 if done == len(prompts) else 1)
