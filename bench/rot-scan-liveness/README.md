# bench/rot-scan-liveness — micro-test for the rot scan's swept-set clause and its gate

Test surface for [`skills/harness-bootstrap/SKILL.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md)
§ 2b's **rot scan** outcome line and the § 2c **gate** that consumes it — the pair deciding whether
a scan that swept zero literals is recorded as a clean, and whether a report carrying that outcome
can still commit. Behavior-shaping prose, so it ships behind the
[`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor. Same protocol and shape as
the sibling [`bench/rot-row-contract/`](../rot-row-contract/README.md): reading-only, no fixture
repo — the model is handed the governing excerpt plus an artifact and asked what it does next.

**Copy under test:** the in-repo dev copy of `SKILL.md`, which was byte-identical to published
`v2.52.0` before this change. **Both arm excerpts are byte-exact copies of the shipped text**
(`diff` clean against the file), so the RED verifies the wording that actually ships, not a
paraphrase of it.

## Protocol

Arms run headless (`claude -p --model haiku`, no tools, empty MCP config) with the prompt on stdin,
three trials per arm. Control = the pre-fix wording taken from `git show HEAD:`, arm = the shipped
wording; the scenario body is byte-identical across arms, so the clause is the only variable.

- **Scenario A — § 2b outcome line.** The transcript shows the literal-extraction command failing
  (a `tr` range error), leaving the literal variable empty, the loop iterating zero times, and the
  step printing `rot rows: 0` over 13 pipeline-owned files. The model answers with the rot outcome
  it writes into `.claude/bootstrap-sync-report.md` *verbatim as it would appear in the file*, then
  CLEAN or NOT-CLEAN, then a justification. **Axis:** does the line that lands in the report — which
  outlives the session and is what § 2c and any later reader consume — preserve the distinction?
- **Scenario B — § 2c gate** (the decisive one). A sync report whose four section rows are all
  `✓ matches` and whose rot line reads `no rot scan — 0 literals read, 13 files swept, 0 rows`,
  handed to a model asked whether the gate commits or halts. **Axis:** is the instrument-failure
  outcome expressible in the gate's vocabulary at all, or does a dead scan reach a commit? A gate
  that cannot stop the pipeline is not a gate.

**Pre-registration.** The expectation for Scenario A — control records a clean, arm records an
instrument failure — was written into [`GAP-086`](../../docs/work/GAP-086.md)'s `Prior:` line and
committed (`0b8a6e4`) before the first trial fired. Scenario B was added after a cold audit found
the § 2b clause had no consuming gate; its expectation was stated when the gate clause was written,
before its trials ran. A later audit pass returned two wording residuals; both were applied and
**both scenarios were re-run against the amended text**, which is what the table below reports — the
bench always measures the bytes that ship. Read the ordering off git, not off this file.

## Findings

Run 2026-09-22, `claude -p --model haiku`, no tools, three trials per arm, against the final shipped
wording of both clauses.

### Scenario A — § 2b outcome line

| Arm | Trial | Report line written | Verdict |
|---|---|---|---|
| Control (pre-fix) | 1 | `rot scan: clean (0 rows)` | **CLEAN** |
| Control | 2 | `**Rot scan:** 0 rot rows found — no stale literals detected in 13 pipeline-owned files.` | **CLEAN** |
| Control | 3 | `**Rot scan:** 0 rows found — no stale rename-map literals in pipeline scope.` | **CLEAN** |
| Arm (shipped) | 1 | `no rot scan — tr command failed extracting rename-map entries (0 literals read, 13 files scanned)` | NOT-CLEAN |
| Arm | 2 | `no rot scan — 0 literals swept, 13 files (extraction error: tr range reversal)` | NOT-CLEAN |
| Arm | 3 | `no rot scan — tr range error prevented literal extraction (swept: 0 old literals, 13 files)` | NOT-CLEAN |

Control reports a clean **3/3**, each trial reasoning from the row count alone — trial 3 states it
outright: "Zero rot rows confirms the repo carries no stale renamed-away literals." Not one control
trial mentions the `tr` error sitting in the transcript it was handed, and none states the swept
set, so no control report line is self-checking. Every arm trial wrote `no rot scan` carrying both
counts.

### Scenario B — § 2c gate

| Arm | Trial | Gate decision | Reasoning quoted |
|---|---|---|---|
| Control (pre-fix) | 1 | **COMMIT** | "drift and rot checks are complete with findings resolved" |
| Control | 2 | **COMMIT** | "rot scan found nothing to resolve" |
| Control | 3 | **COMMIT** | "no drifts, rot, or registration changes detected" |
| Arm (shipped) | 1 | HALT | "0 literals read; per gate § 2c, return to 2b and re-run with a working literal list" |
| Arm | 2 | HALT | "zero swept literals means the scan found no working literal list" |
| Arm | 3 | HALT | "rot scan swept zero literals — report halts per the gate rule" |

**Verdict: RED → GREEN, 3/3 in both directions on both scenarios.** The pre-fix pair fails
end-to-end: § 2b records a dead scan as a clean, and § 2c commits on it while restating the very
fact that should have stopped it ("rot scan found nothing to resolve"). The shipped pair records
`no rot scan` 3/3 and halts on it 3/3.

**Declared bounds.**
1. Scenario A hands the model the `tr` error as visible text, and the control still missed it 3/3.
   A real executor produced that error itself, possibly several tool calls earlier, and may never
   re-read it — so the live failure rate is at least this bad. The instance that motivated the card
   is one such occurrence (this repo, sync `88ce1df`), where the error scrolled past and the clean
   was recorded.
2. N=3 per arm per scenario, one model tier. This shows the clauses move the report line and the
   gate decision, not that no other phrasing would.
