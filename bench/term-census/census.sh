#!/usr/bin/env bash
# Term fan-in census for one repo (GAP-ym4e). Run from the target repo's root:
#   bash D:/Git/super-bootstrap/bench/term-census/census.sh [doc-links.sh path]
# Read-only, zero LLM calls. Prints four sections:
#   A  file-derived terms (the commit door's `terms`) → docs hitting each (`hits --by-term`)
#   B  inline-code-span tokens → number of distinct docs carrying each
#   C  link in-degree per doc-surface target (`index`)
#   D  fan-in histograms for A and B
# Doc surface for B: docs/**/*.md, every README.md, CLAUDE.md, AGENTS.md — minus card
# threads (docs/work/{BUG,DEBT,GAP}-*.md) and outward threads (docs/outward/OUT-*.md).
set -uo pipefail

LINKS="${1:-$(ls -d "$HOME"/.claude/plugins/cache/super-bootstrap/super-bootstrap/*/skills/commit/assets/doc-links.sh 2>/dev/null | sort -V | tail -1)}"
[ -f "$LINKS" ] || { echo "doc-links.sh not found; pass its path" >&2; exit 1; }
TOP="${CENSUS_TOP:-40}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

echo "# census: $(basename "$(pwd)") · $(git rev-parse --short HEAD 2>/dev/null) · doc-links: $LINKS"

git -c core.quotePath=false ls-files | bash "$LINKS" terms - | bash "$LINKS" hits --by-term - > "$TMP/a"
echo; echo "## A — file-derived terms, top $TOP (term<TAB>docs)"
head -n "$TOP" "$TMP/a"

git -c core.quotePath=false ls-files -- 'docs/**/*.md' 'docs/*.md' '*README.md' 'CLAUDE.md' 'AGENTS.md' \
  | grep -vE '^docs/work/(BUG|DEBT|GAP)-|^docs/outward/OUT-' | sort -u > "$TMP/surface"
echo; echo "doc surface for B: $(wc -l < "$TMP/surface") files"
# One awk pass: per file, the set of `code` spans on non-fence lines; count files per token.
while IFS= read -r f; do printf '%s\0' "$f"; done < "$TMP/surface" \
  | xargs -0 awk '
      FNR == 1 { delete seen; fence = 0 }
      /^[ \t]*```/ { fence = !fence; next }
      fence { next }
      {
        line = $0
        while (match(line, /`[^`]+`/)) {
          tok = substr(line, RSTART + 1, RLENGTH - 2)
          line = substr(line, RSTART + RLENGTH)
          if (length(tok) < 3 || length(tok) > 60) continue
          if (!((FILENAME, tok) in seen)) { seen[FILENAME, tok] = 1; n[tok]++ }
        }
      }
      END { for (t in n) printf "%s\t%d\n", t, n[t] }' \
  | sort -t "$(printf '\t')" -k2,2nr -k1,1 > "$TMP/b"
echo; echo "## B — code-span tokens, top $TOP (token<TAB>docs)"
head -n "$TOP" "$TMP/b"

echo; echo "## C — link in-degree, top 20 (referrers<TAB>target)"
bash "$LINKS" index | cut -f1 | sed 's/#.*//' | sort | uniq -c | sort -rn | head -20 \
  | awk '{ printf "%s\t%s\n", $1, $2 }'

hist() {
  awk -F '\t' '{ c = $2 + 0
    if (c <= 1) b["1"]++; else if (c == 2) b["2"]++; else if (c <= 4) b["3-4"]++
    else if (c <= 8) b["5-8"]++; else b["9+"]++; t++ }
    END { printf "total %d · 1:%d · 2:%d · 3-4:%d · 5-8:%d · 9+:%d\n", t, b["1"], b["2"], b["3-4"], b["5-8"], b["9+"] }' "$1"
}
echo; echo "## D — fan-in histograms"
printf 'A  '; hist "$TMP/a"
printf 'B  '; hist "$TMP/b"
