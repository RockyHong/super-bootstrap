# DEBT-120 — drain re-classifies every card in-model though render-board.py already encodes the spec (prompt-audit M8)

**Logged:** 2026-09-24 · **Source:** `/claude-api prompt-audit` over `plugins/super-bootstrap/**`; unverified at capture
**Problem:** `skills/drain/SKILL.md:36` (Shape 2) has the gateway Read `shared/classify-actionable.md` and derive `{action, intent, stage}` per card in-model. The plugin README (`:66`) calls that spec a total function, and `skills/todo/assets/render-board.py` already computes it mechanically — a model call doing deterministic work, with fork risk between the two lanes. The in-model judgment that genuinely remains is relation analysis + wave selection (`drain/assets/relations.md`) and the confirm gate.
**Area:** `plugins/super-bootstrap/skills/drain/SKILL.md`, `plugins/super-bootstrap/skills/todo/assets/render-board.py`, `bench/todo-board/`
**Prior:** A rows-emitting mode on `render-board.py` (e.g. `render-board.py <root> rows` → `id\taction\tintent\tstage`) behind the golden bench; drain consumes it and keeps its model call for relations/waves.
