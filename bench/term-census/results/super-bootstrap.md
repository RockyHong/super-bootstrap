# Census read — super-bootstrap (self)

Raw output: [`super-bootstrap.census.txt`](super-bootstrap.census.txt). Doc surface = the commit door's own: 11 files (`docs/decisions.md` is `dimension: history`, so out; harness files — `CLAUDE.md`, rules, skills — are not doc surface).

## Labels, top of A and B

| Term | Lane | Docs | Label | Home today |
|---|---|---|---|---|
| `needs-me`, `autorun`, `harness-bootstrap`, `commit`, `triage`, `resolve-plugins`, `merge`, `setup`, `session-close`, `session-continue` | A / B (as `/super-bootstrap:*`) | 4–8 | terminology — the product's own commands | plugin README skill list; mentions mostly do not link it |
| `parked`, `test-queue`, `techstack`, `docs/work/`, `docs/outward/`, `docs/*.md` | A / B | 4–6 | path/noise — doc citations | n/a |
| `## Progress` | B | 4 | terminology — card block type | `docs/work/README.md` § Thread contract |
| `.claude/settings.json`, `SKILL.md`, `README.md`, `CLAUDE.md` | B | 4–5 | path/noise | n/a |
| `commit-channel`, `hooks`, `ensure-infra`, `runway-version` | A | 3–4 | leak candidates — hook mechanism named outside its owner | the hook files themselves |

## Missed by the census (plain prose, docs of 11)

`card` 10 · `consumer` 7 · `verdict` 6 · `closure` 5 · `dispatch` 5 · `door` 5 · `gateway` 5 · `skeleton` 5 · `ledger` 4 · `runway` 4. These are the repo's real terminology, and none is backticked. Their definitions live in `CLAUDE.md` (harness, off the doc surface) or nowhere; there is no terminology home.

## Shape notes

1. The surface is small (11 docs), so the B histogram tops out at 5–8 and nothing reaches 9+. An absolute fan-in threshold does not transfer across repos; a share of the surface does (`card` sits in 10 of 11).
2. Code-shape extraction finds commands, paths and file names — mostly path/noise or command terminology — and never finds the prose terminology. Prose words are ordinary English, so they cannot be discovered mechanically without false hits. Two lanes follow: discovery for code-shaped tokens; for prose terms, the ledger declares the term and the census only counts it.
3. The first census pass swept 38 bench READMEs into the surface and its top 20 was bench tooling (`run.sh`, `claude -p`, `CLAUDE_CONFIG_DIR`). The census now uses `doc-links.sh self`, the same surface doc-sync judges.
