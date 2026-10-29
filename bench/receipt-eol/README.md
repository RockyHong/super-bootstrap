# bench/receipt-eol — micro-test for the runway receipt's LF-only contract

Test surface for the three prose writers of `.claude/super-bootstrap-runway.json`:
[`harness-bootstrap/SKILL.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md)
§ 2c Receipt write,
[`harness-bootstrap/assets/hooks-ensure-infra.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks-ensure-infra.md)
(the `placed` record and the retire step), and
[`autorun/assets/ensure-infra.md`](../../plugins/super-bootstrap/skills/autorun/assets/ensure-infra.md)
(the worktree template's `placed` record). No script writes the receipt — the executing agent picks
its own writer — so the line-ending contract is behavior-shaping prose and ships behind the
[`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor. The bench drives the
`hooks-ensure-infra.md` `placed` paragraph; the other two writers carry the same sentence.

- `make-fixture.sh <dir>` — consumer-shaped scratch repo: `core.autocrlf=true`,
  `.gitattributes` `* text=auto eol=lf`, one commit holding `.claude/hooks/commit-channel.sh`
  and an LF receipt whose `placed` entry for that hook is a stale all-zero hash.
- `prompt.txt` — the task: the hook resolved current with sha256 `@HASH@` (filled by the
  runner); carry out the step text for it; do not commit. It names no writer.
- `run.sh <control|arm> <fixture-dir> <out-file>` — builds the fixture, embeds the step
  paragraph verbatim (control: `c033fa9`, pre-fix; arm: the working tree), runs the agent, prints
  the oracle.

## Protocol

Headless, fixture as cwd, prompt on stdin:
`claude -p --model haiku --tools Bash,Read --allowedTools Bash,Read --setting-sources project,local --permission-prompts none`.
The prompt carries the step text verbatim, so the copy under test is this repo's working tree, not
the installed plugin.

- **Tools: `Bash,Read` only.** Claude Code treats `.claude/` files as sensitive: in a headless run
  the Edit/Write tools are denied on the receipt under `--permission-prompts none` and under
  `--permission-mode acceptEdits`, and an `Edit(...)` allow rule in the fixture's
  `settings.local.json` does not lift it. The agent then stops without writing, so the run says
  nothing. Bash is the writer class the bug lives in (the consumer's file-tool writes stayed LF),
  and `--tools` keeps the agent on it without naming any program.
- **Oracle** — CR bytes in the receipt after the run, `tr -cd '\r' < <receipt> | wc -c`
  (0 = pass), beside `git ls-files --eol` for the receipt. `grep -c $'\r'` is not usable on this
  host: under Git Bash it printed the file's line count for an LF file inside `$(...)`, and `0`
  for a CRLF file when piped.
- **Runs** — control until the first CRLF, at most 5; arm ×3, one fresh fixture per run.

## Findings

Run 2026-10-29, Windows 11, Git Bash, `jq` 1.7.1 on `PATH`.

| Run | step text | writer the agent used | `cr_bytes` | `git ls-files --eol` |
|---|---|---|---|---|
| control (5 runs, harness setup) | `c033fa9` | none — Edit denied on `.claude/`, agent stopped | 0 (file untouched) | `i/lf w/lf` |
| control 6 | `c033fa9` | `jq` read-modify-write | 12 | `i/lf w/crlf` |
| arm 1 | working tree | Python (`python -I`) read-modify-write | 0 | `i/lf w/lf` |
| arm 2 | working tree | `sed` replace piped through `tr -d '\r'` | 0 | `i/lf w/lf` |
| arm 3 | working tree | `jq` update piped through `tr -d '\r'` | 0 | `i/lf w/lf` |

RED: the first control run that wrote the receipt reproduced the consumer's report byte for byte —
`i/lf w/crlf attr/text=auto eol=lf`, every line CRLF, `placed` updated correctly. The five
earlier control runs wrote nothing (the permission setup above was found and fixed across them);
they are harness setup, not control results.

GREEN: all three arm runs wrote the correct `placed` hash with 0 CR bytes, across three different
writers — the contract holds whatever writer the agent picks, `jq` included.

Fixture noise, not a result: the fixture hook is a stub, so its hash differs from the shipped
`commit-channel.sh` asset. Agents that searched outside the fixture found the shipped asset and
reported the mismatch (one started a `find /`). The receipt write did not depend on it.
