#!/usr/bin/env python3
"""DEBT-sxck — build the cut-test arms and prompts for items (a), (b), (c), (e).

Each item has two arms that differ only in the item's lines:
  current  — the shipped text, sliced live from the asset and byte-asserted
             against the quoted CURRENT strings below (abort on drift)
  trimmed  — the card Plan step 1 shape (exact text quoted below)

Each reader sees only what loads at the governed moment (Plan step 2):
  a  harness.md alone                 task: record a still-binding past decision in docs/overview.md
  b  rules-index alone                task: author a new path-scoped rule
  c  both doc rules                   task: classify docs/architecture.md + its status section
  e  seeded CLAUDE.md + harness.md    task: add a project-specific workflow line

Writes arms/<item>-<arm>/<file> and prompts/<item>-<arm>.txt next to this file.
"""
import io
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
HB = os.path.join(HERE, "..", "..", "plugins", "super-bootstrap", "skills", "harness-bootstrap")
ASSETS = os.path.join(HB, "assets")


def read(path):
    return io.open(path, encoding="utf-8", newline="").read()


def swap(text, old, new, label):
    n = text.count(old)
    if n != 1:
        sys.exit("%s: expected the current text exactly once, found %d — the bench no longer "
                 "measures the shipped bytes" % (label, n))
    return text.replace(old, new)


# ---------------------------------------------------------------- (a) harness.md Dimension routing
A_CURRENT = ('- Decision still **binding** current work → present-tense constraint in the state doc it '
             'governs, stripped of when/why-decided. ("Refinement deferred behind the port" — not '
             '"on <date> we decided to defer refinement because…").')
A_TRIMMED = ('- Decision still **binding** current work → the state doc it governs, worded per the '
             '`dimension-discipline` rule (Route item 3).')

# ---------------------------------------------------------------- (b) rules-index line 13
B_CURRENT = ('> Use `paths:` in frontmatter — not `globs:` (Cursor key, unrecognized by Claude Code; the '
             'rule silently loads always-on and the path filter is ignored). A rule with no frontmatter '
             'at all takes the same eager lane. `harness.md` is that case — plugin-owned, re-placed whole '
             'by `/super-bootstrap:harness-bootstrap`; author project rules in their own files. Patterns '
             'match gitignore-style — a bare filename fires at any depth, a leading `/` pins root.')
B_TRIMMED = ('> Frontmatter:\n'
             '>\n'
             '> - Use `paths:` — not `globs:` (Cursor key, unrecognized by Claude Code; the rule silently '
             'loads always-on and the path filter is ignored).\n'
             '> - A rule with no frontmatter at all takes the same eager lane.\n'
             '> - Patterns match gitignore-style — a bare filename fires at any depth, a leading `/` pins root.')

# ---------------------------------------------------------------- (c) doc kinds the skeleton set does not seed
C_SWAPS = {
    "rules-dimension-discipline-skeleton.md": [
        ("  place. Overview, techstack, architecture, backlog rows, status fields.",
         "  place. Overview, techstack, specs, status fields."),
        ("Applies to authored prose docs (overview, techstack, architecture, backlog,\nREADMEs).",
         "Applies to authored prose docs (overview, techstack, specs, READMEs)."),
    ],
    "rules-ssot-doc-link-skeleton.md": [
        ("   design and need not link every entry. Frozen tracker/backlog rows count as\n   registries, not candidate prose.",
         "   design and need not link every entry. Frozen tracker rows count as\n   registries, not candidate prose."),
        ("Applies to authored prose docs (overview, architecture, specs, backlog, READMEs).",
         "Applies to authored prose docs (overview, techstack, specs, READMEs)."),
    ],
}

# ---------------------------------------------------------------- (e) CLAUDE.md line 3 + SKILL.md:213
E3_CURRENT = ('Workflow doctrine — pipeline, dispatch, doc sync, git — loads from '
              '[`.claude/rules/harness.md`](.claude/rules/harness.md): plugin-owned, re-placed whole by '
              '`/super-bootstrap:harness-bootstrap`. This file holds the project\'s own sections.')
E3_TRIMMED = ('Workflow doctrine — pipeline, dispatch, doc sync, git — loads from '
              '[`.claude/rules/harness.md`](.claude/rules/harness.md). This file holds the project\'s own sections.')
EB_CURRENT = ('These lines bind in this repo together with `.claude/rules/harness.md`; where one takes over '
              'a doctrine line, it wins here.')
