# bench/code-presence-scope — micro-test for `harness-bootstrap` § Code presence's scan surface

Does § Code presence, as shipped, read a docs-only repo as **code present** on its own second run,
once § 2a-hooks has placed its three `.claude/hooks/*.sh` scripts? The clause names `.sh` among its
source-file examples and states no scan surface, so `.claude/` sits inside its reach by default
(SSOT: [`harness-bootstrap/SKILL.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md)
§ Phase 1, § Code presence). Two cold executors on docs-only fixtures each read those scripts as
harness state and stayed docs-only; two arms is under the three-to-five the closed rows in
[`docs/decisions.md`](../../docs/decisions.md) were each measured at, so it settles nothing.

## Protocol

**Pre-registered 2026-10-08, before any arm ran.**

One condition — the shipped wording is the arm, because the question is whether the shipped wording
misleads. No treatment arm exists yet: an exclusion clause is authored only if this run earns it.

- `claude -p --model haiku`, no tools (`--disallowedTools` over the full default set,
  `--strict-mcp-config`), prompt on stdin, three trials, cwd a neutral empty directory outside this
  repo — an in-repo run reads the answer off this repo's own `CLAUDE.md` and commit log.
- Prompt ([`prompt.txt`](prompt.txt)): § Code presence verbatim; § 2a-hooks' placement sentences
  verbatim, because the executors this bench stands in for had the whole skill and so knew the
  pipeline places those three scripts — withholding it would bias the arm toward the red answer;
  and the file tree of a docs-only repo after one bootstrap run, holding no manifest and no product
  source, only the pipeline's own placements.
- Forced output: first line `VERDICT: code present` or `VERDICT: docs-only`.

**Gate, as the cold triage verdict on `DEBT-127` fixed it before this bench existed:** red on **any**
arm.

| Read | Condition | Consequence |
|---|---|---|
| RED | ≥ 1 of 3 trials answers `code present` | the clause is earned — author a scan-surface exclusion, then RED it against this same prompt |
| GREEN | 3 of 3 answer `docs-only` | the clause is unearned — close the judgment half to `docs/decisions.md` with the 2 fixture executors + 3 trials as its read-out |

A missing or unparsed trial is an instrument failure, not a read: re-run that trial, never score
around it. [`score.sh`](score.sh) reads the first `VERDICT:` line of each trial and nothing else; the
gate is not revised after seeing results.

## Result

Run 2026-10-08, protocol as pre-registered. CC 2.1.292.

| Trial | Verdict | Ground the trial gave |
|---|---|---|
| 1 | docs-only | "harness infrastructure hook files (placed by the bootstrap pipeline itself), not application source code" |
| 2 | docs-only | "the `.sh` files in `.claude/hooks/` are harness infrastructure placed by the prior run, not original project code" |
| 3 | docs-only | "the three `.sh` files are pipeline-placed infrastructure (per the previous run's receipt and Phase 2a spec)" |

`GREEN: 3/3 trials read the repo as docs-only — the clause is unearned at this model and prompt shape.`

With the two fixture executors that raised the card, the read-out is **5 of 5** reaching the correct
docs-only outcome without a scan-surface clause. The clause's "judge by analogy" carries the
distinction the card asked to have stated, and it carries it at Haiku, the smallest current tier.

**What the green rests on.** Every trial cited provenance evidence — the receipt's `placed` map or
§ 2a-hooks' placement table — and the prompt carried both because a real re-run has both on disk
and in context. The read does not cover a run without that evidence: a receipt missing or carrying
no `placed` map (a legacy version-only stamp) leaves the three scripts with nothing marking them as
the pipeline's own. That is the reopen condition the closing row in
[`docs/decisions.md`](../../docs/decisions.md) names.
