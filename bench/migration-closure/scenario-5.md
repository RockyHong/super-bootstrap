You are executing one step of a repo-sync skill. The governing text of that step is below, quoted from the skill (`[…]` marks a cut between quoted passages):

---
{EXCERPT}
---

The run is a doctrine migration of a legacy consumer repo: its old `CLAUDE.md` still holds the plugin's workflow sections, and step 5 will remove the headings `## Development Workflow`, `## Dispatch` and `## Doc Sync (non-negotiable)` from it, so those three are moved sections. The placed `.claude/rules/harness.md` has a heading for every one of their anchors (`#development-workflow`, `#dispatch`, `#doc-sync-non-negotiable`). No file carries uncommitted changes, and no file below declares `dimension: history`.

You are at step 3. `git grep -n -I -F 'CLAUDE.md' -- . ':!CLAUDE.md'` printed exactly these three hits:

```
docs/specs/billing.md:12:Every change to the matcher follows [`CLAUDE.md` Doc Sync](../../CLAUDE.md#doc-sync-non-negotiable).
docs/overview.md:3:> Living doc. Skeleton sections (Problem / User / Current State) carry their placeholder body verbatim at scaffold and fill at GAP card pickup. Grown sections (Module Index / Data Flow / Key Boundaries) start empty and grow via doc-sync — every commit that adds, removes, or reshapes a module triggers a sync proposal, admitted per § Doc Sync. See [`CLAUDE.md` Doc Sync](../CLAUDE.md#doc-sync-non-negotiable).
docs/overview.md:31:- `src/match/` — the matcher; a change here is committed per CLAUDE.md § Doc Sync.
```

`docs/overview.md` line 3 is the blockquote under its `# Overview` H1, above its first `## ` heading. Line 31 sits under its `## Module Index` heading.

Answer in exactly three lines, nothing else, one per hit in the order above. Each line: `HIT n: ` followed by the outcome (`re-point`, `proposed edit`, `open question` or `no change`), then ` — `, then the full line as it reads after step 5 writes every re-point and the user accepts every proposed edit, verbatim (the unchanged line if nothing is written).
