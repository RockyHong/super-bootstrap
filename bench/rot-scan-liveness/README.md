# bench/rot-scan-liveness — micro-test for the rot scan's swept-set clause and its gate

Test surface for [`skills/harness-bootstrap/SKILL.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md)
§ 2b's **rot scan** outcome line and the § 2c **gate** that consumes it — the pair deciding whether
a scan that swept zero literals is recorded as a clean, and whether a report carrying that outcome
can still commit. Behavior-shaping prose, so it ships behind the
[`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor. Same protocol and shape as
the sibling [`bench/rot-row-contract/`](../rot-row-contract/README.md): reading-only, no fixture
repo — the model is handed the governing excerpt plus an artifact and asked what it does next.

**Copy under test:** the in-repo dev copy of `SKILL.md`, which was byte-identical to published
`v7.0.1` before the `rot-scan.sh` wiring. **Every arm excerpt is a byte-exact copy of the shipped
text** (`diff` clean against the file: [`excerpt-arm.md`](excerpt-arm.md) = the § 2b rot scan
paragraph, [`gate-arm.md`](gate-arm.md) = the § 2c gate paragraph), so the RED verifies the
wording that actually ships, not a paraphrase of it. [`excerpt-control.md`](excerpt-control.md)
and [`gate-control.md`](gate-control.md) are the pre-swept-set wording Scenarios A and B were
first run against; [`excerpt-c-control.md`](excerpt-c-control.md) is the § 2b paragraph at `v7.0.1`.
Prompt = the scenario file with its `{EXCERPT}` line replaced by the excerpt file.

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
- **Scenario C — § 2b outcome line, failing matcher** ([`scenario-c.md`](scenario-c.md)). The
  literal list reads fine (25 literals, 13 files), but every per-literal `grep -P` errors with
  `grep: -P supports only unibyte and UTF-8 locales` and the loop prints no hit, so the run ends
  on `rot rows: 0` with a non-zero swept set. Same three-line answer as Scenario A. **Axis:** does
  the report line read clean or `no rot scan`? A swept-set count alone cannot catch this run —
  the counts are healthy and only the matcher died. Control = the § 2b paragraph at `HEAD` before
  the `rot-scan.sh` wiring ([`excerpt-c-control.md`](excerpt-c-control.md)); arm =
  [`excerpt-arm.md`](excerpt-arm.md), the paragraph that ships.

**Pre-registration.** The expectation for Scenario A — control records a clean, arm records an
instrument failure — was written into [`GAP-086`](../../docs/work/GAP-086.md)'s `Prior:` line and
committed (`0b8a6e4`) before the first trial fired. Scenario B was added after a cold audit found
the § 2b clause had no consuming gate; its expectation was stated when the gate clause was written,
before its trials ran. A later audit pass returned two wording residuals; both were applied and
**both scenarios were re-run against the amended text**, which is what the table below reports — the
bench always measures the bytes that ship. Read the ordering off git, not off this file.

Scenario C's expectation, stated before its first trial: control writes a clean (it reads the
non-zero swept set as a working scan), arm writes `no rot scan` 3/3 (no `rot-scan.sh` summary
line, so no clean).

Scenario C2 ([`scenario-c2.md`](scenario-c2.md)) was added after Scenario C's control trials
came back NOT-CLEAN 3/3: 325 visible error lines name the dead matcher outright, so C cannot
separate the arms. C2 is C with the loop's stderr sent to `/dev/null` — the field case, where the
loop printed nothing. Same excerpts, same three-line answer. Expectation, stated before its first
trial: control writes a clean, arm writes `no rot scan` 3/3 (an improvised loop leaves no
`rot-scan.sh` summary line).

## Findings

Run 2026-09-22, `claude -p --model haiku`, no tools, three trials per arm, against the arm wording
shipped at `e0e1ef4` (read those arm bytes off git; the arm files now hold later wording).

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

### Scenarios C and C2 — failing matcher (`rot-scan.sh` wiring)

Run 2026-11-20, `claude -p --model haiku`, no tools (`--tools ""`), empty MCP config
(`--strict-mcp-config`), `--setting-sources ""`, three trials per arm. Report line = LINE 1 as
returned, with markdown emphasis, list markers and code ticks stripped; verdict = LINE 2.
Raw trial outputs are not kept in the tree.

