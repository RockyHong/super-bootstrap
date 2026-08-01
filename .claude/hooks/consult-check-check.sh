#!/bin/bash
# UserPromptSubmit hook — forced-eval consult check (GAP-045 build).
# Injects the compact doc catalog + forced YES/NO-per-doc evaluation before
# every prompt. The forced-eval sentence is verbatim from the measured arm
# (bench/forcedeval-compact-inject.sh — all four pre-registered gates passed);
# the path-resolution tail is adapted for the multi-root catalog and validated
# by the production-wiring spot-check (bench/FINDINGS-gap045.md § Build).
#
# The forced-evaluation moment is the active ingredient — do NOT soften this
# to a passive pointer, add a grep pre-filter, or put an LLM in the trigger
# path (all three are measured failures: ignorable-pointer, 6/9 map routing,
# 20% TN pre-classifier).
#
# Known non-compliance, accepted (DEBT-045): downstream sessions skip the
# emitted per-doc YES/NO enumeration yet behaviorally read the relevant docs —
# the evaluation happens, the stated output is cosmetic. Do not edit the
# measured sentence to chase format compliance; recall is the success metric,
# not the enumeration.
#
# Catalog is derived once per session by consult-check-sessionstart.sh; this
# script fires on every prompt and must stay a pure read. Missing/empty cache
# (session before first sessionstart fire, or no docs) → silent exit.
# Catalog lines are grouped per directory (GAP-052) — the header tail states
# the <dir><stem>.md expansion; the forced-eval sentences stay verbatim.
#
# Channel: UserPromptSubmit stdout on exit 0 → context
# (claude-shape/hook-feedback-channels.md § Prompt-lifecycle events).
set +e

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
CACHE="$ROOT/.claude/.consult-catalog"
[ -s "$CACHE" ] || exit 0

echo "[doc-consult-check] Before answering, evaluate EACH doc below and state YES or NO: does it bear on this prompt? Read every YES doc before composing your answer. If all are NO, answer directly. Each line is a directory (a parenthetical hint may precede the colon) then its docs — expand a doc as <dir><stem>.md. docs/ dirs are project-relative; other dirs live under .claude/guidelines/ in the project (guidelines/ itself means that root), or if absent there, under ~/.claude/guidelines/ (expand to absolute before Read)."
cat "$CACHE"
exit 0
