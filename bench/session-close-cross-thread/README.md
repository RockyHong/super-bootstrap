# bench/session-close-cross-thread — RED for session-close's cross-thread finished-card signal

Test surface for [`skills/session-close/SKILL.md`](../../plugins/super-bootstrap/skills/session-close/SKILL.md) § 3,
signal (e): a card whose latest block's next step another card's block or an unnamed main-line commit finished takes a
**triage** row, never a resolve. Behavior-shaping prose, so it ships behind the
[`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor. Sibling benches for the rest of the sweep:
[`session-close-moves`](../session-close-moves/README.md).

- `make-fixture.sh <dir>` — a garden newsletter repo with dated commits. Target `GAP-tg01`: its 06-02 Progress names the
  next step (post the seed-swap recap, archive the tally sheet); `GAP-an02`'s 06-09 block posts the recap and the commit
  `chore: archive the seed-swap tally sheet` (06-10) archives it, neither naming `GAP-tg01`. `GAP-an02` is the in-motion
  weekly anchor. Decoys sharing topic words, step not done: `DEBT-dc03` (seed-swap signup form), `GAP-dc04` (newsletter
  recap template), `GAP-dc05` (2025 tally sheets). The session's own commit fixes a README typo. Writes `<dir>.snap`.
- `prompt.txt` — the session record: goal delivered, no card logged or read.
- `run.sh <control|arm> <fixture-dir>` — one headless turn, stopped at the pick. `CONTROL_REV` (env) picks control's
  revision, default `HEAD`. Writes `<dir>.turn1.txt`.
- `score.sh <out> <dir>` — (x1)–(x5). `bite.sh <scratch-dir>` — each assertion failing on a violating output. Zero LLM calls.

## Protocol

Headless, one fresh fixture per run, fixture as cwd, prompt on stdin:
`claude -p --model sonnet --allowedTools Bash --setting-sources "" --strict-mcp-config --system-prompt <stub> --permission-prompts none`.
The prompt carries the skill text verbatim, so the copy under test is this repo's working tree. Fixtures stay in a
scratch directory outside this repo.

- **(x1)** a `[triage]` row names `GAP-tg01`.
- **(x2)** no `[resolve]` row names `GAP-tg01`.
- **(x3)** no `[resolve]` row names a decoy (`GAP-an02`, `DEBT-dc03`, `GAP-dc04`, `GAP-dc05`).
- **(x4)** reading, not gating: the count of decoys a `[triage]` row aims at — false positives.
- **(x5)** the fixture snapshot is unchanged at the pick.

Pass condition, named before any run: arm (x1), (x2), (x3), (x5) on 3 of 3; (x4) reported. RED: control fails (x1).
One wording round.

## Findings

Control `ae609f3` (HEAD), two runs; arm the working tree, three runs; sonnet, one fresh fixture per run.

| Assertion | Control | Arm |
|---|---|---|
| (x1) target triage row | 0 of 2 | 3 of 3 |
| (x2) target not resolved | 1 of 2 | 3 of 3 |
| (x3) no decoy resolved | 2 of 2 | 3 of 3 |
| (x4) false-positive triage rows | 0, 0 | 0, 0, 0 |
| (x5) nothing written before the pick | 2 of 2 | 3 of 3 |

RED holds on (x1). Control run 1 sees no move ("**Moves:** I found nothing to do, so there was nothing to pick or
decline."); control run 2 resolves the target off-signal ("- [resolve] **GAP-tg01 (June seed-swap recap):** delete
`docs/work/GAP-tg01.md`."). Arm run 1: "- [triage] **GAP-tg01 (June seed-swap recap):** run `/super-bootstrap:triage
GAP-tg01`. Other work suggests the card's next step may already be done." (x3) and (x5) fail in no run; `bite.sh` bites them.
