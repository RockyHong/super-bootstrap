# DEBT-118 — Dated prompting patterns in shipped skill/agent prose (prompt-audit M1–M6)

**Logged:** 2026-09-24 · **Source:** `/claude-api prompt-audit` over `plugins/super-bootstrap/**`, cold subagent, target model judged per reader (sonnet pin → `claude-sonnet-5`, haiku pin → `claude-haiku-4-5`, inherit + skill bodies → session model assumed `claude-opus-5-5`); claims unverified at capture, review-intake pending
**Problem:** Six medium-confidence findings of text tuned for older models, each tied to the model that reads it:
- M1 — `skills/todo/SKILL.md:89,96,98,100` (dispatch brief read by the Sonnet-pinned `todo` agent): `render EXACTLY` / three-`Do NOT` run / `(Read this FIRST)` / `Classify EXACTLY per it`; caps + prohibition cluster, while the one real reason (the spec is also encoded by `render-board.py`, so a paraphrase forks the two lanes) never reaches the agent. Closure: `agents/todo.md:77` names the `(Read this FIRST)` label.
- M2 — `agents/todo.md:77,81,85`: "read the classification spec" stated 3× in-file plus a 4th in the dispatch brief (repetition as reinforcement); proposed rewrite `:77` plain with reason, drop duplicate first sentence at `:85`.
- M3 — `agents/todo.md:197`: "ranked list, no recommendation" duplicated at `:183`, `:197`, `:224`; `:224` covers every mode → drop `:197` (mechanical).
- M4 — `agents/triage.md:27` "Grep before reading" — strategy coaching the Opus-tier reader does unprompted; wrong where a root cause needs whole-file context.
- M5 — `skills/resolve-plugins/SKILL.md:54-56`: hardcoded upstream star/entry counts (172k, ~200, 78, 1000+, ~20k), undated; Phase 3 re-fetches live, and a stale count can anchor the trust read (mechanical). Same `1000+ skills` at repo-root `README.md:105`.
- M6 — `skills/harness-bootstrap/SKILL.md:699`: "~80k context = 100% recall" / "~120-line target" — capability numbers from a pre-1M-context generation; keep the lean-brief principle, drop the numbers.
Low-confidence flags (L1–L10, not for action without evidence) include `plugin-digest` Haiku-tier repetition — kept, may still be load-bearing on Haiku 4.5.
**Area:** `plugins/super-bootstrap/skills/{todo,resolve-plugins,harness-bootstrap}/SKILL.md`, `plugins/super-bootstrap/agents/{todo,triage}.md`, `README.md:105`
**Prior:** These are removals, so RED = with-text vs without-text equivalence on the reading model (N≥3 per arm; M1/M2 via forced fallback against `bench/todo-board` goldens, M4 via a whole-file-root-cause triage probe); M3/M5 mechanical.
