# resolve-plugins: Format Templates

Reference asset. Not reasoning instructions — static render patterns.

---

## §batch-presentation

Render at Phase 4 batch-present step.

```
Skill / MCP / hook curation for {project} ({stack}):

  Rejected (earn-right): {R} candidates collapsed — type `expand rejected` to list.

  [SKILL]   🛡 {name}@{source}        [bundle]   [+ add | ✓ keep | − drop]
             Why: {matched signal, one-line value}
             (vetted picks: trust block omitted)

  [SKILL]   ★ {name}@{source}         [slash]    [+ add | ✓ keep | − drop]
             ★ {stars} · last commit {recency} · {license}
             Permissions: {read-only / shell / network / etc.}
             Why: {matched signal, one-line value}
             also in: {alt-source-A} (★{stars} · {recency} · {license}) · {alt-source-B} (...)

  [HOOK]    ⚠ {name}@{source}         [hook]     [+ add]
             ★ {stars} · last commit {recency} · {license}
             Permissions: ⚠ {what triggers + what it runs}
             Why: {matched signal}
             ⚠ HOOK = auto-executes. Audit source before accept.

  [MCP]     🆕 {name}@{source}        [delegation] [+ add]
             ★ {stars} · last commit {recency} · {license}
             Permissions: {network / shell / file-system / etc.}
             Why: {matched signal}

Accept all / reject specific / discuss thoughts / expand alternates?
```

---

## §install-plan

Render at Phase 5.1 before execution. One block per accepted candidate.

```text
candidate: graphify
  [skill]   graphify@market           -> .claude/skills/graphify/
  [mcp]     graphify-mcp              -> .mcp.json
  [hook]    post-commit-graphify      -> .claude/hooks/ + settings.json wiring
  [bin]     graphify (manual: brew install graphify per README)

candidate: superpowers
  [plugin]  superpowers@claude-plugins-official  -> enabledPlugins
```

---

## §verify-table

Render at Phase 5.3 per component verify step.

| Component | Verify | Pass |
|---|---|---|
| Plugin install | `claude plugin install <pick>` exits 0 AND `jq -e '.enabledPlugins["<pick>"]' .claude/settings.json` | both 0 |
| Binary (manual install) | `command -v <bin>` | exit 0 |
| Hook script | `[ -x .claude/hooks/<name>.sh ]` AND `bash -n .claude/hooks/<name>.sh` AND `jq -e '.hooks.<event>[]? \| select(.command \| contains("<name>"))' .claude/settings.json` | all 0 |
| Local file copy (rare) | `[ -f <dest> ]` | exit 0 |


---

## §report-block

Render after Phase 5 completes.

```text
✓ Resolve complete.

Pins applied: {N} ({list-of-names})
Pins unchanged: {M}
Pins dropped: {K} ({reasons})

Earn-right rejections: {R}
  {if R > 0: list collapsed sources or `expand rejected` hint}

Verify failures: {V}
  {if V > 0: list candidates that halted, with chosen resolution per candidate}
```

If `R == 0` and `V == 0`, omit those rows entirely.
