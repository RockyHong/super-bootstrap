# bench/triage-taste-shape — does a taste card get grounding, or an invented fork?

Test surface for `BUG-084`: on a taste-grade card (the author flags copy lines that read wrong and
wants replacement candidates), the shipped [`agents/triage.md`](../../plugins/super-bootstrap/agents/triage.md)
had only one `surface` shape — `### Decision needed` with options, a recommendation and `settles by:` —
so the agent invented a fork; [`skills/triage/SKILL.md`](../../plugins/super-bootstrap/skills/triage/SKILL.md)
step 3 then climbed it, ruled it into a `## Design` block and put the rest to the author as an MCQ.
The fix is behavior-shaping prose, so it ships behind the [`skill-authoring`](../../.claude/rules/skill-authoring.md)
RED floor: control (the contracts as they stood) must fail on the fixture before the treatment ships.

## Fixture

[`make-fixture.sh`](make-fixture.sh) builds `harbor` from [`fixture/`](fixture/), one pristine copy per
agent run: 13 ambient lines in `content/ambient.json` keyed `ambient.{time}.{noun}`, a scheduler
`src/ambient.py` that enumerates the keys (blast), a ratified spec `docs/specs/ambient-voice.md`, and
the card `docs/work/GAP-001.md`. The card reproduces the incident's shape:

- four flagged lines, one of them (`ambient.dusk.lamp`) the spec's positive exemplar, cited twice;
- a factual error — "dusk set (5 rows)": the dusk family is 6, and one flagged line is `ambient.night.nets`;
- the ask is the author's own: "Want replacement candidates for each, to pick from."

`docs/work/README.md`, `TEMPLATE.md` and `docs/decisions.md` come from the `harness-bootstrap` assets
as they stand at build time, so a control fixture carries the control thread contract.

## Arms

[`make-arms.sh`](make-arms.sh) `<label>` snapshots both contracts, frontmatter stripped:
`arm-agent-<label>.md` (agent body) and `arm-gateway-<label>.md` (skill body). `control` was taken
before the prose edit, `treatment` after it.

- **Agent arm** — a cold `general-purpose` subagent (Agent tool, `model: opus`; the agent is
  `model: inherit`) told to take the arm file as its system prompt and ground `GAP-001` in its own
  fixture copy ([`prompt-agent.txt`](prompt-agent.txt)). The card it leaves is copied to `runs/`.
- **Gateway arm** — a cold subagent, text-only, given the skill arm and a card that already carries a
  Verdict, asked to run step 3's absorb and answer `USER_MESSAGE` / `CARD_APPENDS` / `TOOL_CALLS` /
  `WHY` ([`prompt-gateway.txt`](prompt-gateway.txt)). Three inputs:
  - `taste` — [`gateway-input-taste.md`](gateway-input-taste.md), a fixed hand-written grounding-only
    `surface` block (`### Taste needed`), identical across arms, so only the skill text differs;
  - `incident` — the control agent's own cards (`runs/agent-control-r{1,2}.card.md`), the option set
    the incident produced;
  - `e2e` (treatment only) — the treatment agent's cards.

Both arms run in-session subagents, so they inherit this repo's ambient context; the fixture and
the arm file are the only task inputs they are pointed at.

## Scoring

[`score.py`](score.py) `agent | gateway <files>` — exit 1 on any failed assertion, each failure
printed `FAIL <file> <assertion>: <why>`.

- agent: `one_verdict`, `no_options` (no `- A —` / `- (a)` / `- Option B` line in the Verdict
  block), `no_reco`, `no_settles`; readings `kind`, `shape` (taste / decision), `cites_spec`,
  `corrects_claim`.
- gateway: `no_design` (no `## Design` in `CARD_APPENDS`), `no_ask_tool` (no AskUserQuestion in
  `TOOL_CALLS`; a declared "No AskUserQuestion" does not count). Whether the gateway produced the
  candidates is hand-read.

[`bite.sh`](bite.sh) proves every assertion reds on a violating input in [`bite/`](bite/) and passes
on a clean one.

```bash
bash make-arms.sh control            # before the prose edit
bash make-fixture.sh <scratch>/agent-control-r1   # one per run
# dispatch the arms per prompt-agent.txt / prompt-gateway.txt, copy cards + responses into runs/
python score.py agent runs/agent-*.card.md
python score.py gateway runs/gateway-*.md
bash bite.sh
```

Results: [`FINDINGS.md`](FINDINGS.md).
