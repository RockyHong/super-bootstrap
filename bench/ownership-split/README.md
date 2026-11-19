# bench/ownership-split — does `harness-bootstrap` place by state?

Test surface for [`DEBT-ymdg`](../../docs/work/DEBT-ymdg.md) (its `## Plan — 2026-11-19 · ownership
split`, the "State detection" pick). The plugin-owned doctrine moves out of the consumer's
`CLAUDE.md` into one whole file the plugin owns, `.claude/rules/harness.md`, and
[`harness-bootstrap`](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md) decides what
to do from the repo's state: fresh → place; split → current / stale / fork; legacy → stop. Four
headless walks, one per state, each read mechanically off the resulting tree and transcript.

**Copy under test: the in-repo dev copy** (`plugins/super-bootstrap/`), loaded with
`claude --plugin-dir <repo>/plugins/super-bootstrap`. The run's cold config dir holds no installed
plugin, and the scorer marks a run invalid when the stream's `init` event lists no `super-bootstrap`
plugin or lists it at another path.

## Walks

| Walk | Fixture ([`make-fixture.sh`](make-fixture.sh)) | Pass ([`score.py`](score.py)) |
|---|---|---|
| `fresh` | code-present git repo, no `CLAUDE.md`, no `.claude/` | `.claude/rules/harness.md` exists and equals the shipped asset (CR-insensitive); `CLAUDE.md` exists and every `## ` heading is in the project set (`Tech Stack`, `Commands`, `Rules (auto-load on file match)`, `Planning`, a `Monorepo…` heading); the receipt's `covered` holds no `CLAUDE.md § <doctrine>` row and holds the `.claude/rules/harness.md` row |
| `legacy` | bootstrapped pre-split: `CLAUDE.md` holds the doctrine sections ([`legacy/CLAUDE.md`](legacy/CLAUDE.md), frozen), no owned file | zero writes — `git status --porcelain --untracked-files=all` empty and `HEAD` unchanged; the final assistant text names `.claude/rules/harness.md` and states the pre-split shape (`LEGACY_SHAPE_PATTERNS`) |
| `stale` | split shape; the owned file equals an older asset version whose sha256 is the receipt's `placed` record; the shipped asset differs | the owned file equals the shipped asset; no approval prompt naming it in the transcript |
| `fork` | split shape; the owned file carries a hand edit — equals neither the shipped asset nor the `placed` record | the transcript carries an overwrite-or-keep choice naming the file; the file is unchanged, unless a second turn answered `overwrite` (then it equals the shipped asset) |

**Expected on today's skill text (the control): every walk fails.** `fresh` puts the doctrine
sections in `CLAUDE.md` and places no owned file; `legacy` does not stop; `stale` and `fork` have no
whole-file lane for that path. The scorer reports each as `pass 0` with a reason line per failed
property.

`legacy`'s zero-writes property alone does not discriminate — a re-run that finds everything current
also writes nothing. The stop-message marker carries that walk's RED.

### The shipped asset is a parameter

`assets/harness.md` does not exist until the split's placement contract lands. Until then:

- `make-fixture.sh --shipped FILE` / `--older FILE` supply the "shipped" and "older" bytes for
  `stale` / `fork`. Defaults: shipped = `assets/harness.md` when it exists, else
  [`standin/harness-shipped.md`](standin/harness-shipped.md) (the doctrine sections of
  `legacy/CLAUDE.md`, in order); older = the shipped bytes minus their last `## ` section; the fork
  bytes = older plus a `## Local Additions` hand edit.
- `score.py --asset FILE` names the asset to compare against; with no `assets/harness.md` on disk
  and no `--asset` it exits 2.
- `run-round.sh` picks the same file for both.

A control round is therefore scored against the stand-in: no skill text can pass `fresh`, `stale` or
`fork` until the plugin ships an asset with those bytes.

### Fixture shape forced, not inherited

`legacy`, `stale` and `fork` start from the consumer runway
[`../assertion-liveness/make-fixture.sh`](../assertion-liveness/make-fixture.sh) places (called, not
copied). That builder follows the shipped skeleton, so its `CLAUDE.md` changes shape when the split
lands. This bench overwrites the three split-sensitive facts per walk — `CLAUDE.md`, the owned file,
the receipt's `covered` / `placed` — and each build ends in guards that assert the walk's starting
state. The frozen `legacy/` pair keeps the legacy walk on the pre-split shape after the skeleton is
cut.

Limit: the rest of the runway (docs, rules, hooks) is whatever that builder places. It places no
`docs/terminology.md` and neither doc-authoring rule, so a walk also sees those as missing and writes
them without a prompt. The scorer keys on the owned file, `CLAUDE.md` and the receipt only.

## Approval prompts in a headless run

`harness-bootstrap` asks the user before a drift write, a migration, and a fork overwrite. A
`claude -p` turn has nobody to answer. The bench does not pre-answer:
[`walk-prompt.txt`](walk-prompt.txt) invokes the skill and tells it to print a question it needs
answered, write nothing that waits on it, and end the turn. Where each walk meets that:

