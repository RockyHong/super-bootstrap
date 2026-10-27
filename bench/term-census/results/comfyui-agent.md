# Re: term fan-in census — ComfyUI agent/ (workflows repo, 9aca623)

Run from the repo root with super-bootstrap 5.6.0 (doc-links from the 5.6.0 cache). Read-only; nothing in this repo changed.

## 1. Census output (whole)

Pasted verbatim from `census.sh`.

Raw output: [`comfyui-agent.census.txt`](comfyui-agent.census.txt).


## 2. Labels

Repo shape in one line: a ComfyUI workflow factory. Python builders in `tools/` (`graphs.py`, `*_polish.py`, `ui_lint.py`, `comfy.py`) emit shipped workflow JSON; `README.md` is the hub (Gotchas, Routing, Server, Files index); `docs/specs/` hold four feature specs; `prompting/` holds per-model writer blocks.

### A — top 20

| term | docs | label | home / links |
|---|---|---|---|
| comfy | 10 | leak (partly terminology) | `tools/comfy.py` is the render interface; home `docs/specs/agent-render-interface.md` exists. Most mentions name the CLI verbs (`comfy.py run/submit/free`) — command usage, fine. Mentions do not link the spec. |
| graphs | 8 | leak | `tools/graphs.py` builder; narrated in README, overview, techstack, specs. Owner = the file; `build-ship-pipeline.md` is the natural home for "builder" as a concept. |
| ui_lint | 7 | terminology via tool | stands for the **UI contract** check. Home: `CLAUDE.md § UI contract` + lint header. Some mentions link `tools/ui_lint.py` (in-degree 4), none link the CLAUDE.md section. |
| audio_graphs | 6 | leak | builder file. |
| convert_headless | 4 | leak | converter internals narrated outside its owner. |
| jobs | 4 | path/noise | `api/jobs.json` + the generic word. |
| shipped-workflows | 4 | path/noise | doc path. |
| wf_polish | 4 | leak | polish step tool. Concept "polish" is terminology (see §3). |
| HERMES | 3 | terminology | Hermes (outside agent). Home `HERMES.md` exists; linked from overview + agent-render-interface only (2 of ~6 docs naming her). |
| agent-render-interface | 3 | path/noise | doc path. |
| build-ship-pipeline | 3 | path/noise | doc path. |
| dasiwa_polish | 3 | leak | per-model polish builder. |
| dogfood | 3 | leak/terminology unclear | `tools/dogfood.py` + "dogfood run" as a verify step; no home doc defines the step. |
| image_graphs | 3 | leak | builder file. |
| image_polish | 3 | leak | builder file. |
| inspect_video | 3 | leak | tool. |
| prompt_writer | 3 | leak | PE runner; concept home `docs/specs/prompt-generation.md`. |
| qwen | 3 | terminology | model family. Home `prompting/qwen.md` (in-degree 3). Mixed: file stem and model name collide. |
| qwen21_polish | 3 | leak | per-model polish builder. |
| ui_layout | 3 | leak | layout helpers. |

Ranks 21-40 of A include shipped workflow display names (`[Image t2i] Krea 2`, `[Post] Film finish`, `[Video r2v] H3`) — these are terminology (user-facing product names); home = the file + `docs/specs/shipped-workflows.md`, rarely linked.

### B — top 20

