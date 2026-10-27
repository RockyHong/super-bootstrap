# Term census reply: jowagoko (commit 0055032, working tree dirty)

Census ran clean (exit 0, empty stderr). doc-links helper: super-bootstrap 5.6.0 `skills/commit/assets/doc-links.sh`. The census's own B doc surface is 36 files. My greps below use a wider 78-file surface (docs/*.md, know-how, specs, work, outward, SKILL.md, scripts/*/README.md), so my counts run higher than the census for the same word.

## (1) Census output, verbatim

Raw output: [`jowagoko.census.txt`](jowagoko.census.txt).


## (2) Labels (top 20 of A, top 20 of B)

Link check = other surface files naming the term vs. files carrying a markdown link whose target contains it (grep spot-check, 78-file surface, home excluded). "named / linked" below.

### A (file-derived terms: the term is a filename stem, so it is a doc or script name)

| Term (docs) | Label | Home today | Mentions link to it |
|---|---|---|---|
| ep-prep (13) | terminology (skill/workflow name) | `.claude/skills/ep-prep/SKILL.md` | none/few: only 1 file links the SKILL.md; the rest write `/ep-prep` or plain text |
| voice (13) | terminology (聲線) | `.claude/skills/ep-prep/references/voice.md` | some: 22 named, about 6 linked |
| exposure (12) | terminology (曝光 mechanism) | `docs/know-how/platform/exposure.md` | most: 15 / 11 |
| podcast-distribution (11) | terminology | `docs/know-how/platform/podcast-distribution.md` | most: 18 / 12 |
| monetization (10) | terminology | `docs/know-how/platform/monetization.md` | most: 20 / 15 |
| render_episode (9) | leak (script name narrated in 9 files: ep-render, ep-member, decisions, history, 4 know-how/craft docs, a spec, overview, parked, techstack). Owner is techstack + ep-render SKILL | `scripts/render_episode.py`, `techstack.md` | none, named in code spans |
| title (9) | path/noise (generic word matching `title.md`) | `know-how/platform/title.md` | n/a |
| channel-scale (8) | terminology | `know-how/platform/channel-scale.md` | most: 10 / 7 |
| tags (8) | noise (generic word) | `know-how/platform/tags.md` | n/a |
| description (7) | noise (generic word; also a YT/RSS field name) | `know-how/platform/description.md` | n/a |
| ep-cut (6) | terminology (skill name) | `.claude/skills/ep-cut/SKILL.md` | none, slash-command form |
| ep-render (6) | terminology (skill name) | `.claude/skills/ep-render/SKILL.md` | none, slash-command form |
| comment-resonance (5) | terminology | `know-how/craft/comment-resonance.md` | some: 10 / 5 |
| ep-illustrate (5) | terminology (skill name) | its SKILL.md | none, slash form |
| episodes (5) | noise (generic word; `episodes.md` and the `episodes/` dir) | `docs/episodes.md` | n/a |
| residual_velocity (5) | unclear (a metric name; file stem is a data script/CSV, home not located) | not located | not checked |
| sponsorship (5) | terminology (業配) | `know-how/platform/sponsorship.md` | some: 9 / 5 |
| topic-probe (5) | terminology (skill name) | its SKILL.md | none, slash form |
| video-fx-layers (5) | terminology (craft concept) | `know-how/craft/video-fx-layers.md` | not checked |
| Table data (4, just past top 20) | noise (heading text, tokenizer artifact) | n/a | n/a |

### B (backticked tokens)

