<!-- scale-module: fact fields -->

**Optional card fields** — add to a card's origin block only when known at capture; an absent field means "derive at pickup", never "no". They sharpen routing without gating the log.

- **Test-feel:** `unit | e2e | manual | doc-only` — how the fix wants to be verified. Feeds venue derivation (`.claude/rules/venue-map.md`).
- **Stochastic:** `llm` — present only when diagnosis or verification depends on live-LLM behavior. Feeds venue derivation (`.claude/rules/venue-map.md`).
- **Blast:** `local | pkg | cross-pkg | repo` — how far the change reaches. Feeds pickup sizing.
- **Actor:** `author | external` — who moves the item as a whole; absent = the repo. `author` = a pass only the author performs (taste round, line-by-line review, an author writing session); `external` = the next move is an outside party's (a reply, a review, a signature) — the card form applies when `docs/outward.md` is absent; with the container present the outward entry is that item's home. Feeds classification: the board holds the card as a Decide row naming the mover; drain never admits it.

**Capture routing** — before logging, name the action:

- Nameable **and** its fire-moment is now → a card file via `/super-bootstrap:log`.
- Nameable, fire-moment now, but an outside party's move (or the author's move outward) with a repo tail → an entry in `docs/outward.md` when it exists (its header owns the admission bar), else a card carrying `Actor: external`.
- An author-only pass on repo work (taste round, review) → a card carrying `Actor: author`.
- Nameable but waits on a trigger → a `docs/parked.md` entry (its header owns the admission bar).
- Can't name the action → drop it; it re-enters on the next pain.

<!-- /scale-module -->
