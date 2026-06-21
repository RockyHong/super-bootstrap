# Overview

<!-- harness-meta: read by /super-bootstrap:resolve-plugins. Keep YAML shape; list values in [...].
external-tools: [github]
-->

> Living doc. Skeleton sections (Problem / User / Current State) seeded at scaffold from Q&A answers. Grown sections (Module Index / Data Flow / Key Boundaries) start empty and grow via doc-sync — every commit that adds, removes, or reshapes a module triggers a sync proposal. See `CLAUDE.md` Doc Sync.

## Problem

Per-project Claude Code setup is a repeated grind: write `CLAUDE.md`, pick skills/MCPs/hooks, pin config, establish a workflow. super-bootstrap collapses that into one command (`/super-bootstrap`) that inspects a repo and installs the [superpowers](https://github.com/obra/superpowers) development pipeline — CLAUDE.md, skeleton docs, path-scoped rules, curated skill/MCP/hook picks — plus a **phase-gated workflow** so every session runs only the pipeline phases the work actually needs (workflow, not just a toolbelt). Greenfield repos get lean ideation Q&A first; repos with code get scanned and scaffolded. It also bundles the companion skills that run the pipeline day-to-day: commit, todo, log, help, merge, drain, and optional release-init.

## User

Solo devs juggling multiple repos.

## Current State

Active development.

## Module Index

> Grows via doc-sync as modules are added or refactored. One-line description per significant file or directory.

## Data Flow

> Grows via doc-sync as entry points and pipelines crystallize. Inputs → transforms → outputs through the code.

## Key Boundaries

> Grows via doc-sync as API contracts, internal interfaces, and external dependencies stabilize.