| Token (docs) | Label | Home | Links |
|---|---|---|---|
| overview.md (19), docs/overview.md (14) | path/noise (doc path) | itself | the in-degree of 37 in C is the real signal |
| index.md (15) | path/noise (three different index.md files collapse into one token) | n/a | n/a |
| exposure.md (11), podcast-distribution.md (10), monetization.md (9), channel-scale.md (7) | path/noise as paths; same terminology as A | see A | see A |
| .claude/skills/ep-prep/references/voice.md (9), voice.md (5) | path/noise (pointer to voice home, written as a code span, not a markdown link) | voice.md | counted as unlinked by a link check |
| decisions.md (8), techstack.md (6) | path/noise (pillar paths) | themselves | n/a |
| data/ (7) | path/noise (directory; techstack owns the data layer) | techstack.md | n/a |
| render_episode.py (7), align_cues.py (4) | leak | techstack.md | none |
| /ep-cut (6), /ep-illustrate (5), /ep-render (4), /ep-subs (4), /topic-probe (3), /yt-replies (3) | path/noise (command), fine as is; these are the skills' public names | SKILL.md each | n/a |
| /super-bootstrap:log (6), /super-bootstrap:needs-me (3) | path/noise (plugin command) | plugin | n/a |
| docs/work/ (5) | path/noise | work/README.md | n/a |
| 實務未驗證 (6) | terminology (evidence-grade label) | know-how/index.md scheme (not re-verified which section) | used as a tag, no link expected |
| description.md, tags.md, title.md, subtitle-emphasis.md, comment-resonance.md, sponsorship.md (4 each) | path/noise as paths; terminology as in A | see A | see A |
| --dry, `<description>`, `<link>`, Error: video, FONT_WGHT, 1×2, 1×3, Highlight members, M<n> (3 each) | path/noise (flags, XML tags, error strings, config tokens). `M<n>` (會員片 id) is a weak terminology candidate | n/a | n/a |

Roll-up of the 40 labelled terms: about 10 are terminology with an existing home that is mostly linked; about 7 are skill names (terminology whose home is a SKILL.md, almost never linked because written as `/name`); 3 are leaks (render_episode, align_cues and script names generally); the rest are paths, commands or generic English words.

## (3) Hot terms the census misses

Counts are files out of the 78-file surface containing the string (grep -l). The census cannot see these because they are plain prose or bold, not file stems or backticked.

| Term | Files | Home / note |
|---|---|---|
| 會員 (any) | 38 | specs/podcast-membership.md, craft/membership-video.md |
| cohost | 40 | role word, no home needed |
| 娜妹 / 迪哥 | 35 / 34 | proper names, no home needed |
| 字幕 | 33 | generic |
| 正片 | 33 | episode vs 會員片 distinction; spread over ep-cut/ep-member, no single home |
| 曝光 | 29 | has home exposure.md |
| hook | 28 | overview §3 (標題 hook structure); the video hook segment (ep-cut `hook/`) is a second meaning |
| 縮圖 | 27 | craft/thumbnail-prompt.md, overview |
| CTA | 27 | two meanings: audio tail (ep-stitch) and call-to-action; no home |
| 會員片 | 26 | membership-video.md is home; ep-member SKILL narrates it |
| 訂閱 | 26 | generic; 訂閱人參與率 is the defined metric in overview |
| CTR | 25 | overview §3 findings; used everywhere |
| Shorts | 24 | platform word |
| SoundOn / Spotify | 22 / 22 | platform names |
| 母題 | 21 | defined via overview (母題串, §3 motif CTR) and the episodes.md ledger; 18 of the files that say it also link overview.md |
| 留存 | 20 | overview 訂閱人參與率 / retention section |
| 片尾 | 19 | generic |
| 業配 | 16 | sponsorship.md home |
| 聲線 | 15 | voice.md home |
| 漏斗 | 14 | funnel-benchmarks.md, overview §3 funnel table |
| 母帶 | 13 | ep-cut/ep-stitch vocabulary; techstack is not the home |
| 實務未驗證 / retention / huddle / 章節-chapters | 13 / 13 / 13 / 14 | evidence label; EN twin of 留存; harness skill name; two words for one concept |
| 長尾 / 標題公式 | 11 / 7 | overview owns 標題公式 |
| 切角 | 8 | episodes.md ledger column; low |
| 定調 | 5 | overview opening; low |
| 換手語 | 2 | ep-cut SKILL + one card; a coined term at fan-in 2 |
| ⟲ marker | 7 | defined by rules/data-update.md (re-test marker), used in overview and others |

