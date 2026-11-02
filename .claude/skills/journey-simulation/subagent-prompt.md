# Runner prompt template — journey-simulation

Layer 3 (runner-facing) prompt. Sealed against Layer 3 forbidden vocab from `SKILL.md`. Used by the gateway during Phase 3 dispatch as the positional prompt of the headless process (§ Dispatch call shape).

## Fill discipline

- Each placeholder fills from Phase 1 curated inputs (post-Phase-0 de-bias).
- If any placeholder requires the gateway to compose new prose, check that prose against the Layer 3 forbidden vocab list in `SKILL.md` before substitution.
- Do not add anything to this template that isn't a placeholder substitution. No "extra context", no "helpful notes to the runner", no be-honest pleas.

## Placeholders

| Placeholder | Source | Notes |
|---|---|---|
| `{persona_identity}` | Phase 1 input #1, curated | role + 1-3 differentiating facts. Not a biographic dump. Naturalistic. |
| `{pre_context}` | Phase 1 input #2, baggage portion | What they bring — prior tools, recent events. ~1 sentence. |
| `{arrival_situation}` | Phase 1 input #2, channel portion | Where they came from in this moment + the entry point. ~1 phrase. |
| `{posture}` | Phase 1 input #2, posture portion | Current mood / urgency. ~1 phrase. Omit if unspecified after Phase 0. |
| `{drive}` | Phase 1 input #3 | "want to X" OR "curious about Y, specifically Z". Neutral framing — no aspirational leak. |
| `{sandbox}` | Phase 2 sandbox questions 1–3 only (perceive + actions + transitions) | Questions 4 (hidden) and 5 (out-of-bounds) are gateway-side; never substituted into the prompt. |
| `{output_file_path}` | Gateway-computed | `{neutral-dir}/{persona-slug}_{scenario-slug}.md` — inside the neutral directory the process runs in (§ Dispatch call shape), never inside the caller's project. The two slugs are the only caller-derived words in it; check them against the Layer 3 fence like any other substitution. The gateway moves the file to `docs/walkthroughs/{batch}/` after the run. |

## Hidden affordances + out-of-bounds — gateway-side only

The sandbox 5-question contract (SKILL.md §Phase 2) collects 5 answers. The brief receives only answers 1, 2, 3. Answers 4 (hidden) and 5 (out of bounds) stay with the gateway.

- Hidden affordances let the runner's narration reveal whether they discover or miss the hidden item — that signal extracts in Phase 5.
- Out-of-bounds attempts surface as "I tried X but the screen didn't seem to support it" in narration — extracted as missing-affordance signal.

If both 4 and 5 are dumped into the brief, those signals are pre-resolved and the runner has nothing to discover or hit.

## The template

Everything between the lines below is what the runner receives. **Nothing else.**

---

You are {persona_identity}.

Recently, {pre_context}.

You came here {arrival_situation}. {posture}.

You want to {drive}.

What's available to you:

{sandbox}

(That's everything you can see and do. You don't have documentation, help, or anything beyond this.)

Talk through what's happening as you move through this:
- What you notice
- What you think it means
- What you try
- What happens after
- How you feel about it

It's fine to:
- Skip things that don't seem worth your time
- Quit if you've had enough — say what made you quit
- Try things that aren't obviously supported — see what happens
- Forget what you were doing
- Click the wrong thing because something else caught your eye
- Be wrong about what something means

Move through this however feels natural.

When done — finished, gave up, or got sidetracked — write your full walkthrough (every state, every reaction, what you tried, what happened, what you thought) to:

{output_file_path}

Write what happened — what you saw, did, thought, felt. When nothing else is happening, stop. Don't tack a summary, takeaways, or "what would be better" on the end. That's not the kind of writing this is.

Use the Write tool. The file is mandatory.

Begin.

---

## Anti-templates — what NOT to add

Common "helpful additions" that contaminate Layer 3. Each is forbidden:

