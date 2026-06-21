# Trust Upstream Defaults

When integrating opinionated third-party tooling (plugins, MCP servers, SDKs, framework presets), default posture is trust upstream as shipped. Downstream "moderating overlays" (tool-selection tables duplicating routed skill descriptions, pre-flight rules re-stating built-in auto-triggers, ambient nudges paraphrasing upstream's prompt) assume downstream has a better view than upstream — upstream owns more invocations, versions, and failure data. The assumption is almost always wrong, and overlays decay fastest: upstream evolves, the overlay drifts, the overlay becomes the bug.

## Adopted rule

**Default = upstream canonical. Empirically prove canonical fails before authoring overlay. Date-stamp every overlay as decay debt.**

1. Use the tool with its canonical wiring as shipped.
2. If behavior feels off, strip the proposed overlay, dispatch a representative task under canonical-only wiring, observe ambient.
3. Ambient covers it → no overlay. Ambient demonstrably fails → overlay earns its slot, scoped narrowly, with a date for re-test on next upstream version.
4. Track every shipped overlay as debt with a half-life measured in upstream releases.

This is the inverse of "we know our context better." That claim holds at the **project-shape level** (which features matter, which trade-offs are acceptable). It does NOT hold at the **tool-usage level**.

## Failure modes

- **Overlay added without empirical probe** — authored from session memory of how the tool "should" behave; never tested against canonical-only under the current upstream version.
- **Overlay framed as "moderation"** ("upstream is too aggressive, I'll constrain it") → the framing itself is the ego signal; upstream's posture is usually a tested tradeoff.

Pairs with [`runtime-parity.md`](runtime-parity.md) — overlay decay and placement asymmetry compound.
