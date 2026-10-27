Term fan-in census reply from magnetized-remake (HEAD d50bacde, doc-links 5.6.0). Read-only run; nothing in this repo changed.

## 1. Census output (whole)

Raw output: [`magnetized-remake.census.txt`](magnetized-remake.census.txt).


## 2. Labels

Home docs in this repo: `docs/specs/terminology.md` (player-facing / design vocabulary) and `docs/specs/name-meanings.md` (identifier meanings, rename rulings). "Links" = whether mentions link to the home.

### A top 20

| term | docs | label | home / links |
|---|---|---|---|
| visual-guidelines | 26 | path/noise (spec stem; fan-in = citations) | — |
| game | 24 | path/noise (common word; also `game.gd` stem) | — |
| platform-plan | 21 | path/noise | — |
| game.gd | 19 | leak (core autoload narrated across specs) | owner = techstack § Architecture Rules; mentions mostly unlinked |
| ui-guidelines-desktop | 19 | path/noise | — |
| bigcake-spec | 17 | path/noise | — |
| mechanics-spec | 17 | path/noise | — |
| shell-pack-spec | 17 | path/noise | — |
| terminology | 16 | path/noise (the home itself) | — |
| lv60-spec | 15 | path/noise | — |
| shell-level-spec | 15 | path/noise | — |
| story-theme | 14 | path/noise | — |
| shell-index-spec | 13 | path/noise | — |
| shell-lvtext-option-spec | 13 | path/noise | — |
| ui-guidelines-mobile | 13 | path/noise | — |
| ui-strings | 12 | path/noise (the i18n table, cited by rule) | — |
| ui-strings.csv | 12 | path/noise (duplicate of the above) | — |
| Intro.tscn | 11 | leak (scene file narrated outside intro-spec) | owner = intro-spec; partly linked |
| achievements-spec | 11 | path/noise | — |
| platform | 11 | path/noise (common word; dir stem) | — |

Below 20 worth noting: `edge`, `press`, `player`, `project`, `audio`, `magnet` are file stems that are also common English words, so their A counts are English-word hits, not term hits. `titledown` (9) = an sfx asset name narrated in bigcake/ending/intro specs — leak, no home. `canvas_stack` (9) = leak, no home.

### B top 20

| token | docs | label | home / links |
|---|---|---|---|
| visual-guidelines.md | 12 | path/noise | — |
| CLAUDE.md | 10 | path/noise | — |
| Hello World | 10 | terminology (a level / page name) | terminology.md § Level names + name-meanings; mentions mostly unlinked |
| assets/i18n/ui-strings.csv | 10 | path/noise | — |
| game.gd | 10 | leak | as A |
| ui-guidelines-desktop.md | 10 | path/noise | — |
| dev-harness.md | 9 | path/noise | — |
| ../decisions.md | 8 | path/noise | — |
| /super-bootstrap:log | 8 | path/noise (command) | — |
| mechanics-spec.md | 8 | path/noise | — |
| techstack.md | 8 | path/noise | — |
| Game.move_camera | 7 | leak (function) | no home |
| back | 7 | unclear — mixes the InputMap action `back` (leak) with the **Back** chrome (terminology, home terminology.md) | partly |
| black_curtain | 7 | leak (node name) | name-meanings rules it; unlinked |
| docs/work/ | 7 | path/noise | — |
| magnet | 7 | terminology (core mechanic + the InputMap action) | terminology.md + name-meanings; mostly unlinked |
| project.godot | 7 | path/noise | — |
| scripts/audio.gd | 7 | leak | no home |
| title_logo | 7 | leak (placed object type) | name-meanings; unlinked |
| titledown | 7 | leak (sfx asset name) | no home |

## 3. Hot terms the census misses

Counts are files over all 117 `docs/**/*.md` (cards, outward, walkthroughs included), word-boundary, case-insensitive. Most of these appear in plain prose. Many are defined in terminology.md, but the docs that use them rarely link there.

