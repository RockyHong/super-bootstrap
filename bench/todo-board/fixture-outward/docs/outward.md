# Outward

Items whose next move is the author's or an outside party's — a reply to send, a pitch to make, an answer to wait for — where the repo owns only the **result tail**: something in this repo changes when the answer lands. The repo never moves these; this file holds them so the author sees at a glance what to move next and who is being waited on. Delete an entry when its tail fires (the repo edit lands, or a card opens for it). Git holds the history.

**Admission:** Outward = the author or an outside party moves it **and** it names a repo tail. Every entry MUST name the tail — the doc, card, or preset that changes when the result lands — else it drops: an outward item with no repo tail is the author's personal todo, not repo state. A card the repo moves stays in `docs/work/` (an author-only pass carries `Actor: author` there); a mixed card keeps its repo work in `docs/work/` and spawns an entry here for its external wall, citing the card.

**Pointer, not restatement:** an entry points at the doc that holds the status (a business doc, a spec, a card) — it never restates it.

**ID convention:** Every entry carries a stable `OUT-###` ID. IDs are monotonic and **never reused** — a resolved entry's ID stays consumed (history = `git log --grep="<id>"`). IDs index and cross-reference only — no ordering, no priority.

**ID high-water mark:** `OUT-002` — last consumed outward ID. `/super-bootstrap:log` assigns max+1 from this line and bumps it in the same write.

**Entry shape** — an `### OUT-### — {summary}` heading (so every entry indexes by ID in the outline), then the fields:

```
### OUT-### — {one-line summary}

**Logged:** {date} · **Source:** {where this surfaced}
**Next move:** {who does what next — "author: send the revised deck" / "vendor: answer the licence request"}
**Waiting on:** {the outside party — or `author` when the next move is the author's own}
**Repo tail — fires on:** {the doc / card / preset that changes when the result lands}
**Owning card:** {BUG|DEBT|GAP}-###   ← optional; the mixed card whose external wall this entry externalizes
```

**Consumer note:** `/super-bootstrap:todo` renders entries in their own need-me group — next move and waiting-on party visible, never folded into the drainable count; `/super-bootstrap:drain` never reads this file.

## Entries

### OUT-001 — font licence answer

**Logged:** 2026-08-10 · **Source:** release prep
**Next move:** vendor: answer the licence request
**Waiting on:** font vendor
**Repo tail — fires on:** docs/business/licences.md status row + the export preset include_filter

### OUT-002 — Steam pairing for the leaderboard

**Logged:** 2026-08-11 · **Source:** release prep
**Next move:** author: send the pairing request
**Waiting on:** author
**Repo tail — fires on:** GAP-401
**Owning card:** GAP-401
