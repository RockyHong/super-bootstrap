<!-- scale-module: fact fields -->

**Optional card fields** — add to a card's origin block only when known at capture; an absent field means "derive at pickup", never "no". They sharpen routing without gating the log.

- **Test-feel:** `unit | e2e | manual | doc-only` — how the fix wants to be verified. Feeds venue derivation (`.claude/rules/venue-map.md`).
- **Stochastic:** `llm` — present only when diagnosis or verification depends on live-LLM behavior. Feeds venue derivation (`.claude/rules/venue-map.md`).
- **Blast:** `local | pkg | cross-pkg | repo` — how far the change reaches. Feeds pickup sizing.

**Capture routing** — before logging, name the mover, then the action:

- **Mover first** — whose hands move the next step: the repo's, the author's, or an outside party's? The repo → a card file via `/super-bootstrap:log`, and the action gates below apply.
- The author's or an outside party's — taste sitting, line-by-line review, a portal registration, a reply to wait for → an entry in `docs/outward.md` when it exists (its header owns the admission bar), else a card whose `Problem:` line names `waiting on {party}`.
- Mixed — the repo moves part of it → split at capture: the repo's remainder is the card, the other step an entry in `docs/outward.md`, carrying `Owning card:` when the card waits on that step.
- Nameable **and** its fire-moment is now → a card file via `/super-bootstrap:log`.
- Nameable but waits on a trigger → a `docs/parked.md` entry (its header owns the admission bar).
- Can't name the action → drop it; it re-enters on the next pain.

<!-- /scale-module -->
