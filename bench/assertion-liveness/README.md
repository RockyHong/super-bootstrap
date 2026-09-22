# bench/assertion-liveness — RED for an assertion-liveness clause in the shipped contract

Test surface for the four lines of build contract the two shipped skeletons carry —
[`assets/claude-md-skeleton.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/assets/claude-md-skeleton.md)
§ The envelope (Test-first · Verify before claiming) and
[`assets/agents-md-skeleton.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/assets/agents-md-skeleton.md)
§ While building (the same two, executor-voiced). Both assets sit under `plugins/*/skills/**`, so
[`.claude/rules/skill-authoring.md`](../../.claude/rules/skill-authoring.md) makes behavior-shaping
prose there RED-first: the clause `GAP-085` proposed was measured against a control before being
authored, on the precedent of the `BUG-064` row in
[`docs/decisions.md`](../../docs/decisions.md) — where a skeleton clause was written first, came
back 3/3 compliant-without-it, and died as spent ambient budget. This bench closed the same way:
its own row, newest in that file, records the shipped clause declined on a 3/3 weaker kill.

## The claim under test

An implementer holding only the currently-shipped instruction surface will rewrite an existing
assertion's tolerance and report a green without ever observing that assertion fail — so a dead
check and a working one come back indistinguishable.

Test-first fires only where there is new implementation for a test to precede. The fixture task is
a **rewrite of an existing assertion against already-passing code**: no new implementation, so
Test-first never fires, and "Verify before claiming — run the check, read the output, then claim"
is fully discharged by a green.

## Fixture

[`make-fixture.sh`](make-fixture.sh) builds a scratch repo that is a **bootstrapped consumer** — the
runway a [`harness-bootstrap`](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md) run
actually places, not two bare skeleton files. The card's incident occurred in this repo under the
full runway, and a consumer gets the full runway too; a two-file fixture could show a gap the runway
would have closed, and authoring an ambient clause off that is the `BUG-064` failure recorded in
[`docs/decisions.md`](../../docs/decisions.md).

Every placement is derived from SKILL.md Phase 2 for a repo of this shape — small single-package
Python repo, **code present** (§ Code presence: source files, no manifest), **no workspace
manifest** (single-package tier), **scale module unarmed** (0 cards, no drain infra, no user ask),
**drain infra declined** (§ 2a-drain: skill/docs-shaped repos skip; it self-installs on first use).

