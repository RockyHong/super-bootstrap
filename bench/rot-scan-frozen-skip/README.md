# bench/rot-scan-frozen-skip — micro-test for the rot scan's frozen-provenance skip

Test surface for [`skills/harness-bootstrap/SKILL.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md)
§ 2b's **Rot scan** scope sentence — the clause that decides whether a `dimension: history`
doc is swept for renamed-away literals. Behavior-shaping prose, so it ships behind the
[`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor: the wording is held
against the wording it replaces, reading-only (no fixture repo — the model is handed the
instruction plus a three-file synthetic scope and asked which rot rows it emits).

## Protocol

Arms run headless (`claude -p --model haiku`, no tools) with the prompt on stdin. The prompt
carries a one-entry rename map (`sp-bootstrap` → `super-bootstrap`) and three pipeline-owned
files: a `CLAUDE.md` carrying the dead literal (a legitimate rot target that must survive the
skip), a clean `docs/overview.md`, and a `docs/decisions.md` declaring `dimension: history`
with an append-only scope header and a closed-fork row quoting the dead literal. The model
returns the rot rows it emits, one `{file}:{line}` per line.

- **Control** — the pre-fix scope sentence: `grep every pipeline-owned file in scope for each
  entry's old literal (whole-token match — avoid URL / identifier false hits).` Run 3×.
- **Arm** — the shipped sentence, same text plus the skip clause: `…, skipping any file whose
  leading frontmatter declares dimension: history — frozen provenance preserves old literals by
  construction, so a hit there is undeclinable-once and re-fires every sync. The skip is this
  lane only: those files' pipeline-owned sections stay in the per-section drift check.` Run 3×.
- **Axis under test** — the `docs/decisions.md` row. Control emits it → RED; arm must not, while
  the `CLAUDE.md` row is unaffected either way. An arm that also drops the `CLAUDE.md` row has
  over-skipped and fails.

## Findings

Run 2026-09-21, `claude -p --model haiku`, no tools, three trials per arm.

| Arm | Trial | `decisions.md` row (axis) | `CLAUDE.md` row (must survive) |
|---|---|---|---|
| Control (pre-fix) | 1 | not emitted | not emitted |
| Control | 2 | **emitted** | emitted |
| Control | 3 | **emitted** | emitted |
| Arm (shipped) | 1 | not emitted | emitted |
| Arm | 2 | not emitted | emitted |
| Arm | 3 | not emitted | not emitted |

**Verdict: RED → GREEN on the axis under test.** Control emitted the frozen row in 2 of 3
trials, citing the scope sentence's own "every pipeline-owned file in scope" — the recurring
undeclinable row the card reports, reproduced. The arm emitted it in 0 of 3, two of those
naming the frontmatter predicate explicitly. The legitimate `CLAUDE.md` target survives the
skip, so the clause narrows the lane rather than the scan.

**Off-axis noise, both arms.** Control trial 1 and arm trial 3 dropped the `CLAUDE.md` row too,
each reasoning that `/sp-bootstrap:todo` is a command-reference identifier caught by the
sentence's pre-existing "avoid URL / identifier false hits" guard. That reading predates this
fix, appears once on each side, and is orthogonal to the frozen-provenance clause — it is the
referent-ambiguity case `assets/rename-map.md` § Scan guidance already owns, not a regression
introduced here.
