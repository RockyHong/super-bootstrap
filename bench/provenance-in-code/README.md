# bench/provenance-in-code — does a card pickup leak provenance into code?

Probe for whether an agent fixing a card writes the card's provenance — its tracker ID, a date, the
decision's precedent ("rejected clamping…", "as the old Go limiter did") — into the code, tests or
durable docs it touches, under the assets a bootstrapped repo places. It decides whether the
no-provenance discipline needs a prose line beyond the commit door's mechanical ID and date lanes.

## Fixture

[`fixture/`](fixture/) is a tiny Python library: `parse_window` in `src/ratelimit/window.py`, its
tests, a one-paragraph spec, and one live card, `docs/work/BUG-r4k8.md`, whose `## Design` block
carries a dated decision with a rejected alternative and its war story — the salient provenance a
fix might copy.

## Run

[`run.sh`](run.sh) `<scratch-dir> <tag> <ref> [model]`. Builds `<scratch-dir>/<tag>/repo`, places
`assets/harness.md` and `assets/rules-dimension-discipline-skeleton.md` under `.claude/rules/` from
`<ref>` (`HEAD` → committed assets, the control; `worktree` → working-tree assets, an arm), commits
the fixture, and runs `claude -p` with the repo as cwd on: "Pick up BUG-r4k8 and fix it, with
tests." It writes `runs/<tag>.prompt.md`, `.result.txt`, `.added.txt` (every added line outside
`docs/work/`) and `.score.txt` (`id-hits`, `date-hits`, `precedent-hits`, `card-path-hits`). Pass a
`<scratch-dir>` outside this repo.

## Pass condition

All four hit counts are 0. The prose line earns its slot only when the control fails at least 2 of
3 runs.

## Readings (sonnet)

| | Control (assets at `HEAD`) |
|---|---|
| ID / date / precedent / card path in added lines | 0/3 each |

Every control run fixed the bug, added tests and updated the spec present-tense, with no provenance
in any added line. The clean fixture does not reproduce the leak; the leaks this repo's own tracked
files carry (closed card IDs in test labels and comments) land through the commit door's ID lane
scanning doc-surface files only — the mechanical lane widening answers that path, and this
reading earns no prose line.
