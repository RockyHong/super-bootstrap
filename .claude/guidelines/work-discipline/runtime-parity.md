# Runtime Parity

When authoring tool config that affects ambient behavior (hooks, settings, scripts, plugin enables), the placement layer determines which runtimes load it. Config placed in a layer that loads in some runtimes but not others creates silent behavioral divergence — same prompt, different tool selection, different output across environments. The bug is the placement asymmetry, not the config.

Principle: **place config at the level where ambient parity must hold across all consumer runtimes**. If a behavior must fire everywhere the repo runs, the config must live where every target runtime loads it.

## Adopted rule

Before placing or accepting an ambient-behavior config:

1. **Name the runtimes** the repo runs in (developer machine, cloud orchestrator, CI, remote-ssh, ephemeral sandbox, container).
2. **Identify the layers each runtime loads** (user-global, project-tracked, upstream-bundled, runtime-default).
3. **Pick the lowest layer covered by every target runtime.** If the behavior must fire in all of them, place above the join.
4. **Document a parity exception** when intentionally placing in a partial-coverage layer — single line naming which runtimes get it and which do not.

The lowest-common layer is often more user-global than feels intuitive. The intuition "project-local is the right home for project-specific config" trades correctness for placement convenience.

## Failure modes

- **Project-tracked config expecting universal fire** — placed in a layer one or more target runtimes skip (cloud sandbox, headless agent, CI); divergence surfaces sessions later as "why does behavior differ between environments?"
- **Parity exception undeclared** — config intentionally placed at a partial-coverage layer with no note → future reader cannot tell whether the asymmetry was deliberate or oversight.

Pairs with [`trust-upstream-defaults.md`](trust-upstream-defaults.md) — downstream overlay and runtime asymmetry compound.
