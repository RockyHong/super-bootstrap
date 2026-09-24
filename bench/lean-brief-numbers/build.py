#!/usr/bin/env python3
"""DEBT-118 M6 — build the three arm excerpts and the six prompts.

Arms are the Principles section of harness-bootstrap SKILL.md, sliced live
from the in-repo dev copy, with the "Precision per always-on byte" bullet
varied:
  current      — the bullet exactly as shipped (asserted byte-equal to the slice)
  proposed     — the card's rewrite
  no-principle — the bullet removed (control: does the bullet bite at all?)

Fixtures are tagged line files (S signal / F fluff / H heading / B blank);
the prompt carries them untagged, each line prefixed `L001|`.

Writes arms/*.md and prompts/<arm>-<task>.txt next to this file.
"""
import io
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SKILL = os.path.join(HERE, "..", "..", "plugins", "super-bootstrap", "skills",
                     "harness-bootstrap", "SKILL.md")

CURRENT = ('- **Precision per always-on byte** — every CLAUDE.md line answers "what decision does this '
           'sharpen, at what moment?" Length is downstream of that. The Anthropic / community ~120-line '
           'target is a smoke alarm on bloat, not a hard cap. Sweet-spot session quality (~80k context = '
           '100% recall) requires the orchestrator brief stays lean enough that opening file reads + '
           'workflow + actual task fit.')
PROPOSED = ('- **Precision per always-on byte** — every CLAUDE.md line answers "what decision does this '
            'sharpen, at what moment?" Length is downstream of that: a line-count target is a smoke alarm '
            'on bloat, not a cap. Every always-on line competes with the task\'s own reads for attention, '
            'so the orchestrator brief stays lean enough that opening file reads + workflow + the task '
            'itself stay high-signal.')

TEMPLATE = """You are executing the `harness-bootstrap` skill on a repo. The skill's Principles section governs your judgment on harness shape:

--- PRINCIPLES ---
{principles}
--- END PRINCIPLES ---

The user says: "Our CLAUDE.md feels bloated. Tighten it — cut what doesn't earn its place."

Below is the repo's current CLAUDE.md. Each line is prefixed with an ID (`L001|`); the ID is not part of the file.

--- CLAUDE.md ---
{body}
--- END CLAUDE.md ---

This pass is deletion-only: you may delete whole lines but not rewrite any line. Answer in exactly three lines, nothing else:
LINE 1 — `CUT:` followed by the comma-separated IDs of every line you delete (or `CUT: none`).
LINE 2 — `STOP:` one sentence on why you stopped cutting where you did.
LINE 3 — `KEPT:` the number of lines the file has after your cuts.
"""


def principles_slice():
    lines = io.open(SKILL, encoding="utf-8").read().split("\n")
    start = lines.index("## Principles")
    sect = lines[start:]
    while sect and sect[-1] == "":
        sect.pop()
    return sect


def main():
    sect = principles_slice()
    hits = [i for i, l in enumerate(sect) if l.startswith("- **Precision per always-on byte**")]
    if len(hits) != 1:
        sys.exit("expected exactly one Precision bullet in the Principles slice, got %d" % len(hits))
    i = hits[0]
    if sect[i] != CURRENT:
        sys.exit("shipped bullet drifted from CURRENT — the bench no longer measures the shipped bytes")
    arms = {
        "current": sect,
        "proposed": sect[:i] + [PROPOSED] + sect[i + 1:],
        "no-principle": sect[:i] + sect[i + 1:],
    }
    os.makedirs(os.path.join(HERE, "arms"), exist_ok=True)
    os.makedirs(os.path.join(HERE, "prompts"), exist_ok=True)
    for arm, body in arms.items():
        io.open(os.path.join(HERE, "arms", arm + ".md"), "w", encoding="utf-8", newline="\n").write(
            "\n".join(body) + "\n")

    for task, fx in (("a", "long"), ("b", "short")):
        tagged = io.open(os.path.join(HERE, "fixtures", fx + ".tagged"), encoding="utf-8").read().rstrip("\n").split("\n")
        rendered = []
        for n, row in enumerate(tagged, 1):
            tag, _, text = row.partition("|")
            if tag not in "SFHB" or len(tag) != 1:
                sys.exit("bad tag %r at %s:%d" % (tag, fx, n))
            rendered.append("L%03d| %s" % (n, text) if text else "L%03d|" % n)
        body = "\n".join(rendered)
        for arm, psect in arms.items():
            p = TEMPLATE.format(principles="\n".join(psect), body=body)
            io.open(os.path.join(HERE, "prompts", "%s-%s.txt" % (arm, task)), "w", encoding="utf-8",
                    newline="\n").write(p)
    print("arms: %s  prompts: %d" % (", ".join(arms), len(arms) * 2))


if __name__ == "__main__":
    main()
