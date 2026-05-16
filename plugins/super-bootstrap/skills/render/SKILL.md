---
name: render
description: "Generate human-facing HTML render of an md source — pruned, multimodal, intent-shaped. Five intents (decision / status / map / browse / read) decide recipe; intent inferred from explicit arg, path prefix, or content heuristics. Source is canonical (Claude re-reads md); render is derivation, throwaway, output to .render/ (gitignored). On-demand only — no hook, no auto-fire. Bundled with super-bootstrap; serves any md, not just pipeline docs."
tags: [render, html, docs, review, superpowers]
---

# Render — Intent-Shaped Human View

Source md stays canonical for Claude + subagents + future sessions. Render is the human cognition surface: pruned to intent-relevant content, multimodal grouping (typography, tables, optional SVG), collapsible appendix for depth. Render is a **build artifact** — never edited, regenerated any time, never committed.

Recipe axis is **intent**, not doc shape. Same source can render five different ways depending on what the human wants right now. Path-prefix and content heuristics are inference shortcuts toward intent; the user can always override.

Bundled with `/super-bootstrap`. Works on any md — pipeline docs (specs, plans, overview, backlog), READMEs, RFCs, meeting notes, retros, anything.

## Invocation

```
/super-bootstrap:render                          # bare — infer source + intent
/super-bootstrap:render <path>                   # path given — infer intent
/super-bootstrap:render <path> as <intent>       # explicit — no inference
```

`<intent>` ∈ `decision`, `status`, `map`, `browse`, `read`. Unknown intent → refuse with list.

## Intents

| Intent     | When user wants this                     | Render shape                                                                 |
| ---------- | ---------------------------------------- | ---------------------------------------------------------------------------- |
| `decision` | Pick among options / approve a proposal  | Context · option tradeoff table · decision row · risk + revert · prose appendix |
| `status`   | Track execution / report progress        | Progress header · phase timeline · blockers · next step · history appendix   |
| `map`      | Understand topology / module relations   | Pillars grid · module/boundaries graph (light SVG) · key boundaries          |
| `browse`   | Scan a catalog / list                    | Count pills · cards sorted by priority · category chips · resolved collapsed |
| `read`     | Absorb the source as-is (default)        | TOC if ≥6 headings · TL;DR if derivable · typographic pass · long sections collapsed |

## Inference cascade

Done by the agent on each invocation. Gateway forwards args; agent figures the rest.

**Source** (if path not given):

1. Last md file edited by Claude this session (transcript trace).
2. Most recently `git diff`-touched md within last day.
3. Most recently mtime-changed md under `docs/`.
4. Refuse: `no recent md found — pass a path`.

**Intent** (in priority order):

1. Explicit `as <intent>` arg → no inference.
2. Path prefix shortcut:
   - `**/specs/**` or `**/spec/**` → `decision`
   - `**/plans/**` or `**/plan/**` → `status`
   - filename matches `*backlog*` → `browse`
   - filename matches `*overview*` or `*architecture*` or `*module*map*` → `map`
3. Content heuristics (agent reads source):
   - options table or "vs" comparison or "Approach A / B" headings → `decision`
   - checkbox tasks (`- [ ]` / `- [x]`) total ≥3 → `status`
   - explicit list of modules/packages/pillars under headings → `map`
   - ≥3 ID-prefixed rows (BUG-/DEBT-/GAP-/TICKET-/ISSUE-) → `browse`
4. Default: `read`.

**Transparency rule:** the rendered HTML carries a small inference chip at the top — `Inferred: <intent>. Override: /super-bootstrap:render <path> as <other>`. User sees what was assumed; wrong call is one keystroke to fix.

## Output convention

```
.render/<sanitized-path>.html
```

Sanitization: source path slashes → `__`. Example: `docs/superpowers/specs/foo.md` → `.render/docs__superpowers__specs__foo.md.html`.

`.render/` is gitignored (agent ensures the line is present on each run). HTML is self-contained — inline CSS, no external assets, no JavaScript, opens directly in any browser.

Every render footer cites: `Source: <md path> · Regenerate: /super-bootstrap:render <md path> as <intent>` plus the derivation rule (`render contains no info absent from source — if it does, file a bug, fix the recipe, never edit the render`).

## Dispatch behavior

Gateway is thin — parse args, pre-flight validate, dispatch, relay. All recipe + render I/O happens in the agent so the gateway's context stays clean of HTML payload. Gateway-level pre-flight prevents subagent waste on garbage inputs.

On invocation:

