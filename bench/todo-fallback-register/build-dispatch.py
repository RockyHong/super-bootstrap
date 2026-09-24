#!/usr/bin/env python3
"""Build one arm's dispatch inputs the way `skills/todo/SKILL.md` § Execution — dispatch lane does.

Writes, under <out-dir>:
  agents.json          --agents payload: the arm's `agents/todo.md` body as the `todo` agent
  prompt-<mode>.txt    the dispatch prompt per mode, built from THIS arm's SKILL.md template

Template steps mirrored (SKILL.md § Execution — dispatch lane, Steps 2-3):
  - the fenced block after `**Dispatch prompt template:**` is the template;
  - `{needme | discuss | ...}` -> the resolved mode;
  - `{classify_spec_path}` -> the resolved absolute spec path (never its contents);
  - the scaffold slot -> what that arm's slot text names, verbatim from `assets/scaffolds.md`:
    the pre-BUG-074 slot (`current` / `proposed`) -> the chosen-mode section alone; the shipped
    slot -> the preamble (everything above the first `### ` mode heading) + the chosen-mode section;
  - `{any user-supplied filter ...}` -> nothing (bare invocation, no user filter).

Usage: python build-dispatch.py <arm-dir> <scaffolds.md> <spec-abs-path> <out-dir> <mode>...
"""
import io
import json
import os
import re
import sys

arm_dir, scaffolds_path, spec_path, out_dir = sys.argv[1:5]
modes = sys.argv[5:]


def read(p):
    return io.open(p, encoding="utf-8").read()


skill = read(os.path.join(arm_dir, "SKILL.md"))
m = re.search(r"\*\*Dispatch prompt template:\*\*\s*\n```\n(.*?)\n```", skill, re.S)
if not m:
    sys.exit("FATAL: no dispatch template in %s" % arm_dir)
template = m.group(1)

scaffolds = read(scaffolds_path).splitlines(keepends=True)


def preamble():
    """Lines above the first `### ` mode heading (macro header, § Sheet columns)."""
    end = next(i for i, l in enumerate(scaffolds) if l.startswith("### "))
    return "".join(scaffolds[:end]).rstrip("\n")


def section(title):
    """Lines from `### <title>` up to (not including) the next `### ` heading."""
    start = next(i for i, l in enumerate(scaffolds) if l.startswith("### " + title))
    end = next((i for i in range(start + 1, len(scaffolds)) if scaffolds[i].startswith("### ")),
               len(scaffolds))
    return "".join(scaffolds[start:end]).rstrip("\n")


SECTION = {"needme": "Need-me", "full": "Full", "discuss": "Discuss", "cloud": "Cloud",
           "device": "Device", "harness": "Harness"}

# scaffold slot text -> builder; an arm carries exactly one of these slots
SLOTS = {
    # pre-BUG-074: chosen-mode section only
    "{scaffold for chosen mode from assets/scaffolds.md, copied verbatim}":
        lambda mode: section(SECTION[mode]),
    # shipped: preamble + chosen-mode section
    "{assets/scaffolds.md preamble + chosen-mode section, copied verbatim}":
        lambda mode: preamble() + "\n\n" + section(SECTION[mode]),
}
slot = [s for s in SLOTS if s in template]
if len(slot) != 1:
    sys.exit("FATAL: expected exactly one known scaffold slot in %s, found %d" % (arm_dir, len(slot)))
slot = slot[0]

os.makedirs(out_dir, exist_ok=True)
for mode in modes:
    p = template
    for old, new in [
        ("{needme | discuss | cloud | device | harness | full}", mode),
        ("{classify_spec_path}", spec_path),
        (slot, SLOTS[slot](mode)),
        ("{any user-supplied filter or context appended unchanged}\n\n", ""),
    ]:
        if old not in p:
            sys.exit("FATAL: template slot missing: %r" % old)
        p = p.replace(old, new)
    io.open(os.path.join(out_dir, "prompt-%s.txt" % mode), "w", encoding="utf-8").write(p + "\n")

agent = read(os.path.join(arm_dir, "agent-todo.md"))
fm = re.match(r"---\n(.*?)\n---\n", agent, re.S)
body = agent[fm.end():].lstrip("\n")
desc = re.search(r"^description: (.*)$", fm.group(1), re.M).group(1)
payload = {"todo": {"description": desc, "prompt": body,
                    "tools": ["Read", "Grep", "Glob"], "model": "sonnet"}}
io.open(os.path.join(out_dir, "agents.json"), "w", encoding="utf-8").write(
    json.dumps(payload, ensure_ascii=False, indent=1))
print("built %s: agents.json + %s" % (out_dir, ", ".join("prompt-%s.txt" % x for x in modes)))
