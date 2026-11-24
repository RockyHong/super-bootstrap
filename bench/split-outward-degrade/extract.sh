#!/usr/bin/env bash
# extract.sh — the SKILL.md sections this bench renders: Phase 2's intro (per-artifact rule, registration
# rule, pipeline-owned / project-owned lists, up to `### 2a:`) and the whole § 2a-scale (up to `### 2b:`).
# Usage: bash extract.sh <skill-md-file>   — keyed on headings, so it works on any revision.
awk '
  /^## Phase 2: /    { on = 1 }
  /^### 2a: /        { on = 0 }
  /^### 2a-scale: /  { on = 1 }
  /^### 2b: /        { on = 0 }
  on
' "${1:?usage: extract.sh <skill-md-file>}"
