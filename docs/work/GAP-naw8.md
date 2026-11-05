# GAP-naw8 — `/harness-bootstrap` is a burden to keep re-running; can orthogonal harness prose splice in without editing CLAUDE.md?

**Logged:** 2026-11-05 · **Source:** author, in discussion
**Problem:** The author finds `/harness-bootstrap` troublesome because it must keep being updated. The author's words, verbatim: 「/harness-bootstrap 我覺得滿麻煩，要一直更新。如果我們的東西本身跟其他plugin正交，是不是能用hook或其他的方式(例如start session hook) 之類的來拼接就不用去做claude.md之類的編輯，而且claude md不應該always 母層，而是SOC 各層級path 的rules 或sub folder的 claude.md?」
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/`, `plugins/super-bootstrap/hooks/`, root `CLAUDE.md`
**Prior:** A hook such as SessionStart, or another mechanism, splices the prose in; what stays in CLAUDE.md separates by concern into path rules or subfolder `CLAUDE.md` files rather than always sitting at the root.

## Amendment — 2026-11-05 · the logging session's own analysis, added on the author's ask; not the author's claim

Scope set by the author: ground first; the session that logged this card changes no real pipeline.

**Measured on this repo (`plugins/super-bootstrap/skills/harness-bootstrap/`):**

- `assets/claude-md-skeleton.md` is 19,102 bytes. 83 commits touch it, 17 of them in the last 60 days.
- `SKILL.md` is 73,582 bytes.

**Read from the official docs, through a Sonnet `claude-code-guide` dispatch.** It read about the first 100k of 286k characters of the hooks page, so an "undocumented" below may only be unread:

- A plugin `SessionStart` hook can inject context by stdout or `additionalContext`. The cap is 10,000 characters per output. Over the cap, the output goes to a file and leaves a path plus a 2,000-character preview, and Claude is not told to read the file.
- The hooks page advises writing injected text as facts, not imperative commands.
- `SubagentStart` can inject into a subagent. Whether `SessionStart` context reaches a subagent: not found. `CLAUDE.md` reaches non-fork subagents.
- After compaction, root `CLAUDE.md` is re-injected from disk. `compact` is a `SessionStart` matcher value. How injected hook text survives compaction: not found.
- Plugin-shipped `rules/` is not listed among plugin components, and a `CLAUDE.md` at a plugin root is not loaded.
- `paths:` rules load on Read, Write or Edit of a matching file, and a Bash `cat` or `head` of one file also counts. Subdirectory `CLAUDE.md` files load on demand.

**Repo surfaces that bear on the ask:**

- [`docs/decisions.md`](../decisions.md) closes carrying the discipline fences as path-scoped rules (`GAP-039`'s row): those fences fire at a moment, not on a file operation. That collides with the rules half of this card's ask for those fences only. Its ground says "fires on file read", narrower than the docs' Read, Write or Edit; the verdict's reason does not depend on the difference.
- The `entry-nudge` row closes a hook that re-pushes prose on top of `CLAUDE.md`. This ask replaces the carrier instead, so that row's verdict does not reach it, and its 10/10 evidence is for `CLAUDE.md` delivery only.
- The runway-version row (`GAP-076`) is a precedent for moving something from placed to plugin-owned, so it updates with `autoUpdate`.
- [`docs/specs/harness-architecture.md`](../specs/harness-architecture.md) §8 states that a section dropped from the skeleton orphans in consumer repos. Moving prose out of the skeleton meets that hole.
- [`docs/overview.md`](../overview.md) § User says the runway is light enough for a consumer to modify. Prose delivered by a plugin hook is not editable in the consumer's repo.

**A shape the session proposed, unverified and not settled:**

| Content | Carrier |
|---|---|
| Discipline with no file operation to bind to | plugin `SessionStart` + `SubagentStart` hook |
| Content needed only when a door runs | that skill's body |
| Path-bound content | placed `.claude/rules/` |
| Project facts | thin root `CLAUDE.md` |
| Placed hooks (`commit-channel`, `consult-check`) | plugin-owned hooks |

**Open questions for grounding:**

- Does hook-delivered discipline shape behavior as well as `CLAUDE.md` does, in a main session, in a subagent and after compaction?
- How much of the skeleton fits 10,000 characters once door-bound content moves out?
- What does a repo with no plugin installed lose?
- Does this card's pain sit in the skeleton churn at all, or elsewhere in the re-run?

## Verdict — surface · 2026-11-05

### Findings

- premise age: clean. No commit touches the Area paths after the 2026-11-05 observation.
- root cause: the re-run burden sits mainly in the trigger and the walk, not in the `CLAUDE.md` carrier. Direct evidence, git tag diffs `v2.46.0..v5.9.0` (37 releases, 2026-09-01 to 2026-11-04, about one per 1.7 days):

  | What the release changed in files that reach a consumer | Releases |
  |---|---|
  | Nothing. The re-run writes only the receipt | 11 |
  | `claude-md-skeleton.md` only | 7 |
  | Another placed file, with or without the skeleton (17 touch a doc or rule skeleton, 5 touch a placed hook; overlap allowed) | 19 |

  Excluded as not placed: `bootstrap-plan.md`, `hooks-ensure-infra.md`, `rename-map.md`, `split-outward.py`, `card-fact-fields.md`. The 19 is an upper bound for any one consumer, since scale-module and signal-seeded skeletons place conditionally.
- mechanism, trigger: [`runway-version.sh:76-78`](../../plugins/super-bootstrap/hooks/runway-version.sh) compares the receipt to the plugin version, and any release bumps that version. So the nudge fires on all 37 releases, at every `startup|resume|clear|compact` boundary until a re-run. It carries no signal of whether a placed file changed.
- mechanism, walk: `SKILL.md` § Version-staleness signal (`:103`) sets `version_stale` on any older receipt and enforces the full drift re-check. A re-run loads the 73,582-byte skill and walks every applicable row (this repo's receipt lists 41). § 2b adds per-section approval on drift, and § 2c `:571` re-prompts a declined section when its template text changes. A release that changed nothing placed still pays this walk.
- answer, skeleton churn: real but small and not the main driver. The Amendment's counts hold (83 commits, 17 in 60 days; `SKILL.md` churned more, 42 in the same window). Skeleton diffs are 1-8 lines per release. If every line of `CLAUDE.md` prose left the placed set, 7 of the 26 releases with placed change would need no re-run, and 19 still would. The nudge would still fire on all 37 unless it is rekeyed.
- limit: this repo holds no measurement of a consumer re-run (prompt count, minutes). Its own last 10 sync commits changed only the receipt, but the asset and prose lanes in [`.claude/rules/repo-boundary.md`](../../.claude/rules/repo-boundary.md) keep this repo current at commit time, so that does not represent a consumer.
- answer, root `CLAUDE.md` by default: the pipeline already separates by concern for project content. `SKILL.md:46` and `:645` send path-bound and enforcement content to rules, with "no nested CLAUDE.md needed", and the § 2b migration table routes the rest out. Measured by skeleton section offsets, root residue is:
  - 15,718 of 19,102 bytes (82%): plugin-generic prose (Development Workflow 4,831 · Dispatch 4,186 · Doc Sync 4,464 · Edit Discipline, Context Hygiene, Finding Triage, Git Notes 2,237)
  - about 2,460 bytes: § Rules and § Planning index lines
  - under 1,000 bytes: project-fact slots (Tech Stack, Commands)

  So the author's observation holds for the plugin-generic 82%: it is not project-specific. Thin root `CLAUDE.md` is a question about that prose only. Subfolder `CLAUDE.md` has no evidence for it here beyond the existing rule-first stance.
- answer, what fits 10,000 characters: 15,718 bytes does not fit. Moving all of § Doc Sync to the commit door and the `dimension-discipline` rule leaves 11,254, still about 1,300 over, so a further cut is owed. The 10,000 cap is the Amendment's reading of the docs. No docs tool exists in this lane, so it stays unverified here.
- answer, hook delivery vs `CLAUDE.md`: not settled. Attested: a SessionStart `additionalContext` token reaches the main session (`claude-shape/hook-feedback-channels.md`, positive control, CC 2.1.284). Unmeasured here: subagent reach, reach after `compact` (`hooks.json` wires the matcher, and no probe observes its context arriving), and behavior shaping against the 10/10 `CLAUDE.md` control.
- addition the Amendment missed: the `DEBT-122` row in [`docs/decisions.md`](../decisions.md) measured a once-per-session injection against per-prompt: 42/54 vs 46/54, with a recurring turn-3 miss. It tested a forced-eval catalog, not standing discipline, and did not compare against `CLAUDE.md`, so it closes nothing here. It does show delivery form changes recall, and `bench/consult-hook/` is a bench that can measure it.
- closed forks: no row closes a carrier replacement.
  - `GAP-039`: confirmed. It closes moment-fired fences as path rules only.
  - `entry-nudge`: confirmed. It closes a hook on top of `CLAUDE.md`, not a replacement. [`docs/specs/harness-architecture.md`](../specs/harness-architecture.md) §5 still states ambient prose as the proven carrier, so a replacement owes that spec an edit.
  - `GAP-076`: confirmed as precedent for moving a detector to plugin-owned. Its reason is `${CLAUDE_PLUGIN_ROOT}` access, not prose delivery.
- what a plugin hook adds as cost, beyond the Amendment:
  - It spawns in every repo where the plugin is enabled (`runway-version.sh:22-24`). Injected discipline, and `commit-channel` or `consult-check` as plugin-owned hooks, need a receipt gate or they reach never-bootstrapped repos. The Amendment's table omits this.
  - The `declined` mechanism has no equivalent. This repo declines 4 `CLAUDE.md` sections in its own receipt, and [`docs/overview.md`](../overview.md) § User states the runway is light enough to modify. Confirmed collision.
  - [`docs/specs/harness-architecture.md`](../specs/harness-architecture.md) §8: a section dropped from the skeleton orphans in consumers. Confirmed. Moving prose out owes either an adopt-mode removal path or a hand sweep, or the text doubles.
- answer, no plugin installed: every skeleton door (`/super-bootstrap:*`) already dangles there, so the doors are no new loss. The new loss is the ambient laws, § Dispatch and § Doc Sync, which `CLAUDE.md` delivers today from the repo alone. `SKILL.md:241` names a cloud session as loading no repo-declared plugin. The `GAP-076` row says cloud reach rides the marketplace install. These two lines disagree on how a cloud session gets the plugin, and this lane did not settle it. `AGENTS.md` stays placed, so a foreign executor loses nothing.
- orthogonality premise: holds as § 4 of the architecture spec states it (no foreign skill named at runtime), but it does not bear on the burden. The re-run comes from placing copies, not from coupling to other plugins.
- duplicates: no open card overlaps. No grep hit in `docs/work/` beyond this card, and none in `docs/parked.md`.
- scope reach: `runway-version.sh`, `harness-bootstrap/SKILL.md` Phases 1-2c, `claude-md-skeleton.md`, every § Pipeline-owned row, `hooks/hooks.json`, `hooks-ensure-infra.md`, `tests/runway-version.test.sh`, architecture spec §5 and §8, `docs/overview.md`, and this repo's dogfood `CLAUDE.md`.
- attempted: static reads and git tag diffs only, per the author's grounding-only scope. No consumer re-run was observed and no hook probe ran.

### Decision needed

- Which part of the burden does the next card target: when and how much the re-run costs, or where the discipline prose lives?
- Options:
  - (a) Trigger and walk only. Key the nudge and `version_stale` on a change to placed content, and scope the walk to changed rows. `CLAUDE.md` stays the carrier. Silences the 11 no-op releases and cuts walk cost on the other 26. Prose stays editable and needs no delivery measurement.
  - (b) Carrier only. Move plugin-generic prose to a receipt-gated plugin hook. Removes re-runs on 7 releases and the approval step for that prose, gives up per-consumer edits, and needs the delivery measurement below. The nudge stays at release cadence.
  - (c) Sequence: (a) now, then (b) only if the measurement below passes and the burden remains.
  - (d) No change. Accept the cost as it stands.
- recommendation: (c). The evidence places the larger share of the burden in the trigger and walk, and (a) carries no delivery risk. (b) gives up consumer editability and has no behavior evidence yet.
- settles by: preference and business authority (the author's judgment on whether consumers keep edit rights over discipline prose, and which part of the burden is felt). The delivery half of (b) settles by measurement:
  - `dispatched probe`: a positive-control token through a plugin SessionStart hook, checked in a subagent and after compaction.
  - `phased build`: a behavior-shaping comparison, hook-delivered vs `CLAUDE.md`, on a multi-turn bench in the `bench/consult-hook/` mould.
  - `inline read`: the remaining pages of the hooks docs for the 10,000 cap and its multi-hook behavior.

## Amendment — 2026-11-05 · official docs, device guidelines and community survey, gathered on the author's ask

The author directed that grounding includes the official manual and community practice. This block is second-hand: Sonnet dispatches read the sources, and the gateway read the device guidelines. A cold `triage` agent has no web tools, so this is its only route to the external evidence. It supersedes the earlier Amendment where the two differ.

### Official docs (`code.claude.com/docs/en/`), about 200k of 286k characters of the hooks page read

- **Compaction — closes the earlier "not found".** `context-window.md`: "SessionStart hooks that match the `compact` source | Claude Code runs them and adds their output to the compacted context"; "Context that hooks added earlier | Summarized with the rest of the conversation". `hooks-guide.md`: "Use a `SessionStart` hook with a `compact` matcher to re-inject critical context after every compaction."
- **Cap — corrects the earlier reading of a whole-prose limit.** `hooks.md`: "Claude Code measures each string on its own, even when several hooks run for the same event"; "When several hooks return `additionalContext` for the same event, Claude receives all of the values."
- **Imperative text — a direct risk for this prose.** `hooks.md`: "Write the text as factual statements rather than imperative system instructions... Text framed as out-of-band system commands can trigger Claude's prompt-injection defenses, which causes Claude to surface the text to you instead of treating it as context."
- **Subagents.** `SubagentStart` context is injected "only when the subagent's context doesn't already hold the copy from an earlier run", and again after auto-compaction discards it. Whether `SessionStart` context reaches a subagent: not documented.
- **Where instructions belong.** `plugins/components.md`: "To include instructions in a plugin, write them as a skill." `features-overview.md`: "Put it in CLAUDE.md if Claude should always know it"; "Keep CLAUDE.md under 200 lines. If it's growing, move reference content to skills or split into `.claude/rules/` files." A recommendation to deliver always-on plugin prose by `SessionStart`: not documented.
- **Plugins.** Plugin-contributed `paths:` rules or nested instructions: not documented; a plugin `settings.json` honors only `agent` and `subagentStatusLine`.
- **Cloud.** A cloud session does not add marketplaces listed under `extraKnownMarketplaces`. Whether a plugin `SessionStart` hook fires in a cloud session: not documented.
- **Authority.** A comparison of hook-injected context against `CLAUDE.md`: not documented. `memory.md` calls `CLAUDE.md` "context, not enforced configuration".

### Device guidelines (`~/.claude/guidelines/`; these resolve on the author's device only)

- `axiom-principles/layer-placement.md` § Split discipline: an always-on surface fails visibly and an on-demand surface fails silently, so the burden of proof sits on the split. "Ownership is the judge, not size." "Trim before split." Seam rules stay at the lowest shared surface.
- `claude-shape/layer-placement.md` anti-patterns: a commit-time or session-start rule does not belong in a nested `CLAUDE.md`. Nested loading has silently failed on several releases; verify it with the `InstructionsLoaded` hook.
- `claude-shape/hook-feedback-channels.md`: `SessionStart` re-fires on `clear` and `compact`, and a `startup`-only matcher loses its injection at the first compaction. It also fires in `claude -p`.

### Community (searched 2026-11-05). `read` = the page was fetched; `snippet` = search summary only, weaker

- `read` — [obra/superpowers `hooks/session-start`](https://raw.githubusercontent.com/obra/superpowers/main/hooks/session-start) wraps a SKILL.md in `<EXTREMELY_IMPORTANT>`, emits it as `additionalContext`, and applies no size limit. It is a live example of always-on prose through this channel, in imperative framing. Its compliance is unmeasured.
- `snippet` — claude-mem injects prior-session context at startup.
- `snippet` — sync tools (`sync-claude-md`, `agentsync`, `sync-ai-coding-instructions`) work per repo or per file, for Claude-versus-other-agent parity. None found for one block across many repos.
- `snippet` — [#16538](https://claudeissues.com/issue/16538-plugin-sessionstart-hooks-dont-surface-hookspecificoutput-additionalcontext-to-c) (closed 2026-05-11) and [#45438](https://claudeissues.com/issue/45438-plugin-sessionstart-hooks-execute-but-additionalcontext-stdout-is-silently-disca) report plugin `SessionStart` output not reaching Claude while settings-wired hooks worked. Whether #45438 still holds on the current build is unknown.
- `snippet` — [#46696](https://claudeissues.com/issue/46696-feature-sub-agents-should-inherit-claude-env-file-environment-variables-from-par) says `SessionStart` does not fire for subagents.
- `snippet` — [#43733](https://github.com/anthropics/claude-code/issues/43733) calls a `SessionStart`-compact re-read "hit or miss". This sits against the official line above.
- `read` — [#18560](https://github.com/anthropics/claude-code/issues/18560) (v2.1.9, closed not planned): the reporter holds that the `CLAUDE.md` wrapper's "may or may not be relevant" weakens it, and one commenter moved to a hook for that reason. Unverified theory.
- `read` — [#17204](https://github.com/anthropics/claude-code/issues/17204) and `snippet` [#33581](https://claudeissues.com/issue/33581-bug-path-scoped-rules-with-multiple-paths-in-frontmatter-silently-fail-to-load), [#61357](https://claudeissues.com/issue/61357-rules-with-paths-not-auto-loaded-when-editing-matching-files): reports of `paths:` rules failing to load (v2.1.25 to 2.1.116). No report found that a split worked; subdirectory `CLAUDE.md` experience: not found.
- **No measurement comparing delivery channels was found.**

### Sources in conflict, unresolved; each needs a probe on the current build

| Question | One side | Other side |
|---|---|---|
| Does Write or Edit trigger a `paths:` rule? | Official docs as read by the dispatch: Read, Write or Edit. | `claude-shape/layer-placement.md`: Read only, citing `anthropics/claude-code#23478` with the fix `NOT_PLANNED` (#38487); `snippet` #61357 agrees. |
| Do subagents get `CLAUDE.md` and rules? | `sub-agents.md` and `claude-shape/layer-placement.md`: yes, except Explore and Plan. | `snippet` #27661 says no; `snippet` #61467 says rules are skipped (closed 2026-05-26, fix unstated). |
| Does a `paths:` YAML list work? | `claude-shape/layer-placement.md`: yes, as of CC 2.1.267. | #17204 commenters: no (2026-01 builds). Possibly a version difference. |
| What is the hook output cap? | Official: 10,000 characters per string. | `snippet` unofficial gist: about 20 KB. Official taken as the lead. |