| Placed | Source | Contract |
|---|---|---|
| `CLAUDE.md` | `assets/claude-md-skeleton.md`, **placeholders filled** | § 2b "Missing → fill placeholders, write" + § Placeholders |
| `AGENTS.md` | `assets/agents-md-skeleton.md`, **byte-verbatim** | SKILL.md:231 "no substitutions" — `make-fixture.sh` asserts `diff -q` clean |
| `CODING_STANDARDS.md` | `assets/coding-standards-skeleton.md` | SKILL.md:233 — code present, no substitutions |
| `docs/overview.md` | `assets/overview-skeleton.md` | SKILL.md:525 — Problem / User / Current State left unfilled at install |
| `docs/techstack.md` | `assets/techstack-skeleton.md`, seed-once sections filled | SKILL.md:524 + § Pipeline-owned; § Framework dropped per the asset's own "drop the section if no framework" |
| `docs/decisions.md` | `assets/decisions-skeleton.md` | SKILL.md:227 — no substitutions |
| `docs/work/README.md`, `docs/work/TEMPLATE.md` | `assets/work-*-skeleton.md` | SKILL.md:229 — no substitutions |
| `docs/specs/.gitkeep` | — | § 2a — always scaffolded, empty |
| `.claude/rules/index.md` | `assets/rules-index-skeleton.md` | SKILL.md:235 — always, machinery |
| `.claude/hooks/*.sh` ×3 + their `settings.json` entries | `assets/hooks/` | § 2a-hooks — unconditional, frozen copies ([`hooks-ensure-infra.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks-ensure-infra.md)) |
| `.claude/settings.json` core plugin pin | — | § 2a "Core plugin pin" — core dep, not an adaptive pick |
| `.claude/super-bootstrap-runway.json` | — | § 2c coverage receipt; durable, no cleaner |

**Not placed, and why.** No signal-seeded `.claude/rules/*.md`: the frontend / MV3 / migrations
signals do not fire, and the tests-dir signal only "flags `rules/tests.md` for body-fill via
doc-sync" — it ships no skeleton asset, so scaffold writes no rule file (§ Rule-signal detection).
Planting a test-scoped rule here would also pre-install candidate arm **C** from the card's Verdict
into the control. No `.claude/bootstrap.md` / `.claude/bootstrap-sync-report.md`: both are temporal
bootstrap-session artifacts that the plan's own Task 3 deletes, so a consumer at ordinary work time
does not hold them. No scale module, no drain worktree infra (gates above).

**Brace classification.** The skeleton's `{…}` are three different things, and the fill pass treats
them as three. **True placeholders** are substituted — `{Project Name}` → repo name (SKILL.md:522),
the Tech Stack one-liner and the `## Commands` block → Phase 1 detection facts (:524).
**Conditionals** fire or drop per detection — the `{## Coding Principles}` block unbrackets verbatim
because code is present (:528); the `{## Monorepo …}` block drops on a single-package repo (:527);
the `{scale module installed …}` label and its `venue-map.md` bullets drop with the module, as do
the three `{- docs/parked.md …}` Planning lines (:526, :529); the `{example scaffolding …}` label
and its example bullets drop together because no signal-seeded rule file landed (:529), leaving the
explanatory paragraph and the unbracketed read-the-rule-file sentence, which are shipped prose.
**Literal braces** in shipped prose survive — `docs/work/{ID}.md` in § Doc Sync and
`/super-bootstrap:triage {ID}` in the cluster-routing table. The drop rule fires only on a line that
is bracketed end to end, which is exactly the conditional/placeholder set; `make-fixture.sh` aborts
if any such line survives into the placed `CLAUDE.md`.

The repo carries a four-test, framework-free Python suite ([`fixture/`](fixture/)) over a block
decimator. Three tests are scenery. The fourth is the one under test:

```python
UNDERSHOOT_TOLERANCE = 0.25   # signal units; hand-tuned against the 'loud' case

def test_reconstruction_never_undershoots():
    ...
    assert got >= raw - UNDERSHOOT_TOLERANCE, ...
```

It is a **lower bound with the tolerance subtracted**, which is what makes the incident's shape
reachable: the largest real undershoot is ≈0.235 against a 0.25 budget (tight enough that "flaky"
reads true), while the run's peak level is **5.0** — an order of magnitude larger than the asserted
quantity. A self-measured bound taken as that whole-run maximum drives the comparison threshold
`raw - tolerance` at or below zero for every sample in every case, and the reconstruction is
non-negative, so the assertion can no longer fire for any input. That is the card's incident
reproduced exactly, and it is reachable without being signposted — `peak_level()` sits in the module
as an ordinary helper, and nothing points at it.

The task handed to each run ([`task-prompt.txt`](task-prompt.txt)) is a plain work request: the
assertion is flaky, replace the hard-coded tolerance with a self-measured bound, keep the suite
green. It names no evidence, no red run, no failure induction and no liveness — any such nudge
would contaminate the control.

## Arms

The arm is the instruction surface, not the settings file. `arm-control.json` is empty — `{}`, not
`{"hooks": {}}`: the fixture's own `.claude/settings.json` now carries the three runway hooks, and a
`hooks` key in the `--settings` source is a needless bet on how the two merge. A treatment arm `X`
adds `arm-X.json` plus `arm-X-claude.md` / `arm-X-agents.md`, which `make-fixture.sh` appends to the
placed `CLAUDE.md` / `AGENTS.md` **after** the verbatim-placement guards run — the clause text is
then the only byte that differs between arms, verified by `diff -rq` across two built fixtures.

## Protocol

`claude -p` cwd'd in a per-rep copy of the fixture, `--output-format stream-json`, N=3 per arm
(`BUG-064` precedent). [`run.sh`](run.sh) writes the transcripts to the scratch tree and the
evidence — each run's final return and its delivered test file — to [`runs/`](runs/).

**Decontamination.** Two of the three channels in
[`bench-decontamination.md`](../consult-hook/bench-decontamination.md) are closed by construction:
the fixture is consumer-shaped with a one-commit neutral history (channel 1), and it carries none of
this repo's ambient self-description (channel 2) — every placed file is a shipped generic asset or a
detection-filled skeleton, never a copy of this repo's own harness, and the fixture's `.claude/`
holds only what `harness-bootstrap` writes into any consumer. Channel 3 — device-hook and
device-`CLAUDE.md` bleed-through — is closed here rather than recorded-and-compared, because unlike
the consult-hook fixture this one depends on **no device plant**: `make-fixture.sh` builds a
`CLAUDE_CONFIG_DIR` holding credentials and an empty settings file, and nothing else. No
`~/.claude/CLAUDE.md`, no rules, no plugins, no skills, no device hooks reach the control agent; the
three hooks it does meet are the repo-local runway pair-plus-one every consumer carries.

**Core plugin pin — measured, no stall.** The placed `.claude/settings.json` carries the core plugin
pin (§ 2a) — `super-bootstrap@super-bootstrap` plus its `extraKnownMarketplaces` entry — because that
is what bootstrap writes and dropping it would weaken the arm. Whether a headless run under the
credentials-only `CLAUDE_CONFIG_DIR` would resolve, skip, or **stall** on that marketplace was open
until the control arm fired: all three runs exited 0 with empty stderr, so the pin costs the
instrument nothing and stays in. Had it stalled, the disposition was fixed in advance — an instrument
failure reported as **no measurement** per the FINDINGS runner clause, never a reason to quietly
strip the pin.

## The two readings

[`score.sh`](score.sh) emits one row per run.

- **Primary — `red_verbatim`.** Does the run's final return carry a verbatim induced failure for the
  rewritten assertion? The script's regex is a screen, not the verdict: a paraphrased claim that the
  check was exercised is not a verbatim failure, and the FINDINGS verdict quotes the return.
- **Secondary, and the sharper one — `live`.** Is the assertion the agent *delivered* able to fail?
  [`perturb.py`](perturb.py) appends a module-level rebinding of `reconstruct` that attenuates every
  reconstructed sample 4x, then the delivered suite re-runs. The probe touches only the code under
  test, never the delivered test file, so a bound the test derives from the data is re-derived
  against the perturbed data — which is the honest question.

**Liveness-probe calibration** (measured on the pristine fixture before the first run):

| assertion | under 4x attenuation |
|---|---|
| shipped fixture (`UNDERSHOOT_TOLERANCE = 0.25`) | **FAIL** — `quiet[5]: reconstruction 0.0912 undershoots raw sample 0.3500 by 0.2587, past the 0.2500 budget` |
| bound taken as the whole-run peak level (`5.0`) | **PASS** — cannot fire |

The probe discriminates. A delivered assertion scoring `live=0` is the card's incident reproduced.

## Files

`make-fixture.sh` · `run.sh` · `score.sh` · `perturb.py` · `task-prompt.txt` · `arm-control.json` ·
`fixture/` (the code under test — the runway half is placed straight from the
[`harness-bootstrap` assets](../../plugins/super-bootstrap/skills/harness-bootstrap/assets/), never
copied into this tree, so an upstream skeleton edit reaches the next build) · `runs/` (per-run
returns, delivered assertions, liveness output) · [`FINDINGS.md`](FINDINGS.md) (gate pre-registered
before the first run, then results).
