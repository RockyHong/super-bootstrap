# Overview

<!-- harness-meta
external-tools: [{Q4 multi-select: github, notion, linear, jira, slack, trello, clickup, other}]
-->

> Living doc. Skeleton sections (Problem / User / Current State) seeded at scaffold from Q&A answers. Grown sections (Roadmap / Module Index / Data Flow / Key Boundaries) start empty and grow via doc-sync — every commit that adds, removes, or reshapes a module triggers a sync proposal. See `CLAUDE.md` Doc Sync.
>
> `<!-- harness-meta -->` block at top: structured record of harness Q&A answers that aren't naturally prose. Read by `/super-bootstrap:resolve-plugins` as Tier-2 fallback when no pinned MCPs encode the signal. Hand-edit safe — keep YAML shape, list values in `[...]`.

## Problem

{from Q&A: "what does this project do?" — one paragraph in the user's words, what problem it solves and why it exists}

## User

{from Q&A: "who uses it?" — end users / developers / internal tool / library consumers / etc.}

## Current State

{from Q&A: greenfield / active development / maintenance / mid-rewrite — short phrase capturing where the project is today}

## Roadmap

> Forward feature list — ordered name + one-liner per feature. Single pillar for "what product will become." `/super-bootstrap:todo` reads this section: first unstarted entry (no matching spec slug under `docs/superpowers/specs/` or `docs/specs/`) surfaces as the next `Brainstorm:` row. Entries stay until the feature ships into the product narrative above; remove on ship via doc-sync.

## Module Index

> Grows via doc-sync as modules are added or refactored. One-line description per significant file or directory.

## Data Flow

> Grows via doc-sync as entry points and pipelines crystallize. Inputs → transforms → outputs through the code.

## Key Boundaries

> Grows via doc-sync as API contracts, internal interfaces, and external dependencies stabilize.
