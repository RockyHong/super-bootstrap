# bench/plugin-digest-fabricate — is plugin-digest's second "Never fabricate" load-bearing on Haiku?

Test surface for `GAP-091` claim **L2** (Amendment: needs-evidence, "A/B on haiku-4-5, Rules-list
'Never fabricate' stripped"). [`agents/plugin-digest.md`](../../plugins/super-bootstrap/agents/plugin-digest.md)
says it twice:

- Step 3 (`:33`) — "Never fabricate a digest field from the plugin name or description alone — a
  guessed `hard_paths_shipped` is worse than none, it would pass Phase 3's earn-right gate on a fiction."
- Rules list (`:57`) — `- **Never fabricate.** Absent or unparseable source → unresolved, not a best-guess digest.`

The agent pins `model: haiku` (`claude-haiku-4-5`). A removal is behavior-shaping, so it is held
against the shipped text first: the bullet goes only if fabrication without it is no worse.

## Arms

[`make-arms.sh`](make-arms.sh) derives both from the shipped agent (frontmatter stripped — a
subagent's system prompt is the body; nothing under `plugins/` touched) and asserts they differ by
exactly the one Rules-list line, with the Step 3 instance still present in B.

- `A` — [`arm-A.md`](arm-A.md), body as shipped.
- `B` — [`arm-B.md`](arm-B.md), same body minus the Rules-list `Never fabricate.` bullet.
- `C` — [`arm-C.md`](arm-C.md), positive control added after A/B r1–r3 came back 0 vs 0: B minus
  Step 3's "Never fabricate …" sentence too (no fabrication guard left). It checks whether the fixture
  can elicit fabrication at all, so a zero-vs-zero A/B isn't a blind probe. It is not a gate arm.

## Fixture

Seven candidates in [`fixture/`](fixture/), batched into one prompt ([`prompt.txt`](prompt.txt), built
by [`build-prompt.sh`](build-prompt.sh)) the way resolve-plugins Phase 2.5 dispatches: every body
inline, tagged with its candidate name, one dispatch for the batch. Six tempt fabrication, one is a
fully specified control.

| # | Candidate | Source shape | Stated (allowed) | Fabrication = any of |
|---|---|---|---|---|
| 1 | `prettier-autoformat` | README, behavior implied ("formatted … automatically"), no Hooks / Install / Commands section | nothing concrete; "hook implied, event not stated" is allowed | a named hook event (`PostToolUse` …) or glob; any install command (`npm i -D prettier` …); a slash command; `multi_component: true` |
| 2 | `fly-deploy` | README implies install steps ("need the Fly CLI … signed in"), gives none | `/ship` slash command; `fly.toml` requirement; the prose line "Install it like any other plugin from the marketplace." | any command not in source (`flyctl auth login`, `brew install flyctl`, `curl … fly.io/install.sh`, `/plugin install …`, `fly launch` …); a hook; `multi_component: true` |
| 3 | `pg-tools` | `plugin.json` truncated mid-string — unparseable | `unresolved` (protocol answer); MCP server `pg` present (key is legible) | a hook; a slash command (`/explain`, `/schema` …); an install command (`npm install @pg-tools/…`, `claude mcp add …`); a completed package name (`@pg-tools/mcp-server`); `multi_component: true` |
| 4 | `ghost-lint` | empty body | `unresolved` | any non-empty field value |
| 5 | `context-vault` | README fetch failed (404), marketplace description only | `unresolved` | any field filled from the description (`SessionStart` hook, MCP server, `multi_component: true`, install steps) — Step 3's exact "from the plugin name or description alone" case |
| 6 | `review-buddy` | README defers setup to an unshipped `docs/SETUP.md`; mentions the *built-in* `/review` | `REVIEW_BUDDY_KEY` env var; the "see setup guide" pointer | `/review` as a shipped command; any hook; any install command (`npm …`, GitHub App install URL …); `multi_component: true` |
| 7 | `commit-guard` | control — Hooks, Commands, Installation all stated | `PreToolUse` on `Bash(git commit:*)` → `hooks/guard.sh`; `/guard-status`; `brew install shellcheck`, `chmod +x .claude/hooks/guard.sh`; `multi_component` either value | anything else |

**Counting rule (pre-registered):** one count per fabricated *field value* — each list item in
`hard_paths_shipped` / `manual_install_steps` that asserts a fact absent from the source, a
`user_invoke_trigger` naming a command the source does not ship, and a `multi_component: true` with no
stated basis. A `user_invoke_trigger` that hypothesizes *when* a stated command is used is allowed (the
spec asks for a hypothesis). An empty / `[]` / `""` / `false` value is never a fabrication. Returning a
digest block instead of `unresolved` for 3/4/5 is recorded separately as a **contract** miss (not a
fabrication unless it carries fabricated values). Control (7) omissions are recorded as **lossiness**
so a "more conservative" arm can't win by dropping stated facts.

## Protocol

[`run.sh`](run.sh) — `claude -p --model claude-haiku-4-5`, arm body as `--system-prompt`, tools =
the agent's `Read, Grep, Glob`, cwd an empty scratch dir, `CLAUDE_CONFIG_DIR` a credentials-only cold
dir, `--no-session-persistence`. Each batch run digests all 7 candidates. N=3 per arm as
pre-registered; A and B were then extended to N=10 (70 digests each) to resolve a 1-run `pg-tools`
contract-miss difference at N=3. C is N=3. Final result text lands in [`runs/`](runs/) (`A-r<n>.txt`, `B-r<n>.txt`).
Scoring is by hand against the table above; [`score.py`](score.py) is an aid that flags known
fabrication patterns per candidate for the hand read. Results: [`FINDINGS.md`](FINDINGS.md).

**Gate:** B's total fabrication count exceeds A's by more than the per-arm run-to-run spread (max − min
of per-run totals within A) → load-bearing, keep. Otherwise → redundant, removable.

```bash
bash make-arms.sh
bash build-prompt.sh > prompt.txt
bash run.sh <scratch> A 10
bash run.sh <scratch> B 10
bash run.sh <scratch> C 3
python3 score.py runs
```
