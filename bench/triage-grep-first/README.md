# bench/triage-grep-first — does the triage agent need its `Grep before reading.` bullet?

Test surface for `DEBT-118` finding **M4**: [`agents/triage.md`](../../plugins/super-bootstrap/agents/triage.md)
§ Investigation carries

> `- **Grep before reading.** Narrow to call sites / definitions first; whole-file reads burn the budget.`

The audit claim: this is strategy coaching a top-tier reader applies unprompted, and it points the
wrong way when a root cause needs whole-file context. A removal is behavior-shaping, so it is held
against the shipped text first ([`skill-authoring`](../../.claude/rules/skill-authoring.md) RED
floor): the line goes only if behavior without it is equivalent or better.

## Arms

[`make-arms.sh`](make-arms.sh) derives both from the shipped agent — frontmatter stripped (a
subagent's system prompt is the body), nothing under `plugins/` touched — and asserts they differ by
exactly the one bullet.

- `current` — [`arm-current.md`](arm-current.md), the body as shipped.
- `removed` — [`arm-removed.md`](arm-removed.md), the same body minus that bullet.

## Fixture

[`make-fixture.sh`](make-fixture.sh) builds `tally`, a small Python billing package from
[`fixture/`](fixture/) (18 `.py` files, a green 10-test suite that covers neither bug), with the
consumer card substrate (`docs/work/README.md`, `TEMPLATE.md`, `docs/decisions.md`) placed verbatim
from the `harness-bootstrap` assets, and one neutral commit. Two cards:

| Card | Where the cause lives | Planted decoy (card `Prior`) |
|---|---|---|
| `BUG-001` — a refund that is the last event of a nightly batch never reaches a statement | **Whole-file control flow** in `tally/engine.py` (374 lines): `_on_refund` holds every refund one step in `_held`; `_rollover` settles held refunds at the *next* event; `run()` calls `_emit_period()` **before** the final `_rollover(None)`, so the trailing refund lands in a fresh `_open` slot that is never emitted (and `_apply_refund` records it in the replay ledger, so the redelivery is skipped too). The three pieces span lines 81–363. | `RefundLedger.is_duplicate()` keys on (account, amount, posted_on) — grep-reachable, a real latent collision risk, and the job log names it; it cannot explain the position-in-batch dependence. |
| `BUG-002` — a GBP amount renders as `en_GB 312.40` on some customer surface | **One call site among many**: `tally/reports/dunning.py:45` passes `(locale, currency)` into `fmt_money(cents, currency, locale)`; the other 27 call sites across 9 files are correct. Grep-first is the efficient path. | GBP missing from `money.SYMBOLS` — it is present. |

Both bugs are verified to reproduce against the fixture code before any run.

## Protocol

[`run.sh`](run.sh) — `claude -p --model opus` (the agent is `model: inherit`; downstream sessions
run the top tier), cwd'd in a pristine per-rep copy of the fixture, briefed the way
[`skills/triage/SKILL.md`](../../plugins/super-bootstrap/skills/triage/SKILL.md) step 2 dispatches:
arm body as system prompt (`${CLAUDE_PLUGIN_ROOT}` resolved to a stand-in dir holding
`shared/grounding-discipline.md`, added via `--add-dir`), prompt = card ID + date + gateway-aligned
problem-aim ([`prompt-BUG-001.txt`](prompt-BUG-001.txt), [`prompt-BUG-002.txt`](prompt-BUG-002.txt) —
no cause theory, no fix preference). Tools = the agent's own set (`Read, Grep, Glob, Bash, Edit`);
Bash allow-listed to read-only `git status/diff/log` + `ls`. `CLAUDE_CONFIG_DIR` = a credentials-only
cold dir (no device CLAUDE.md, rules, plugins, hooks). N=3 per arm per card. Wall-clock is not
recorded.

[`extract.py`](extract.py) pulls each transcript's final report and a per-tool-call log;
[`score.py`](score.py) scores each run's card. Assertions: `origin` (origin block untouched), `one_block`
(exactly one well-formed Verdict header), `shape` (every field the verdict kind's template requires),
`cause` (true root cause named — card-specific rubric). Readings: `decoy`, `budget`
(`truncated at budget` exit), tool / Read / Grep / partial-Read counts, `read_tok` (Read result
chars / 4), `intake_tok` (all tool-result chars / 4 — also counts files read through Bash `cat`),
`whole_target` (the cause file Read without offset/limit). [`bite.sh`](bite.sh) proves
each assertion fails on an induced bad verdict ([`bite/`](bite/)).

Evidence lands in [`runs/`](runs/) (`<card>-<arm>-r<n>.card.md` / `.result.txt` / `.tools.tsv`);
transcripts stay in the scratch tree. Results: [`FINDINGS.md`](FINDINGS.md).

```bash
bash make-arms.sh
bash make-fixture.sh <scratch>
for c in BUG-001 BUG-002; do for a in current removed; do bash run.sh <scratch> $a $c 3; done; done
python3 score.py runs
bash bite.sh
```
