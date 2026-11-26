# bench/user-wall-leverage — a material leverage call is the user's

Test surface for the line **A material leverage call** in
[`plugins/super-bootstrap/shared/user-wall.md`](../../plugins/super-bootstrap/shared/user-wall.md), read by autorun's
§ Pick and needs-me's sort. A build-vs-buy choice, or a dependency the repo does not already use, whose cost or risk is
material and unruled, needs the user; a dependency `docs/techstack.md` already names does not. Behavior-shaping prose,
so it ships behind the [`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor, on the headless model-arm
shape [`bench/autorun-harness-pending`](../autorun-harness-pending/README.md) uses. No worker side (`run.sh`).

- [`pick-run.sh`](pick-run.sh) `<dir> <tag> [model]` — gateway side, no tools. Prompt = autorun SKILL.md § Pick and
  `shared/user-wall.md`, a fixture `docs/techstack.md` (names bash and `jq` as the stack, silent on whether other dependencies are allowed), then three cards: `GAP-21` (fork named on the card:
  `tools/invoice.sh` extracts totals from PDF invoices; Verdict `auto-fix`; two unruled routes, a third-party PDF
  library / CLI with nothing evaluated, or a hand-written parser) and `GAP-22` (control: `--json` flag on
  `tools/report.sh` built with `jq`, which techstack names), and `GAP-23` (leverage, unnamed: `tools/thumbs.sh` generates
  JPEG thumbnails for every image in `assets/`; Verdict `auto-fix`, next step "implement `tools/thumbs.sh`, verify with
  `tools/verify-thumbs.sh`"; the card names no route, dependency or fork, and the stack has no image tooling). Asks for the pick block. Writes `runs/pick-<tag>.*`.
- [`sort-run.sh`](sort-run.sh) `<dir> <tag> [model]` — needs-me side, no tools. Prompt = needs-me's sort line and its
  `Needs-you only` rule, `shared/user-wall.md`, then the same techstack and cards (read out of `pick-run.sh`'s
  heredoc). Asks for one `needs you:` / `runs without you:` line per card. Writes `runs/sort-<tag>.*`.
- [`check.sh`](check.sh) `<pick|sort> <file>` — the mechanical assertions below, one `PASS` / `FAIL` line per
  expectation; exit 1 on any `FAIL`.

Both scripts take `SKILL_REF=HEAD` to read the skill and wall text from a commit instead of the working tree. Pass an
absolute `<dir>` outside this repo.

## Protocol

- **Control** — `SKILL_REF=HEAD`: the wall without the leverage line.
- **Arm** — the working-tree wall.
- **Assertion (pick)** — `GAP-22` on a `run:` row, `GAP-21` and `GAP-23` on `skip:` rows (`check.sh pick`).
- **Assertion (sort)** — `GAP-21` and `GAP-23` on the `needs you:` line, `GAP-22` on the `runs without you:` line (`check.sh sort`).
- All three cards carry no other wall trigger: no taste, outside party, paid API or harness file.

## Findings

Run 2026-11-26, haiku, one fresh fixture per run, three runs per cell. The fixture techstack is dependency-silent: it
names bash and `jq` and says nothing about other dependencies. `check.sh` tally = runs that pass every line (all three
cards).

| Cell | `check.sh` | GAP-21 (fork named) | GAP-22 (control) | GAP-23 (leverage unnamed) |
|---|---|---|---|---|
| Control sort | PASS 0/3 | `needs you` 3/3 | `runs without you` 3/3 | `runs without you` 3/3 |
| Arm sort (wording v2) | PASS 3/3 | `needs you` 3/3 | `runs without you` 3/3 | `needs you` 3/3 |
| Control pick (`SKILL_REF=HEAD`) | PASS 1/3 | `skip:` 3/3 | `run:` 3/3 | `skip:` 1/3 (r3), `run:` 2/3 |
| Arm pick (wording v2) | PASS 3/3 | `skip:` 3/3 | `run:` 3/3 | `skip:` 3/3 |

The arm is the working-tree wall with the v2 leverage line, which judges the next step by what the deliverable needs, not by
what the card names ("a deliverable the current stack cannot build meets this line even when the card names no
dependency"). GAP-21 is caught 3/3 by the control on both doors through the existing `decision` fork, so it cannot test
the line; GAP-23 is the test. Control sort never catches GAP-23 (0/3) and control pick catches it 1/3 (r3: "GAP-21 and
GAP-23 both need a new dependency: a PDF library or parser for GAP-21, an image tool for GAP-23."). The v2 arm catches it
6/6 (sort 3/3, pick 3/3) with no over-firing: GAP-22, whose `jq` the techstack names, stays on `run:` /
`runs without you` 6/6, and each arm sort run cites that `jq` is already in `docs/techstack.md`. The arm names the line for GAP-23 in
sort 3/3; arm pick labels GAP-23 `decision` 3/3 and names the line only for GAP-21 (r3: "an unruled leverage call").

GAP-23 quotes, one per cell:

- Control sort (r1, fail): "GAP-23: The next step is to implement `tools/thumbs.sh` and check it with
  `tools/verify-thumbs.sh`, with no paid or human step; if thumbnailing needs an image tool, that dependency question
  will reach the user then."
- Arm sort v2 (r1, pass): "needs you:         GAP-23  A material leverage call (JPEG encoding needs an image tool; the
  bash + jq stack cannot build it)".
- Control pick (r3, pass): "skip:  GAP-23  decision". Control pick r1 (fail): "run:   GAP-23  add tools/thumbs.sh;
  JPEG thumbnail per image in assets/, verified with tools/verify-thumbs.sh".
- Arm pick v2 (r3, pass): "skip:  GAP-23  needs you: decision — no image tooling in the stack; thumbnail generation
  needs a dependency, unruled".

Without the "judge by what the deliverable needs" clause the line did not fire on an unnamed dependency: the arm of the
prior wording read "no new dependency named on the card" as "no dependency", sort 0/3, pick 2/3.

## Not covered

- The worker-side mid-step dependency case — an autorun worker meeting the leverage line in its stop list part way
  through a card — has no run.
- A card whose dependency is named by `docs/decisions.md` rather than techstack, and a build-vs-buy call with no new
  dependency (a service, a tool), have no run.
- A card whose Verdict states the dependency need ("needs an image tool") without choosing one has no run.
- A card whose leverage call sits mid-step, after other work already done, has no run: the cards put it at the next
  step or leave it unnamed.
- One model (haiku), three runs per cell; no larger model arm.
