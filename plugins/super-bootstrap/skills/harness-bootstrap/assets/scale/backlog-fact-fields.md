<!-- scale-module: fact fields -->

**Optional row fields** — add to a row only when known at capture; an absent field means "derive at pickup", never "no". They sharpen routing without gating the log.

- **Test-feel:** `unit | e2e | manual | doc-only` — how the fix wants to be verified. Feeds venue derivation (`.claude/rules/venue-map.md`).
- **Stochastic:** `llm` — present only when diagnosis or verification depends on live-LLM behavior. Feeds venue derivation (`.claude/rules/venue-map.md`).
- **Blast:** `local | pkg | cross-pkg | repo` — how far the change reaches. Feeds pickup sizing.

**Capture routing** — before logging, name the action:

- Nameable **and** its fire-moment is now → a row here.
- Nameable but waits on a trigger → a `docs/parked.md` entry (its header owns the admission bar).
- Can't name the action → drop it; it re-enters on the next pain.

<!-- /scale-module -->
