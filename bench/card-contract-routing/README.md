# bench/card-contract-routing — append routing and the date wait marker in the card Thread contract

Test surface for [`assets/work-readme-skeleton.md` § Thread contract](../../plugins/super-bootstrap/skills/harness-bootstrap/assets/work-readme-skeleton.md)
(mirrored in [`docs/work/README.md`](../../docs/work/README.md#thread-contract)): a candidate **Append routing** line, not shipped
(`DEBT-z0qz` — content that stays true after the card is gone lands in its owning doc in the same write, the card
block links to it) and the `not before YYYY-MM-DD` date wait in the Design bullet (`GAP-qp6a`, contract half).
Behavior-shaping prose shipped to every consumer, so it ships behind the
[`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor, on the no-tools prompt shape
[`bench/needs-me-wall-read`](../needs-me-wall-read/README.md) uses.

- [`run.sh`](run.sh) `<dir> <scenario> <tag> [model]` — no tools. Prompt = the doctrine line that places settled design
  on the card thread (`assets/harness.md`, same in both arms), the asset's § Thread contract extracted at run time,
  then one scenario file. The model prints each file write as `=== WRITE {path} === … === END ===`. Writes
  `runs/<scenario>-<tag>.prompt.md` and `.result.txt`. `SKILL_REF=<rev>` reads the contract from that commit.
- [`check.sh`](check.sh) `<scenario> <file>` — one `PASS` / `FAIL` line per expectation, exit 1 on any `FAIL`.
- [`scenarios/`](scenarios/):
  - `s1` — a user ruling on a card's fork binds other cards (a CLI naming rule), `docs/specs/cli.md` owns CLI
    conventions; task "Record this ruling". Pass: `cli.md` gets the rule, the GAP-31 block links `cli.md`.
  - `s1b` — `s1` with the task the pickup skills give ("Append the Design block for this ruling to GAP-31"). Same pass.
  - `s2` — a parked next step cannot run before the 2026-12-03 deploy. Pass: the DEBT-41 block carries
    `not before 2026-12-03` verbatim.
  - `s3` (decoy) — a mid-fix working note. Pass: `docs/work/BUG-51.md` is the only file written.

Pass an absolute `<dir>` outside this repo.

## Protocol

- **Control** — `SKILL_REF=HEAD` before the edit.
- **Arm** — the working-tree contract.
- **Expectation** — control fails `s1`/`s1b` or `s2` (RED); arm passes all four; the decoy passes in both cells.

## Findings

Run 2026-11-26, sonnet, one fresh fixture dir per run. `s2` arm r1–r2 and `s1`/`s1b`/`s3` arm r1–r2 ran on a first
marker wording ("names it — `not before YYYY-MM-DD`, that shape only —"); the rest on the shipped wording ("in one
fixed shape, verbatim and lowercase"). The Append routing line did not change between them.

| Scenario | Control | Arm |
|---|---|---|
| `s1` | PASS 2/2 | PASS 2/2 |
| `s1b` | PASS 2/2 | PASS 3/3 |
| `s2` | FAIL 2/2 | first wording 1/2; shipped wording PASS 3/3 |
| `s3` (decoy) | PASS 2/2 | PASS 3/3 |

RED (`s2`): the control parks the date in free prose, in no shape a reader can match — control r1: "- **Next:** Do
not run this step before 2026-12-03."; control r2: "**Blocked until:** the weekly deploy on 2026-12-03 ships the
fix." First-wording arm r1 wrote "Not before 2026-12-03." (sentence-initial capital), so the shipped wording pins
the case. GREEN: shipped arm r3 "- Next step, not before 2026-12-03: after the deploy is live, re-measure the hit
rate…"; r4 "- **Next step (not before 2026-12-03):** Confirm that the deploy shipped the fix."

No RED (`s1`, `s1b`): the HEAD contract already routes a binding ruling to its owning doc 4/4 — control `s1b` r1:
"It follows the CLI-wide naming rule in [`docs/specs/cli.md`](../specs/cli.md#naming), which also covers GAP-32,
GAP-33 and every later subcommand." Sonnet does this unprompted when the ruling names the cards it binds and the
owning doc is shown. RED never went red, so the Append routing line did not ship; `DEBT-z0qz` closed as a fork in
[`docs/decisions.md`](../../docs/decisions.md), reopen on a RED in the "Not covered" shape below.

Bite checks with no failing run: a hand-written card-only `s1` result fails all three `s1` lines; an `s3` result that
also writes `docs/specs/export.md` fails "s3 writes nothing but BUG-51.md".

Not covered:

- A ruling whose reach outside the card is implicit (no card IDs named), or an owning doc the prompt does not show —
  the jowagoko case of many Design blocks accruing over time. This prompt shape does not reproduce that drift.
- A live run with tools over a fixture repo, and the reader side (session-continue / needs-me / autorun reading the
  marker) — that ships in a later edit.
