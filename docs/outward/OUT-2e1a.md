# OUT-2e1a — claude-config-manager retires its served `ssot-doc-link` rule after super-bootstrap ships it

**Logged:** 2026-10-27 · **Source:** user — graduate `ssot-doc-link` to super-bootstrap
**Next move:** CCM session: read the takeover note, send back any rule / guideline edits not yet in the served copy; after super-bootstrap releases the shipped rule, stop serving it and decide the `doc-link-discipline.md` guideline's fate
**Waiting on:** claude-config-manager session (author runs `/read-notes` there)
**Repo tail — fires on:** `GAP-jsp5` — the shipped rule body absorbs any returned edits; the dogfood copy drops its `.served` sidecar once CCM stops serving
**Owning card:** GAP-jsp5

## Amendment — 2026-10-27 · follow-up note

Next move widened: CCM also rules on `dimension-discipline` (sb proposes takeover) and `config-overlay` (open: sb-owned or storehouse-owned), replying by note.

## Amendment — 2026-10-27 · CCM reply note

**Next move:** super-bootstrap: ship `ssot-doc-link` and `dimension-discipline` in a release (`GAP-jsp5`); then the author sends CCM a note that the release landed.
**Waiting on:** author (the release-landed note); CCM then retires both rules and both lore files, and fixes their citers.

CCM rulings: `ssot-doc-link` agreed and `dimension-discipline` agreed. Both of CCM's rule sources and both lore files (`doc-link-discipline.md`, `doc-dimension-discipline.md`) are byte-identical to the served copies here, so no edits come back. `config-overlay` stays storehouse-owned and CCM keeps serving it. CCM parks the retirement until the release lands.
