# Terminology

> **The project's term home.** One canonical word per project concept, one entry per word. Docs use the word this file registers; a doc's first substantive use of a registered term links its entry here.
>
> **Entry shape** — one line at line start, optionally `- ` prefixed: `**<Term>**: <definition>`. The definition is 1–2 sentences on what the term IS — no implementation detail.
>
> **Alias list** — an `_Avoid_: <word>, <word>` line directly after its entry, comma-separated. A retired or rejected word for the same concept goes here; a doc that uses it writes the registered term instead.
>
> **Admission** — a concept specific to this project. A general programming word stays out. Two words for one concept → pick one as the entry, list the other under `_Avoid_`.
>
> Fenced code blocks and HTML comments are never entries.

<!-- Example entry — copy the shape, not the content:

**Batch**: One scaled copy of a recipe, fixed to a target serving count and one unit system.
_Avoid_: run, scaled recipe

-->

**Runway**: The generic harness that `harness-bootstrap` installs or syncs in a repo — CLAUDE.md, AGENTS.md, skeleton docs, path-scoped rules and hooks. It seeds disciplines and doors, not a framework to conform to ([`harness-bootstrap`](../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md)).

**Card**: One open unit of work — a `BUG`, `DEBT` or `GAP` file at `docs/work/{ID}.md`, holding one append-only thread, deleted on resolve. It is the grounding artifact and the anchor of its change ([`docs/work/`](work/README.md)).
_Avoid_: backlog row

**Envelope**: The fixed sequence every card runs — ground → route → implement → verify → doc-sync → commit — with only the phases the card's shape needs ([CLAUDE.md § The envelope](../CLAUDE.md#the-envelope)).

**Cluster**: One of the eight card shapes (bug, fuzzy feature, design-intact multi-step, refactor, config tweak, docs, harness edit, triage) that sets a card's route ([CLAUDE.md § Cluster routing](../CLAUDE.md#cluster-routing)).

**Verdict**: The `## Verdict` block that triage appends to a card — `auto-fix` with fix-shape tags, or `surface` when the user is needed. It is the context scope implement runs on ([`triage`](../plugins/super-bootstrap/skills/triage/SKILL.md)).

**Gateway**: The main session that owns the user thread. It routes, sequences and integrates dispatched work, and it holds only reads and bounded live tweaks itself ([CLAUDE.md § Dispatch](../CLAUDE.md#dispatch--who-holds-each-phase)).

**Door**: A bundled skill or agent that is the one named entry for its move, such as the capture front door (`log`), the commit door or a grounding door. Work that needs the move passes through it.

**Commit door**: `/super-bootstrap:commit` — the one route by which a session's changes land. It is session-isolated, runs doc-sync gateway-inline, and commits locally without pushing ([`commit`](../plugins/super-bootstrap/skills/commit/SKILL.md)).

**Propagation closure**: An edit plus every truth it must keep in sync. Its size, not the diff size, decides whether work is dispatched or inlined ([CLAUDE.md § Dispatch](../CLAUDE.md#dispatch--who-holds-each-phase)).

**Doc surface**: The set of narrative docs that doc-sync keeps true — `docs/`, the root README, plugin READMEs, and any manifest description field the behavior changes ([CLAUDE.md § Doc Sync](../CLAUDE.md#doc-sync-non-negotiable)).

**Scan scope**: The docs that the commit door's mechanical lanes enumerate for one diff — citers, grep hits, link targets and the changed docs themselves — that the doc-sync judgment reads ([`commit`](../plugins/super-bootstrap/skills/commit/SKILL.md)).

**Restatement**: A fact written again outside its SSOT home. Restated in two or more places with a copy unlinked to the home, it is reported as a non-blocking `restatements` item ([`doc-sync-scan`](../plugins/super-bootstrap/agents/doc-sync-scan.md)).

**Closed fork**: A direction that was evaluated and rejected, recorded so that it is not proposed again. It lives as an append-only row in [`docs/decisions.md`](decisions.md).
_Avoid_: rejected direction

**Outward thread**: An item whose next move is the author's or an outside party's, and whose result changes something in this repo. It is one file in [`docs/outward/`](outward/README.md).
_Avoid_: outward item

**Scale module**: The opt-in, earn-gated runway addition that adds the `docs/parked.md`, `docs/test-queue.md` and `docs/outward/` containers beside the cards ([`harness-bootstrap` § 2a-scale](../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md#2a-scale-scale-module-opt-in-earn-gated)).

**Session-carry ledger**: The root `SESSION-STATE/` folder — one file per session — holding volatile in-flight state that no card owns, between session-close and session-continue ([`session-close` § Ledger convention](../plugins/super-bootstrap/skills/session-close/SKILL.md#ledger-convention)).

**Shipped skeleton**: A frozen asset under `plugins/*/skills/*/assets/` that `harness-bootstrap` renders into a consumer repo. It must be self-contained, because downstream is not the author ([`repo-boundary`](../.claude/rules/repo-boundary.md)).

**Placed**: Said of a file that `harness-bootstrap` wrote into a repo from a shipped skeleton and refreshes byte-identical on re-run ([CLAUDE.md § Rules](../CLAUDE.md#rules-auto-load-on-file-match)).

**Served**: Said of a file that the storehouse delivers into this repo's `.claude/` tree, clone-replaced, and not owned by this repo ([CLAUDE.md § Rules](../CLAUDE.md#rules-auto-load-on-file-match)).

**Storehouse**: claude-config-manager — the author's device-wide config repo that serves guidelines and rules into this repo, and receives artifacts through `/contribute` ([harness-architecture § The second seam](specs/harness-architecture.md#the-second-seam-claude-config-manager-the-authors-device-storehouse)).

**Dogfood**: This repo's own harness — its root CLAUDE.md and placed or served rules — run on itself. It may wire served guidelines that a shipped skeleton cannot ([`repo-boundary`](../.claude/rules/repo-boundary.md)).

**Process harness**: A third-party skill set that supplies process disciplines (for example superpowers). None is pinned, and a repo takes one as an ordinary adaptive pick ([harness-architecture § 2](specs/harness-architecture.md#2-which-slot-each-system-occupies)).

**Bench**: The `bench/` folder of measured fixtures — RED, GREEN and A/B probes kept beside the SSOT each one tests. A closed fork's reopen condition often names one ([overview § Module Index](overview.md#module-index)).
