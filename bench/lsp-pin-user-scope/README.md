# bench/lsp-pin-user-scope — micro-test for the language-server pin's user-scope skip and removal carry

Test surface for [`skills/harness-bootstrap/SKILL.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md)
§ 2b's **Language-server pins (techstack-derived)** paragraph — the step deciding whether a sync
writes a `*-lsp@claude-plugins-official: true` key into the project `.claude/settings.json`.
Behavior-shaping prose, so it ships behind the [`skill-authoring`](../../.claude/rules/skill-authoring.md)
RED floor. Same protocol and shape as the sibling [`bench/rot-scan-liveness/`](../rot-scan-liveness/README.md):
reading-only, no fixture repo — the model is handed the governing excerpt plus the on-disk state and
asked what the step writes.

**Copy under test:** the in-repo dev copy of `SKILL.md`. [`excerpt-arm.md`](excerpt-arm.md) is a
byte-exact copy of the shipped text — `SKILL.md` lines 483–505: the pin paragraph, its resolve list,
the paragraph after it and the language table (`diff` clean against the file); every arm row below
ran against these bytes. [`excerpt-control.md`](excerpt-control.md) is the same span at the
commit before the change (`git show HEAD:` at authoring time — the pin paragraph and table, v7.0.2
wording). Prompt = the scenario file with its `{EXCERPT}` line replaced by the excerpt file.

## Protocol

Arms run headless (`claude -p --model haiku --tools "" --strict-mcp-config --setting-sources ""`)
with the prompt on stdin, three trials per arm. The scenario body is byte-identical across arms, so
the excerpt is the only variable. Each answer is three lines: `WRITE:` (the key the step adds to the
project file, or `NONE`), `RESOLUTION:` (the report row's resolution), `PHASE3:` (the closing-output
line for the pin, or `NONE`).

- **Scenario 1 — user-scope override** ([`scenario-1.md`](scenario-1.md)). Techstack § Runtime names
  Node.js. User scope sets `typescript-lsp@claude-plugins-official: false` and enables
  `typescript-lsp-win@local`; the project file lacks the key; the receipt covers no pin. **Axis:**
  does the step write `true` over the user's `false`?
- **Scenario 2 — removal carry** ([`scenario-2.md`](scenario-2.md)). Same techstack, no user-scope
  file, project key absent, and the prior receipt's `covered` holds
  `.claude/settings.json § enabledPlugins:typescript-lsp@claude-plugins-official`. **Axis:** does the
  step re-insert a key the user deleted after a sync covered it?
- **Scenario 4 — variant alone** ([`scenario-4.md`](scenario-4.md)). Scenario 1 with the user-scope
  `false` key removed: user scope enables only `typescript-lsp-win@local`. **Axis:** does the
  name-prefix variant clause skip the pin on its own? Added after the first pass, which never
  isolated it.
- **Scenario 3 — no over-skip** ([`scenario-3.md`](scenario-3.md)). Techstack names Python; user
  scope carries only the TypeScript `false` + variant from Scenario 1. **Axis:** does a user-scope
  choice for one language leak into another language's pin? Regression guard, not a RED.
- **Scenario 5 — own key `true` at user scope** ([`scenario-5.md`](scenario-5.md)). Scenario 1 with
  the user-scope file holding only the pin's own key `typescript-lsp@claude-plugins-official: true`
  (as `claude plugin install` writes it): no variant, project key absent, no prior receipt pin.
  **Axis:** does the step over-skip a user-scope `true` of the pin's own key? Regression guard for
  the rule 2 change (a variant key other than the pin's own); added after the BUG-bqc8 wording change.

**Pre-registration** (written before the first trial):

| Scenario | Control expected | Arm expected |
|---|---|---|
| 1 | `WRITE: "typescript-lsp@claude-plugins-official": true`, resolution `inserted` 3/3 | `WRITE: NONE`, resolution `skipped (user scope: …)`, a `PHASE3:` line naming the skip 3/3 |
| 2 | `WRITE: "typescript-lsp@claude-plugins-official": true`, resolution `inserted` 3/3 | `WRITE: NONE`, resolution `kept (removed)` 3/3 (BUG-bqc8 refresh; was `declined (carried: removed)`) |
| 3 | `WRITE: "pyright-lsp@claude-plugins-official": true`, `inserted` 3/3 | same as control 3/3 |
| 4 (registered before its own trials, after the first pass) | `WRITE: "typescript-lsp@claude-plugins-official": true`, `inserted` 3/3 | `WRITE: NONE`, resolution `skipped (user scope: typescript-lsp-win@local)` 3/3 |
| 5 (registered before its own trials, BUG-bqc8 refresh) | `WRITE: "typescript-lsp@claude-plugins-official": true`, `inserted` 3/3 (control on `excerpt-control.md`, HEAD bytes) | `WRITE: "typescript-lsp@claude-plugins-official": true`, resolution `⊕ new`, `inserted` 3/3 — regression guard against over-skipping |

## Findings

Run 2026-11-20, `claude -p --model haiku --tools "" --strict-mcp-config --setting-sources ""`,
three trials per arm. Control rows (Scenarios 1–4) come from the first pass; the control bytes are
unchanged. Arm rows come from a re-run of Scenarios 1–5 against the refreshed `excerpt-arm.md`
(BUG-bqc8 wording: rule 2 skips only a variant key other than the pin's own, rule 3 resolves
`kept (removed)`, an unparsable user-scope file counts as no user choice). Scenario 5's control ran
in the same refresh. In Scenario 1 arm trial 2 the model printed the line label as `RESESOLUTION:`;
the label is dropped like the others. Lines as returned, `LINE n:` prefixes dropped. Raw trial outputs are
not kept in the tree.

### Scenario 1 — user-scope override

| Arm | Trial | WRITE | RESOLUTION | PHASE3 |
|---|---|---|---|---|
| Control (v7.0.2) | 1 | `"typescript-lsp@claude-plugins-official": true` | `` ⊕ new, resolving `inserted` `` | NONE |
| Control | 2 | `"typescript-lsp@claude-plugins-official": true` | `` ⊕ new, resolving `inserted` `` | NONE |
| Control | 3 | `"typescript-lsp@claude-plugins-official": true` | `` ⊕ new, resolving `inserted` `` | NONE |
| Arm (shipped) | 1 | NONE | `.claude/settings.json: enabledPlugins:typescript-lsp@claude-plugins-official` is `⊘ missing`, resolving `skipped (user scope: typescript-lsp@claude-plugins-official)` | NONE |
| Arm | 2 | NONE | `.claude/settings.json: enabledPlugins:typescript-lsp@claude-plugins-official` resolves `⊘ missing`, skipped (user scope: typescript-lsp@claude-plugins-official) | NONE |
| Arm | 3 | NONE | `.claude/settings.json: enabledPlugins:typescript-lsp@claude-plugins-official` → `⊘ missing`, resolving `skipped (user scope: typescript-lsp@claude-plugins-official)` | NONE |

### Scenario 2 — removal carry

| Arm | Trial | WRITE | RESOLUTION | PHASE3 |
|---|---|---|---|---|
| Control (v7.0.2) | 1 | `"typescript-lsp@claude-plugins-official": true` | `` ⊕ new, resolving `inserted` `` | NONE |
| Control | 2 | `"typescript-lsp@claude-plugins-official": true` | `⊕ new, resolving inserted` | NONE |
| Control | 3 | `"typescript-lsp@claude-plugins-official": true` | `` ⊕ new, resolving `inserted` `` | NONE |
| Arm (shipped) | 1 | NONE | `.claude/settings.json: enabledPlugins:typescript-lsp@claude-plugins-official` — ⊘ removed, resolving `kept (removed)` | NONE |
| Arm | 2 | NONE | `.claude/settings.json: enabledPlugins:typescript-lsp@claude-plugins-official` → `⊘ removed`, resolving `kept (removed)` | NONE |
| Arm | 3 | NONE | ⊘ removed, row `.claude/settings.json: enabledPlugins:typescript-lsp@claude-plugins-official` resolves `kept (removed)` | NONE |

### Scenario 3 — no over-skip

| Arm | Trial | WRITE | RESOLUTION | PHASE3 |
|---|---|---|---|---|
| Control (v7.0.2) | 1 | `"pyright-lsp@claude-plugins-official": true` | `` ⊕ new, resolving `inserted` (key absent from project `.claude/settings.json`, so the pin is inserted as `true`) `` | NONE |
| Control | 2 | `"pyright-lsp@claude-plugins-official": true` | `⊕ new, resolving inserted (Python is named by § Runtime, and the project settings have no key for this pin)` | `` pyright-lsp@claude-plugins-official pinned for Python; install with `npm install -g pyright` `` |
| Control | 3 | `"pyright-lsp@claude-plugins-official": true` | `` ⊕ new, resolving `inserted` `` | NONE |
| Arm (shipped) | 1 | `"pyright-lsp@claude-plugins-official": true` | `.claude/settings.json: enabledPlugins:pyright-lsp@claude-plugins-official` — ⊕ new, resolving `inserted` | NONE |
| Arm | 2 | `"pyright-lsp@claude-plugins-official": true` | ⊕ new, resolving `inserted` | NONE |
| Arm | 3 | `"pyright-lsp@claude-plugins-official": true` | inserted | NONE |

### Scenario 4 — variant alone

Control rows from a second pass; arm rows from the re-run above. Same flags.

| Arm | Trial | WRITE | RESOLUTION | PHASE3 |
|---|---|---|---|---|
| Control (v7.0.2) | 1 | `"typescript-lsp@claude-plugins-official": true` | `` ⊕ new, resolving `inserted` `` | NONE |
| Control | 2 | `"typescript-lsp@claude-plugins-official": true` | `` ⊕ new, resolving `inserted` `` | NONE |
| Control | 3 | `typescript-lsp@claude-plugins-official: true` | `` ⊕ new, resolving `inserted` `` | NONE |
| Arm (shipped) | 1 | NONE | `.claude/settings.json: enabledPlugins:typescript-lsp@claude-plugins-official` → `⊘ missing`, resolving `skipped (user scope: typescript-lsp-win@local)` | NONE |
| Arm | 2 | NONE | `.claude/settings.json: enabledPlugins:typescript-lsp@claude-plugins-official` → `⊘ missing`, resolving `skipped (user scope: typescript-lsp-win@local)` | NONE |
| Arm | 3 | NONE | ⊘ missing, resolving `skipped (user scope: typescript-lsp-win@local)` | NONE |

### Scenario 5 — own key `true` at user scope

Run 2026-11-20 (BUG-bqc8 refresh), same flags. Control = `excerpt-control.md` (HEAD bytes).

| Arm | Trial | WRITE | RESOLUTION | PHASE3 |
|---|---|---|---|---|
| Control (HEAD) | 1 | `"typescript-lsp@claude-plugins-official": true` | ⊕ new, resolving `inserted` | NONE |
| Control | 2 | `"typescript-lsp@claude-plugins-official": true` | ⊕ new, resolving `inserted` (the project `.claude/settings.json` has no key for this plugin; the user-scope entry does not count) | NONE |
| Control | 3 | `"typescript-lsp@claude-plugins-official": true` | ⊕ new, resolving `inserted` | NONE |
| Arm (shipped) | 1 | `"typescript-lsp@claude-plugins-official": true` | ⊕ new `.claude/settings.json: enabledPlugins:typescript-lsp@claude-plugins-official` — inserted | NONE |
| Arm | 2 | `"typescript-lsp@claude-plugins-official": true` | `.claude/settings.json: enabledPlugins:typescript-lsp@claude-plugins-official` — ⊕ new, inserted | NONE |
| Arm | 3 | `"typescript-lsp@claude-plugins-official": true` | `.claude/settings.json: enabledPlugins:typescript-lsp@claude-plugins-official` — ⊕ new, resolving `inserted` | NONE |

**Verdict: GREEN on Scenarios 1–5, 3/3 each, WRITE and RESOLUTION both.** The shipped wording
writes nothing 3/3 in Scenarios 1, 2 and 4, resolving `skipped (user scope: …)` (Scenarios 1 and 4)
and `kept (removed)` (Scenario 2) 3/3; the `⊘ missing` / `⊘ removed` status shows in 9 of 9 of those
trials. Scenario 5 holds: the arm inserts `true` (`⊕ new`, `inserted`) 3/3, the same as the control,
so a user-scope `true` of the pin's own key does not skip the pin. Scenario 3 holds: the TypeScript
user-scope keys do not leak into the pyright pin. The v7.0.2 control still writes `true` over the
user's `false` 3/3 and re-inserts a removed key 3/3 (first pass, bytes unchanged).

**Declared bounds.**
1. The `PHASE3:` column is not measured. The Phase 3 line templates live in § Phase 3, and the
   sentence pointing a skipped pin there sits after the table, both outside the excerpt: arm trials
   print no skip line in Scenarios 1 and 4, and the lines other trials print restate the report row.
   The write and resolution columns are the axis.
2. Scenario 1's arm cites the pin's own key in every trial, so Scenario 4 isolates the variant clause.
   The prefix match is a name test: a variant named without the pin's stem is not caught.
3. Scenario 2 hands the model a receipt that already holds the pin identity. A receipt written before
   this change holds none, so the first sync after the upgrade still re-inserts a key the user
   removed earlier; the carry starts from the next covered run.
4. N=3 per arm per scenario, one model tier.
5. The unparsable-user-scope-file clause has no scenario; it is not measured here.