The earlier Amendment's line that `paths:` rules load on Read, Write or Edit reports one side of the first row and is not settled.

## Verdict — surface · 2026-11-05

This block supersedes the verdict above on the points below. The official-docs Amendment landed while that verdict was being written, so that verdict did not read it. Its release counts, trigger and walk mechanism, and closed-fork checks stand. The Amendment is second-hand evidence: this lane has no web tools and did not re-read its sources.

### Findings

- root cause: unchanged. 11 of 37 releases change nothing placed, 7 change only the skeleton, 19 change another placed file. The nudge fires on all 37. The Amendment holds no evidence on where the re-run cost sits.
- corrected, what fits: the 10,000 cap is per string, and several hooks each return their own string. So 15,718 bytes need not be trimmed to fit, and the earlier "does not fit" and "further cut is owed" fall. Size is no longer a constraint on option (b). A split into several strings is unmeasured.
- corrected, compaction: the docs state that `compact`-matched SessionStart output is added to the compacted context. The earlier "unmeasured" narrows to one open report (#43733, snippet, "hit or miss").
- new risk to (b), plugin hook reach: #16538 and #45438 (snippets) report plugin `SessionStart` output not reaching Claude while settings-wired hooks worked. The earlier verdict's attested reach came from `hook-feedback-channels.md`, and that line does not state a plugin-wired hook. `runway-version.sh` ships on this same channel, so a discarded output would also silence its nudge. Current-build status is unknown.
- new risk to (b), imperative text: the docs warn that imperative out-of-band text can trigger prompt-injection defenses, and § Dispatch and the ambient laws are imperative prose. Rewriting them as facts is itself a behavior-shaping edit, so the `CLAUDE.md` control no longer covers the same text.
- new risk to (b), subagents: no documented `SessionStart` reach, and #46696 (snippet) says it does not fire for subagents. `SubagentStart` is the documented route. Sources conflict on `CLAUDE.md` reach to subagents, so the baseline itself needs a probe. This session gives one data point: this dispatched triage agent received project `CLAUDE.md`.
- official placement guidance: the docs say to write plugin instructions as a skill and to put always-known content in `CLAUDE.md`. No doc recommends always-on plugin prose through `SessionStart`. This does not rule (b) out, but no official line supports it. obra/superpowers is a live example with unmeasured compliance.
- corrected, cloud: a cloud session does not add `extraKnownMarketplaces`, which supports `SKILL.md:241` over the `GAP-076` row's wording for a repo-declared plugin. The no-plugin loss therefore applies to cloud sessions of a repo-pinned plugin.
- rules half of the ask: three source conflicts on `paths:` loading are open, and `GAP-039`'s row rests on a file-read trigger. No report of a successful split was found. Subfolder `CLAUDE.md` gains no support: the device guideline reports silent nested-load failures.
- scope reach: unchanged from the verdict above.
- attempted: read the Amendment against the earlier findings. No probe ran.

### Decision needed

- The question and options (a), (b), (c), (d) stand as framed in the verdict above: which part of the burden does the next card target?
- recommendation: (c), now with more weight on doing (a) first. The Amendment removes one obstacle to (b), the size, and adds three delivery risks. None of them touches (a).
- settles by: the same author authority, on consumer edit rights and on which part of the burden is felt. The delivery half of (b) now sizes as:
  - `dispatched probe`: on the current build, a positive-control token through a plugin `SessionStart` hook and a plugin `SubagentStart` hook, read in the main session, a subagent, and after compaction; plus `CLAUDE.md` reach to a subagent as baseline.
  - `phased build`: a behavior-shaping comparison, fact-framed hook text vs `CLAUDE.md`, on a multi-turn bench in the `bench/consult-hook/` mould. It runs only if the probe passes.
  - The earlier `inline read` of the hooks docs is dropped, since the Amendment answers it.

## Amendment — 2026-11-05 · the author's answer on the felt burden, plus the gateway's first-hand doc and hook reads

**The author's words, verbatim, on which part of the re-run burden is felt:** 「會跟 cmm 的audit harness chain導致很久再audit，如果能拼接之類的做法就能省」. Read here as: a re-run chains into `claude-config-manager`'s harness audit, and that re-audit is the long wait. On the verdicts' options, the author's words: 「先不選，這session不決定」. No option is settled.

The verdicts measured re-run frequency and walk size, and neither measured this cost. Both verdicts' recommendation predates this answer and is open to re-weighing.

**The audit chain, read first-hand in `claude-config-manager`:**

- `templates/harness-audit-pretool.sh` `_harness_paths` gates a commit that carries `CLAUDE.md`, `AGENTS.md`, or anything under `.claude/rules/`, `.claude/skills/` or `.claude/agents/`, in any repo on the device. An unstamped commit gets a nudge to run `/audit-harness-edits`.
- `skills/audit-harness-edits/SKILL.md`: "Dispatch is unconditional" on a harness target. A cold probe loads the guideline trees and holds the diff against them. The skill states no exception for a sync of already-audited content.
- `.claude/hooks/`, the receipt and `docs/` are outside the gate's predicate.
- So the audit is a device-layer cost. A consumer without `claude-config-manager` does not pay it.

**Releases that change a placed, audit-gated file.** Git tag diffs, this Amendment's own count over `claude-md-skeleton`, `agents-md-skeleton` and `rules-*skeleton`: 19 of the 38 tags after `v2.46.0` through `v5.9.0` (the verdicts count 37 releases; the one-tag difference is not reconciled). Of the 19, 10 change only `claude-md-skeleton` and 9 change another gated skeleton. The verdicts' "7 of 26" counted re-runs over all placed files; for the audit cost, the comparable share is 10 of 19. Each is a ceiling: a consumer pays only when the sync writes the change and commits it. Not measured: audit wall-clock time, and how many sync commits ran an audit.

**Official docs, read first-hand. These replace the earlier second-hand lines on these points:**

- `memory.md`: subdirectory `CLAUDE.md` loads "once Claude reads, writes, or edits another file in that subdirectory". A path-scoped rule "loads when Claude uses the Read, Write, or Edit tool on a matching file". The docs are unambiguous; the conflict with `claude-shape/layer-placement.md` (Read only) is docs against a device guideline and is settled only by a probe on the current build.
- `memory.md`: "target under 200 lines per CLAUDE.md file. Longer files consume more context and reduce adherence. Move instructions that matter for only part of the codebase into path-scoped rules". An on-demand file over a per-file size limit delivers only its start.
- `large-codebases.md` § Layer CLAUDE.md files by directory, the page the earlier search missed: "A common split is two levels": root for "instructions that apply everywhere, such as coding standards and commit conventions"; per-subdirectory for "conventions specific to that area's stack". A per-directory file fits when "Directory owners maintain their own conventions"; a path-scoped rule fits when "You want all conventions in one place, or the same rule applies to many scattered paths".
- `large-codebases.md` § Centralize conventions when layering stops scaling: "Move conventions and reference content out of always-loaded CLAUDE.md and into mechanisms that load on demand", naming skills and "Plugins: versioned bundles of skills, hooks, and commands that a platform team owns centrally". "When shared skills need their own version history or must work across repositories, package them as a plugin".
- `large-codebases.md`: a skill's `paths` frontmatter makes Claude load it "automatically only when it works with matching files". Whether a plugin-shipped skill honors `paths`: not read. If it does, a plugin has a path-scoped carrier, which the earlier Amendment's table lacks.
- `best-practices.md` § Keep CLAUDE.md short: every line "takes a little of Claude's attention on every task"; the file "works best when it only holds what Claude couldn't work out from the code itself".

**Correction to the earlier reply in the session.** The session told the author it found no evidence for subfolder `CLAUDE.md`. The dispatches asked about loading mechanics and community reports only, and no search asked for official placement guidance. That statement reported a gap in the search as a gap in the evidence.

**One candidate route the verdicts do not list, unverified:** content a sync places byte-identical to a shipped skeleton was already audited at its source here, so the audit gate could treat it as audited. The fix would sit in `claude-config-manager`, and it addresses the audit cost without moving any prose. Skeleton rendering and per-section consumer edits may break the byte match; not checked.
