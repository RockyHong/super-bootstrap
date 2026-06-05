---
name: log
description: 'Capture front door. Logs 1..N observations into docs/backlog.md (BUG / DEBT / GAP), classified + gated on Sonnet. Use when the user says "log this", "track that", "note this down", or types `/super-bootstrap:log <observation>` — and when Claude needs to file its own findings (out-of-scope findings from a review, audit, or returned subagent report). Dispatches the `log` subagent so classify + write run off the gateway model. Does NOT triage (that is the `/super-bootstrap:todo` triage lane) and does NOT file feature ideas (those route to docs/overview.md § Roadmap).'
tags: [log, capture, backlog, pipeline, superpowers]
---

# Log — Capture Front Door

Muscle-memory capture. Takes whatever the caller hands it — one observation or a batch — classifies each into **BUG / DEBT / GAP**, enforces the admission gate (actionable-now only), and writes canonical rows to `docs/backlog.md`. The thinking runs in the `log` subagent (`agents/log.md`, `model: sonnet`); this skill is the dispatch shell.

All new backlog rows route through here — user-initiated and Claude-initiated captures alike. One funnel centralizes classification consistency, dedup, and ID assignment.

## When it fires

- **User** — explicit `/super-bootstrap:log <observation>`, or natural-language "log this / track that / note this down".
- **Claude** — its own captures: a bug spotted mid-task, the out-of-scope findings a review or returned subagent surfaced. Batch them into one invocation — never one dispatch per finding.

Out of lane: **triage** (root-cause investigation → the `/super-bootstrap:todo` triage lane) and **feature ideas** (→ `docs/overview.md` § Roadmap). This skill creates new backlog rows only.

## Arguments

The argument is the raw observation(s). Free-form. May be one item or many (a list, a pasted findings block). The skill does not parse buckets from the arg — the subagent classifies.

| Invocation | Behavior |
| --- | --- |
| `/super-bootstrap:log <text>` | Dispatch the `log` subagent with the text as entries. |
| `/super-bootstrap:log` (bare) | Ask the caller what to capture (one line), then dispatch. |

## Execution

1. Gather the entries — the user's text and/or the findings block the gateway is holding. Keep each entry's context (where it came from, any source file/line) so the subagent can dedup + write a faithful row.
2. Dispatch: `Agent` tool, `subagent_type: "log"`, prompt = the entries (1..N) + any source context, verbatim, + today's date. Do not pre-classify, do not pre-judge buckets — that is the subagent's job, and pre-judging feeds it bias.
3. Relay the subagent's return:
   - **logged / deduped / flagged / deferred** lines → report to the caller plainly (what landed where, what routed elsewhere, what deferred on which trigger). Deferred entries are not stored anywhere — the user holds them; a fresh `/super-bootstrap:log` re-enters one when its trigger fires.
   - **questions** → surface to the user as the subagent phrased them. A follow-up `/super-bootstrap:log` with the answer resolves the ambiguous entries. Do not guess the bucket on the user's behalf.

## Rules

- **Dispatch, don't classify.** The admission gate and category decisions live in the `log` subagent. This shell routes input and relays output.
- **Batch over loop.** Many findings → one dispatch with all entries. Per-finding dispatch is the anti-pattern this skill exists to avoid.
- **Relay questions, never auto-answer.** Thin context is the subagent's signal to ask; the caller resolves it. Silent guessing files wrong rows the caller then trusts.
- **Works in any repo with the superpowers pipeline.** Requires `docs/backlog.md` (scaffolded by `/super-bootstrap:harness-bootstrap`); the subagent routes the caller there when it's absent.
