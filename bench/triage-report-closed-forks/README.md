# bench/triage-report-closed-forks — micro-test for `triage-report`'s Closed Forks source line

Test surface for [`agents/triage-report.md`](../../plugins/super-bootstrap/agents/triage-report.md)
step 1 and § Output contract (`tools: Read, Grep, Glob`, `model: sonnet`): does the verdict sheet
carry one unconditional source line for `docs/decisions.md` § Closed Forks, so a clean read and an
unread source stop looking alike? Behavior-shaping prose, so it ships behind the
[`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor. Sibling of
[`bench/log-closed-forks/`](../log-closed-forks/README.md), which pins the same defect class in the
`log` door. The gateway's sheet check in
[`skills/triage-report/SKILL.md`](../../plugins/super-bootstrap/skills/triage-report/SKILL.md)
step 2 is the consumer that reads the line; it is not measured here.

**Copy under test:** the in-repo dev copy. Control = [`agent-control.md`](agent-control.md),
byte-exact `git show HEAD:plugins/super-bootstrap/agents/triage-report.md` at `022766c`. Arm = the
working-tree `agents/triage-report.md`.

## Fixture

[`fixture/`](fixture/) is a minimal consumer repo for the bash CLI `tally`: `README.md`, `tally`,
`docs/techstack.md`, `docs/decisions.md` (the shipped skeleton plus three Closed Forks rows),
`docs/work/` (README with high-water `BUG-004` · `DEBT-001` · `GAP-005`, TEMPLATE, two open cards
as the dedup surface), and `.review/docs-consistency-2026-10-09.md` (one scan report, two findings):

1. Port the script to Python — collides with the row *Port the `tally` CLI from bash to Python for
   speed*.
2. README does not say where `tally.csv` lands — clean: no row touches it, no open card covers it.

## Protocol

Each trial copies `fixture/` to a fresh scratch directory and dispatches one cold
`general-purpose` subagent (Agent tool, `model: sonnet`) with [`scenario.md`](scenario.md),
`{ROOT}` = the scratch copy, `{AGENT}` = the arm's agent file, `{PLUGIN_ROOT}` =
`plugins/super-bootstrap`. The scenario names no outcome line; the agent text is the only variable.

**Absent trial:** delete `docs/decisions.md` from the scratch copy before dispatch.

**Axis:** the verdict sheet carries a `decisions.md § Closed Forks` line that accounts for the
clean finding (a row count with `collisions: … | none`, or `absent`).

**Pre-registration:** stated before the first trial ran — control emits no source line for the
clean finding, and its absent trial is indistinguishable from its clean trial; the arm's sheets
carry the line, `absent` on the absent trial.

## Findings

Run 2026-10-10, `model: sonnet`, cold subagents.

| Arm | Trial | Finding 1 (collides) | Closed Forks source line on the sheet |
|---|---|---|---|
| Control | 1 | dismiss, cites the fork row | **none** |
| Control | 2 | dismiss, cites the fork row | **none** |
| Control | 3 | dismiss, cites the fork row | **none** |
| Control | absent | dup `GAP-005` (no fork to cite) | none as a field; volunteered in prose: "`docs/decisions.md` does not exist in this repo … There was no Closed Forks surface to check" |
| Arm | 1 | dismiss, cites the fork row | `decisions.md § Closed Forks — 3 rows, collisions: F1` |
| Arm | 2 | dismiss, cites the fork row | `decisions.md § Closed Forks — 3 rows, collisions: Finding 1.` |
| Arm | 3 | dismiss, cites the fork row | `decisions.md § Closed Forks — 3 rows, collisions: finding 1.` |
| Arm | absent | dup `GAP-005` | `decisions.md § Closed Forks — absent` |

Control on the clean finding, verbatim (trial 1): "No open card covers it. BUG-004 is about
`chmod +x`, and GAP-005 is about the Python rewrite." — the dedup surface is accounted for;
`decisions.md` is not.

**Verdict: RED → GREEN.** Control: 0/3 sheets carry a source line; each surfaces the collision on
finding 1, so the read fires on a hit and is silent on a miss. Arm: 4/4 sheets carry the line, the
absent trial as `absent`.

**Scope note — the `triage` agent.** The same hit-only wording sits in
[`agents/triage.md`](../../plugins/super-bootstrap/agents/triage.md) § Aim + blast mechanics. Its
HEAD control was run on the same fixture (clean card `BUG-004`, ×4 `opus`, ×2 `sonnet`, absent ×1):
6/6 clean verdicts and the absent verdict name the `decisions.md` outcome in their Aim line (e.g.
"No `docs/decisions.md` Closed Forks row touches install docs or file mode"; "`docs/decisions.md`
does not exist in this repo, so no closed fork applies"). The defect did not reproduce there, so
that agent stays unchanged.

## Declared bounds

1. N=3 clean + 1 absent per arm, one model tier. Shows the wording moves the trace, not that no
   other phrasing would.
2. The `unresolved` path (heading or table missing) is not exercised.
3. Trials run as in-session subagents, so the dispatching repo's `CLAUDE.md` is in their ambient
   context; the scenario points them at the fixture root only.
4. The fixture is not a git repository; nothing in `triage-report` reads git history.
