#!/usr/bin/env bash
# new-id.sh — collision-guarded ID generator for cards, outward threads and parked items.
#
# Usage (run from the repo root):  bash new-id.sh <CAT> [<CAT>...]
#   CAT is one of BUG DEBT GAP OUT PARK. Prints one `{CAT}-xxxx` per argument, in
#   order, one per line. Any other CAT, or no argument, exits 1 (stderr names the
#   bad argument / prints usage) and prints nothing.
#
# ID shape: xxxx = 4 chars drawn from 0123456789abcdefghjkmnpqrstvwxyz (0-9a-z minus
#   i l o u), at least one letter — a draw of four digits is redrawn, so a new ID never
#   reads as a legacy numeric one. IDs are distinct within one call. Randomness comes
#   from /dev/urandom (one read per batch of draws; byte % 32 is unbiased).
#
# Guard: a candidate is redrawn when it (word-bounded, fixed string) already appears in
#   - a file name under docs/work/ or docs/outward/,
#   - a `### PARK-` heading of docs/parked.md,
#   - any tracked file's content (git grep -w -F),
#   - any commit message on any ref (git log --all).
#   Outside a git repo the git-based checks are skipped silently. The redraw loop is
#   bounded (50 tries per ID); exhaustion exits 1 with a message.
#
# Test-only override: env NEW_ID_DRAWS = space-separated candidate suffixes, consumed in
#   order before falling back to /dev/urandom, so a test can force a guard hit. The
#   guard and the letter rule apply to override draws exactly as to random ones.
set -u

MAX_TRIES=50
ALPHABET=0123456789abcdefghjkmnpqrstvwxyz

usage() { echo "Usage: new-id.sh <BUG|DEBT|GAP|OUT|PARK>..." >&2; exit 1; }

[ "$#" -ge 1 ] || usage
for cat in "$@"; do
    case "$cat" in
        BUG|DEBT|GAP|OUT|PARK) ;;
        *) echo "new-id.sh: bad category '$cat' (expected BUG, DEBT, GAP, OUT or PARK)" >&2; exit 1 ;;
    esac
done

# Guard inputs, gathered once (fork-free matching per candidate except git grep).
in_git=0
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then in_git=1; fi

names=""
for f in docs/work/* docs/outward/*; do
    [ -e "$f" ] && names="$names
${f##*/}"
done

parked=""
if [ -f docs/parked.md ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in '### PARK-'*) parked="$parked
$line" ;; esac
    done < docs/parked.md
fi

msgs=""
if [ "$in_git" -eq 1 ]; then
    msgs="$(git log --all --format=%B 2>/dev/null)"
fi

# word-bounded fixed-string membership of $1 in text $2 (ID chars are [A-Za-z0-9-], regex-safe)
has_word() { [[ "$2" =~ (^|[^A-Za-z0-9_])"$1"($|[^A-Za-z0-9_]) ]]; }

taken() {
    local id="$1"
    has_word "$id" "$names" && return 0
    has_word "$id" "$parked" && return 0
    if [ "$in_git" -eq 1 ]; then
        has_word "$id" "$msgs" && return 0
        git grep -q -w -F -- "$id" >/dev/null 2>&1 && return 0
    fi
    return 1
}

# Draw sources: override list first, then urandom bytes (refilled in batches of 64 -> 16 draws).
read -r -a override <<< "${NEW_ID_DRAWS:-}"
ov=0
bytes=()
bi=0
draw() {
    if [ "$ov" -lt "${#override[@]}" ]; then
        SUFFIX="${override[$ov]}"; ov=$((ov + 1)); return
    fi
    if [ $((bi + 4)) -gt "${#bytes[@]}" ]; then
        # unquoted on purpose: od wraps 16 bytes per line, word-splitting joins the lines
        bytes=( $(od -An -tu1 -N64 /dev/urandom) )
        bi=0
    fi
    local s="" i b
    for i in 0 1 2 3; do
        b=${bytes[$((bi + i))]}
        s="$s${ALPHABET:$((b % 32)):1}"
    done
    bi=$((bi + 4))
    SUFFIX="$s"
}

made=" "
for cat in "$@"; do
    tries=0
    while :; do
        tries=$((tries + 1))
        if [ "$tries" -gt "$MAX_TRIES" ]; then
            echo "new-id.sh: no free $cat ID after $MAX_TRIES draws" >&2
            exit 1
        fi
        draw
        [[ "$SUFFIX" =~ [a-z] ]] || continue            # at least one letter
        id="$cat-$SUFFIX"
        case "$made" in *" $id "*) continue ;; esac      # distinct within the call
        taken "$id" && continue                          # collision guard
        break
    done
    made="$made$id "
    printf '%s\n' "$id"
done
