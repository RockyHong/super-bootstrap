# asset-wording-cut — findings (DEBT-sxck)

**Bench:** [`bench/asset-wording-cut`](README.md) · **Card:** `DEBT-sxck` items (a), (b), (c), (e) ·
**Reader:** `claude -p --model opus` · **N:** 3 per arm per item, 24 runs, budget spent, no extra runs

## Pre-registered gate

> Written before the first run fired; `score.py` and the bite check ran before the first reader run.

**Criterion.** Per item, the `trimmed` arm passes the governed-behavior assertion on every run that
`current` passes (read as: trimmed PASS count ≥ current PASS count; current 3/3 → trimmed 3/3).

## Trimmed texts

The `*_TRIMMED` constants in [`build.py`](build.py).

**(a)** `assets/harness.md` § Doc Sync, Dimension routing first bullet:

```
- Decision still **binding** current work → the state doc it governs, worded per the `dimension-discipline` rule (Route item 3).
```

**(b)** `assets/rules-index-skeleton.md` line 13 → five lines, the `harness.md` restatement dropped:

```
> Frontmatter:
>
> - Use `paths:` — not `globs:` (Cursor key, unrecognized by Claude Code; the rule silently loads always-on and the path filter is ignored).
> - A rule with no frontmatter at all takes the same eager lane.
> - Patterns match gitignore-style — a bare filename fires at any depth, a leading `/` pins root.
```

**(c)** `rules-dimension-discipline-skeleton.md` Classify: `place. Overview, techstack, specs, status fields.`;
Scope: `Applies to authored prose docs (overview, techstack, specs, READMEs). Harness files (skills, agents, rules) carry their own discipline.`
`rules-ssot-doc-link-skeleton.md` predicate 3: `Frozen tracker rows count as`; Scope:
`Applies to authored prose docs (overview, techstack, specs, READMEs).`

**(e)** `claude-md-skeleton.md` line 3:

```
Workflow doctrine — pipeline, dispatch, doc sync, git — loads from [`.claude/rules/harness.md`](.claude/rules/harness.md). This file holds the project's own sections.
```

`harness-bootstrap/SKILL.md` split-lane template:

```
These lines bind in this repo together with `.claude/rules/harness.md`; a line labelled *takes over* wins over the doctrine line it names.
```

## Instrument validity

- `current` arms are byte-asserted against the live assets; any drift aborts `build.py`.
- Decontamination: `CLAUDE_CODE_DISABLE_CLAUDE_MDS=1`, `--setting-sources project`, `--tools ""`,
  `--strict-mcp-config`, empty scratch cwd.
- Bite check ([`bite/bite-check.txt`](bite/bite-check.txt), exit 1): every `induced-*-bad` output fails
  its assertions; the four `induced-*-good` controls pass.

## Results

| Item | current PASS | trimmed PASS | Verdict |
|---|---|---|---|
| a | 3/3 | 3/3 | loss on an unregistered reading — current text stays |
| b | 3/3 | 3/3 | no loss — trim lands |
| c | 3/3 | 3/3 | no loss — trim lands |
| e | 3/3 | 3/3 | no loss — trim lands |

**(a).** The registered `NOWHY` assertion catches back-story tokens only (incident IDs, outage,
retro, "took down"); no arm wrote them. The arms split on a reason sentence the assertion does not
cover: `current` wrote the constraint and its exit condition with no reason on 3/3; `trimmed` added a
present-tense why on 3/3 ("because concurrent export load can overwhelm the primary database"). The
dropped example is the one that forbids that shape ("not 'on <date> we decided to defer refinement
because…'"). The scorer was not changed after the runs; the reading is recorded here and decides
the item against the trim, since the rule strips when *and* why.

**(b).** Both arms created `.claude/rules/migration-immutability.md` with `paths:` and a `CLAUDE.md`
§ Rules entry on every run; no run touched `harness.md`. The reader saw the index alone — stricter
than the live moment, where `harness.md` also loads.

**(c).** All six outputs identical: `Payments provider: Stripe`, overwritten in place.

**(e).** All six put the line in `CLAUDE.md` with a takes-over label against the doctrine's
"No PR self-review" line.
