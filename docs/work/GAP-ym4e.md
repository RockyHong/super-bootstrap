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

## Amendment — 2026-10-29 · research read of mattpocock/skills (upstream via `gh api`; the plugin is a catalog entry only on this device, not installed)

The established method is `skills/engineering/domain-modeling/SKILL.md` + `GLOSSARY-FORMAT.md`:
- Home: one root `GLOSSARY.md` (multi-context repo: root `GLOSSARY-MAP.md` pointing at per-context `GLOSSARY.md`), created lazily "when the first term is resolved".
- Entry: `**Term**:` 1–2 sentence definition ("Define what it IS, not what it does"), `_Avoid_:` synonyms; optional `## Relationships`, `## Flagged ambiguities`. "totally devoid of implementation details".
- Admission: "Only include terms specific to this project's context … is this a concept unique to this context, or a general programming concept? Only the former belongs." "Be opinionated": one word, others under `_Avoid_`.
- Update moment: in-session, "When a term is resolved, update GLOSSARY.md right there. Don't batch these up." Called from `grill-with-docs`, `triage`, `wayfinder`, `improve-codebase-architecture`; `setup-matt-pocock-skills` writes consumer rules into `docs/agents/domain.md`.
- Consumer use: no link-to-home rule. Consumers read the glossary and use its vocabulary verbatim (`to-spec`, `to-tickets`, `tdd`, `pr`, `wait-what`, `diagnosing-bugs`, `triage`: "read GLOSSARY.md (if it exists)").
- Drift: caught live in conversation only ("Challenge against the glossary: call it out immediately"); resolved drift lands in `## Flagged ambiguities`. No static scan for docs using a term without linking it.

## Verdict — surface · 2026-10-29

### Findings

- premise age: clean on the Area paths — no commit touched `plugins/super-bootstrap/agents/doc-sync-scan.md` or `plugins/super-bootstrap/skills/commit/SKILL.md` since 2026-10-27. Card-thread history since then: `d920b49` closed the card, `b1317ff` reopened it. The `docs/decisions.md` row for this card now rejects only census-threshold discovery. A home declared by the author is not that lane, so this aim does not re-walk a closed fork. No open card overlaps (the only other open card is `GAP-0asv`, the commit door push ask).
- root cause, per-commit lane (verified): the commit door's lanes do not see a term use. `terms` derives its terms from changed path structure only (`commit/SKILL.md` §3 "Terms → grep hits", and §5 "Term extraction is path-structure only"). `hits` matches those terms only in code shape. The citer lane (`refs`) returns only docs that already link the changed path. `restatement-predicate.md` counts copies of a fact, not uses of a term. So a doc that uses a registered term and does not link its home reaches no lane unless the doc is in scope for another reason. The card's claim holds.
- card correction, rest of the surface: the gap is not "no mechanism exists". Two of the three moments are covered already. (1) Authoring: `ssot-doc-link` (shipped asset `harness-bootstrap/assets/rules-ssot-doc-link-skeleton.md`, byte-identical to `.claude/rules/ssot-doc-link.md`) already requires a link on the first substantive use of a concept that has a real home, one link per doc. (2) Audit: `check-docs-consistency/SKILL.md:104` already reports "Missing link to a concept's home doc" with `assets/link-predicate.md`. Only the per-commit doc-sync lane is missing. Also, the census figure "46 docs, 14 linking" does not equal 32 violations. The predicate excludes passing tokens, catalogs and ephemeral docs, and nobody has measured how many of the 32 docs use the term substantively.
- research read against the aim: mattpocock's `domain-modeling` method supplies a home format and nothing else this card asks for. It gives one `GLOSSARY.md`, `**Term**:` entries with `_Avoid_:` synonyms, an admission test ("unique to this context") and an in-session update moment. Its consumer model is "read GLOSSARY.md and use its words". It has no link-to-home rule and no static scan. So "adopt over build" covers the home only. The unlinked-users half has no established method in his set, and this repo's own `ssot-doc-link` rule already owns that half.
- useful property of the glossary: a declared entry list (`**Term**:` plus `_Avoid_:`) gives a doc-sync lane a term list without tokenizing prose. That removes the precision objection that rejected census discovery (CJK prose, ordinary English words, file-stem noise).
- scope reach: the change ships to every consumer, so it is not one feature surface. It touches the shipped rule asset `rules-ssot-doc-link-skeleton.md` and its placed copy `.claude/rules/ssot-doc-link.md`, the `claude-md-skeleton.md` § Doc Sync, `commit/assets/doc-links.sh` (a new verb that reads glossary entries), `commit/SKILL.md` §3/§4, `doc-sync-scan.md` § Scan and output contract, `check-docs-consistency/SKILL.md` with `link-predicate.md`, possibly a new `glossary-skeleton.md` asset plus `harness-bootstrap/SKILL.md` seeding, and this repo's dogfood docs (it has no term home on the doc surface today).
- attempted: static reads of the commit lanes, the link predicate, the restatement predicate, the shipped rule, and the decisions rows (mattpocock pairing removed; "distil-foreign-doctrine" ruled out for pasting his skill bodies, not for adopting a file format). Stopped at the consumer-model fork below. It is a shipped-behavior call for every bootstrapped repo, and no spec or decisions row settles it.

