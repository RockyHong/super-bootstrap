---
description: "Repo-boundary discipline — state which copy is under test (published vs in-repo dev); route findings to /super-bootstrap:log vs /contribute by ownership; shipped skeletons stay self-contained while the dogfood harness may taste-couple; a dogfood edit propagates to its shipped-skeleton mirror"
paths:
  - "CLAUDE.md"
  - "plugins/**"
  - ".claude/rules/**"
  - ".claude/guidelines/**"
---

# Repo Boundary — Copy Under Test, Finding Lanes, Taste-Coupling

This repo is the plugin source. Three boundaries bind every session:

**Copy under test.** State which copy a verification targets — the
published/installed plugin or the in-repo dev copy — before running it.
Default: verify against published; work the dev copy only when the session
explicitly targets it.

**Finding lanes.** Findings about this repo's own artifacts →
`/super-bootstrap:log`. Findings about device/global Claude config
(`~/.claude`, served rules, imported work-discipline guidelines) →
`/contribute` — imported artifacts are read-only here; surface, never edit
in place.

**Taste-coupling layers.** Two authoring layers, opposite latitude on wiring the
author's served `.claude/guidelines/`:

- **Dogfood harness** — this repo's own harness (`.claude/rules/` here; root
  `CLAUDE.md` via its always-on brief). MAY taste-couple: this repo's maintainer
  authors both the served guidelines upstream and this dogfood harness, so
  referencing them is sound.
- **Shipped skeletons** — `plugins/*/skills/*/assets/**`, seeded into downstream
  repos. MUST be self-contained: downstream ≠ author, so no wire to
  `.claude/guidelines/` and no reference to a plugin-internal path a consumer
  repo lacks (e.g. `skills/todo`). Judge a skeleton line by whether it resolves
  in a repo that has only the installed plugin, nothing of the author's.

**Sync direction — a dogfood edit carries its skeleton mirror.** The dogfood
harness is the ahead-SSOT; shipped skeletons (`plugins/*/skills/*/assets/**`, e.g.
`harness-bootstrap/assets/claude-md-skeleton.md`) are its seed. Editing a
dogfood-harness section pulls any shipped-skeleton counterpart into the edit's
propagation closure. Look it up live — grep the skeleton for the same section
heading; no static map. Counterpart exists → propagate the change, stripped of
dogfood-only references (per self-containment above); no counterpart, or the
change is genuinely dogfood-specific → state so and the skeleton stays.