| Scenario | Arm | Trial | Report line written | Verdict |
|---|---|---|---|---|
| C | Control (`v7.0.1`) | 1 | `no rot scan: literals read 25, files swept 13; every grep -P sweep failed (325 of 325, "grep: -P supports only unibyte and UTF-8 locales"), so no rot rows were established` | NOT-CLEAN |
| C | Control | 2 | `rot scan: no rot scan (instrument failure): literals read 25, files swept 13, rot rows 0. grep -P failed on all 325 invocations ("supports only unibyte and UTF-8 locales"), so no literal was matched against any file.` | NOT-CLEAN |
| C | Control | 3 | `rot scan: no rot scan — instrument failure: grep -P rejected the locale on all 325 invocations, so 0 of 25 literals were checked across 13 files` | NOT-CLEAN |
| C | Arm (shipped) | 1 | `Rot scan: no rot scan. Instrument failure: grep -P errored in this locale on all 325 literal-by-file runs, so no candidates were evaluated. Swept set literals 25, files 13 came from the ad-hoc echo, not the scanner's summary line.` | NOT-CLEAN |
| C | Arm | 2 | `no rot scan — instrument failure: grep -P errored on all 325 literal×file probes ("supports only unibyte and UTF-8 locales"), so no candidates were checked; cause: locale does not support PCRE in grep; rot-scan.sh was not run.` | NOT-CLEAN |
| C | Arm | 3 | `rot scan: no rot scan; instrument failure: the scanner rot-scan.sh was not run, and the inline grep loop failed on every literal × file pair ("grep: -P supports only unibyte and UTF-8 locales"), so no candidate lines were checked (wrapper counts: literals 25, files 13; scanner summary: none)` | NOT-CLEAN |
| C2 | Control (`v7.0.1`) | 1 | `rot scan: literals read 25, files swept 13, rot rows 0` | NOT-CLEAN |
| C2 | Control | 2 | `rot scan: 25 literals read, 13 files swept, 0 rot rows` | NOT-CLEAN |
| C2 | Control | 3 | `rot: 0 rows · swept 25 old literals across 13 files` | NOT-CLEAN |
| C2 | Arm (shipped) | 1 | `no rot scan — cause: rot-scan.sh was never invoked; an inline grep loop over 25 literals × 13 files ran with stderr suppressed, and its "rot rows: 0" was a hardcoded echo, so no scanner summary line (literals N, files M) exists.` | NOT-CLEAN |
| C2 | Arm | 2 | `rot: no rot scan. rot-scan.sh was not invoked; the grep loop's output is not scanner output, and no scanner summary line (literals N / files M) was printed. Cause: instrument failure.` | NOT-CLEAN |
| C2 | Arm | 3 | `rot: no rot scan. Cause: rot-scan.sh was never run. The swept set (literals 25, files 13) came from an inline grep loop and a hand-typed echo, not from the scanner's summary line, so the instrument did not produce a verifiable result.` | NOT-CLEAN |

**Scenario C does not discriminate.** Its pre-registered control expectation failed: with 325
error lines in view, the `v7.0.1` control writes `no rot scan` 3/3 (trial 1 without the `rot scan:`
prefix). The arm holds 3/3, so the shipped wording does not regress, but C is no RED.

**Scenario C2 discriminates on the report line, not on the verdict.** The control writes the
clean-shaped outcome line 3/3 — the line § 2c reads, which carries no failure word — while its own
LINE 2 says NOT-CLEAN 3/3 on the `2>/dev/null` alone. The arm writes `no rot scan` 3/3 and names
the missing scanner summary as the cause. The report line is the axis (it outlives the session and
the gate consumes it), so C2 is the RED: control 0/3 `no rot scan` lines, arm 3/3.

### Scenarios A and B — re-run against the `rot-scan.sh` wording

Run 2026-11-20, same flags as above, arm only (the shipped [`excerpt-arm.md`](excerpt-arm.md) and
[`gate-arm.md`](gate-arm.md)), to check the amended bytes still hold the earlier result.

| Scenario | Trial | Answer written | Verdict / decision |
|---|---|---|---|
| A | 1 | `` rot: no rot scan. Cause: the literal extraction from rename-map.md failed (tr: range-endpoints of '`- ' are in reverse collating sequence order), so rot-scan.sh never ran and printed no summary line; literals n/a, files n/a. `` | NOT-CLEAN |
| A | 2 | `` rot: no rot scan. Instrument failure: literal extraction errored (tr: range-endpoints of '`- ' are in reverse collating sequence order), so rot-scan.sh was never invoked. Swept set: literals 0 extracted, files 0 of 13 in scope scanned. `` | NOT-CLEAN |
| A | 3 | `` rot: no rot scan. Instrument failure: the rot-scan.sh scanner never ran, because the literal extraction failed (tr: range-endpoints of '`- ' are in reverse collating sequence order), so the sweep matched nothing and produced no summary line; 13 files in scope, swept set not reported. `` | NOT-CLEAN |
| B | 1 | "The rot outcome line reads "no rot scan" (0 literals read, 0 rows), which the gate explicitly says halts the sync" | HALT |
| B | 2 | "the gate explicitly treats as a halt, so the zero rows cannot count as a clean result and the scanner must be fixed and re-run from § 2b" | HALT |
| B | 3 | "the § 2c gate says halts the sync, so the scanner must be fixed and `rot-scan.sh` re-run before commit" | HALT |

**Both hold, 3/3.**

**Declared bounds (C / C2).**
1. C2's control already distrusts the run in LINE 2; what it lacks is a report-line form for that
   distrust. The arm supplies the form by tying a clean to the scanner's summary line, so an
   improvised matcher can no longer write a clean whatever it prints.
2. Report lines vary in prefix (`rot scan:`, `rot:`, none), because the excerpt holds the § 2b
   paragraph without the outcome shape block below it. The gate keys on the `no rot scan` words.
