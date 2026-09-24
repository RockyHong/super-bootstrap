#!/usr/bin/env python3
"""DEBT-118 M1+M2 — derive the `proposed` arm from the `current` arm copies.

`arms/current/` holds the shipped text (`git show HEAD:` of
`plugins/super-bootstrap/skills/todo/SKILL.md` and `agents/todo.md`).
This script applies the card's proposed replacements verbatim and writes
`arms/proposed/`. Every old string must occur exactly once, or it aborts —
so the two arms differ by exactly these edits and nothing else.

Usage: python make-arms.py
"""
import io
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))

SKILL_EDITS = [
    # M1b
    (
        "Classify every open item per this spec, then render EXACTLY the scaffold below. "
        "Fill bracketed slots from your gathered + filtered + ranked rows per agent protocol. "
        "Do NOT change shape, do NOT swap to an alternative template, do NOT merge or split "
        "groups the scaffold separates. Omit a group's table only if its row count is zero "
        "(omit the sub-heading too).",
        "Classify every open item per the spec below, then render the scaffold below as-is: "
        "fill its bracketed slots from your gathered, filtered, and ranked rows per the agent "
        "protocol, keeping its shape and its group split — the gateway relays your reply "
        "verbatim, so the scaffold is the board. Omit a group's table (and its sub-heading) "
        "only when its row count is zero.",
    ),
    # M1c label
    (
        "--- CLASSIFICATION SPEC (Read this FIRST) ---",
        "--- CLASSIFICATION SPEC ---",
    ),
    # M1c body
    (
        "Before classifying, use the Read tool on this exact path: {classify_spec_path}. "
        "It is the classification SSOT. Classify EXACTLY per it — do not paraphrase, do not "
        "substitute your own criteria.",
        "Before classifying, Read this path once: {classify_spec_path}. It is the "
        "classification SSOT, also encoded by the board script — apply its criteria as "
        "written, since a paraphrased criterion forks the board between the two lanes.",
    ),
]

AGENT_EDITS = [
    # M2a (:77) label
    (
        "`--- CLASSIFICATION SPEC (Read this FIRST) ---`",
        "`--- CLASSIFICATION SPEC ---`",
    ),
    # M2a (:77) body
    (
        "**Use the Read tool on that path once at the start of §1 — no re-read.** "
        "Classify EXACTLY per it — do not paraphrase, do not substitute your own criteria.",
        "Read it once at the start of §1 and apply its criteria as written — the board "
        "script encodes the same spec, so a paraphrased criterion forks the two lanes.",
    ),
    # M2b (:85)
    (
        "Read the classification spec from the path supplied in the dispatch prompt. "
        "Apply it to every open card",
        "Apply the classification spec to every open card",
    ),
]


def patch(name, edits):
    src = os.path.join(HERE, "arms", "current", name)
    dst = os.path.join(HERE, "arms", "proposed", name)
    text = io.open(src, encoding="utf-8", newline="").read()
    for old, new in edits:
        n = text.count(old)
        if n != 1:
            sys.exit("FATAL: %s: expected 1 occurrence, found %d: %r" % (name, n, old[:70]))
        text = text.replace(old, new)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    io.open(dst, "w", encoding="utf-8", newline="").write(text)
    print("wrote %s (%d edits)" % (os.path.relpath(dst, HERE), len(edits)))


patch("SKILL.md", SKILL_EDITS)
patch("agent-todo.md", AGENT_EDITS)