| term | docs | home | notes |
|---|---|---|---|
| shell | 46 | terminology.md | screen class; core vocabulary |
| sheet | 46 | terminology.md | script driving one screen |
| pack (Pack screen) | 41 | terminology.md | also ships as `Pack` layout key |
| layout | 37 | terminology.md | engine-loaded unit; names are data |
| magnet | 36 | terminology.md | core mechanic |
| e2e | 30 | CODING_STANDARDS § Testing / dev-harness | process vocabulary |
| seam | 29 | terminology.md | page-transition vocabulary |
| overlay / modal | 29 | terminology.md | |
| BIGCAKE | 27 | bigcake-spec | page name |
| level strip | 24 | terminology.md | |
| route | 22 | terminology.md | |
| LVtext / transit (card) | 20 / 14 | terminology.md (level transition) | |
| ink | 19 | none | ink shader / puff vocabulary (active perf work) |
| cutscene | 19 | none central | |
| marquee | 17 | terminology.md (via level transition) | |
| Hello World | 15 | terminology.md | |
| wipe | 14 | terminology.md | |
| C2 (original project) | 14 | CLAUDE.md § Where truth lives | allowed only in docs/business by rule — fan-in outside it is itself a signal |
| page change | 13 | terminology.md | |
| star whisper | 13 | terminology.md (shell list) | |
| static lane | 9 | CLAUDE.md / dev-harness | |
| first clear | 9 | lv60-spec / achievements | |
| burn / comet / star-paved road | 9 / 8 / 7 | name-meanings partial | LV57 / level-scene vocabulary |
| 命題 | 7 | docs/business/product-frame | CJK — a regex with `\b` misses it |
| field line / 電弧 (arc) | 7 / 3 | terminology.md | bilingual pairs: one concept, two spellings |

## 4. Doc-shape notes

1. **Surface mismatch.** B's surface is 44 files; `docs/` holds 117 `.md`. The card set (`docs/work/`, 29 files, 2 on the surface), `docs/outward/` (14, 2 on the surface), and `docs/walkthroughs/` (33, none) are mostly outside it. Cards are where implementation names leak the most, so the ledger sees the cleanest part of the repo only.
2. **A is dominated by spec stems.** Of A's top 20, 16 are doc stems. Their fan-in is link citations, which C already measures. A ledger threshold on A flags the spec set itself. Suggest: drop terms whose stem is a doc on the surface, or subtract C.
3. **Common-word stems.** `game`, `edge`, `press`, `player`, `project`, `audio`, `platform` are source file stems that are also English words. The A count is English hits. A needs a word-likeness filter (dictionary or "stem only matches in code spans").
4. **One table inflates B.** `docs/overview.md` carries a 317-row test roster (`| \`unit_…gd\` | description |`). Many B tokens with 5–8 docs get one of those hits from that table. A roster/index table is an index, not narration — weight it as one hop, or skip table rows whose first cell is a file name.
5. **Two homes, by design.** This repo splits vocabulary into terminology.md (concepts) and name-meanings.md (identifiers → meanings, rename rulings). Identifier tokens (`black_curtain`, `title_logo`, `StarPavedRoad`) are "registered" in name-meanings, so a ledger that only knows one home calls them unregistered leaks.
6. **Live lookup keys look like leaks.** `Pack`, `LVtext`, `Hello World`, `magnet` are both domain terms and exact-string engine keys (layout names, InputMap actions). The ledger should treat them as terminology, not leaks. The census cannot split them.
7. **Bilingual vocabulary.** terminology.md pairs English with zh-TW (`arc` / 電弧, `field line` / 力線). CJK has no word boundary, and the pair is one concept spelled two ways. A term ledger needs aliases per entry.
8. **Linking habit.** Homes exist for most hot terms, but mentions rarely link: e.g. 46 docs say "shell" and 14 of those docs link terminology.md at all. The gap here is "unlinked mention of a registered term", not "unregistered term". That is the more useful check for this repo.
