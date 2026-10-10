# Ambient voice — harbor district

**Status:** ratified 2026-08-02 (approval: author)

Ambient lines are what the player overhears while walking the harbor district. They are the
district's only narration. Lines live in [`content/ambient.json`](../../content/ambient.json),
keyed `ambient.{time}.{noun}`; [`src/ambient.py`](../../src/ambient.py) schedules them by time of day.

## Rules

1. **Fragments, not reports.** A line is a sensory beat the player catches, not a sentence that explains.
2. **Present tense, no second person.** Never "you".
3. **One concrete noun carries the line.** No abstractions ("sorrow", "regret", "memory") — the
   object does the feeling. Example: `ambient.dusk.lamp` — the post, not the loneliness.
4. **Nine words at most.**

## Exemplars

Lines that set the bar for new copy:

- `ambient.dusk.rope` — "Wet rope, creaking. Nobody coiling it."
- `ambient.dusk.lamp` — "The lamplighter skips the third post again."
- `ambient.night.bell` — "One bell. Then the gulls go quiet."
