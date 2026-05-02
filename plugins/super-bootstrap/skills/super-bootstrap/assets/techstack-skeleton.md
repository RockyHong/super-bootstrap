# Tech Stack

> Living doc. Skeleton sections (Runtime / Framework / Key Dependencies / Build & Distribution) seeded at scaffold from detected facts. Grown sections (Architecture Rules / Coding Patterns / Rejected Alternatives) start empty and grow via doc-sync — every commit that touches a relevant area triggers a sync proposal. See `CLAUDE.md` Doc Sync.

## Runtime

{detected from primary manifest — e.g. Node.js 20+ (ESM), Python 3.12, Rust 1.78, Go 1.22}

## Framework

{detected — e.g. Next.js 14, FastAPI, Axum, Echo. Drop the section if no framework.}

## Key Dependencies

{top-level deps grouped by role — runtime, dev, test, build. Skim from manifest, not exhaustive.}

## Build & Distribution

{commands as they exist in scripts / Makefile / Cargo.toml / etc. — copy verbatim, don't invent.}

## Architecture Rules

> Grows via doc-sync as patterns crystallize. Module boundaries, data flow direction, dependency philosophy, layering rules.

## Coding Patterns

> Grows via doc-sync as patterns crystallize. Import style, error handling convention, naming, class-vs-function bias, type usage.

## Rejected Alternatives

> Grows via doc-sync when a decision documents what was considered and dropped, and why.
