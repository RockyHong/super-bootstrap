"""GAP-091 L6 — pull shell calls + final report out of one stream-json transcript.

Writes <prefix>.tools.tsv (seq, tool, command — every Bash/PowerShell call,
newlines folded to ' \n ') and <prefix>.result.txt (final report).

Usage: python3 extract.py <transcript.jsonl> <out-prefix>
"""
import io
import json
import sys


def main(src, prefix):
    rows, result = [], ""
    for line in io.open(src, encoding="utf-8", errors="replace"):
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        if ev.get("type") == "result":
            result = ev.get("result") or ""
        msg = ev.get("message")
        if not isinstance(msg, dict) or not isinstance(msg.get("content"), list):
            continue
        for b in msg["content"]:
            if isinstance(b, dict) and b.get("type") == "tool_use":
                inp = b.get("input") or {}
                cmd = inp.get("command") or inp.get("file_path") or inp.get("pattern") or ""
                rows.append((b.get("name", ""), str(cmd).replace("\t", " ").replace("\r", "").replace("\n", " \n ")))
    io.open(prefix + ".result.txt", "w", encoding="utf-8").write(result)
    with io.open(prefix + ".tools.tsv", "w", encoding="utf-8") as fh:
        fh.write("seq\ttool\tcommand\n")
        for i, (t, c) in enumerate(rows, 1):
            fh.write(f"{i}\t{t}\t{c}\n")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
