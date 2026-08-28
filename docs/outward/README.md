# docs/outward — outward-item workspace

Items whose next move is the author's or an outside party's — a reply to send, a pitch to make, an answer to wait for — where the repo owns only the **result tail**: something in this repo changes when the answer lands. The repo never moves these; the folder holds them so the author sees at a glance what to move next and who is being waited on.

One item = one file = one append-only thread. Everything here dies with its item — only `README.md` and `TEMPLATE.md` are standing files.

## Routing

New entries enter via `/super-bootstrap:log` (mover gate + dedup + ID assignment) or by hand-copying `TEMPLATE.md` (sanctioned transcription path). Either way the ID high-water line below is bumped in the same change.

**Admission:** Outward = the next step is the author's hands or an outside party's **and** it names a repo tail. Every entry MUST name the tail — the doc, card, or preset that changes when the result lands — else it drops: an outward item with no repo tail is the author's personal todo, not repo state. An item the repo moves next stays a card in `docs/work/`; a mixed item splits at capture — the repo's remainder stays a card, the author-or-outside step is an entry here, carrying `Owning card:` when the card waits on it.

**Pointer, not restatement:** an entry points at the doc that holds the status (a business doc, a spec, a card) — it never restates it.

## Entry glob

`OUT-###.md` at `docs/outward/` root. Only `README.md` and `TEMPLATE.md` stand beside them.

## ID convention

Every entry carries a stable `OUT-###` ID — its filename and its H1 both. IDs are monotonic and **never reused**: a resolved entry's ID stays consumed (history = `git log --grep="<id>"`), so IDs come from the high-water line below, never from the live files. IDs index and cross-reference only — no ordering, no priority.

**ID high-water mark:** `OUT-002` — last consumed outward ID. `/super-bootstrap:log` assigns max+1 from this line and bumps it in the same write.

## Thread contract

**Origin block** (H1 + field lines) — frozen at capture; the breadcrumb at the top of the thread:

```
# OUT-### — {one-line summary}

**Logged:** {date} · **Source:** {where this surfaced}
**Next move:** {who does what next — "author: send the revised deck" / "vendor: answer the licence request"}
**Waiting on:** {the outside party — or `author` when the next move is the author's own}
**Repo tail — fires on:** {the doc / card / preset that changes when the result lands}
**Owning card:** {BUG|DEBT|GAP}-###   ← optional; the card that waits on this entry — the board holds it until the entry closes; an entry that only touches a card cites it in `Repo tail — fires on:` instead
```

**Appended blocks** — each at end of file, dated + sourced, from the same block vocabulary `docs/work/README.md` § Thread contract states for cards:

- `## Amendment — {date} · {source}` — a reply landed, a move made, a re-route, a new fact.
- `## Progress — {date}` — durable state carried between moves.

**Mutation authority:** any session or agent appends (end-of-file only, dated + sourced); existing content stays as written.

**Latest block leads:** a block restating `**Next move:**` / `**Waiting on:**` supersedes the origin's lines for every reader — board, log dedup, drain wall. `Owning card:` is the origin's alone — the wall is frozen at capture, never re-pointed by a block. Top-to-bottom reads as the item's evolution; the origin stays as grounding.

**Resolve:** the resolving session deletes the entry file when the tail fires — the repo edit lands, or a card opens for it; the deleting commit's message carries the why. Git history is the archive. Deletion dead-ends every markdown link that pointed at the file, so the same change drops those links to plain `` `OUT-###` `` spans — only a live entry earns a link.

## Consumer note

`/super-bootstrap:todo` renders entries in two need-me groups, split on `Waiting on` — **Outward — your move** when it names `author`, **Outward — waiting on others** for any other party. Next move and waiting-on party stay visible, never folded into the drainable count; `/super-bootstrap:drain` never reads this folder.