- `fresh` — a fresh install writes from templates and asks nothing; the turn runs to the commit.
- `legacy` — the expected stop is the walk's answer.
- `stale` — the whole-file copy is silent by contract; a prompt naming the owned file is the fail.
- `fork` — the overwrite-or-keep question is the pass; the turn ends on it. `ANSWER=overwrite` (or
  `keep`) adds a second turn (`claude -p --continue`, same cwd and config dir) that gives the answer;
  the scorer then reads the file against that answer.

Tool permission prompts are a second, separate channel: `--permission-prompts none` denies anything
that would prompt, `--permission-mode acceptEdits` plus
`--allowedTools "Bash,Read,Edit,Write,Glob,Grep,Skill"` let the walk's own tool calls through. A run
that lost a tool call to a denial carries `note: N permission denial(s)` on its score row.

Verified against `claude --help` on Claude Code 2.1.328 (flag exists, wording as quoted): `--plugin-dir`
("Load a plugin from a directory … for this session only"), `--permission-prompts none` ("nobody:
anything that would prompt is denied automatically"), `--permission-mode acceptEdits`,
`--allowedTools`, `--continue`, `--setting-sources`, `--strict-mcp-config`. Verified on an earlier
stream of this build: the `init` event carries `plugins` (`name`, `path`) and `skills`; `result`
carries `is_error`, `subtype`, `permission_denials`.

**Unverified — no `claude` process was started while building this bench.** The first run is the
smoke test for each:

- `--plugin-dir` makes `/super-bootstrap:harness-bootstrap` resolve as the prompt's first token in
  `-p` mode, and the `init` event reports the plugin `path` as passed (the scorer normalises
  separators and case; a different spelling reads as `not the dev copy`).
- The fixture's own `.claude/settings.json` pins `super-bootstrap@super-bootstrap`; that pin does not
  pull a second copy of the plugin into a cold config dir.
- The rest of the prompt line reaches the skill as its argument text.
- `acceptEdits` lets `Edit` / `Write` reach `.claude/settings.json` and `.claude/rules/` without a
  prompt. If a run shows permission denials on those paths, re-run with
  `PERM_MODE=bypassPermissions`.
- The skill's nested `/super-bootstrap:commit` call (`fresh`, `stale`) commits in a headless turn.
- `--continue` after a turn that ended on the fork question resumes that session.
- The model prints the fork question as text. An `AskUserQuestion` tool call is also read by the
  scorer, but was absent from the `-p` tool list on the earlier stream.

## Run

```bash
bash selftest/selftest.sh [-v]               # scorer bite check, no claude process (exit 1 on a wrong verdict)
bash make-fixture.sh <tmp>/fx stale          # one fixture, prints its guards
DRY=1 bash run.sh <outdir> fork              # fixture + the exact command, no claude process
bash run.sh <outdir> <walk> [label]          # one walk -> <outdir>/<walk>[-label]/
bash run-round.sh <outdir> [label]           # the four walks, then the score
python3 score.py <outdir> [--asset FILE]     # score again
```

Keep `<outdir>` out of Claude Code's own temp tree (`%TEMP%/claude/…`, a session scratchpad included)
— [`../carrier-equivalence`](../carrier-equivalence/README.md) § Run measured that no project
instruction file loads from there; `run.sh` refuses such a path. `%TEMP%/os-round1` is fine.
Fixtures and streams stay in `<outdir>`, outside the repo.

A round is four headless runs on one model (`MODEL`, default `sonnet`), each a whole skill walk with
writes — far heavier than a one-turn probe. Control = one round on today's skill text; the green
check = one round after the placement contract lands.

## Scorer

One row per walk directory: `walk  valid  pass  reason`. `valid 0` (no stream, no `result` event,
errored run, no assistant text, a missing `meta/` file, dev plugin not loaded) is never a pass or a
fail; its `pass` column reads `-`. A fail's reason joins every failed property with `; `.

- Prompt detection is textual: a match of `PROMPT_PATTERNS` whose own **prompt block** names
  `harness.md` (`prompt_block` in `score.py`). The block is the fence, when the match sits in a
  fenced block; the unindented header line plus its indented body, when it sits on an indented line
  (the skill's prompt format, unfenced); otherwise its paragraph, widened to the labelled section —
  a heading or whole-line-bold line above it, down to the next such line — when one stands above.
  A summary that names the file a few lines above a prompt about another doc does not count
  (`stale-ok-summary-fenced-prompt`, `-plain-prompt`, `-labelled-prose` in the selftest; the first is
  the shape of the real run that the earlier 800-character proximity window failed). Limit: prose
  with no label line between a summary naming the file and an unrelated plain-paragraph prompt in
  the same labelled section still reads as a prompt for the file. Read the quoted snippet on the
  reason line before trusting a `stale` fail on this property alone.
- `LEGACY_SHAPE_PATTERNS` is a guess at a message not yet written; pin it to the fixed stop message
  when that text lands, and add its exact sentence to `selftest/make-trees.py`.

[`selftest/make-trees.py`](selftest/make-trees.py) builds the hand-made result trees at selftest time
and holds each tree's expected verdict and the substring its reason must carry: per walk one
conforming tree and at least one violating tree per property, plus the invalid cases. The trees are
generated, not committed — one carries CRLF bytes, and this repo's `* text=auto eol=lf` would
normalise a committed copy and empty the CR-insensitivity check.
