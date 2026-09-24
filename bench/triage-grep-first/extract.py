"""Pull the evidence out of one stream-json transcript.

Writes <prefix>.result.txt (the run's final report) and <prefix>.tools.tsv
(one row per tool call: seq, tool, target, offset, limit, result_chars).
result_chars is the length of the tool_result text the model received for
that call — the read-budget proxy (tokens ~ chars / 4).

Usage: python3 extract.py <transcript.jsonl> <out-prefix>
"""

import io
import json
import sys


def text_of(content):
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return "".join(
            (c.get("text") or "") if isinstance(c, dict) else str(c) for c in content
        )
    return ""


def main(src, prefix):
    calls = {}     # tool_use_id -> row
    order = []
    result = ""
    for line in io.open(src, encoding="utf-8", errors="replace"):
        line = line.strip()
        if not line:
            continue
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        t = ev.get("type")
        if t == "result":
            result = ev.get("result") or ""
        msg = ev.get("message")
        if not isinstance(msg, dict):
            continue
        content = msg.get("content")
        for block in content if isinstance(content, list) else []:
            if not isinstance(block, dict):
                continue
            if block.get("type") == "tool_use":
                inp = block.get("input") or {}
                target = (inp.get("file_path") or inp.get("pattern") or inp.get("command")
                          or inp.get("path") or "")
                row = {
                    "tool": block.get("name", ""),
                    "target": str(target).replace("\t", " ").replace("\n", " ")[:400],
                    "offset": inp.get("offset", ""),
                    "limit": inp.get("limit", ""),
                    "chars": 0,
                }
                calls[block.get("id")] = row
                order.append(block.get("id"))
            elif block.get("type") == "tool_result":
                row = calls.get(block.get("tool_use_id"))
                if row is not None:
                    row["chars"] = len(text_of(block.get("content")))
    io.open(prefix + ".result.txt", "w", encoding="utf-8").write(result)
    with io.open(prefix + ".tools.tsv", "w", encoding="utf-8") as fh:
        fh.write("seq\ttool\ttarget\toffset\tlimit\tresult_chars\n")
        for i, cid in enumerate(order, 1):
            r = calls[cid]
            fh.write(f"{i}\t{r['tool']}\t{r['target']}\t{r['offset']}\t{r['limit']}\t{r['chars']}\n")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
