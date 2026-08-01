# Overview

<!-- harness-meta: read by /super-bootstrap:resolve-plugins (tier-2 curation). Keep YAML shape; list values in [...].
Default [github]; add any of: notion, linear, jira, slack, trello, clickup, other.
external-tools: [github]
-->

> Living doc. Skeleton sections (Problem / User / Current State) start empty at scaffold and fill at GAP-card pickup. Grown sections (Module Index / Data Flow / Key Boundaries) start empty and grow via doc-sync — every commit that adds, removes, or reshapes a module triggers a sync proposal. See `CLAUDE.md` Doc Sync.

## Problem

Per-project Claude Code setup is a repeated grind: write `CLAUDE.md`, pick skills/MCPs/hooks, pin config, establish a workflow. super-bootstrap collapses that into one command (`/super-bootstrap`) that inspects a repo and installs a development pipeline — CLAUDE.md, skeleton docs, path-scoped rules, curated skill/MCP/hook picks — plus a **phase-gated workflow** so every session runs only the pipeline phases the work actually needs (workflow, not just a toolbelt). The harness names disciplines rather than skill entries, so no process-harness plugin is a dependency ([`docs/specs/harness-architecture.md`](specs/harness-architecture.md)). Greenfield repos get lean ideation Q&A first; repos with code get scanned and scaffolded. It also bundles the companion skills that run the pipeline day-to-day: commit, todo, log, triage, triage-report, help, merge, drain, check-docs-consistency, and optional release-init.

## User

Solo devs juggling multiple repos — **agentic builders, not pure engineers**. They hold
product intent (what problem, for whom) alongside the code, so the harness covers the
product dimension and not only the engineering pipeline: `/super-bootstrap:log` admits
feature `GAP`s beside defects, this doc carries Problem / User, and
[`docs/decisions.md`](decisions.md) admits product and business forks beside technical
ones.

A codebase answers *solution* only. An agent asked whether something should be built has
no premise to judge against unless the product anchor is written down somewhere it reads
([`docs/specs/harness-architecture.md`](specs/harness-architecture.md) §2).

The runway is deliberately light enough for a consumer to modify — it seeds disciplines
and doors, not a framework to conform to.

## Current State

Active development.

## Module Index

> Grows via doc-sync as modules are added or refactored. One-line description per significant file or directory.

## Data Flow

> Grows via doc-sync as entry points and pipelines crystallize. Inputs → transforms → outputs through the code.

## Key Boundaries

> Grows via doc-sync as API contracts, internal interfaces, and external dependencies stabilize.
