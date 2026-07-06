---
description: "Repo-boundary discipline — state which copy is under test (published vs in-repo dev); route findings to /super-bootstrap:log vs /contribute by ownership"
paths:
  - "plugins/**"
  - ".claude/rules/**"
  - ".claude/guidelines/**"
---

# Repo Boundary — Copy Under Test, Finding Lanes

This repo is the plugin source. Two boundaries bind every session:

**Copy under test.** State which copy a verification targets — the
published/installed plugin or the in-repo dev copy — before running it.
Default: verify against published; work the dev copy only when the session
explicitly targets it.

**Finding lanes.** Findings about this repo's own artifacts →
`/super-bootstrap:log`. Findings about device/global Claude config
(`~/.claude`, served rules, imported work-discipline guidelines) →
`/contribute` — imported artifacts are read-only here; surface, never edit
in place.
