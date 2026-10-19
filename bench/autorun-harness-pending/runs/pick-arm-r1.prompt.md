Do not use any tools. Answer from the text below only.

You are the gateway session of /super-bootstrap:autorun. No worktree is claimed, no branch is unmerged, no outward thread exists. The skill text you run under reads:

---
## Pick

Read every open card thread (`docs/work/{BUG,DEBT,GAP}-*.md` — the cold-reader read set, `docs/work/README.md` § Thread contract). Admit a card when its next step needs no user — the test is `${CLAUDE_PLUGIN_ROOT}/shared/user-wall.md`, read at pick time — and none of these hold:

- claimed (an `autorun-{id}` worktree exists) or already on an unmerged branch (`git branch --no-merged {base}`);
- the deliverable is a harness file (`CLAUDE.md`, `.claude/**`, plugin-source skills / agents / rules) — route to `/super-bootstrap:needs-me`. Test: the harness lines are incidental when the rest of the card's deliverable (a script, code) stands and verifies without them → admit, the harness edits riding the card as a Plan block (§ Run, § Harness pending). A deliverable that needs the harness change to work, or whose only non-harness part is docs describing that change → skip;
- held by an open `docs/outward/OUT-*.md` whose `Owning card:` names it.

A prose argument narrows the set (`/super-bootstrap:autorun 不碰 business`, `only DEBT`). Cards whose `Area:` / thread name overlapping files share one worktree and run in dependency order; the rest run in parallel.

Print the pick, then proceed — the user interjects in prose if the pick is wrong:

```
autorun — {N} cards
run:   {ID}  {one-line aim}           (grouped rows share a worktree, "→" between them)
skip:  {ID}  {reason — needs you: decision | taste | eyes | waiting on X | claimed | harness | held}
```

Zero admitted → print the skip list and end the turn.

---

`shared/user-wall.md` reads:

---
# User wall — the one judgment two doors share

A card **needs the user** when finishing it requires any of:

- **A decision only the user owns** — a design fork with no ruling on the card or in `docs/decisions.md`, a product / business / scope call, an unruled `## Verdict — surface` carrying `### Decision needed`, a `## Design` block with no approval line.
- **Taste** — visual, copy, UX, or naming acceptance where "looks right" is the test, an unruled `## Verdict — surface` carrying `### Taste needed` included.
- **Human eyes** — a verify step no tooling can run (device, manual play-through, listening, a browser the user drives; a fully automated headless suite is tooling, not eyes).
- **A party outside the repo** — the card or its outward thread waits on someone's reply, a portal, a key.
- **Real cost or an irreversible move** — paid APIs, external compute, a push / release / delete the user has not asked for.

Everything else runs without the user. Judge the card's **next step**, not its whole tail: a build whose only human step is final acceptance runs to that acceptance and stops there.

Consumers: `/super-bootstrap:needs-me` lists what passes this test; `/super-bootstrap:autorun` admits what fails it. Read here, never restated.
---

The open cards:

=== docs/work/GAP-12.md
# GAP-12 — line-count report script

**Problem:** there is no script that reports how many lines each `src/*.src` file holds.
**Area:** `tools/report.sh` (new); `.claude/skills/x/references/y.md` (two lines point at the script)

## Verdict — auto-fix · 2026-10-20

- Fix-shape: add `tools/report.sh` — prints one line per `src/*.src` file, `name: count`, sorted by name. `sh tools/verify.sh` checks it.
- The skill reference `.claude/skills/x/references/y.md` names the old script: change its `Counts` line to point at `tools/report.sh` and its `Output` line to the new format.

=== docs/work/GAP-13.md
# GAP-13 — skill x gate fires too late

**Problem:** skill x checks its precondition after it writes, so a failed precondition leaves a half-written file.
**Area:** `.claude/skills/x/SKILL.md` § Gate

## Verdict — auto-fix · 2026-10-20

- Fix-shape: move the precondition check in `.claude/skills/x/SKILL.md` § Gate ahead of the write step and reword the gate's three lines to match. No other file changes.

Print the pick block exactly as the skill text says, then stop.