| token | docs | label | note |
|---|---|---|---|
| CLAUDE.md | 5 | path/noise | |
| tools/graphs.py | 5 | leak | same as A. |
| ui_lint.py | 5 | path/noise | command usage. |
| .json | 4 | noise | |
| README.md | 4 | path/noise | |
| prompting/ | 4 | path/noise | folder pointer. |
| renders/ | 4 | path/noise | |
| tools/comfy.py | 4 | path/noise | |
| --pe | 3 | leak | CLI flag narrated in several docs; owner = comfy.py guide. |
| /free | 3 | path/noise | API endpoint. |
| /prompt | 3 | path/noise | API endpoint. |
| D:/AI/REGISTRY.md | 3 | path/noise | device pointer. |
| HERMES.md | 3 | path/noise | |
| MiniMaxChunkFeedForward | 3 | leak | a node class from one gotcha, restated in 3 docs. Clearest leak in the set. |
| OFFICIAL_PE | 3 | leak | lint constant; CLAUDE.md names it on purpose (rule points at the lint). |
| PE_MODEL | 3 | leak | lint constant; the concept "PE model" is terminology. |
| TextGenerate | 3 | leak | node class. |
| api/<name>.note.md | 3 | path/noise | |
| assets/INDEX.md | 3 | path/noise | |
| audio_graphs.py | 3 | leak | |

## 3. Hot terms the census misses (plain prose / bold)

Rough count = tracked `*.md` files hitting a case-insensitive grep, 65 files (includes `prompting/`, `docs/work/`, served `.claude/guidelines/`; excludes `api/`).

| term | ~docs | home today |
|---|---|---|
| Direction (the prompt field / writer output) | 26 | none single; defined per writer block in `prompting/*.md` |
| INPUTS (the ① INPUTS knob group) | 19 | `CLAUDE.md § UI contract` rule 2 |
| builder | 18 | implicit; `docs/specs/build-ship-pipeline.md` |
| writer block | 15 | `docs/specs/prompt-generation.md` (most mentions), `prompting/README.md` index |
| prompt enhance / PE | 15 | `CLAUDE.md` rule 5 + `prompt-generation.md` — two homes |
| polish | 13 | none; spread across README + specs |
| loop point / seam | 13 | README Gotchas |
| best set | 12 | none; README + CLAUDE.md use it, never defined in one place |
| TGW (LLM wrapper node) | 12 | README (23 hits) |
| Gotchas | 12 | `README.md § Gotchas` |
| Knobs (canvas README table) | 10 | CLAUDE.md rule 2 / lint R11 |
| UI contract | 7 | `CLAUDE.md § UI contract` |
| packed core | 4 | `docs/specs/shipped-workflows.md` (linked once from CLAUDE.md) |
| agent_fixed | 4 | CLAUDE.md rule 2 |

None of these appear in A; only `agent_fixed` / `OFFICIAL_PE`-style constants surface in B. The real vocabulary of this repo is UI-contract and prompt-pipeline prose, which the census does not see.

## 4. Shape notes

- **Hub README skews C and inflates A.** `README.md` (in-degree 17) is the de facto glossary + Files index. Its Files section names every `tools/*.py` stem on purpose, so A's top ranks are mostly an index doing its job, not leaks. A ledger should treat an index section's mentions as pointers, not fan-in.
- **File-derived terms here are tool stems, not concepts.** In this repo the file layer and concept layer barely overlap (`graphs.py` vs "builder", `wf_polish.py` vs "polish", `ui_lint.py` vs "UI contract"). Fan-in on stems flags the tool, while the concept it implements stays unregistered.
- **A large doc surface lives outside `.md`.** Each shipped workflow embeds a canvas README (Knobs table) as a Markdown note node inside its `.json`; `api/*.note.md` carry per-workflow notes. A ledger that only reads `docs/` + root misses the user-facing vocabulary.
- **Name collisions.** `qwen` is both a file stem and a model family; `comfy` is the tool, the server and the product. Census cannot split them.
- **CLAUDE.md is a home, not just a reader.** Several terms (INPUTS, agent_fixed, UI contract, prompt enhance) have their only definition in `CLAUDE.md`, which is harness and read-only to doc-sync. A ledger that forbids harness as a home would have no home for them.
- **Dated grounding docs** (`docs/*-grounding-2026-*.md`) repeat model vocabulary heavily (`Direction` 16 in one doc); they are history-shaped and probably belong in the ledger's skip set.
