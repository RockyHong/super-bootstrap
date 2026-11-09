# GAP-h3cz — placed doc rules' `paths:` do not follow a repo's declared doc surface

**Logged:** 2026-11-09 · **Source:** GAP-ha7m's Design block (option iii, split out)
**Problem:** Once a repo declares extra doc-surface globs in `.claude/doc-surface` (GAP-ha7m), the commit door's lanes and the write boundary cover them, but the placed `dimension-discipline` and `ssot-doc-link` rules still fire only on the hardcoded `docs/**/*.md`, `README.md`, `plugins/*/README.md` in their `paths:` frontmatter. Authoring in a declared folder (e.g. `kinds/*.md`) gets no rule at the decision moment. Static YAML cannot read the declaration.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/assets/rules-dimension-discipline-skeleton.md:5`, `rules-ssot-doc-link-skeleton.md:5`, `claude-md-skeleton.md:121,123`; harness-bootstrap's rule placement step
**Prior:** harness-bootstrap renders the declared globs into the placed rules' `paths:` on placement and re-run; the frozen-asset byte-identical refresh then needs a defined render step.
