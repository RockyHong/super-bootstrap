# GAP-ym4e — doc-sync: a scope doc confirmed current is silently passed even when its being in scope signals an SSOT / SoC leak

**Logged:** 2026-10-27 · **Source:** user, reviewing the v5.5.0 doc-sync restatement count
**Problem:** The commit door's doc-sync judges each scope doc stale or "read-and-confirmed-unchanged". A doc that is correct but got pulled in because it narrates something it does not own — another module's mechanism (separation-of-concerns leak), or a copied fact where a link to the owner would do (SSOT leak) — lands as confirmed-unchanged with no signal. The hit itself is the smell: a doc a reader should not need to open for this change still had to be read. The v5.5.0 restatement count covers only K copies of a fact the diff changed, not "this doc should not carry this at all".
**Area:** `plugins/super-bootstrap/agents/doc-sync-scan.md` § Scan + output contract; `plugins/super-bootstrap/skills/commit/SKILL.md` §4
**Prior:** a non-blocking per-doc suspicion item beside `restatements` (doc, what it narrates, the owner it should link to instead), offered as a card like restatements; the CLAUDE.md § Doc Sync admission rule ("a line earns the doc surface when it lets a reader skip opening a file"; single-file mechanism stays in that file) as the yardstick. Distinct from the closed citer-inversion row: this reports, it does not filter the scan scope.

## Amendment — 2026-10-27 · user deliberation

Re-aim: a per-doc "this doc should not carry this" judgment is subjective and low-precision. Replace it with a term fan-in ledger: (1) census — per term, the number of docs naming it and its link in-degree (`hits --by-term`, `doc-links.sh index`); (2) ledger — a high-fan-in term either holds a registered home every copy links to (terminology that earned its entry: domain concept, stable, many real consumers) or is unregistered; (3) doc-sync, mechanical and non-blocking — a diff-touched term over a fan-in threshold and not registered is surfaced; (4) audit — `check-docs-consistency` works the ledger's unregistered hot terms (register, or pull the detail back into its owner file and link / drop) instead of a carpet read. Data first: census this repo plus three consumers of different shape (ComfyUI workflows — tooling; magnetized-remake — game dev; jowagoko — podcast) to see whether fan-in has a break that sets the threshold, and what the shapes miss. Census tool: `bench/term-census/census.sh`. Collection thread: `OUT-k2g0`.

## Amendment — 2026-10-27 · user deliberation

Registration also happens at authoring time, not only by scan: the session editing a doc knows when it coins or leans on a term, so it registers born-registered — same fire moment and shape as the `ssot-doc-link` rule (born-linked). On a term's first asserting use: ledger hit → link the entry; miss and the term earns an entry → add it; otherwise use it inline. Earn gate against agent term-coining: a cold reader stalls without the definition, or the term spans two or more docs; a term private to one doc stays out. This makes the prose lane workable: authors declare, the census counts, doc-sync flags unregistered code-shaped hot tokens and registered-but-unlinked mentions, the audit works the leftovers. Ownership to settle at Design: `ssot-doc-link` is served from claude-config-manager (read-only here → `/contribute`), or the authoring rule ships as this repo's own skeleton rule.

## Amendment — 2026-10-27 · gateway

The "ownership to settle at Design" fork resolves: `ssot-doc-link` ships as this repo's own rule (`plugins/super-bootstrap/skills/harness-bootstrap/assets/rules-ssot-doc-link-skeleton.md`, GAP-jsp5), so the authoring-time registration extends that asset directly.

## Amendment — 2026-10-27 · census read + user direction

Census landed for four repos (`bench/term-census/results/`). Read against this card's concern (a correct doc in doc-sync scope because it narrates what it does not own):
- Rejected lane: census-threshold discovery of unregistered hot terms — low precision everywhere (top fan-in terms are doc stems, indexes, command names, mostly with homes already); prose terms cannot be tokenized mechanically (CJK, ordinary English).
- Supported gap: registered term, unlinked users — e.g. magnetized-remake "shell" in 46 docs, 14 linking `docs/specs/terminology.md`; jowagoko skill names in 13 docs, 1 linking; ComfyUI agent and this repo hold term homes only in `CLAUDE.md` (off the doc surface) or nowhere. Current lanes miss it: restatements count copies of a fact, not uses of a term; `hits` derives terms from file names; the citer lane reaches only docs that already link the home.
- Not this card's evidence: a drift probe on two magnetized renames found no stale doc; its one stale term traced to a rename left undone in code (consumer notified). Staleness is not the concern here.

Next session, before Design: research mattpocock's skills for an established method for a project term home / glossary and how docs use it (the paired pin, `docs/decisions.md` mattpocock rows) — adopt a mature method over building one.