### Decision needed

- Which consumer model does a project term home ship with, and does the per-commit doc-sync check follow from it?
- options:
  - A. Glossary home plus link rule plus per-commit flag. Ship a `GLOSSARY.md` skeleton in mattpocock's entry format. `ssot-doc-link` names the glossary as the home of a registered term, and its first substantive use per doc links the glossary. A new `doc-links.sh` verb reads the `**Term**:` and `_Avoid_:` entries. The doc-sync lane flags, non-blocking, a changed doc whose added lines use a registered term (or an `_Avoid_` synonym) and that has no link to the glossary. The flag works like `restatements`: it offers a card and never edits.
  - B. Glossary home with mattpocock's consumer model unchanged. Agents read `GLOSSARY.md` before they write, and an unlinked use is not a defect. No doc-sync lane. The card's "registered term, unlinked users" gap is then defined away, not closed, and the method conflicts with `ssot-doc-link`'s link requirement for that class of concept.
  - C. No new home and no new lane. Keep `ssot-doc-link` (authoring) plus `check-docs-consistency` (audit) as the coverage, and close the card on the finding that only the per-commit moment is missing. Consumers that already have a term home (for example magnetized-remake `docs/specs/terminology.md`) are covered by the existing predicate.
- recommendation: A. It is the only option that closes the per-commit gap the card names. It adopts the established home format rather than building one. It reuses the link rule this repo already ships. The declared entry list is what makes the lane mechanical, with no tokenizing.
- settles by: preference/product authority (behavior shipped to every consumer, plus the open question of whether an `_Avoid_` hit counts as a flag). Before that call, one measurement sizes whether A catches anything that C misses. Run it as a dispatched probe: in magnetized-remake, for the terms defined in `docs/specs/terminology.md` (start with "shell"), apply `link-predicate.md` to the 32 docs that do not link the home, and count substantive-use violations against passing tokens, catalogs and ephemeral docs. A count near zero favors C. A real count favors A.


## Amendment — 2026-10-29 · gateway-dispatched read-only probe, Magnetized Remake (Verdict's `settles by:` proxy)

`link-predicate.md` applied to docs that mention a `docs/specs/terminology.md` term without linking it. Top-5 terms (mention docs / linking docs): area 49/12, shell 42/14, screen 34/15, layout 33/12, arc 33/6. Checked: all 28 non-linking "shell" docs, 8 sampled for each other term — 60 doc×term checks → 13 MISS, 47 PASS (token/homonym, catalog, ephemeral card). Per term MISS: shell 5, layout 5, area 2, arc 1, screen 0. Distinct MISS docs: 8 (`page-transition-rulings`, `shell-index-spec`, `platform-plan`, `dev-harness` clear; `level-data-rulings`, `ending-spec`, `intro-spec`, `lv81-spec` weak). Evidence: `docs/specs/shell-index-spec.md:3` "Covers the shell layouts the player passes through before gameplay"; `docs/specs/page-transition-rulings.md:3` "The state-now home of the shell's page-change system".
Read: substantive misses are real (not near zero), but a whole-word match on a registered term is a MISS only ~22% of the time (13/60) — homonyms ("screen", "arc", star "shell") and passing tokens dominate.

