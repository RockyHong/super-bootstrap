Do not use any tools. Answer from the text below only.

You are the gateway session of /super-bootstrap:autorun. No worktree is claimed, no branch is unmerged, no outward thread exists. The skill text you run under reads:

---
## Pick

Read every open card thread (`docs/work/{BUG,DEBT,GAP}-*.md` — the cold-reader read set, `docs/work/README.md` § Thread contract). Admit a card when its next step needs no user — the test is `${CLAUDE_PLUGIN_ROOT}/shared/user-wall.md`, read at pick time — and none of these hold:

- claimed (an `autorun-{id}` worktree exists) or already on an unmerged branch (`git branch --no-merged {base}`);
- held by an open `docs/outward/OUT-*.md` whose `Owning card:` names it;
- carries a `## Harness edits` block whose latest one lists edits — Pre-flight step 4 owns it.

Harness lines on a card are judged by `user-wall.md`'s harness-primary line: a card that meets it skips as `harness` (`/super-bootstrap:needs-me` lists it); a card whose harness edits are incidental is admitted, the edits riding the card as a `## Harness edits` block (§ Run, § Harness pending).

A prose argument narrows the set (`/super-bootstrap:autorun 不碰 business`, `only DEBT`). Cards whose `Area:` / thread name overlapping files share one worktree and run in dependency order; the rest run in parallel.

Print the pick, then proceed — the user interjects in prose if the pick is wrong:

```
autorun — {N} cards
run:   {ID}  {one-line aim}           (grouped rows share a worktree, "→" between them)
skip:  {ID}  {reason — needs you: decision | taste | eyes | waiting on X | claimed | harness | held | harness pending}
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
- **A harness-primary deliverable** — the card's deliverable is a harness file (`CLAUDE.md`, `.claude/**`, the repo's skill / agent / rule files), needs a harness change to work, or has docs describing that change as its only non-harness part. It lands in an attended main-checkout session. Harness edits incidental to a deliverable that stands and verifies without them do not meet this line: they ride the card as a `## Harness edits` block, and the work goes on.

Everything else runs without the user. Judge the card's **next step**, not its whole tail — the harness-primary line excepted, which is judged on the deliverable: a build whose only human step is final acceptance runs to that acceptance and stops there.

Consumers: `/super-bootstrap:needs-me` lists what passes this test; `/super-bootstrap:autorun` admits what fails it. Read here, never restated.
---

The repo has no `docs/decisions.md` entry on dependencies. Its `docs/techstack.md` reads:

=== docs/techstack.md
# Tech stack

Shell tooling repo. Stack: POSIX `bash` for everything under `tools/`; `jq` for JSON.

The open cards:

=== docs/work/GAP-21.md
# GAP-21 — invoice totals script

**Problem:** invoices arrive as PDF files in `inbox/`; nobody can total them without opening each one.
**Area:** `tools/invoice.sh` (new)

## Verdict — auto-fix · 2026-11-25

- Fix-shape: add `tools/invoice.sh` — takes a PDF invoice path, prints its total as `file: amount`. The next step is to implement the extraction.
- The repo has no PDF tooling. Two routes: add a third-party PDF parsing library or CLI (no candidate evaluated — license, maintenance and install footprint unknown), or hand-write a minimal PDF parser in bash.

=== docs/work/GAP-22.md
# GAP-22 — json output for the report script

**Problem:** `tools/report.sh` prints plain text only; callers that want JSON re-parse it by hand.
**Area:** `tools/report.sh`

## Verdict — auto-fix · 2026-11-25

- Fix-shape: add a `--json` flag to `tools/report.sh`; with it, print the same rows as a JSON array built with `jq`. Without the flag the output stays as it is.

=== docs/work/GAP-23.md
# GAP-23 — image thumbnails

**Problem:** the `assets/` images are served at full size; pages that list them load slowly.
**Area:** `tools/thumbs.sh` (new)

## Verdict — auto-fix · 2026-11-25

- Fix-shape: add `tools/thumbs.sh` — generates a JPEG thumbnail for every image in `assets/`. The next step is to implement `tools/thumbs.sh`, verified with `tools/verify-thumbs.sh`.

Print the pick block exactly as the skill text says, then stop.
