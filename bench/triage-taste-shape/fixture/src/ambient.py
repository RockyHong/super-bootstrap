"""Schedule harbor ambient lines by time of day.

Keys must exist in content/ambient.json; the loader raises on a missing key.
"""
import json
from pathlib import Path

SCHEDULE = {
    "dawn": ("ambient.dawn.crate", "ambient.dawn.bread", "ambient.dawn.oar"),
    "dusk": (
        "ambient.dusk.rope",
        "ambient.dusk.lamp",
        "ambient.dusk.salt",
        "ambient.dusk.door",
        "ambient.dusk.tar",
        "ambient.dusk.coin",
    ),
    "night": (
        "ambient.night.bell",
        "ambient.night.nets",
        "ambient.night.hull",
        "ambient.night.cards",
    ),
}


def load(root: Path) -> dict:
    lines = json.loads((root / "content" / "ambient.json").read_text(encoding="utf-8"))
    for keys in SCHEDULE.values():
        for key in keys:
            if key not in lines:
                raise KeyError(f"ambient key missing from content: {key}")
    return lines


def lines_for(root: Path, time_of_day: str) -> list[str]:
    lines = load(root)
    return [lines[k] for k in SCHEDULE[time_of_day]]
