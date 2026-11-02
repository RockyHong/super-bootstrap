# BUG-ptvs — Hub-stem rule claims the anchored citer lane reaches what it does not

**Logged:** 2026-11-03 · **Source:** BUG-et1c triage and replay probe
**Problem:** `doc-links.sh:645-648` and `commit/SKILL.md` §3 say a path mention of a hub doc is "a citation the anchored citer lane already reaches". `do_refs:532-533` matches an anchored query only against a link carrying that anchor, so an anchorless link to `techstack.md`, or a backticked `docs/techstack.md`, is not reached on a section-grain change. Those citers fall out of the scan scope today. The replay's widened `refs` arm added 32 doc × commit pairs current lanes miss (7 here, 25 in `magnetized-remake`), all anchorless citers of hub docs; nobody judged whether any narrates the changed truth.
**Area:** `plugins/super-bootstrap/skills/commit/assets/doc-links.sh` hub stems and `do_refs`, `plugins/super-bootstrap/skills/commit/SKILL.md` §3
**Prior:** The rule was written assuming citers link with anchors.
