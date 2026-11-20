You are running the rot scan step of a `harness-bootstrap` re-run sync on a repo. The governing
instruction is quoted below, then the run transcript.

--- GOVERNING INSTRUCTION (§ 2b, rot scan) ---
{EXCERPT}
--- END INSTRUCTION ---

--- RUN TRANSCRIPT ---
$ OLD=$(grep -oE '^- `[^`]+`' "$A/rename-map.md" | sed 's/^- `//; s/`$//')
$ printf '%s\n' "$OLD" | wc -l
25

$ for o in $OLD; do for f in $FILES; do
>   grep -nP "(?<![\w/.:-])\Q$o\E(?![\w/-])" "$f" 2>/dev/null | sed "s|^|ROT $f:|"
> done; done

$ echo "literals read: 25, files swept: 13, rot rows: 0"
literals read: 25, files swept: 13, rot rows: 0
--- END TRANSCRIPT ---

$FILES held 13 pipeline-owned files. Answer in three lines, nothing else:

LINE 1 — the rot outcome you write into `.claude/bootstrap-sync-report.md`, verbatim as it
would appear in the file.
LINE 2 — CLEAN or NOT-CLEAN: does this run establish that the repo carries no stale literals?
LINE 3 — one sentence of justification.
