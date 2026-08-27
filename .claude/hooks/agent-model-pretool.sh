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
#   plugin cache (namespaced plugin:agent types) — the installed version only:
#     <cache-dir>/agents/<agent>.md
#     <cache-dir>/agents/<agent>/AGENT.md
#   where <cache-dir> is resolved from ~/.claude/plugins/installed_plugins.json:
#   the <plugin>@<marketplace> record whose projectPath is $CLAUDE_PROJECT_DIR,
#   else the user-scope record, read from its installPath. Registry unreadable /
#   no matching key / no usable installPath -> highest cached version by
#   `sort -V` over ~/.claude/plugins/cache/*/<plugin>/*/ (a bare glob sorts
#   lexically, which reads 2.29.4 as newer than 2.6.0 and older than 2.37.2).
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
    # Frontmatter parse runs under BSD awk/sed on macOS, so this stays awk: a
    # sed script there rejects `;` straight after `}`, and GNU BRE `\+` reads as
    # a literal plus (measured: `model: opus` does not match, `model: a+` does).
    # `[ \t]` rather than `[[:space:]]` — older one-true-awk builds carry no
    # POSIX classes. The leading `sub` keeps a CRLF checkout parseable.
    raw="$(awk '
        { sub(/\r$/, "") }
        NR == 1 && $0 != "---" { exit }
        NR == 1 { next }
        $0 == "---" { exit }
        /^model:[ \t]*[^ \t]/ { print; exit }
    ' "$1")"
    [ -n "$raw" ] || return 1
    printf '%s' "$raw" | sed -E 's/^model:[[:space:]]*//; s/[[:space:]]*$//; s/^"(.*)"$/\1/; s/^'"'"'(.*)'"'"'$/\1/'
}

# Normalize a path for comparison and for opening from bash. installed_plugins.json
# stores native Windows paths (C:\Users\...) that no `[ -f ]` here can open, and
# $CLAUDE_PROJECT_DIR may arrive in either form — both sides run through this, so
# they compare in one shape. POSIX paths pass through untouched, so macOS/Linux
# needs no cygpath (which does not exist there).
norm_path() {
    local p="${1//\\//}"
    p="${p%/}"
    case "$p" in
        [A-Za-z]:/*) p="/$(printf '%s' "${p%%:*}" | tr 'A-Z' 'a-z')${p#?:}" ;;
    esac
    printf '%s' "$p"
}

# True when two paths name the same directory. Normalized string compare first —
# a projectPath whose repo has since moved still matches its own recorded text —
# then `-ef` (device + inode), which is what catches one directory reached by two
# spellings: Git Bash's /tmp is a mount alias for C:\Users\...\Temp, and neither
# cygpath nor any textual rewrite maps one spelling onto the other.
same_dir() {
    [ -n "$1" ] && [ -n "$2" ] || return 1
    [ "$1" = "$2" ] && return 0
    [ -d "$1" ] && [ -d "$2" ] && [ "$1" -ef "$2" ]
}

# Cache directory of the INSTALLED version of a plugin. Reads globals HOME_DIR /
# PROJECT_DIR. Prints the directory, or nothing.
#
# The registry keys plugins as "<plugin>@<marketplace>" — the marketplace is not
# in subagent_type, so the key matches by "<plugin>@" prefix — and holds an ARRAY
# of install records per key (measured: 8 records across 5 versions for one
# plugin), so a bare .version read is ambiguous. Preference: the record whose
# projectPath is this project, then the user-scope record; each record's
# installPath names the marketplace and version segments both. The projectPath
# match runs for every scope, so a "local" record (from .claude/settings.local.json)
# wins for its own project like a "project" one; only "user" is captured as the
# no-match fallback, because "local" and "project" are project-bound by definition
# and must not answer for a different project. Anything unusable
# (no registry, unparseable, no matching key, no installPath, pruned directory)
# degrades to the highest cached version by `sort -V` — never to lexical order,
# which is the whole defect: 2.29.4 sorts before 2.6.0 and 2.37.2.
plugin_cache_dir() {
    local plugin="$1"
    local registry="${HOME_DIR}/.claude/plugins/installed_plugins.json"
    local proj scope raw_proj raw_install dir candidate user_dir=""

    proj="$(norm_path "${PROJECT_DIR}")"

    if [ -r "$registry" ]; then
        # One field per line, not @tsv: bash collapses runs of tab when tab is the
        # IFS, so a record with an empty projectPath would shift installPath left.
        # `tr -d '\r'`: Windows-native jq.exe writes CRLF, and unlike command
        # substitution `read` keeps the CR — a path ending in one matches no [ -d ].
        while IFS= read -r scope && IFS= read -r raw_proj && IFS= read -r raw_install; do
            [ -n "$raw_install" ] || continue
            dir="$(norm_path "$raw_install")"
            [ -d "$dir" ] || continue
            if [ -n "$proj" ] && same_dir "$(norm_path "$raw_proj")" "$proj"; then
                printf '%s' "$dir"
                return 0
            fi
            if [ "$scope" = "user" ] && [ -z "$user_dir" ]; then
                user_dir="$dir"
            fi
        done < <(jq -r --arg p "$plugin" '
            (.plugins // {}) | to_entries[]
            | select(.key | startswith($p + "@"))
            | .value[]? | select(type == "object")
            | (.scope // "" | tostring),
              (.projectPath // "" | tostring),
              (.installPath // "" | tostring)
        ' "$registry" 2>/dev/null | tr -d '\r')
        if [ -n "$user_dir" ]; then
            printf '%s' "$user_dir"
            return 0
        fi
    fi

    candidate="$(
        for dir in "${HOME_DIR}/.claude/plugins/cache/"*/"${plugin}"/*/; do
            [ -d "$dir" ] || continue
            dir="${dir%/}"
            printf '%s\t%s\n' "${dir##*/}" "$dir"
        done | sort -V | tail -n 1 | cut -f2-
    )"
    [ -n "$candidate" ] && printf '%s' "$candidate"
    return 0
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
    # in the plugin cache — not in the static candidate list above. The cache keeps
    # every version ever installed, so the version is resolved, not globbed.
    if [ -z "$PIN" ] && [[ "$SUBAGENT_TYPE" == *:* ]]; then
        _PLUGIN_NAME="${SUBAGENT_TYPE%%:*}"
        _AGENT_NAME="${SUBAGENT_TYPE#*:}"
        _CACHE_DIR="$(plugin_cache_dir "$_PLUGIN_NAME")"
        if [ -n "$_CACHE_DIR" ]; then
            for AGENT_FILE in \
                "${_CACHE_DIR}/agents/${_AGENT_NAME}.md" \
                "${_CACHE_DIR}/agents/${_AGENT_NAME}/AGENT.md"; do
                [ -f "$AGENT_FILE" ] || continue
                PIN="$(extract_pin "$AGENT_FILE")"
                [ -n "$PIN" ] && break
            done
        fi
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