EB_TRIMMED = ('These lines bind in this repo together with `.claude/rules/harness.md`; a line labelled '
              '*takes over* wins over the doctrine line it names.')

# Fill for the seeded CLAUDE.md fixture (skeleton placeholders → one fixed project).
E_PROJECT = "ledgerline"
E_STACK = "Node 20 + Fastify + Postgres 15 + pnpm"
E_COMMANDS = "pnpm test\npnpm build"
E_ENTRIES = """**§ Git Notes** — added to "Conventional commits":

- Scope is the package name: `feat(api): …`, `fix(web): …`.

**§ Development Workflow** — takes over "Commit in flow":

- Commit once per card, at the card's close — a card's verified units ride one commit."""


def seeded_claude_md(line3, bind):
    skel = read(os.path.join(ASSETS, "claude-md-skeleton.md")).split("\n")
    if skel[2] != E3_CURRENT:
        sys.exit("(e) claude-md-skeleton.md line 3 drifted from E3_CURRENT")
    out = []
    for i, line in enumerate(skel):
        if i == 0:
            out.append("# " + E_PROJECT)
        elif i == 2:
            out.append(line3)
            out.append("")
            out.append("## This repo's additions to the harness doctrine")
            out.append("")
            out.append(bind)
            out.append("")
            out.extend(E_ENTRIES.split("\n"))
        elif line.startswith("{detected one-line summary"):
            out.append(E_STACK)
        elif line.startswith("{detected from scripts"):
            out.extend(E_COMMANDS.split("\n"))
        elif line.startswith("{"):
            continue
        else:
            out.append(line)
    text = "\n".join(out)
    while "\n\n\n" in text:
        text = text.replace("\n\n\n", "\n\n")
    if "{" in text.replace("{ID}", ""):
        sys.exit("(e) seeded CLAUDE.md still holds a placeholder")
    return text.rstrip("\n") + "\n"


def skill_bind_line():
    lines = read(os.path.join(HB, "SKILL.md")).split("\n")
    hits = [l.strip() for l in lines if l.strip().startswith("These lines bind in this repo together with")]
    if hits != [EB_CURRENT]:
        sys.exit("(e) SKILL.md split-lane bind line drifted from EB_CURRENT: %r" % hits)
    return hits[0]


# ---------------------------------------------------------------- prompts
PROMPT_A = """You are the gateway session in a software repo. Your session loads the file below every turn; it is `.claude/rules/harness.md`, the repo's workflow doctrine:

--- .claude/rules/harness.md ---
{harness}--- END .claude/rules/harness.md ---

You are at the doc-sync step of a commit. The commit adds batching to the nightly CSV export in `src/export/worker.ts`. Earlier in the session the user told you this, and it still holds:

"Back on 2026-10-02 the export worker took down the primary database (incident INC-42). In the retro we decided the export job stays single-threaded until the storage layer moves to Postgres 16. That's still the rule — the batching you just added keeps it single-threaded."

Record this in `docs/overview.md`, the repo's product overview. Its "Export" section currently reads:

## Export
Nightly CSV export of all ledgers, written to `s3://acme-exports/`. Driven by `src/export/worker.ts`.

Answer with the new "## Export" section in full, between a line `--- SECTION ---` and a line `--- END ---`, and nothing else.
"""

PROMPT_B = """You are working in a software repo. You just read a file under `.claude/rules/`, so the rule file below loaded into your context:

--- .claude/rules/index.md ---
{index}--- END .claude/rules/index.md ---

`.claude/rules/` currently holds these files (first heading shown):
- `index.md` — `# Rules — Authoring Guide`
- `harness.md` — `# Harness — workflow doctrine` (no frontmatter)
- `dimension-discipline.md` — `# Dimension Discipline — Classify Before You Propagate`
- `ssot-doc-link.md` — `# SSOT Doc-Link — Emit at Authoring`

The user says: "Add a workflow rule: once a migration under `db/migrations/` is merged, never edit it — write a new migration instead. I want it in front of you whenever you touch a migration."

Do it. Answer with the file edits you make and nothing else. For each file you create or change, write a line `FILE: <path>`, then the file's full content if you create it, or only the lines you add if it already exists.
"""

