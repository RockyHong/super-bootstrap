# GAP-by73 — doc-sync asks one per-commit gate to do three jobs; decide the layering from its measured track record

**Logged:** 2026-11-13 · **Source:** author + gateway design discussion during `BUG-q2jy`, and a transcript-mined history of the commit door (30 days, 228 cold runs)
**Problem:** The commit door's doc-sync is a delta check tuned for recall. Author's framing: docs exist for agent context retrieval, not for human readers; doc-sync exists to catch leaks, because authoring discipline fragments — "就算一次只 fragmented degrade 1%，久了還是會散" — and an LLM copies the fragmentation it finds as if it were the repo's style, so only a real constraint holds. Code is the SSOT in theory, but code carries no taste or orchestration context and no cross-context index, and retrieving from code alone is too fragmented; the harness decides which side is the home. A delta check that misses a stale line never looks at it again, so any miss rate compounds; the door answers by scanning wide, and its cost and its `BUG-q2jy` over-scope follow from that. Open question: which guarantee belongs to which layer — a whole-surface mechanical invariant on every commit (a miss is re-checked next time), a cheap precise delta lookup, and a recall sweep fired by a mechanical trigger rather than on demand — and whether the per-commit cold scan is the right place for recall at all.
**Area:** `plugins/super-bootstrap/skills/commit/SKILL.md` §3–§4; `plugins/super-bootstrap/agents/doc-sync-scan.md`; `plugins/super-bootstrap/skills/commit/assets/doc-links.sh`; `/super-bootstrap:check-docs-consistency`; `bench/doc-sync-history/`
**Prior:** Gateway's three-layer proposal, unmeasured: (1) invariants — today's link and model-tier checks, plus a dead-symbol check (a symbol-shaped code-span token in a doc resolves in the code tree or in `docs/terminology.md`); (2) delta lookup — changed identifiers and changed-doc citers, warm; (3) a triggered whole-surface sweep. Adjacent closed forks in `docs/decisions.md`: the roster-count pin row (`GAP-081`), the pure reverse-link gate row (`DEBT-023` / `GAP-049`), the `DEBT-94g6` and `BUG-ptvs` rows, the reopened `GAP-ym4e` term-ledger row.
**Blast:** repo

## Amendment — 2026-11-13 · transcript history probe, gateway session

Evidence in hand, from Claude Code session transcripts of `magnetized-remake` (201 sessions) and this repo (18), 2026-10-13 to 2026-11-12, plugin 5.2.0–5.10.4. Tables and extractor: `bench/doc-sync-history/` (`runs.tsv`, `judged.tsv`, `stage1.py`, `stage2.py`, `rubric.md`) — left untracked; they hold transcript excerpts and the repo is public, so committing them is the author's call. Judged by four model readers on one rubric, not cross-checked.

- Cold runs: 228 (MR 219, this repo 9). `clean` 82 (36%), `stale-docs` 146 (64%). Median scope 17–19 docs, 53 s, about 450k tokens a run (cache reads dominate); 191.9M tokens and 4.07 h in total.
- A stale report is acted on, not a false alarm: of 56 sampled stale runs, 51 real catches, 3 cosmetic, 1 not a catch, 1 false alarm. At candidate grain 129 of 169 were handled; the rest were dropped without a stated reason.
- No sampled cold catch needed a broad scan: of 51, 30 sat in a doc the commit was already editing or the session had read, 22 on a line a literal lookup of the diff's identifiers reaches, 12 behind a reverse link, 2 behind a mechanical whole-surface check; 0 by none of these (0 to 5 under stricter readings of the lookup and link tests). Lane that brought the doc into scope: changed-doc 24, grep-hit 10, citer 8, the judge's own grep 3, other 6.
- Catch classes, 67 real catches (51 cold, 16 warm): doc-vs-doc 18, prose narration naming nothing in the diff 24, symbol / value / path 13, mechanical 6, code comment 3, other 3.
- Warm runs: 160 commit windows; the outcome is mostly unrecorded (109 with no outcome text, against the per-doc outcome marker the skill requires). 16 real catches among 24 judged; 6 of them reachable only by reading the scoped docs — 3 are the changed file's own row in `docs/overview.md`, found through the basename grep hit.
- No commit in the window was fixed because `check` or `pins` fired.
- Limits: 30 days, one consumer repo carries 96% of cold runs; a transcript cannot show a stale doc nobody caught, so there is no miss rate and no with/without comparison; "the session could have caught it" is a counterfactual — every one of those 30 was in fact fixed only after the scan reported it.

## Amendment — 2026-11-13 · transcript history probe, second read

- Lane models: the cold `doc-sync-scan` agent runs `model: sonnet`; the warm lane runs on the gateway session's own model.
- The cold judge is not cold in practice: dispatch prompts commonly carry a "Change intent" line and sometimes "Known suspects"; in at least 2 runs the judge could not read the diff and judged from the intent alone.
- At least 5 cold catches were code comments, off the doc surface, found by the judge reading the diff or its own grep.
- The changed-doc (self) lane is the top producer: 24 of the 51 sampled cold catches.
- 37 warm windows show a path count over 8 — an over-count or a ceiling not followed, undetermined.
- Probe intermediates (per-run detail, sidechain records, judging packs) sit beside the tables in `bench/doc-sync-history/`, untracked.

## Amendment — 2026-11-13 · author ruling on the probe's files

Author: "隱私資料或transcript要集中管理然後gitignore，或是刪掉". `bench/doc-sync-history/` stays on this device and is git-ignored whole — tables, extractor and intermediates. It is this card's evidence and costs four reader passes to rebuild, so it is kept; whether the extractor becomes a tracked bench is this card's call. The grep-lane catches among its rows were replayed without their text: `bench/scope-replay/README.md` § Pre-fix replay of recorded catches.
