#!/bin/bash
# PreToolUse hook (matcher: Workflow) — model-tiering guard.
# Hard-blocks Workflow launches whose script contains agent() calls without
# model designations. Each agent() call must carry `model:` in opts, or a
# deliberate-inherit annotation (`// model: inherit — <why>`); both count as
# a model mark (crude textual count, not a parse).
#
# Stdin schema (PreToolUse):
#   { ..., "tool_name": "Workflow",
#     "tool_input": { "script": "...", "scriptPath": "...", "name": "...",
#                     "resumeFromRunId": "..." } }
#
# Pass-through cases:
#   - resumeFromRunId present — model is part of the resume cache key;
#     forcing retiers on a resume busts journaled results (lore: resume
#     corollary).
#
# Name-only launch (script resolves at launch, nothing to inspect pre-flight):
#   - local copy exists at .claude/workflows/<name>.js (project, then
#     personal) — deny + redirect to scriptPath: the inspectable branch
#     audits tiers pre-flight; resolution precedence (project > personal >
#     built-in) never substitutes for inspection (verified CC 2.1.175).
#   - no local copy — defer + stop-first nudge: TaskStop on launch return,
#     pin tiers, resume, save tiered copy to .claude/workflows/ (later launches
#     then take the inspectable scriptPath branch). Terminal branch for all
#     no-local-copy name launches (built-in and plugin), NOT an unfinished
#     deny — neither is pre-launch-inspectable, so deny has no redirect target.
#     Why neither resolves pre-launch, and why in-hook plugin enumeration is
#     out of scope: lore (claude-shape workflow-tool-response.md
#     § Saved-workflow resolution).
#
# Lore: .claude/guidelines/work-discipline/model-tiering.md (§ Named-launch corollary)

set +e
command -v jq >/dev/null 2>&1 || exit 0

PAYLOAD="$(cat)"

RESUME="$(jq -r '.tool_input.resumeFromRunId // empty' <<< "$PAYLOAD")"
[ -n "$RESUME" ] && exit 0

SCRIPT="$(jq -r '.tool_input.script // empty' <<< "$PAYLOAD")"
if [ -z "$SCRIPT" ]; then
    SCRIPT_PATH="$(jq -r '.tool_input.scriptPath // empty' <<< "$PAYLOAD")"
    [ -n "$SCRIPT_PATH" ] && [ -f "$SCRIPT_PATH" ] && SCRIPT="$(cat "$SCRIPT_PATH")"
fi
if [ -z "$SCRIPT" ]; then
    NAME="$(jq -r '.tool_input.name // empty' <<< "$PAYLOAD")"
    if [ -n "$NAME" ]; then
        for LOCAL_WF in "${CLAUDE_PROJECT_DIR:-.}/.claude/workflows/${NAME}.js" "$HOME/.claude/workflows/${NAME}.js"; do
            if [ -f "$LOCAL_WF" ]; then
                # Hand the model a scriptPath that resolves cross-drive on Windows:
                # the Workflow tool resolves a relative/POSIX path against cwd's drive,
                # so a /c/... path breaks from a D:\ cwd. cygpath -w → native C:\ form
                # (Git Bash only; native macOS/Linux paths are already correct).
                WF_NATIVE="$LOCAL_WF"
                command -v cygpath >/dev/null 2>&1 && WF_NATIVE="$(cygpath -w "$LOCAL_WF")"
                REASON="Model-tiering guard: workflow '${NAME}' has a local copy at ${WF_NATIVE}. Re-send as scriptPath: \"${WF_NATIVE}\" — scriptPath audits tiers pre-flight; a name launch resolves at runtime, can't be inspected. Ref: .claude/guidelines/work-discipline/model-tiering.md"
                jq -n --arg r "$REASON" \
                    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
                exit 0
            fi
        done
        NUDGE="Model-tiering guard: named workflow '${NAME}' resolves its script at launch — untiered agent() calls inherit the main-loop model across the fan-out. On launch return: (1) TaskStop FIRST — fan-out burns at top tier while you read; (2) read the persisted script (path in tool result), tier the phases still ahead; (3) resume with resumeFromRunId; (4) save tiered script to .claude/workflows/${NAME}.js so future launches go via scriptPath and audit pre-flight. Ref: .claude/guidelines/work-discipline/model-tiering.md"
        jq -n --arg c "$NUDGE" \
            '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "defer", additionalContext: $c}}'
    fi
    exit 0
fi

# agent( preceded by non-identifier char — excludes subagent(, myagent(.
AGENT_CALLS="$(printf '%s' "$SCRIPT" | grep -oE '(^|[^A-Za-z0-9_])agent\(' | wc -l | tr -d '[:space:]')"
MODEL_MARKS="$(printf '%s' "$SCRIPT" | grep -oE 'model[[:space:]]*:' | wc -l | tr -d '[:space:]')"

[ "$AGENT_CALLS" -le "$MODEL_MARKS" ] 2>/dev/null && exit 0

REASON="Model-tiering guard: ${AGENT_CALLS} agent() call(s), ${MODEL_MARKS} model designation(s). Tier every agent() with model: (haiku|sonnet|opus), or annotate a deliberate inherit // model: inherit — <why> (annotation satisfies this guard). Choose tiers per .claude/guidelines/work-discipline/model-tiering.md (read it: tier shapes + centrality amplifier + width axis). Re-send with every agent() tiered."

jq -n --arg r "$REASON" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
exit 0
