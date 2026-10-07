---
description: "Repo-boundary discipline — state which copy is under test (published vs in-repo dev); route findings by concern-ownership first (the consumer-resolvability test) and only then by provenance, which names the write door — /super-bootstrap:log when the concern is this repo's, a served copy under this repo's own .claude/ included; /contribute when it is the serving repo's — never a local-clone edit; shipped skeletons stay self-contained while the dogfood harness may taste-couple; an edit propagates to its mirror in both lanes — dogfood prose → shipped skeleton, frozen asset → placed dogfood copy; .claude/guidelines/ is the storehouse's tree whole — this repo's own material lives in .claude/rules/ or docs/, never under it"
paths:
  - "CLAUDE.md"
  - "plugins/**"
  - ".claude/rules/**"
  - ".claude/guidelines/**"
  - ".claude/hooks/**"
  - ".claude/skills/**"
  - ".claude/agents/**"
  - "AGENTS.md"
  - "CODING_STANDARDS.md"
  - "docs/overview.md"
  - "docs/techstack.md"
  - "docs/decisions.md"
  - "docs/work/README.md"
  - "docs/work/TEMPLATE.md"
  - "docs/parked.md"
  - "docs/test-queue.md"
  - "docs/outward/README.md"
  - "docs/outward/TEMPLATE.md"
---

# Repo Boundary — Copy Under Test, Finding Lanes, Taste-Coupling

This repo is the plugin source. Five boundaries bind every session:

**Copy under test.** State which copy a verification targets — the
published/installed plugin or the in-repo dev copy — before running it.
Default: verify against published; work the dev copy only when the session
explicitly targets it.

**Finding lanes.** Two questions, in order — whose **concern** the finding is, then
whose **tree** holds the file.

*Concern first — the consumer-resolvability test.* Does the artifact **have to**
resolve in a repo that has only the installed plugin, nothing of the author's?

- Yes → this repo's concern. Log it here (`/super-bootstrap:log`), a served file
  included — the served copy itself stays untouched, and the fix lands in this repo's
  own artifact. A duplicate the serving repo holds is retired in that repo, so the
  card names the retirement as owed there and the author carries it; the session
  writes to one repo only.
- No, it resolves only where the author's device layer exists → the serving repo's
  concern. `/contribute` hands it over.

One edge the test already decides: a test surface or bench follows its artifact's
owner.

This file is the test's canonical home. A storehouse session cannot read this repo's
rules, so the storehouse needs the same test in its own routing rule, and a change to
the test here owes that copy the same change, routed by `/contribute`.

*Then provenance* — it names whose tree holds the file, and so which door a
**write** goes through, never whose concern the finding is. The `/contribute` handoff
is also the dedup step, so a serving repo's fix lands there and never as an edit here
or in a local clone of that repo. Served copies live under this repo's own `.claude/`
as well as at device level (`~/.claude`, imported work-discipline guidelines).
Tell a served copy by provenance, per class:

- `rule:` / `agent:` — a `<file>.served` sidecar beside it.
- `skill:` — a `.served` marker inside the skill directory.
- `hook:` — no marker; a `.claude/hooks/` file is served when it is
  byte-identical to `templates/<same name>` in the serving repo.

The serving repo is the path in `~/.claude/.repo-path`; its `must-have.txt`
lists the served classes but not every served hook, so the byte-compare is
the hook oracle. Served and imported artifacts are read-only here —
surface, never edit in place.

**Ownership by folder.** `.claude/guidelines/` is the storehouse's tree whole —
served and clone-replaced on every sync, present only where claude-config-manager
is; nothing this repo owns lives under it. This repo's own material takes its own
homes: a firing rule in `.claude/rules/`, reference prose in `docs/`, and a fact a
harness line already states stays on that line.

**Taste-coupling layers.** Two authoring layers, opposite latitude on wiring the
author's served `.claude/guidelines/`:

- **Dogfood harness** — this repo's own harness (`.claude/rules/` here; root
  `CLAUDE.md` via its always-on brief). MAY taste-couple: this repo's maintainer
  authors both the served guidelines upstream and this dogfood harness, so
  referencing them is sound.
- **Shipped skeletons** — `plugins/*/skills/*/assets/**`, seeded into downstream
  repos. MUST be self-contained: downstream ≠ author, so no wire to
  `.claude/guidelines/` and no reference to a plugin-internal path a consumer
  repo lacks (e.g. `skills/needs-me`). Every skeleton line must satisfy the
  plugin-only-repo test § Finding lanes states above.

**Sync direction — an edit carries its mirror; author on the SSOT side.** Two
lanes, opposite direction, one closure rule. A `harness-bootstrap` re-run verifies
both lanes and catches up what a commit missed.

- **Prose lane — dogfood ahead.** Harness prose authored here (`CLAUDE.md`
  sections, the `docs/` surfaces in `paths:` above) seeds its shipped
  skeleton (`plugins/*/skills/*/assets/**`, e.g.
  `harness-bootstrap/assets/claude-md-skeleton.md`). Editing such a section pulls
  the skeleton counterpart into the edit's propagation closure. Look it up live —
  grep the skeleton for the same section heading; no static map. Counterpart
  exists → propagate the change, stripped of dogfood-only references (per
  self-containment above); no counterpart, or the change is genuinely
  dogfood-specific → state so and the skeleton stays.
- **Asset lane — asset ahead.** A frozen asset (`assets/hooks/*` script +
  `.hook.json` snippet, `agents-md-skeleton.md`, `coding-standards-skeleton.md`
  preamble, rule / scale skeleton bodies, autorun templates) is authored in the
  plugin source; its dogfood copy (`.claude/hooks/*`, the merged
  `.claude/settings.json` entry, root `AGENTS.md` / `CODING_STANDARDS.md` shipped
  body, `.claude/templates/*`) is a placed
  derivative. Editing the asset pulls that copy into the closure — refresh it
  byte-identical (deep-equal for a snippet) so the next re-run reads it
  `✓ current`. Look it up live — grep the shipped assets for the matching
  destination; no single static map.
