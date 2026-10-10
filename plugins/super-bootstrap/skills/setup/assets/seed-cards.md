# Setup seed cards

The GAP cards the entry seeds. The greenfield branch seeds the first three (overview, techstack, tech-curation) when the seed docs are not substantive; the code-present seed step seeds the last two (spec-seeding, marker-sweep) when the repo carries code — an undocumented repo with code takes all five. Each fenced body is written verbatim as `docs/work/{ID}.md`. Fills: `{ID}` — a GAP ID from the log skill's generator (`/super-bootstrap:setup` § Greenfield branch), used verbatim, `{date}` — today. Nothing else varies; the H1 summary after `{ID} — ` is the idempotency-guard key. Each `Problem:` line states the card's precondition, judged at pickup. The two code-present bodies also pin their method — the spec shape and the sweep cap are the pipeline's contract, not the pickup's to choose.

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

## spec-seeding

```markdown
# {ID} — Seed feature specs

**Logged:** {date} · **Source:** /super-bootstrap:setup bootstrap
**Problem:** `docs/specs/` holds no spec for the features already built. Identify 3–5 major features from `docs/overview.md` Module Index and the code structure; write each at `docs/specs/{feature-slug}.md` — first line `# {Feature Name}`, then a one-paragraph intro (what it does, why it exists), then a code-light product body: intent, user flow, cross-module interactions, design decisions. The user reviews before the commit. Precondition: built features and a grown Module Index — blocked while `docs/overview.md` Module Index is empty or the "Pin down product overview" card is open. Forward design before code belongs in `docs/overview.md` § Problem and GAP cards, never a speculative spec.
**Area:** `docs/specs/`, `docs/overview.md`
```

## marker-sweep

```markdown
# {ID} — Sweep code markers into cards

**Logged:** {date} · **Source:** /super-bootstrap:setup bootstrap
**Problem:** Deferred work already visible in the code has no card. Scan source for `TODO` / `FIXME` / `XXX` / `HACK` markers, review test output for failing or skipped tests with no recent fix attempt, and note design gaps the scan surfaces. Cap at ~5 highest-signal candidates (list the rest), the user prunes, and the kept ones land through `/super-bootstrap:log`; none found → resolve with nothing logged. Precondition: source code present.
**Area:** source tree, test output, `docs/work/`
```
