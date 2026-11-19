# bench/fresh-rerun-criterion — micro-test for the fresh-install / re-run criterion

Test surface for [`skills/harness-bootstrap/SKILL.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md)
Phase 1 § Existing CLAUDE.md and the § 2b rot scan: which signal tells a re-run from a fresh
install. Behavior-shaping prose, so it ships behind the
[`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor. Reading-only, no fixture
repo — the shape of the sibling [`bench/rot-scan-liveness/`](../rot-scan-liveness/README.md).

**Copy under test:** the in-repo dev copy of `SKILL.md`.

## Protocol

[`run.sh`](run.sh) cuts the same line-pattern excerpt from two copies of `SKILL.md` — control from
`$CONTROL_REF` (default `HEAD`; once the change is committed, pass the parent of that commit),
arm from the working tree — and splices each into [`scenario.md`](scenario.md). Arms run headless
(`claude -p --model haiku`, no tools, empty MCP config, no setting sources) from the outdir, prompt
on stdin. `run.sh --build <outdir>` builds the prompts with no model call; the script stops when
the two excerpts are identical.

**Scenario.** A repo in the split state (`.claude/rules/harness.md` present, receipt present) whose
history is one squashed commit, with a renamed-away literal in a pipeline-owned doc. The model
answers the state, then RUN or SKIP for the § 2b rot scan. **Axis:** does a missing
bootstrap-shaped commit switch the rot scan off on a repo the files show as bootstrapped?

## Findings

One round, three trials per arm, haiku.

| Arm | Trial | State | Rot scan | Reasoning quoted |
|---|---|---|---|---|
| Control | 1 | split | **SKIP** | "no bootstrap-shaped commit exists and this is not a re-run" |
| Control | 2 | split | RUN | "the squashed "Initial commit" hides the bootstrap-shaped commit, so the commit-based fresh-install test does not apply" |
| Control | 3 | split | **SKIP** | "the commit test marks this as a fresh install … despite `.claude/rules/harness.md` being present" |
| Arm | 1 | split | RUN | "the state is split, which makes this a re-run" |
| Arm | 2 | fresh | RUN | "Phase 1 reads `split` because `.claude/rules/harness.md` exists, so this is a re-run" |
| Arm | 3 | split | RUN | "the squashed-history commit does not change that" |

**Verdict: RED → GREEN.** Control skips the scan 2 of 3 while naming the state split in the same
answer — the two criteria disagree inside one run. The arm runs it 3 of 3.

**Declared bounds.**

1. Arm trial 2 writes `fresh` on its state line and `split` in its justification; the scan decision
   follows the justification. One slip of three on the state line, in the arm only.
2. N=3 per arm, one model tier, one scenario. The opposite disagreement — a bootstrap-shaped commit
   in history on a repo the files read as fresh — is not walked.
3. Reading-only: no run greps a file. The bench shows which criterion the text hands the reader,
   not that a full sync performs the scan.
