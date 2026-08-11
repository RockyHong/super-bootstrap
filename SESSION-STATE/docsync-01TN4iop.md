# Carry — doc-sync redesign

**Anchor:** solve [`GAP-058`](../docs/work/GAP-058.md) whole. Operator drives the next pickup with Fable and has ruled out incremental patching explicitly.

**Read first**

- [`docs/work/GAP-058.md`](../docs/work/GAP-058.md) — the aim, the nine-arm measurement, the two forks, the closed bounds. Everything durable lives here; this file only holds what the card does not.
- [`docs/decisions.md`](../docs/decisions.md) — the coverage-line row and the reverse-link-gate row bound the fix; both name their own reopen conditions.
- [`CLAUDE.md`](../CLAUDE.md) § Doc Sync — the guarantee whose wording and placement fork one questions.

**State**

Measurement done and committed; no work in flight, tree clean. `DEBT-062` and `DEBT-063` resolved into `GAP-058` — their aims (scanner stopping behaviour, scan cost per commit) are both closed as wrong targets, so do not restart from either framing.

**Next step**

Settle fork one — where the guarantee lives, write boundary or read boundary — before touching fork two. The card states the order and it is load-bearing: the marking form for fork two is only designable once the position is fixed, otherwise any marker is patching the current placement.

**Watch-outs**

- **Token count is not a cost metric here.** Per-token price differs by tier, so raw volume comparisons say nothing. Quality is the ordering axis; a cheaper mechanism that degrades recall is worse than the current price. Two replies in this session were corrected on exactly this.
- **Tier is not the lever, measured.** Downgrading is strictly dominated; raising the pin is rejected on price. Do not re-propose either.
- **The scan agent's `model:` pin is enforced** — a call-site override on `subagent_type: super-bootstrap:doc-sync-scan` is rejected outright. To sweep tiers, inline the agent body into a `general-purpose` container and note the container substitution as a deviation.
- **State which copy is under test.** The loaded install lagged the repo this session (2.31.0 against 2.32.0 released), and the older copy is missing the claims-comparison scan step.
- **Fixture rebuild:** `git worktree add --detach <path> d3161f3`; diff = `git show --format= d3161f3`; prompt carries diff + date only, pasted inline. Never paraphrase the diff from memory — that is the one channel that leaks the answer key into a cold arm.
