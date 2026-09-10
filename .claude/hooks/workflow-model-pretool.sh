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
# Name-only launch (script resolves at launch, nothing to inspect pre-flight)
# splits by where the local copy sits, because the tool accepts a scriptPath
# only inside the working directory or a directory added to the session — a
# prior Read does not satisfy it (holds as of CC 2.1.251):
#   - project copy at .claude/workflows/<name>.js — deny + redirect to
#     scriptPath. It is inside the working directory, so the inspectable
#     branch audits tiers pre-flight. Checked first: project wins name
#     resolution (project > personal > built-in).
#   - personal copy at ~/.claude/workflows/<name>.js — no reachable redirect
#     target, so audit the planted file here instead: tiered → exit silent,
#     the name launch takes the normal permission flow; shortfall → deny
#     naming that file and its counts.
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

# Crude textual tier count over a script body — echoes "<agent-calls> <model-marks>".
# agent( preceded by non-identifier char — excludes subagent(, myagent(.
# Regexes kept identical to workflow-model-posttool.sh's copy.
_tier_counts() {
    local body="$1" calls marks
    calls="$(printf '%s' "$body" | grep -oE '(^|[^A-Za-z0-9_])agent\(' | wc -l | tr -d '[:space:]')"
    marks="$(printf '%s' "$body" | grep -oE 'model[[:space:]]*:' | wc -l | tr -d '[:space:]')"
    printf '%s %s' "${calls:-0}" "${marks:-0}"
}

# Hand the model a path that resolves cross-drive on Windows: the Workflow tool
# resolves a relative/POSIX path against cwd's drive, so a /c/... path breaks
# from a D:\ cwd. cygpath -w → native C:\ form (Git Bash only; native
# macOS/Linux paths are already correct).
_native_path() {
    if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s' "$1"; fi
}

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
        PROJECT_WF="${CLAUDE_PROJECT_DIR:-.}/.claude/workflows/${NAME}.js"
        PERSONAL_WF="$HOME/.claude/workflows/${NAME}.js"

        if [ -f "$PROJECT_WF" ]; then
            WF_NATIVE="$(_native_path "$PROJECT_WF")"
            REASON="Model-tiering guard: workflow '${NAME}' has a local copy at ${WF_NATIVE}. Re-send as scriptPath: \"${WF_NATIVE}\" — scriptPath audits tiers pre-flight; a name launch resolves at runtime, can't be inspected. Ref: .claude/guidelines/work-discipline/model-tiering.md"
            jq -n --arg r "$REASON" \
                '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
            exit 0
        fi

        if [ -f "$PERSONAL_WF" ]; then
            read -r AGENT_CALLS MODEL_MARKS <<< "$(_tier_counts "$(cat "$PERSONAL_WF")")"
            [ "$AGENT_CALLS" -le "$MODEL_MARKS" ] 2>/dev/null && exit 0
            WF_NATIVE="$(_native_path "$PERSONAL_WF")"
            REASON="Model-tiering guard: workflow '${NAME}' resolves to the planted copy at ${WF_NATIVE} — ${AGENT_CALLS} agent() call(s), ${MODEL_MARKS} model designation(s). That path is outside the working directory, so it can't be re-sent as scriptPath: tier it in place instead — every agent() carries model: (haiku|sonnet), or rides the top tier as a deliberate inherit // model: inherit — <why> (annotation satisfies this guard) — then re-launch by name. Choose tiers per .claude/guidelines/work-discipline/model-tiering.md (read it: tier shapes + centrality amplifier + width axis)."
            jq -n --arg r "$REASON" \
                '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
            exit 0
        fi

        NUDGE="Model-tiering guard: named workflow '${NAME}' resolves its script at launch — untiered agent() calls inherit the main-loop model across the fan-out. On launch return: (1) TaskStop FIRST — fan-out burns at top tier while you read; (2) read the persisted script (path in tool result), tier the phases still ahead; (3) resume with resumeFromRunId; (4) save tiered script to .claude/workflows/${NAME}.js so future launches go via scriptPath and audit pre-flight. Ref: .claude/guidelines/work-discipline/model-tiering.md"
        jq -n --arg c "$NUDGE" \
            '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "defer", additionalContext: $c}}'
    fi
    exit 0
fi

read -r AGENT_CALLS MODEL_MARKS <<< "$(_tier_counts "$SCRIPT")"

[ "$AGENT_CALLS" -le "$MODEL_MARKS" ] 2>/dev/null && exit 0

REASON="Model-tiering guard: ${AGENT_CALLS} agent() call(s), ${MODEL_MARKS} model designation(s). Tier every agent() with model: (haiku|sonnet), or ride the top tier as a deliberate inherit // model: inherit — <why> (annotation satisfies this guard). Choose tiers per .claude/guidelines/work-discipline/model-tiering.md (read it: tier shapes + centrality amplifier + width axis). Re-send with every agent() tiered."

jq -n --arg r "$REASON" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
exit 0
