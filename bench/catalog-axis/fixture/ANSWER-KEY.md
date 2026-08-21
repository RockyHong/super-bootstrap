# Answer key — `bench/catalog-axis/fixture`

Ground truth for the eight rows of [`index.md`](index.md). One row per catalog row.
A judge run scores against this: recall per shape, false positives on the clean and
decoy rows.

Both P0 shapes and the P1 shape appear; three rows are clean controls and one is a
decoy that a heading-token comparison flags and a content comparison must not.

| # | Row | Expected verdict | Row span (index.md) | Entry section | Why |
|---|-----|------------------|---------------------|---------------|-----|
| 1 | `port-claim` | clean | whole row | all three (`## What it does`, `## Arguments`, `## Boundary`) | Row covers the lease write, all four flags with their defaults, the sub-1024 and overlap refusals, and the advisory-not-binding fact. Nothing asserted is negated; no named section unrepresented. |
| 2 | `proxy-map` | contradiction P0 | "on a hostname collision the incumbent mapping wins — the newcomer is rejected with a `warn` line naming the holder, so the later project picks a different hostname" | `## Collision handling` | Entry states the exact inverse: "**the later mapping wins**: the incumbent is evicted … and the evicted project has to re-run `proxy-map`". Same vocabulary (collision, incumbent, newcomer, `warn`), inverted rule — a row-sync pass that checks "is collision handling covered?" passes it. |
| 3 | `tunnel-open` | omission P0 | whole row (ends at "`--list` prints what is currently live with its remaining time") | `## Boundary` | Row covers what-it-does, `## Lifetime`, and `## Arguments`; `## Boundary` is absent entirely. That section carries two refusals a reader would walk into unseen — no tunnel to a port bound on `0.0.0.0` (relays the whole LAN surface), and no run with `CI` set (leaks the personal, account-scoped relay token into build logs). Contract-class → P0. |
| 4 | `port-sweep` | omission P0 | whole row (ends at "a `swept.json` receipt written into the run directory") | `## Arguments` | Row covers what-it-does, `## How it identifies a stale listener`, and `## Output`; `## Arguments` is absent entirely. That section carries `--older-than` defaulting to `0s` — matching **every** listener including live ones — and `--yes` being **assumed when stdin is not a TTY**, so a scripted bare invocation sweeps unattended. Contract-class, and destructive → P0. |
| 5 | `cert-mint` | clean | whole row | all three (`## What it does`, `## Trust store`, `## Rules`) | Row covers the 30-day leaf signed by the local dev CA, the one-time OS-trust-store admin prompt plus the separate `--firefox` step, the "hostname `proxy-map` already serves" refusal, and the `0600` keys never leaving `~/.portside/certs/`. Every named section represented. |
| 6 | `service-probe` | decoy-clean | whole row | `## The fact`, `## Failure modes`, `## Boundary` (all rhetorical-role headings) | The false-positive trap. Heading tokens share no vocabulary with the row, so a heading-overlap comparison fires three times. Content is fully covered: "a 200 … means the socket answered, never that the service finished booting, so the table is not a readiness gate" = `## The fact`; the retry/redirect/TLS triple = `## Failure modes`; "reports only — nothing is restarted and the manifest is never rewritten" = `## Boundary`. Must NOT be flagged. |
| 7 | `env-emit` | omission P1 | whole row (ends at "aborts the write rather than guessing where the block ends") | `## Background` | Row covers what-it-does, `## Arguments`, and `## Boundary`; `## Background` is absent. That section is descriptive — why the command exists, why a delimited block beat a line-merge, why the prefix is `PORTSIDE_` rather than `PS_`. No constraint a reader violates by not reading it → P1, not P0. The row's "inside a delimited block" states the mechanism, not the section's rationale. |
| 8 | `conflict-report` | clean | whole row | all three (`## What it does`, `## Output`, `## Boundary`) | Row covers the lease-vs-listening cross-check, the four-column table with all four verdicts, the exit-1-on-any-non-`ok` rule, and the read-only boundary delegating freeing to `port-sweep`. Nothing negated, nothing unrepresented. |

## Scoring

- **Recall** — rows 2, 3, 4, 7 must each be reported, at the listed shape and pointing
  at the listed entry section. A right row at the wrong shape (e.g. row 4 as P1) is a
  partial: recall counts, leveling does not.
- **False positives** — any finding on rows 1, 5, 6, or 8 is a false positive. Row 6 is
  weighted: it is the shape the measured deterministic tier fails on, so a run that is
  clean everywhere except row 6 still fails the decoy gate.
- **Precision within a hit row** — a finding on row 2/3/4/7 naming a section other than
  the listed one counts as a false positive as well as a miss.
