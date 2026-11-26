# bench/pickup-date-wait — the pickup skills read a date wait and a stale carry

Test surface for [`skills/needs-me/SKILL.md`](../../plugins/super-bootstrap/skills/needs-me/SKILL.md) § Scan and
[`skills/autorun/SKILL.md`](../../plugins/super-bootstrap/skills/autorun/SKILL.md) § Pick against two contract facts:

- the block-level date wait — a `## Progress` / `## Design` block naming `not before YYYY-MM-DD`
  ([`docs/work/README.md` § Thread contract](../../docs/work/README.md#thread-contract)): a date after today → needs-me
  lists the card as not yet due with its date, autorun skips it; a date today or earlier → the card reads as normal;
- needs-me's carry pointer line: `{N} carries ({M} stale)`, stale = a carry whose load-bearing pointer is gone, the
  test [`session-continue`](../../plugins/super-bootstrap/skills/session-continue/SKILL.md) § 2 runs.

Behavior-shaping prose, so it ships behind the [`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor,
on the no-tools sort shape [`bench/needs-me-wall-read`](../needs-me-wall-read/README.md) uses.

- [`run.sh`](run.sh) `<dir> <tag> needs-me|autorun [model]` — no tools, today fixed at 2026-11-26. Prompt = the
  skill's `SKILL.md` whole, `shared/user-wall.md` whole and `docs/work/README.md` § Thread contract (working tree in
  both cells), then [`cards.md`](cards.md): `GAP-31` (auto-fix, latest Progress `not before 2026-12-10`), `GAP-32`
  (same shape, `not before 2026-11-01` — the past-date decoy), `GAP-33` (plain auto-fix). needs-me also gets
  [`carries.md`](carries.md): three carries, `GAP-29-*.md` pointing at a card the `docs/work/` listing lacks.
  `SKILL_REF=<rev>` takes the skill text from that commit; `NOCONTRACT=1` leaves the contract excerpt out. Writes
  `runs/<skill>-<tag>.prompt.md` and `.result.txt`.
- [`check.sh`](check.sh) `<file> needs-me|autorun` — one `PASS` / `FAIL` line per expectation, exit 1 on any `FAIL`.
  needs-me: `GAP-31` not yet due with `2026-12-10` and not sorted to runs-without-you, `GAP-32` and `GAP-33` runs
  without you, a carry line reading 3 carries with 1 stale. autorun: `GAP-31` on `skip:`, `GAP-32` and `GAP-33` on
  `run:`.

Pass an absolute `<dir>` outside this repo.

## Protocol

- **Control** — `SKILL_REF=HEAD`.
- **Arm** — the working-tree text.
- **Assertion** — `check.sh` passes.

## Findings

Run 2026-11-26, sonnet, one fresh fixture dir per run.

| Cell | date wait (`GAP-31`, `GAP-32`, `GAP-33`) | carry line |
|---|---|---|
| needs-me control | PASS 2/2 | FAIL 2/2 — `3 carries in flight → /super-bootstrap:session-continue` |
| needs-me control, `NOCONTRACT=1` | FAIL 1/1 — `GAP-31 → runs without you` | FAIL 1/1 |
| needs-me arm (carry line only) | PASS 3/3 | PASS 3/3 — `3 carries (1 stale) → /super-bootstrap:session-continue` |
| needs-me arm (+ § Scan date-wait clause), `NOCONTRACT=1` | PASS 2/2 | PASS 2/2 |
| autorun control | PASS 2/2 — `skip:  GAP-31  waiting on date: not before 2026-12-10` | — |
| autorun control, `NOCONTRACT=1` | PASS 1/1 | — |

No RED on the date wait: the contract line already names the readers ("`/super-bootstrap:needs-me` lists the card as
not yet due, and `/super-bootstrap:autorun` leaves it alone"), and both skills read that section, so the HEAD skill
text meets the pass. No date-wait wording ships in either skill. needs-me's pass rests on the contract excerpt alone
(`NOCONTRACT=1`: "the skill has no separate bucket for date-gated work"), and every passing run notes that
`SKILL.md` has no output slot for the not-yet-due card; autorun skips the card even without the excerpt.

RED on needs-me's own text: with the excerpt left out, the HEAD skill fails the date wait 1/1 while the arm, whose
§ Scan names the `not before` wait beside `waiting on {party}`, passes 2/2 — so needs-me ships that one clause and
no longer rests on a live scan opening the contract. autorun ships none.

RED on the carry line: the HEAD text leaves the carries unread, so the count includes the carry whose card is gone.
GREEN: the arm reads each carry's Read first slot against the `docs/work/` listing and prints `3 carries (1 stale)`.

Bite checks with no failing run: [`runs/needs-me-bite-violating.result.txt`](runs/needs-me-bite-violating.result.txt)
and [`runs/autorun-bite-violating.result.txt`](runs/autorun-bite-violating.result.txt), hand-written, fail every
line of `check.sh`.

Not covered:

- A live run with tools: whether a real needs-me or autorun scan opens `docs/work/README.md` § Thread contract, which
  the date-wait pass depends on for needs-me, is not measured.
- A date wait in a `## Design` block, a date equal to today, and a stale carry whose gone pointer is a doc path.
