---
description: "Skill-edit test-surface routing — behavior-shaping prose in a shipped skill takes writing-skills' RED (micro-test floor); mechanical edits ride audit-harness-edits + /release checks"
paths:
  - "plugins/*/skills/**"
---

# Skill Authoring — Test-Surface Routing

You are editing a shipped skill. The envelope's red phase is NOT structurally
empty here — `superpowers:writing-skills` defines the test surface for skill
prose. Route by what the edit changes:

- **Behavior-shaping content** — gates, protocol steps, disciplines, trigger
  descriptions, anything a consuming agent obeys → invoke
  `superpowers:writing-skills` and run its RED first: micro-test the wording
  against a no-guidance control as the floor; full pressure-scenario baseline
  for discipline-enforcing rules.
- **Mechanical edits** — typo, path/link fix, version string, formatting → no
  behavior surface; `audit-harness-edits` + the `/release` dispatch-shell
  check cover it.

Contract-shaped sections (an IO contract or dispatch spec another agent
authors from) ship only after a cold dry-run: a fresh agent authors the
executable from the section text alone; every guess it must make is a gap in
the section to patch. Full: `~/.claude/guidelines/axiom-principles/skill-authoring.md`
§ Cold dry-run gate.