## Design — 2026-10-29

User ruling (in session, 2026-10-29): super-bootstrap ships one unified terminology shape and every downstream repo conforms to it ("我們要有terminology，downstream來跟我們的型。都是我的repo，unify最好") — not a consumer-declared home path. Rules out B and C; takes A with the judged flag the probe Amendment calls for.

- **Home — fixed path `docs/terminology.md`.** One cross-doc home beside `overview` / `techstack` / `decisions`; `docs/specs/` stays one-spec-per-feature. `harness-bootstrap` seeds it from a new skeleton asset and it joins the skeleton-mirrored docs.
- **Entry shape** (format adopted from mattpocock `domain-modeling`): `**Term**:` + a 1–2 sentence definition of what it IS, `_Avoid_:` synonyms. Admission: a concept specific to this project; a general programming word stays out. `_Avoid_` doubles as the alias list — a retired or rejected word for the same concept goes there.
- **Link rule.** `ssot-doc-link` (shipped asset + this repo's placed copy, byte-identical) names `docs/terminology.md` as the home of a registered term: a doc's first substantive use links its entry.
- **Per-commit lane — judged, non-blocking.** `doc-links.sh` gains a verb printing the registered terms and their `_Avoid_` synonyms. The commit door's doc-sync takes the changed docs' added lines that contain a registered term or an `_Avoid_` word, in a doc with no link to `docs/terminology.md`, as candidates; the judgment (warm inline, or `doc-sync-scan` past the ceiling) applies `link-predicate.md` and reports only substantive misses. An `_Avoid_` hit reports as "use the registered term". Reported like `restatements`: offer a card, never edit, never block. Pure word-match is not the gate — measured MISS rate 13/60 (probe Amendment).
- **Audit.** `check-docs-consistency`'s link predicate reads `docs/terminology.md` as a registered term's home.
- **Dogfood.** This repo gets its own `docs/terminology.md`.
- **Downstream.** Magnetized Remake moves `docs/specs/terminology.md` to `docs/terminology.md` in the unified shape; its `name-meanings.md` (identifier meanings) is MR's own and outside the shape. MR's session executes that; a `/send-note` handoff is the user's to send.

## Plan — 2026-10-29

Runs after GAP-0asv lands (both edit `commit/SKILL.md`). Test-first per `.claude/rules/skill-authoring.md`.

1. `commit/assets/doc-links.sh`: new verb reading `docs/terminology.md` → one registered term or `_Avoid_` word per line, tagged by kind; plus the candidate pass (changed docs' added lines × term list, minus docs linking `docs/terminology.md`, minus frozen provenance). Failing shell tests in `tests/` first, bite-checked.
2. RED bench for the judged lane: fixture diff with (a) a substantive unlinked registered-term use, (b) an `_Avoid_` word, (c) a homonym / passing token. Control = current door (reports none); arm reports (a) and (b), not (c).
3. `commit/SKILL.md` §3 lane + §4 judgment and report slot; `agents/doc-sync-scan.md` § Scan + output contract.
4. Shipped `harness-bootstrap/assets/terminology-skeleton.md`; `harness-bootstrap/SKILL.md` seeds `docs/terminology.md` and lists it among the skeleton-mirrored docs; `.claude/rules/repo-boundary.md` path list follows (harness edit).
5. `rules-ssot-doc-link-skeleton.md` + `.claude/rules/ssot-doc-link.md` (byte-identical); `check-docs-consistency` `link-predicate.md`; `claude-md-skeleton.md` § Doc Sync line + root `CLAUDE.md` mirror.
6. Dogfood `docs/terminology.md` for this repo; doc-sync over `docs/overview.md`, `docs/techstack.md`, `docs/specs/harness-architecture.md`, READMEs.
7. `audit-harness-edits` on the harness diff → `/super-bootstrap:commit` → `/release`.
