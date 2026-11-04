#!/usr/bin/env python3
"""score.py — (s1): a branch-out precedes the first edit, read off a run's ordered tool calls.

Usage: python bench/spike-route/score.py <stream.jsonl>
An edit is an Edit or Write call, or a Bash command that writes a file. A write under docs/work/ is a card,
which the excerpt's route may ask for, and does not count. Exits 1 on FAIL.
"""
import json
import re
import sys

BRANCH = re.compile(r"git\s+(?:-C\s+\S+\s+)?(?:switch\s+(?:-c|--create)|checkout\s+-b|worktree\s+add|branch\s+(?!-)\S+)")
WRITE = re.compile(r"sed\s+-i|\btee\b|(?<![0-9&])>>?\s*(?!/dev/null|&)[\w./\"'-]+|\bcp\s|\bmv\s")


def is_card(text):
    return "docs/work/" in text.replace("\\", "/")


def events(path):
    for raw in open(path, encoding="utf-8", errors="replace"):
        try:
            rec = json.loads(raw)
        except ValueError:
            continue
        if rec.get("type") != "assistant":
            continue
        for block in rec.get("message", {}).get("content", []):
            if block.get("type") != "tool_use":
                continue
            name, args = block.get("name"), block.get("input", {})
            if name in ("Edit", "Write"):
                target = args.get("file_path", "")
                if not is_card(target):
                    yield "edit", f"{name} {target}"
            elif name == "Bash":
                cmd = args.get("command", "")
                found = []
                match = BRANCH.search(cmd)
                if match:
                    found.append((match.start(), "branch"))
                for match in WRITE.finditer(cmd):
                    if not is_card(match.group(0)):
                        found.append((match.start(), "edit"))
                        break
                for _, kind in sorted(found):
                    yield kind, cmd.splitlines()[0][:120] if cmd else ""


def main():
    seq = list(events(sys.argv[1]))
    first_branch = next((i for i, e in enumerate(seq) if e[0] == "branch"), None)
    first_edit = next((i for i, e in enumerate(seq) if e[0] == "edit"), None)
    if first_branch is None:
        print(f"FAIL (s1) no branch-out in the run; first edit: {seq[first_edit][1] if first_edit is not None else 'none'}")
        return 1
    if first_edit is None:
        print("FAIL (s1) the run branched and edited nothing")
        return 1
    if first_edit < first_branch:
        print(f"FAIL (s1) an edit precedes the branch-out: {seq[first_edit][1]}")
        return 1
    print(f"PASS (s1) branched before the first edit: {seq[first_branch][1]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