| Addition | Why forbidden |
|---|---|
| "Please be honest in your reactions" | "honest" implies dishonesty is the default → performance frame |
| "Imagine you are this person" | "imagine you are" = role-assignment, not identity |
| "Pretend you've never seen this before" | "pretend" = role-assignment |
| "Simulate clicking through the screens" | "simulate" = performance frame |
| "Try to act like a real first-time user" | "act like", "real ... user" = performance frame + meta-vocabulary |
| "We're testing / evaluating the onboarding flow" | "testing", "evaluating" = meta-frame |
| "The team wants to know if X..." | leaks caller's hypothesis |
| "Rate each step on friction (1-10)" | friction taxonomy in Layer 3 + numeric grading |
| "After each step, report what felt wrong" | meta-grading frame |
| "Provide a summary of friction points and recommendations" | recommendations forbidden + friction taxonomy in Layer 3 |
| "You are a participant / subject / probe / runner in this study" | every word forbidden |
| "This is for a usability study / cognitive walkthrough" | meta-frame disclosure |
| Closing summary / takeaways / "what would be better" list at end of narration | Helpful-assistant default loads "summary at end" pattern. Counter explicitly via the "stop when nothing's happening" line above. Runner-side fix-list = recommendations contamination. |
| Output path containing "journey-simulations", "simulation", "test", or other Layer 3 forbidden vocab | Path string substitutes into prompt and is read by the runner. Keep the path to the neutral directory plus the two slugs. |
| Output path inside the caller's project, or carrying its folder name / codename / flow label | The runner reads the path as fact — a project named for its hypothesis hands the hypothesis over. The neutral directory keeps it out by construction. |

## Dispatch call shape

One headless process per runner, started from a neutral directory outside the caller's project. The gateway's Bash call, with the filled template as the final argument:

```
PROJECT_ROOT="$PWD"                     # the caller's project root — the gateway's cwd
RUN="$(mktemp -d)"; RUN="$(cygpath -m "$RUN" 2>/dev/null || printf '%s' "$RUN")"   # OS temp root, native path form
NARRATOR="$(sed '1,/^---$/d' "$PROJECT_ROOT/.claude/agents/walkthrough-narrator.md")"   # body only, frontmatter stripped
[ -n "$NARRATOR" ] || { echo "narrator body missing — run /resolve-claude-config"; exit 1; }
( cd "$RUN" && claude -p --model sonnet --system-prompt "$NARRATOR" \
    --setting-sources "" --strict-mcp-config --disable-slash-commands --no-session-persistence \
    --permission-mode acceptEdits --tools Write \
    -- "<filled template, {output_file_path} = $RUN/{persona-slug}_{scenario-slug}.md>" )
```

- `--setting-sources ""` withholds every instruction file (device, project, local), every hook, and every MCP instruction block; `--strict-mcp-config` keeps project MCP servers out; `--system-prompt` replaces the default prompt with the narrator body. The process still receives the runtime's environment block — OS, date, model name, account email, and `$RUN`.
- `--tools Write` is the whole toolkit; `acceptEdits` lets the write land in `$RUN` without a prompt. Read / Grep / Bash / WebSearch / WebFetch would leak lookup access and create lookup-thinking primes that distort behavior.
- The `--` terminator keeps the template positional after the variadic flags; without it the prompt is swallowed and the process exits before any call.
- N runners start as N such processes at once (`&` + `wait`) from the same `$RUN`, one output file each. After `wait`, move `$RUN/*.md` to `$PROJECT_ROOT/docs/walkthroughs/{batch}/` and remove `$RUN`.
- The served agent file is read for its body only, from the project root: `.claude/agents/walkthrough-narrator.md`. The guard line stops the run when the body is empty (file absent, wrong cwd) — route the caller to `/resolve-claude-config`, never substitute a body from memory.
- Path boundary: `$RUN` is handed to a native process and substituted into the brief, so it is converted to the native form (`cygpath -m` under Git Bash; a no-op elsewhere). The runner's path therefore carries the OS account name under a Windows temp root.
- Permission: the Bash call that starts the processes goes through the gateway session's normal permission flow — one grant on the wrapper command (name it to the caller in a mode that prompts). A session that cannot run `claude` (cloud, no PATH entry) has no runner; say so at the checkpoint.

The mandatory `Runner: claude -p` line in SKILL.md Phase 3's confirmation-checkpoint output template exists so the gateway has to type it before caller approval. If that line is absent from the checkpoint, the dispatch is not approved.
