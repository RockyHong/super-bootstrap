# bench/dimension-predicate-audit — RED for routes 4 and 5 of the audit predicate

Test surface for routes 4 and 5 in
[`dimension-predicate.md`](../../plugins/super-bootstrap/skills/check-docs-consistency/assets/dimension-predicate.md).
Behavior-shaping prose in a shipped asset, so it ships behind the
[`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor.

## Fixture

[`fixture.md`](fixture.md) is a state doc whose three body lines each take one verdict:

- L1, a dated "last probed" stamp: route 4 flags it.
- L2, a routing line that sends new work to `docs/work/` and points at no item: route 5 leaves it.
- L3, the status pointer from [`volatile-id-citation`](../volatile-id-citation/README.md) Arm 3: route 5 flags it.

## Run

[`run.sh`](run.sh) `<scratch-dir> <tag> <HEAD-ish|worktree> [model]` embeds the predicate and the fixture in the
prompt, runs one headless `claude -p` from an empty scratch dir with no tools, and prints the three verdicts.
Pass a `<scratch-dir>` outside this repo.

## Pass condition

Stated before any run. A run passes on `L1: FLAG`, `L2: KEEP`, `L3: FLAG`. Control RED = at least one failed run in 3
on the pre-edit predicate. Arm GREEN = 3/3. One wording round; a failed arm stops the work.

## Findings

Sonnet, 3 runs each. Control = the predicate before route 4 changed. Arm = route 4 restated to "When-checked → git"; route 5 unchanged.

| | L1 FLAG | L2 KEEP | L3 FLAG | Pass |
|---|---|---|---|---|
| Control | 0/3 | 3/3 | 3/3 | 0/3 |
| Arm | 3/3 | 3/3 | 2/3 | 2/3 |

Control holds RED on L1. The arm fails its stated 3/3: one run keeps L3. Route 4 moves L1 as intended. The L3 miss sits on route 5's unchanged text, and 3 runs per arm cannot separate it from variance. L2 stays KEEP on the control, so route 5 takes no widening.