Takeaway: plain-prose domain vocabulary (母題, CTR, hook, 會員片, 曝光, 縮圖) reaches 20-30 files each, 2-3x the top of A (13). Also note most of these were counted over 78 files, A over 36.

## (4) Shape notes

1. **The unit of "term" is wrong for this repo.** Candidates come from file stems and code spans. The real vocabulary here is Chinese prose (母題, 切角, 會員片, 母帶, 換手語), which the census cannot tokenize. A's 464 terms are mostly skill, script and know-how filename stems. B is 84% singletons (846 of 1009) and its top rows are doc paths; a path mention is not terminology.
2. **Know-how files are already the home registry.** Each `docs/know-how/{platform,craft}/*.md` and `docs/specs/*.md` is named after the concept it owns, and the `index.md` files list them. A ledger here is mostly "filename stem = registered term"; it already exists. The know-how stems in A show 55-100% link rates (exposure 11/15, monetization 15/20, episode-anatomy 8/8, subtitle-emphasis 5/5, brand-palette 6/6).
3. **Biggest real gap: skill names and voice.** Skills (ep-prep, ep-cut, ep-render, ep-subs, ep-illustrate, topic-probe) are named in 4-13 docs, always as `/ep-cut`, almost never as a markdown link to SKILL.md (ep-prep: 1 file). That is by design (a command), so a ledger that expects links will flag all of them. It needs a "command" class that exempts them or defaults the link target to the SKILL.md. `voice` is named in 22 files with about 6 links because mentions are `voice.md` in code spans.
4. **Code-span path versus link.** Many mentions are a backticked path (`know-how/platform/channel-page.md`): a pointer without a link target. Treat a backticked doc path as a half-link, or link rate is understated.
5. **Leaks sit in techstack.md and in script names; past-tense docs inflate fan-in.** `render_episode` hits decisions.md and history.md, where timestamped narration is legitimate (doc-ownership: past-tense pillars are append-only). Skip `history.md`, `decisions.md` and closed work cards when counting fan-in; that removes 2-5 per term.
6. **Working tree is mid-refactor.** git status shows deleted scripts (transcribe_episode.py, review_page.py, diarize_split.py, speaker_enroll.py, audio_cache.py) that `docs/techstack.md` still narrates at length (about lines 60-64). The census is read from the old and new trees at once. Run it on a clean tree before reading numbers. This is also a live example of a leak: the long script narration in techstack.md is stale after the delete.
7. **Same word, two concepts.** `hook` (title hook vs video hook segment), `CTA` (audio tail vs call-to-action), `index.md` (three files), `title`/`tags`/`description` (generic words and field names). Fan-in cannot separate them, so a threshold flags these first and the hit rate for real drift is low.
8. **Threshold hint from the histograms.** A: 379 of 464 at fan-in 1; 19 at 5+. B: 846 of 1009 at 1; 18 at 5+. A cut at 5+ gives about 19-20 candidates per section, a reviewable size; a cut at 3+ gives 47 (A) and 64 (B), mostly noise. After removing paths, generic words and commands, 5+ leaves roughly 8-10 real terms here, and all already have homes. For the prose vocabulary in (3) a 10+ cut is needed to keep it small.
9. **Link in-degree (C) is the better registry signal.** Top C targets are exactly the pillar and know-how docs. A term with fan-in 5+ whose home is not in C (skill names, residual_velocity) is the real "unregistered" set. That check is cheap and sidesteps CJK tokenization.
10. **ssot-doc-link interaction.** The rule says one link per concept per doc, on the first asserting use, so "named in N, linked in M" is well defined per doc. Catalog/index docs (know-how/index.md, work README) are exempt under the rule, so remove them from the denominator or they read as unlinked mentions.
