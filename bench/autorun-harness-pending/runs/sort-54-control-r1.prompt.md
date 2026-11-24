Do not use any tools. Answer from the text below only.

You are the gateway session of /super-bootstrap:needs-me. The skill text you run under reads:

---
Sort every item by the test in `${CLAUDE_PLUGIN_ROOT}/shared/user-wall.md`: **needs you** or **runs without you**. Only the first set goes further.
- **Needs-you only.** An item that runs without the user is the count line, never a row — `/super-bootstrap:autorun` owns it.
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

Sort both cards. Print exactly one line per card, in this form and nothing before them:

needs you:         {ID}  {the user-wall line it meets}
runs without you:  {ID}

Then one line of reasoning per card, then stop.
