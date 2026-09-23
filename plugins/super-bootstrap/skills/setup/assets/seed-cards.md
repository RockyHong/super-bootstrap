# Greenfield seed cards

The three GAP cards the entry's greenfield branch seeds. Each fenced body is written verbatim as `docs/work/{ID}.md`. Fills: `{ID}` — the next GAP ID from `docs/work/README.md`'s high-water line (bumped in the same write), `{date}` — today. Nothing else varies; the H1 summary after `{ID} — ` is the idempotency-guard key.

## overview

```markdown
# {ID} — Pin down product overview

**Logged:** {date} · **Source:** /super-bootstrap:setup bootstrap
**Problem:** `docs/overview.md` is an unfilled skeleton. Resolve at pickup by settling the framing with the user (no source code) or by reverse-engineering it from the code (code present, undocumented).
**Area:** `docs/overview.md`
```

## techstack

```markdown
# {ID} — Decide techstack

**Logged:** {date} · **Source:** /super-bootstrap:setup bootstrap
**Problem:** `docs/techstack.md` lacks product + architecture context (manifest facts auto-filled where a manifest exists). Blocked on the "Pin down product overview" card.
**Area:** `docs/techstack.md`
```

## tech-curation

```markdown
# {ID} — Run tech curation

**Logged:** {date} · **Source:** /super-bootstrap:setup bootstrap
**Problem:** Stack-matched tech curation has not run. Re-run `/super-bootstrap:setup` once `docs/overview.md` + `docs/techstack.md` are filled. Blocked on the "Pin down product overview" and "Decide techstack" cards.
**Area:** `docs/overview.md`, `docs/techstack.md`
```