PROMPT_C = """You are working in a software repo. You just read `docs/architecture.md`, so the two rule files below loaded into your context:

--- .claude/rules/dimension-discipline.md ---
{dim}--- END .claude/rules/dimension-discipline.md ---

--- .claude/rules/ssot-doc-link.md ---
{ssot}--- END .claude/rules/ssot-doc-link.md ---

`docs/architecture.md` reads:

# Architecture

Three services sit behind one gateway: `api` (Go, REST), `worker` (Go, queue consumer) and `web` (Next.js). Postgres 15 is the only store; `worker` reads jobs from a Postgres-backed queue.

## Data flow

`web` calls `api`; `api` writes rows and enqueues jobs; `worker` drains the queue and calls the payment provider.

## Status

- Payments provider migration to Stripe: in progress
- Search index: Elasticsearch 8
- Mobile push: not started

The user says: "The Stripe migration finished today and the old provider code is deleted. Update the doc."

Answer in exactly this shape and nothing else:
DOC: <state or history> — the dimension `docs/architecture.md` owns
STATUS: <state or history> — the dimension its `## Status` section owns
--- SECTION ---
<the new `## Status` section in full>
--- END ---
"""

PROMPT_E = """You are the session in a software repo. The two files below load into your context every session:

--- CLAUDE.md ---
{claude}--- END CLAUDE.md ---

--- .claude/rules/harness.md ---
{harness}--- END .claude/rules/harness.md ---

The user says: "In this repo every change goes through a pull request with one approving review before it lands on main. Make that part of our workflow."

Do it. Answer in exactly this shape and nothing else:
FILE: <the one file you edit>
--- TEXT ---
<the exact lines you add or change, with the heading they sit under>
--- END ---
"""


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    io.open(path, "w", encoding="utf-8", newline="\n").write(text)


def main():
    harness = read(os.path.join(ASSETS, "harness.md"))
    index = read(os.path.join(ASSETS, "rules-index-skeleton.md"))
    dim = read(os.path.join(ASSETS, "rules-dimension-discipline-skeleton.md"))
    ssot = read(os.path.join(ASSETS, "rules-ssot-doc-link-skeleton.md"))
    bind = skill_bind_line()

    arms = {}
    # (a)
    arms[("a", "current")] = {"harness.md": swap(harness, A_CURRENT, A_CURRENT, "(a)")}
    arms[("a", "trimmed")] = {"harness.md": swap(harness, A_CURRENT, A_TRIMMED, "(a)")}
    # (b)
    arms[("b", "current")] = {"index.md": swap(index, B_CURRENT, B_CURRENT, "(b)")}
    arms[("b", "trimmed")] = {"index.md": swap(index, B_CURRENT, B_TRIMMED, "(b)")}
    # (c)
    src = {"rules-dimension-discipline-skeleton.md": dim, "rules-ssot-doc-link-skeleton.md": ssot}
    cur, trm = {}, {}
    for name, pairs in C_SWAPS.items():
        t = src[name]
        for old, new in pairs:
            swap(t, old, old, "(c) " + name)
            t = t.replace(old, new)
        cur[name], trm[name] = src[name], t
    arms[("c", "current")] = cur
    arms[("c", "trimmed")] = trm
    # (e)
    arms[("e", "current")] = {"CLAUDE.md": seeded_claude_md(E3_CURRENT, bind), "harness.md": harness}
    arms[("e", "trimmed")] = {"CLAUDE.md": seeded_claude_md(E3_TRIMMED, EB_TRIMMED), "harness.md": harness}

    # arms must differ, and the current arm must equal the shipped bytes
    for item in "abce":
        if arms[(item, "current")] == arms[(item, "trimmed")]:
            sys.exit("(%s) arms are identical" % item)
    assert arms[("a", "current")]["harness.md"] == harness
    assert arms[("b", "current")]["index.md"] == index
    assert arms[("c", "current")]["rules-dimension-discipline-skeleton.md"] == dim
    assert arms[("c", "current")]["rules-ssot-doc-link-skeleton.md"] == ssot

    for (item, arm), files in arms.items():
        for name, text in files.items():
            write(os.path.join(HERE, "arms", "%s-%s" % (item, arm), name), text)
        if item == "a":
            p = PROMPT_A.format(harness=files["harness.md"])
        elif item == "b":
            p = PROMPT_B.format(index=files["index.md"])
        elif item == "c":
            p = PROMPT_C.format(dim=files["rules-dimension-discipline-skeleton.md"],
                                ssot=files["rules-ssot-doc-link-skeleton.md"])
        else:
            p = PROMPT_E.format(claude=files["CLAUDE.md"], harness=files["harness.md"])
        write(os.path.join(HERE, "prompts", "%s-%s.txt" % (item, arm)), p)
    print("items: a b c e  arms: current trimmed  prompts: %d" % len(arms))


if __name__ == "__main__":
    main()
