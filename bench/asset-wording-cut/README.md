# bench/asset-wording-cut — cut test for DEBT-sxck (a), (b), (c), (e)

Test surface for four wording trims in the shipped
[`harness-bootstrap` assets](../../plugins/super-bootstrap/skills/harness-bootstrap/assets/) and the
split-lane template in [`harness-bootstrap/SKILL.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md).
Each trim removes or rewords behavior-shaping prose on a surface a consumer loads, so
[`skill-authoring`](../../.claude/rules/skill-authoring.md) wants a RED: show the trimmed text keeps
the behavior the current text produces. Reading-only probe, same shape as
[`bench/lean-brief-numbers/`](../lean-brief-numbers/README.md) — no fixture repo, no tools.

## Arms

[`build.py`](build.py) slices each arm live from the in-repo dev assets and writes
`arms/<item>-<arm>/`: `current` (shipped, byte-asserted — build aborts on drift) · `trimmed` (the
card Plan step 1 shape). The two arms of an item differ only in the item's lines
(`diff -r arms/<item>-current arms/<item>-trimmed`).

| Item | Trimmed lines | Reader sees (what loads at the governed moment) |
|---|---|---|
| a | `harness.md` § Doc Sync Dimension-routing first bullet → pointer to the `dimension-discipline` rule, example dropped | `harness.md` alone |
| b | `rules-index-skeleton.md` line 13 → bullets, `harness.md` restatement dropped | the index alone |
| c | "architecture" / "backlog" in both doc rules → seeded kinds (overview, techstack, specs) | both doc rules |
| e | `claude-md-skeleton.md` line 3 → load pointer only; `SKILL.md` split-lane "where one takes over a doctrine line, it wins here" → a check keyed on the *takes over* label | seeded `CLAUDE.md` (skeleton filled + additions section) + `harness.md` |

## Tasks

- **a** — doc-sync step; a still-binding past decision (dated, with an incident back-story) goes into `docs/overview.md` § Export.
- **b** — user asks for a "workflow rule" on `db/migrations/`; the rules dir lists `harness.md — # Harness — workflow doctrine`.
- **c** — classify `docs/architecture.md` and its `## Status` section; the Stripe migration just finished.
- **e** — user wants PR + one review for every change, against the doctrine's "No PR self-review — commit directly".

## Scoring

[`score.py`](score.py), per item: **a** FORMAT · NODATE · NOWHY · NODECIDED · CONSTRAINT · **b** FORMAT ·
OWNFILE · NOHARNESS · PATHS · **c** FORMAT · DOC · STATUS · OVERWRITE · **e** FORMAT · WHERE · TAKEOVER.
An item's governed behavior passes when all its assertions pass. Bite check:
`python score.py bite/induced-*.txt` — every assertion fails on an induced bad output, the
`induced-*-good` controls pass ([`bite/bite-check.txt`](bite/bite-check.txt)).

## Run

```bash
python build.py                                   # arms/ + prompts/ (run.sh calls it too)
bash run.sh <scratch-dir> <arm> 3 ["a b c e"]     # MODEL=opus default; writes runs/<item>-<arm>-r<n>.txt
python score.py runs/*.txt > runs/scores.tsv
```

Reader decontamination: `CLAUDE_CODE_DISABLE_CLAUDE_MDS=1`, `--setting-sources project`,
`--tools ""`, `--strict-mcp-config`, empty scratch cwd. Gate + results: [`FINDINGS.md`](FINDINGS.md).
