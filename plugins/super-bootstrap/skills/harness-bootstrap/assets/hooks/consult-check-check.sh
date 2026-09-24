#!/usr/bin/env bash
# FROZEN consult-check-check v2
# UserPromptSubmit hook — forced-eval consult check.
# Injects the compact doc catalog + a forced judge-then-Read evaluation before
# every prompt. The forced-eval sentence is verbatim from the measured arm
# (forcedeval-v2; bench + findings: repo-root bench/consult-hook/); the
# path-resolution tail is adapted for the grouped catalog.
#
# The forced-evaluation moment is the active ingredient — do NOT soften this
# to a passive pointer, add a grep pre-filter, or put an LLM in the trigger
# path (all three are measured failures: ignorable-pointer, 6/9 map routing,
# 20% TN pre-classifier).
#
# The sentence demands no stated output: v1's per-doc YES/NO enumeration was
# measured as not load-bearing (v2 held recall + TN on sonnet and opus), so
# success is the Read of each relevant doc, never a restated verdict. Recall
# is the success metric; any edit to the sentence re-runs the bench first.
#
# Catalog is derived once per session by consult-check-sessionstart.sh; this
# script fires on every prompt and must stay a pure read. Missing/empty cache
# (session before first sessionstart fire, or no docs) → silent exit.
# Catalog lines are grouped per directory and each group key is the resolvable
# path itself — always a repo-relative docs/ path, so the header tail states
# only the <dir><stem>.md expansion and never a both-paths fallback: a row
# that resolves two ways is a guess at every prompt. Keep the tail describing
# exactly what the deriver emits — a tail naming markers the catalog cannot
# contain is a per-prompt false claim. The forced-eval sentences stay verbatim.
#
# Channel: UserPromptSubmit stdout on exit 0 → context.
set +e

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
CACHE="$ROOT/.claude/.consult-catalog"
[ -s "$CACHE" ] || exit 0

echo "[doc-consult-check] Before answering, judge which docs below bear on this prompt, and Read each one that does before composing your answer. If none does, answer directly. Each line is a directory, then its docs — expand a doc as <dir><stem>.md. Every dir is project-relative."
cat "$CACHE"
exit 0
