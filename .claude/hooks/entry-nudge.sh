#!/usr/bin/env bash
# FROZEN entry-nudge v1 (A5 — card-grounded entry nudge).
# UserPromptSubmit (no matcher — fires on every prompt, tool-call-independent,
# so it reaches even answer-from-memory turns; see entry-nudge.hook.json). Cost
# discipline: pure cat, no jq, no subprocess, no file reads — the whole script
# is one heredoc. Injector-only: stdout on exit 0 is added to context. It must
# NEVER emit decision:"block" and NEVER exit non-zero — either one ERASES the
# user's prompt (the destructive failure mode of this event). Defensive path is
# exit 0 with no output.
#
# Self-containment (hard constraint): the injected text may reference ONLY
# surfaces harness-bootstrap itself stamps or bundled plugin skills every
# consumer has (docs/backlog.md, /super-bootstrap:todo, /super-bootstrap:log)
# — never device-only skills.

cat <<'JSON' || exit 0
{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"Entry check: change-work rides a docs/backlog.md card — none in context → pick one up (/super-bootstrap:todo or a BUG/DEBT/GAP-### ID) or ground one first (/super-bootstrap:log). Reads and investigation ride free."}}
JSON
exit 0
