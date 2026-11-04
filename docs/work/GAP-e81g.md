# GAP-e81g — triage does not ask whether the normal flow should reach the step a card repairs

**Logged:** 2026-11-04 · **Source:** the session that shipped v5.9.0 (the card that split many commits at session close, resolved in `0be682f`)
**Problem:** A card can repair a step the normal flow should rarely reach. Its verdict grounded how a close should split many commits, and two wording rounds followed. No one asked whether a close should hold many commits until the owner did: commits belong in flow, and the close only catches leaks. The bench also made that exception its main scenario.
**Area:** `plugins/super-bootstrap/agents/triage.md` aim validation
**Prior:** Triage asks whether the normal flow should reach the step, and if not, re-aims at the upstream cause. May over-fire on ordinary edge-case bugs. Needs a light RED first.
