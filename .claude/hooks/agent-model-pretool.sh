#!/bin/bash
# PreToolUse hook (matcher: Agent) — model-designation guard.
# Typed agents own their tier in frontmatter (model: key); callers omit model,
# or pass it matching the pin. Ad-hoc / built-in dispatches must carry an
# explicit model at the call site.
#
# Stdin schema (PreToolUse):
#   { ..., "tool_name": "Agent",
#     "tool_input": { "description": "...", "prompt": "...",
#                     "subagent_type": "...", "model": "..." } }
#
# Decision table:
#   1. subagent_type resolves to an agent file with a model: frontmatter pin:
#        - no model param     -> allow (tier lives in frontmatter)
#        - model param == pin -> allow
#        - model param != pin -> deny, quoting the pin
#   2. subagent_type does not resolve to a pinned agent file (ad-hoc/built-in,
#      e.g. general-purpose, Explore; missing/empty subagent_type counts here;
#      a resolved-but-frontmatter-less local agent also lands here):
#        - model param present -> allow
#        - model param missing -> deny (tier-guidance message; names the
#          resolved frontmatter-less local agent if there is one)
#
# Resolution order (first match wins):
#   $CLAUDE_PROJECT_DIR/.claude/agents/<type>.md
#   ~/.claude/agents/<type>.md
#   $CLAUDE_PROJECT_DIR/.claude/agents/<type>/AGENT.md
#   ~/.claude/agents/<type>/AGENT.md
#   plugin cache (namespaced plugin:agent types):
#     ~/.claude/plugins/cache/*/<plugin>/*/agents/<agent>.md
#     ~/.claude/plugins/cache/*/<plugin>/*/agents/<agent>/AGENT.md
#
# Frontmatter parse: first `model:` line inside the leading `---` block only.
#
# Lore: .claude/guidelines/work-discipline/model-tiering.md

set +e
command -v jq >/dev/null 2>&1 || exit 0

PAYLOAD="$(cat)"

MODEL="$(jq -r '.tool_input.model // empty' <<< "$PAYLOAD")"
SUBAGENT_TYPE="$(jq -r '.tool_input.subagent_type // empty' <<< "$PAYLOAD")"

# Extract the model: pin value from an agent file's leading --- frontmatter block.
# Prints the value (surrounding quotes/whitespace stripped), or nothing if absent.
extract_pin() {
    local raw
    raw="$(sed -n '1{/^---$/!q};/^---$/,/^---$/{/^model:[[:space:]]*.\+/p}' "$1" | head -n 1)"
    [ -n "$raw" ] || return 1
    printf '%s' "$raw" | sed -E 's/^model:[[:space:]]*//; s/[[:space:]]*$//; s/^"(.*)"$/\1/; s/^'"'"'(.*)'"'"'$/\1/'
}

PIN=""
# First resolved-but-frontmatter-less local agent file — named in the deny reason
# so the fix points at an exact path. Plugin-cache paths excluded (not durably editable).
LOCAL_NO_MODEL=""

if [ -n "$SUBAGENT_TYPE" ]; then
    PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"
    HOME_DIR="${HOME:-$USERPROFILE}"

    CANDIDATE_PATHS=(
        "${PROJECT_DIR}/.claude/agents/${SUBAGENT_TYPE}.md"
        "${HOME_DIR}/.claude/agents/${SUBAGENT_TYPE}.md"
        "${PROJECT_DIR}/.claude/agents/${SUBAGENT_TYPE}/AGENT.md"
        "${HOME_DIR}/.claude/agents/${SUBAGENT_TYPE}/AGENT.md"
    )

    for AGENT_FILE in "${CANDIDATE_PATHS[@]}"; do
        [ -f "$AGENT_FILE" ] || continue
        PIN="$(extract_pin "$AGENT_FILE")"
        [ -n "$PIN" ] && break
        [ -n "$LOCAL_NO_MODEL" ] || LOCAL_NO_MODEL="$AGENT_FILE"
    done

    # Plugin agents use a namespaced subagent_type (plugin_name:agent_name) and live
    # in the plugin cache — not in the static candidate list above.
    if [ -z "$PIN" ] && [[ "$SUBAGENT_TYPE" == *:* ]]; then
        _PLUGIN_NAME="${SUBAGENT_TYPE%%:*}"
        _AGENT_NAME="${SUBAGENT_TYPE#*:}"
        for AGENT_FILE in \
            "${HOME_DIR}/.claude/plugins/cache/"*/"${_PLUGIN_NAME}"/*/agents/"${_AGENT_NAME}.md" \
            "${HOME_DIR}/.claude/plugins/cache/"*/"${_PLUGIN_NAME}"/*/agents/"${_AGENT_NAME}/AGENT.md"; do
            [ -f "$AGENT_FILE" ] || continue
            PIN="$(extract_pin "$AGENT_FILE")"
            [ -n "$PIN" ] && break
        done
    fi
fi

if [ -n "$PIN" ]; then
    # Branch 1: pinned typed agent — the pin is authoritative, even against an
    # explicit model param.
    [ -z "$MODEL" ] && exit 0
    [ "$MODEL" = "$PIN" ] && exit 0

    REASON="Model pin: ${SUBAGENT_TYPE} is pinned to ${PIN} in its frontmatter; drop the model param or match the pin."
    jq -n --arg r "$REASON" \
        '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
    exit 0
fi

# Branch 2: ad-hoc / built-in, or a resolved-but-frontmatter-less local agent
# (missing/empty subagent_type also lands here). An explicit model satisfies it.
[ -n "$MODEL" ] && exit 0

# The reason names a path the model will open with a native Windows tool: a
# /c/... form resolves against cwd's drive (→ D:\c\...). cygpath -w → C:\ form
# (Git Bash only; native macOS/Linux paths are already correct).
[ -n "$LOCAL_NO_MODEL" ] && command -v cygpath >/dev/null 2>&1 && LOCAL_NO_MODEL="$(cygpath -w "$LOCAL_NO_MODEL")"

REASON="Model-designation guard: Agent dispatch missing model param.${LOCAL_NO_MODEL:+ Typed agent '$SUBAGENT_TYPE' resolved at $LOCAL_NO_MODEL with no model: frontmatter — add it there and callers can omit.} Designate a tier (haiku|sonnet|opus) per .claude/guidelines/work-discipline/model-tiering.md. Re-send with model set."

jq -n --arg r "$REASON" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
exit 0
