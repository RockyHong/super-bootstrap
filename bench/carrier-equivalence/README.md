# bench/carrier-equivalence — does the doctrine act the same from any carrier?

Probe for [`DEBT-ymdg`](../../docs/work/DEBT-ymdg.md) (its `## Plan — 2026-11-19`). The doctrine text
in a consumer's `CLAUDE.md` is byte-identical across arms; only the file that carries it moves. The
bench measures whether a headless Sonnet run still routes a card by the doctrine (names a cluster /
the bug route) when the plugin-owned sections arrive via `.claude/rules/`, via an `@` import, or
not at all.

## Arms

All arms start from the consumer-shaped runway that
[`../assertion-liveness/make-fixture.sh`](../assertion-liveness/make-fixture.sh) places (called, not
copied), plus a seeded `docs/work/BUG-k3x9.md` and `cart.py` (`cart_total([])` returns 1).
"Plugin-owned" = every `## ` section of the placed `CLAUDE.md` except `Tech Stack`, `Commands`,
`Rules (auto-load on file match)`, `Planning` (and the H1 title). `make-fixture.sh` prints the split
it applied and asserts byte equality for `rules` / `import`.

| Arm | Where the plugin-owned sections sit |
|---|---|
| `claudemd` | the placed `CLAUDE.md`, whole |
| `rules` | `.claude/rules/harness.md`, no frontmatter; `CLAUDE.md` keeps title + project sections |
| `import` | `.claude/harness.md`, pulled in by an `@.claude/harness.md` line under the title |
| `none` | removed, placed nowhere — the control proving the score can miss |

## Contexts

Task prompt ([`task-prompt.txt`](task-prompt.txt)), verbatim in all three:
`Pick up card BUG-k3x9. State how you will proceed with it, then stop. Do not change any file.`

- `main` — one `claude -p` turn.
- `subagent` — [`subagent-prompt.txt`](subagent-prompt.txt) makes the main turn dispatch one
  general-purpose subagent with the task verbatim; the subagent's own text is scored
  (`--forward-subagent-text`). A dispatch prompt that is not the task verbatim = invalid run.
- `compact` — ONE `claude -p --input-format stream-json` process fed three user turns by
  [`drive-turns.py`](drive-turns.py) (shape of `../consult-hook/run-multiturn.py`: next turn sent only
  after the previous `result`; `bench_turn` markers in the stream): filler
  ([`filler-prompt.txt`](filler-prompt.txt)), `/compact` ([`compact-prompt.txt`](compact-prompt.txt)),
  the task. The process is never restarted, so an instruction load logged after the compaction marker
  is an in-process re-injection. The `compact_boundary` must precede the task turn, else invalid.
- `resume-compact` — the old three-process `--resume` form, kept in `run.sh`, NOT in the round: turn 3
  is a fresh process that reloads every file at start, so it measures resume, not compaction.

## Readings (per run, [`score.py`](score.py))

- `valid` — 0 with a reason: errored / no assistant text; subagent dispatch not verbatim or not
  exactly one Agent call; compact without marker.
- `loaded` — the arm's carrier file appears in `.probe/instructions.log` (`InstructionsLoaded` hook).
  `n/a` for `none`; `unknown` when no usable hook line. `compact`: `1` when the carrier file has a
  line (main session id) timestamped after the compaction marker (any `load_reason`, named in the
  note); `0` when only other files loaded after it; `unknown` when nothing loaded after it.
- `behavior` — 1 when the scored text matches the regexes in `BEHAVIOR_PATTERNS` (`cluster N` (markdown between word and digit tolerated), or
  `route` within 80 chars of `root cause|reproduce`). Scored text: final assistant text of the task
  turn (`main`, `compact`); concatenated forwarded subagent text (`subagent`, fallback to the Agent
  tool_result, noted).

Pass rule: each new carrier within one behavior miss of `claudemd`; both `none`/`main` runs miss; no
invalid run left unexplained. After the round: stop and report; the author decides further spend.

## Run

```bash
bash make-fixture.sh <tmp>/fx rules          # one fixture, prints the split
bash run.sh <outdir> <arm> <context> <rep>   # one run -> <outdir>/runs/<arm>-<ctx>-r<rep>.jsonl (+ .probe/)
bash run-round.sh <outdir>                   # the 20-run round, skips finished runs, then scores
python3 score.py <outdir>/runs               # score again
bash selftest/selftest.sh                    # scorer bite check (exit 1 on a wrong verdict)
```

Keep `<outdir>` out of Claude Code's own temp tree (`%TEMP%/claude/…`, a session scratchpad included): with the fixture under it, no run logged a project instruction file — only the operator's `~/.claude/CLAUDE.md` loaded — so every `loaded` reading was 0 and the round measured nothing; under `%TEMP%/ce` the same fixture logged `CLAUDE.md` at `session_start`. A round whose `claudemd`/`main` rows read `loaded 0` is invalid, whatever its behavior column says.

Fixtures and streams live in `<outdir>` (outside the repo); copy the small `scores.tsv` and the
`.probe/` logs back if the round is to be recorded.

## Doc-grounding facts and their limits

- `/compact` through `claude -p --resume` is documented only for the Agent SDK. Smoke-tested on this
  build (Claude Code 2.1.328): it runs, see Observed below. Sent as a stream-json user message in one
  process it also compacts.
- Whether an `@path` import is re-injected after compaction is undocumented; the `import` x `compact`
  cell is that probe (the one-process form removes the resume-reload confound).
- `InstructionsLoaded` fields are from the hooks docs; observed here: `session_id`, `file_path`,
  `memory_type`, `load_reason` (`session_start`). No `agent_type` seen; raw JSON is kept in
  `.probe/instructions.raw.jsonl`.

## Observed on the build (smoke, 4 runs)

- Cold config authenticates (credentials copied into `coldcfg`); the hook logs one line per file.
- **Contamination, unresolved:** the operator's `~/.claude/CLAUDE.md` still loads in every run
  (`InstructionsLoaded` logs it) despite `CLAUDE_CONFIG_DIR`, `HOME`/`USERPROFILE` overrides and
  `--setting-sources project,local`. It is constant across arms; the `none` control shows whether it
  alone can produce the routing text.
- Git Bash rewrites a bare `/compact` argument to `C:/Program Files/Git/compact`; `run.sh` sets
  `MSYS_NO_PATHCONV=1`. `claude` waits 3 s on stdin without `< /dev/null`.
- `/compact` runs headless: stream carries `system/status compacting`, `compact_result: success`, a
  `compact_boundary` message; `compact.log` gets `SessionStart compact` and `PostCompact manual`.
  In the one-process form the hook then logs re-injection lines: `CLAUDE.md` with
  `load_reason=compact`; for the `import` arm `.claude/harness.md` with `load_reason=include` plus
  `CLAUDE.md` `compact` (same timestamp). In the old resume form no compact-reason line appeared.
- `--forward-subagent-text` is accepted; subagent messages arrive with non-null `parent_tool_use_id`
  (its input prompt as a `user` message, then assistant text). The hook logs no separate
  subagent load line.
- `--strict-mcp-config` removes the account-level claude.ai connectors from the run.
- The run is read-only by `--permission-mode default` + `--disallowedTools "Edit,Write,NotebookEdit,Bash"`.
