# bench/lean-brief-numbers — light RED for DEBT-118 M6

Test surface for the "Precision per always-on byte" bullet in
[`harness-bootstrap/SKILL.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md) § Principles.
`DEBT-118` M6 proposes dropping its dated numbers ("~120-line target",
"~80k context = 100% recall") while keeping the obligation. The rewrite is a removal of
behavior-shaping prose under `plugins/*/skills/**`, so [`skill-authoring`](../../.claude/rules/skill-authoring.md)
wants a RED: show equivalence on the reading model. Reading-only probe, same shape as
[`bench/rot-scan-liveness/`](../rot-scan-liveness/README.md) — no fixture repo, no tools.

## Arms

`arms/*.md` = § Principles sliced live from the in-repo dev `SKILL.md` by [`build.py`](build.py):
`current` (shipped, byte-asserted) · `proposed` (card rewrite) · `no-principle` (bullet removed —
does the bullet bite at all?). The bullet line is the only difference between arms.

## Tasks

Same prompt template per arm: "You are executing `harness-bootstrap` … the user says our CLAUDE.md
feels bloated, tighten it", deletion-only, answer `CUT:` IDs / `STOP:` reason / `KEPT:` count.

- **a** — [`fixtures/long.tagged`](fixtures/long.tagged): 169-line CLAUDE.md for a payments service,
  101 signal / 15 fluff / 18 heading / 35 blank. Correct cut leaves 154 — above ~120, so a quota
  reader has to cut signal to get there.
- **b** — [`fixtures/short.tagged`](fixtures/short.tagged): 92-line CLAUDE.md for a tile renderer,
  40 signal / 20 fluff / 11 heading / 21 blank. Already under ~120, so a number-anchored reader could
  stop early.

Each fixture line is tagged `S|` signal, `F|` fluff, `H|` heading, `B|` blank — the answer key.
Fluff is genuine no-decision prose (platitudes, restating the obvious); signal lines each carry a
command, invariant, number or gotcha.

## Scoring

[`score.py`](score.py): FORMAT · FLUFF (≥ 80 % fluff cut) · SIGNAL (≤ 1 signal cut) · NUMBER (STOP
does not justify the stop by a line-count number / 120 / 80k; task a also fails at ≤ 135 kept).
Bite check: `python score.py bite/induced-*.txt` — induced bad outputs fail every assertion
([`bite/bite-check.txt`](bite/bite-check.txt)).

## Run

```bash
python build.py                              # arms/ + prompts/ (run.sh calls it too)
bash run.sh <scratch-dir> <arm> 3            # MODEL=opus default; writes runs/<arm>-<task>-r<n>.txt
python score.py runs/*.txt > runs/scores.tsv
```

Reader decontamination: `CLAUDE_CODE_DISABLE_CLAUDE_MDS=1` (probed — without it the device
`~/.claude/CLAUDE.md` loads), `--setting-sources project`, `--tools ""`, `--strict-mcp-config`,
empty scratch cwd. Gate + results: [`FINDINGS.md`](FINDINGS.md).
