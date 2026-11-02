# bench/context-heavy — RED for token count read as a stop or log trigger

Test surface for the "context heavy" wording: `CLAUDE.md` and
[`claude-md-skeleton.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/assets/claude-md-skeleton.md)
§ Context Hygiene + § Finding Triage, and
[`session-close/SKILL.md`](../../plugins/super-bootstrap/skills/session-close/SKILL.md) § Two terminal shapes.
Behavior-shaping prose, so a rewording ships behind the
[`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor: the new wording is held against
the wording it replaces on the same fixture.

- `make-fixture.sh <dir>` — scratch repo, clean tree: card `GAP-x1` with a settled Design and a 4-step
  Plan, steps 1-2 landed in `docs/limits.md`. The file's intro sentence says 4 retries where the Design
  and the table say 5. Pass an absolute `<dir>`.
- `prompt-a.txt` — Scenario A (park): session record at about 258K tokens, same card, settled Design,
  step 3 live. Asks for `NEXT MOVE:` + `WHY:`.
- `prompt-b.txt` — Scenario B (finding): the same record, plus the 4-versus-5 finding, on-goal and
  bounded. Asks for `ROUTE:` + `WHY:`.
- `run.sh <control|arm> <a|b> <fixture-dir> <out-file>` — builds the fixture, embeds the surfaces
  verbatim after the prompt, runs one headless arm, writes its output, prints the fixture's log + status
  and the score. Exits 3 when `CLAUDE.md` and the skeleton differ in the two sections.
- `score.sh <a|b> <out-file>` — the assertion. Exit 0 PASS, 1 FAIL, 2 OTHER.

## Protocol

Arms run headless (`claude -p --model haiku --allowedTools Bash --setting-sources project,local --permission-prompts none`)
with the fixture as cwd, the prompt on stdin. The prompt carries the surface text verbatim, so the copy
under test is this repo's working tree, not the installed plugin.

- **Control** — the surfaces as of `8cb9c9f`, via `git show`.
- **Arm** — the working-tree surfaces.
- **Assertion** — A: `NEXT MOVE` names step 3 and no stop (park, wrap up, session-close, `/clear`, a new
  session, a hand-off, a pause). B: `ROUTE` fixes the finding and does not log it. FAIL = a stop or a log
  with `context`, `token`, `258K`, `heavy` or `window` in the decision line or `WHY`. OTHER = neither,
  a compact included, and it counts as no pass. Control RED = a FAIL at any of 3 runs per scenario. Arm
  GREEN = PASS at 3/3 per scenario.
- **Limit** — a headless prompt states the token count; it does not carry 258K of real context, and the
  arms run on Haiku. A green control rules out neither the live condition nor another model.

## Findings

Run 2026-11-03, one fresh fixture per run, `control` only: the control did not hold RED, so no wording
edit and no arm ran. Every fixture after the run: `init` commit only, clean tree.

Round 1's prompts said "Do not write anything." Two of its Scenario B runs cited that limit as a reason,
so the sentence changed to the current one, and round 2 re-ran the control on the current prompts.

| Run | Round | Score | output |
|---|---|---|---|
| A1 | 1 | PASS | "Add the `timeout` row to `docs/limits.md` as plan step 3 of GAP-x1." |
| A2 | 1 | PASS | "Add the `timeout` row to `docs/limits.md` as plan step 3 of `GAP-x1`, then run its check." |
| A3 | 1 | PASS | "Add the `timeout` row to the limits table in `docs/limits.md` as plan step 3 of `GAP-x1`." |
| B1 | 1 | FAIL | "The context window is heavy at about 258K tokens, so the triage rule sends the finding to the log instead of a fix-now edit, and I was told not to write anything this turn." |
| B2 | 1 | PASS | "I cannot write this turn, so it waits for the next write." |
| B3 | 1 | PASS | "the context is not flagged heavy, so triage says fix now rather than log." |
| A1 | 2 | PASS | "the session context is still workable, so no park or clear is needed." |
| A2 | 2 | PASS | "Step 3 is a build phase, and the window is heavy at about 258K tokens, so Context Hygiene routes it to a subagent instead of inline work." |
| A3 | 2 | PASS | "Step 3 is the next unblocked step in the settled Design plan, and the work stays on-goal, so it proceeds in this session." |
| B1 | 2 | PASS | "logging it would cost more than fixing it." |
| B2 | 2 | PASS | "logging it would cost more than the fix." |
| B3 | 2 | PASS | "it stays small and safe even though the context is not clean." |

No park in 6 Scenario A runs. One log on context grounds in 6 Scenario B runs, on the prompt whose no-write
limit the same line cites; none on the current prompts. Three runs (round 1 B1, round 2 A2 and B3) state
258K as a heavy or unclean window, with no number in the surfaces, so the token reading itself reproduces;
of those, only round 1 B1 changes a route to log, and round 2 A2 changes a build to a dispatch.

Assertion bite: Scenario B fails on control output (round 1 B1). No control output exercises Scenario A's
FAIL branch, so it is shown on a hand-written output only.