1. **Parse args.** Recognize three forms above. If `as <intent>` present, validate intent ∈ {decision, status, map, browse, read}; unknown → refuse with the valid list.
2. **Pre-flight validate** (only when source path explicitly given — bare calls defer to agent inference):
   - **Path exists** → if not, refuse: `not found: <path>`.
   - **Extension class** — three buckets:
     - **Text-allowlist:** `.md`, `.markdown`, `.mdx`, `.txt`, `.rst`, `.adoc`, `.org`, `.text`. Proceed. Agent runs the full inference cascade — including content heuristics — on plain text too (plain text routinely carries decision audits, ID-prefix rows, status checkboxes). Heuristics fall through gracefully when md idioms are absent.
     - **Binary-blocklist:** `.pdf`, `.docx`, `.doc`, `.xlsx`, `.pptx`, `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.svg`, `.zip`, `.tar`, `.gz`, `.exe`, `.dll`, `.bin`, `.mp3`, `.mp4`, `.mov`, `.wav`. Hard refuse: `render is for text source, not binary (<ext>). use a converter first.` Never proceed — binary as text = garbage + potential terminal-corruption.
     - **Unknown extension** (anything else) → **MCQ escape hatch** via AskUserQuestion: "Extension `<ext>` not in known allowlist. Treat as text? (yes — read intent / no — cancel)." If yes, proceed forcing `intent = read`. If no, refuse: `cancelled by user`.
   - **File size** ≤ 150KB → if larger, refuse: `source too large for useful render (<size>KB > 150KB cap). Render past ~30KB stops being scannable.`
   - **Soft warn** (proceed) if size > 30KB: surface `note: large source (<size>KB) — render may be long`.
   - **Line-count guard** — if source has >2000 lines (count via Read), surface `note: source has <N> lines — wall-of-text risk; render will lean heavily on collapsibles`. Proceed regardless. Plain text can be small in bytes but huge in lines.
3. **Compute output path** if source path given (sanitize: `/` → `__`, append `.html`). If source not given, leave to agent (it will compute after source inference).
4. **Dispatch `render` subagent** (Agent tool, `subagent_type: "render"`). Prompt includes:
   - `source_path` (or `null` for bare invocation)
   - `intent` (or `null` if inferring)
   - `output_path` (or `null` if computing post-inference)
5. **Relay + auto-open.** Forward the agent's one-line summary verbatim. Then run platform-appropriate command to open `output_path` in the user's default browser:
   - Windows: `cmd /c start "" "<output_path>"`
   - macOS: `open "<output_path>"`
   - Linux: `xdg-open "<output_path>"`

   Open failure is non-fatal (headless env / no display) — render file already written, user can open manually.

## Skip dispatch if

- `as <unknown-intent>` → refuse with valid list. No agent dispatch.
- Source path given but pre-flight fails: not found / binary extension / over size cap / user-cancelled MCQ → refuse with one-line reason.

(Empty-source check and bare-call inference cascade happen in the agent — gateway only catches cheap mechanical fails.)

## Rules

- **Derivation only.** Render contains zero info absent from source. Drift = bug — fix the recipe, never the render.
- **Intent transparency.** Every render's header shows the intent + how it was picked (explicit / path / content / default). User can override in one keystroke.
- **On-demand only.** No hook, no auto-fire on save, no Claude self-invoke. User-call or Claude-offer-at-decision-moment only.
- **Throwaway output.** `.render/` is gitignored. Regenerate any time. Never hand-edit.
- **Self-contained HTML.** Inline CSS, no JS, no external deps. Single file travels.
- **Read-mostly skill.** Touches only: source (read), `.gitignore` (read/append-only), `.render/<file>.html` (write). Nothing else.
- **Verbatim relay.** Agent returns confirmation line; gateway forwards without re-summary.

## Why dispatched (Sonnet)

Recipe + intent inference + structural HTML generation. Sonnet sweet spot — Opus overkill for templated render, Haiku weaker on "which intent fits this source" judgment. Single round-trip, agent writes file, gateway relays path.

## Out of Scope

- **Auto-render on save** — would make render feel like state, drift toward duplicate truth.
- **Render-to-PDF / render-to-slides** — HTML covers shareability; other output shapes layer later if signal emerges.
- **Editing the rendered HTML** — never. Source-md change → regenerate.
- **Committing rendered HTML** — never. `.render/` is gitignored; if a render needs to travel, copy the file out manually.
- **Interactive widgets (sliders, kanban, prompt tuners)** — render is a viewing surface, not a tool surface. AI-generated JS is a security cost we don't pay here.
- **Multi-doc compare** — single source per call. Compare patterns can layer if signal warrants.
