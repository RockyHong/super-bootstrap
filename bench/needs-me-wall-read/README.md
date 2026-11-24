# bench/needs-me-wall-read — needs-me sorts on block bodies, not headings

Test surface for [`skills/needs-me/SKILL.md`](../../plugins/super-bootstrap/skills/needs-me/SKILL.md) § Scan's card read
grain. The [`shared/user-wall.md`](../../plugins/super-bootstrap/shared/user-wall.md) test needs block bodies: a
`waiting on {party}` inside a Design body, a Design block's approval line, the `###` sub-heading a surface Verdict
carries. A scan that reads only each card's origin block plus its latest `## ` heading cannot see them, so a waiting
card sorts as "runs without you" and lands in autorun's count line. The fix reads each card at the cold-reader read
set ([`docs/work/README.md` § Thread contract](../../docs/work/README.md#thread-contract)), the read autorun's § Pick
runs for the same test. Behavior-shaping prose, so it ships behind the
[`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor, on the no-tools sort shape
[`bench/autorun-harness-pending`](../autorun-harness-pending/README.md) `sort-run.sh` uses.

- [`sort-run.sh`](sort-run.sh) `<dir> <tag> [model]` — needs-me side, no tools. Prompt = needs-me `SKILL.md` whole,
  `shared/user-wall.md` whole and `docs/work/README.md` § Thread contract, extracted at run time, then three cards
  whole:
  - `GAP-21` — an approved Design whose body says `waiting on Acme Billing's API team`, then a later Progress block
    (expected: needs you, outside party);
  - `GAP-22` — a surface Verdict, then a Design with no approval line as the latest block (expected: needs you);
  - `GAP-23` — an auto-fix Verdict, plain runnable (expected: runs without you).

  Asks for one `needs you:` / `runs without you:` line per card, then which parts of each card it read. Writes
  `runs/sort-<tag>.prompt.md` and `.result.txt`. `SKILL_REF=<rev>` reads the skill text from that commit.
- [`check.sh`](check.sh) `<file>` — `GAP-21` and `GAP-22` on `needs you:` lines, `GAP-23` on the `runs without you:`
  line; one `PASS` / `FAIL` line per expectation, exit 1 on any `FAIL`.

Pass an absolute `<dir>` outside this repo.

## Protocol

- **Control** — `SKILL_REF=HEAD` before the fix (§ Scan: "every open card's origin block plus its latest `## `
  heading").
- **Arm** — the working-tree text.
- **Assertion** — `check.sh` passes: all six lines `PASS`.

With no tools the model sees every byte of each card, so the prompt tells it to judge each card only on the parts
§ Scan says to read. The grain under test is the skill's wording, not a file read.

## Findings

Run 2026-11-24, haiku, one fresh fixture dir per run, three runs per cell.

| Cell | `check.sh` | GAP-21 | GAP-22 | GAP-23 |
|---|---|---|---|---|
| Control | FAIL 3/3 | `runs without you` 3/3 | `needs you` 3/3 | `runs without you` 3/3 |
| Arm | PASS 3/3 | `needs you` 3/3 | `needs you` 3/3 | `runs without you` 3/3 |

RED: the heading grain drops the Design body, so the waiting card goes to autorun's count 3/3 (control r2: "GAP-21:
read origin block and latest block (`## Progress — 2026-10-06 · session`). Not read, outside § Scan: Verdict and Design
blocks."). GREEN: the arm reads the whole read set and names the wait 3/3 (arm r1: "needs you: GAP-21  A party outside
the repo: the Design ruling waits on Acme Billing's API team (JSON API v2, no date).").

Lessons:

- `GAP-22` does not bite on the control: the model reads "latest `## ` heading" as the latest block with its body, so
  a Design that is the latest block shows its missing approval line either way. The bite needs the evidence in a block
  that is no longer the latest one, as `GAP-21` has it.
- The `GAP-22` and `GAP-23` assertions take their bite check from a hand-written violating result (`GAP-22` on
  `runs without you:`, `GAP-23` on `needs you:`): `check.sh` prints `FAIL` for all four lines naming them.

Not covered:

- A live needs-me run with tools over a fixture repo: the read is prompt-simulated, so how many bytes a real scan
  reads per card is not measured.
- A wait named only in an Amendment after the latest Design, and a surface Verdict followed by a Progress block: both
  fall inside the read set, no run carries them.
